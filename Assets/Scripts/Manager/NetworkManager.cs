using System;
using System.Net.Sockets;
using System.Threading;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using ProtoBuf;

namespace Game.Manager
{
    /// <summary>
    /// 网络管理器：负责 TCP 连接、收发原始二进制包和向 Lua 派发回调。
    /// 包含两套逻辑：
    ///   1. 模拟环境（无真实服务器时）：由 MockNetwork.HandleSend(...) 模拟响应
    ///   2. 正式环境（接真实 Skynet 服务器时）：恢复到 _stream.Write(...) 并读取 _stream
    /// 客户端／Lua 均只使用 SendRaw() 和 RegisterHandler() 接口，不关心背后逻辑。
    /// </summary>
    public class NetworkManager : MonoBehaviour
    {
        public static NetworkManager Instance { get; private set; }

        private TcpClient _client;
        private NetworkStream _stream;
        private Thread _recvThread;
        private volatile bool _running;
        private readonly Queue<Action> _mainQueue = new Queue<Action>();
        private readonly Dictionary<ushort, Action<byte[]>> _handlers = new Dictionary<ushort, Action<byte[]>>();

        void Awake()
        {
            if (Instance != null) Destroy(this);
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        void Update()
        {
            // 执行主线程队列内的回调
            lock (_mainQueue)
            {
                while (_mainQueue.Count > 0)
                    _mainQueue.Dequeue().Invoke();
            }
        }

        void OnDestroy()
        {
            Disconnect();
        }

        /// <summary>
        /// 建立 TCP 长连接（正式逻辑）。如果要真正连 Skynet，Lua 端调用此接口。
        /// </summary>
        public void Connect(string host, int port)
        {
            try
            {
                _client = new TcpClient(host, port);
                _stream = _client.GetStream();
                _running = true;
                _recvThread = new Thread(ReceiveLoop) { IsBackground = true };
                _recvThread.Start();
                Debug.Log($"[Network] Connected to {host}:{port}");
            }
            catch (Exception e)
            {
                Debug.LogError($"[Network] Connect Error: {e}");
            }
        }

        /// <summary>
        /// 断开连接（正式逻辑）。如果需要重连或退出时可调用。
        /// </summary>
        public void Disconnect()
        {
            _running = false;
            _stream?.Close();
            _client?.Close();
            _recvThread?.Join();
            Debug.Log("[Network] Disconnected");
        }

        /// <summary>
        /// 发送一段已编码好的二进制 Protobuf 消息体。
        /// <para>Lua 端调用此接口，无论是否有真实服务器均可使用。</para>
        /// <para>如果要接真实 Skynet，把“#if REAL_SERVER”改为启用 _stream.Write(...)。</para>
        /// </summary>
        public void SendRaw(ushort msgId, byte[] body)
        {
            // -------- 模拟模式（本地 Mock） --------
            MockNetwork.HandleSend(msgId, body);

            // -------- 正式模式（连真实 Skynet） --------
            // 如果要启用正式逻辑，请把下面三行注释打开，并把 MockNetwork.HandleSend(...) 注释掉。
            /*
            if (_stream == null || !_client.Connected) return;
            SendToSocket(msgId, body);
            */
        }

        /// <summary>
        /// 真正往 Socket 写数据（正式模式调用）。
        /// </summary>
        private void SendToSocket(ushort msgId, byte[] body)
        {
            using var packet = new System.IO.MemoryStream();
            packet.Write(BitConverter.GetBytes(msgId), 0, 2);
            packet.Write(BitConverter.GetBytes(body.Length), 0, 4);
            packet.Write(body, 0, body.Length);
            _stream.Write(packet.GetBuffer(), 0, (int)packet.Length);
        }

        /// <summary>
        /// Lua 端注册回调：收到对应 msgId 时，会将字节数组传入 handler，由 Lua 再 decode 成表。
        /// </summary>
        public void RegisterHandler(ushort msgId, Action<byte[]> handler)
        {
            _handlers[msgId] = handler;
        }

        /// <summary>
        /// 接收线程主循环（正式模式）。不断从网络读取包头、包体，并派发到主线程。
        /// </summary>
        private void ReceiveLoop()
        {
            var header = new byte[6];
            try
            {
                while (_running)
                {
                    int read = 0;
                    // 先读 6 字节包头
                    while (read < 6)
                    {
                        int len = _stream.Read(header, read, 6 - read);
                        if (len <= 0) throw new SocketException();
                        read += len;
                    }

                    ushort id = BitConverter.ToUInt16(header, 0);
                    int bodyLen = BitConverter.ToInt32(header, 2);

                    var body = new byte[bodyLen];
                    read = 0;
                    // 再读 bodyLen 字节包体
                    while (read < bodyLen)
                    {
                        int len = _stream.Read(body, read, bodyLen - read);
                        if (len <= 0) throw new SocketException();
                        read += len;
                    }

                    // 派发给主线程
                    if (_handlers.TryGetValue(id, out var cb))
                    {
                        lock (_mainQueue)
                            _mainQueue.Enqueue(() => cb(body));
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogError($"[Network] ReceiveLoop Exception: {e}");
                _running = false;
            }
        }

        /// <summary>
        /// MockNetwork 模拟响应时调用：把响应的字节数组传给 Lua 注册的回调。
        /// </summary>
        public void SimulateReceive(ushort msgId, byte[] body)
        {
            if (_handlers.TryGetValue(msgId, out var cb))
            {
                lock (_mainQueue)
                    _mainQueue.Enqueue(() => cb(body));
            }
        }
        
        /// <summary>
        /// C# 端直接用 protobuf-net 把一个消息对象序列化成 byte[]。
        /// Lua 只需要调用这个方法，把表里的字段赋值给 C# 对象后传进来即可。
        /// </summary>
        public static byte[] Encode<T>(T msg) where T : class
        {
            using var ms = new MemoryStream();
            Serializer.Serialize(ms, msg);
            return ms.ToArray();
        }

        /// <summary>
        /// C# 端直接用 protobuf-net 把 byte[] 反序列化成指定类型的对象。
        /// Lua 端接到 byte[] 后，可以调用这个方法，得到 C# 对象，再从对象里取字段。
        /// </summary>
        public static object Decode(ushort msgId, byte[] data)
        {
            using var ms = new MemoryStream(data);
            switch ((MsgID)msgId)
            {
                case MsgID.LoginResponse:
                    return Serializer.Deserialize<LoginResponse>(ms);
                case MsgID.HeartbeatResponse:
                    return Serializer.Deserialize<HeartbeatResponse>(ms);
                // … 如有其它消息，按需加分支 …
                default:
                    throw new ArgumentException($"Unknown MsgID to decode: {msgId}");
            }
        }
    }
}
