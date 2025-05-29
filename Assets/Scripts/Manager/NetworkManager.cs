using System;
using System.Net.Sockets;
using System.Threading;
using System.Collections.Generic;
using UnityEngine;

namespace Game.Manager
{
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
            // 执行主线程队列中的回调
            lock (_mainQueue)
            {
                while (_mainQueue.Count > 0) _mainQueue.Dequeue().Invoke();
            }
        }

        void OnDestroy()
        {
            Disconnect();
        }

        /// <summary>
        /// 建立 TCP 连接
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
        /// 断开连接
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
        /// 发送一个已编码的二进制 Protobuf 消息体
        /// </summary>
        public void SendRaw(ushort msgId, byte[] body)
        {
            if (_stream == null || !_client.Connected) return;

            using var packet = new System.IO.MemoryStream();
            // 写消息 ID（2 字节）
            packet.Write(BitConverter.GetBytes(msgId), 0, 2);
            // 写消息长度（4 字节）
            packet.Write(BitConverter.GetBytes(body.Length), 0, 4);
            // 写消息体
            packet.Write(body, 0, body.Length);

            _stream.Write(packet.GetBuffer(), 0, (int)packet.Length);
        }

        /// <summary>
        /// 注册接收到某消息 ID 时的回调，Lua 层会在回调中解码二进制到表
        /// </summary>
        public void RegisterHandler(ushort msgId, Action<byte[]> handler)
        {
            _handlers[msgId] = handler;
        }

        /// <summary>
        /// 接收线程主循环：读包头+包体，然后派发到主线程
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

                    // 派发到主线程
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
    }
}
