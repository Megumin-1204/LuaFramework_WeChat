using System;
using System.IO;
using ProtoBuf;
using UnityEngine;

namespace Game.Manager
{
    /// <summary>
    /// 本地 Mock 网络响应，用于“无真实服务器”时的本地测试。
    /// 里面的逻辑和正式服务器交互完全分离，方便后续切换。
    /// </summary>
    public static class MockNetwork
    {
        /// <summary>
        /// 客户端调用 NetworkManager.SendRaw(...) 时，拦截并进入此方法进行本地模拟。
        /// </summary>
        public static void HandleSend(ushort msgId, byte[] body)
        {
            Debug.Log($"[MockNetwork] 收到 MsgID={msgId}, BodyLength={body?.Length}");

            switch ((MsgID)msgId)
            {
                case MsgID.LoginRequest:
                    SimulateLoginResponse(body);
                    break;

                case MsgID.HeartbeatRequest:
                    SimulateHeartbeatResponse();
                    break;

                default:
                    Debug.LogWarning($"[MockNetwork] 未处理的 MsgID={msgId}");
                    break;
            }
        }

        /// <summary>
        /// 模拟登录响应：先反序列化客户端发来的 LoginRequest，然后构造 LoginResponse 回给客户端。
        /// </summary>
        private static void SimulateLoginResponse(byte[] body)
        {
            try
            {
                // 反序列化客户端发来的 LoginRequest
                LoginRequest req;
                using (var ms = new MemoryStream(body))
                {
                    req = Serializer.Deserialize<LoginRequest>(ms);
                }
                Debug.Log($"[MockNetwork] 模拟处理 LoginRequest (Username={req.Username}, Password={req.Password})");

                // 构造一个模拟的 LoginResponse
                var resp = new LoginResponse
                {
                    Success = true,
                    Message = $"模拟登录成功，欢迎 {req.Username}！"
                };

                // 序列化响应
                byte[] respBytes;
                using (var ms2 = new MemoryStream())
                {
                    Serializer.Serialize(ms2, resp);
                    respBytes = ms2.ToArray();
                }

                // 回传给 NetworkManager，让它派发给 Lua
                NetworkManager.Instance?.SimulateReceive((ushort)MsgID.LoginResponse, respBytes);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[MockNetwork] SimulateLoginResponse 异常: {ex}");
            }
        }

        /// <summary>
        /// 模拟心跳响应，直接构造一个空的 HeartbeatResponse 回给客户端。
        /// </summary>
        private static void SimulateHeartbeatResponse()
        {
            try
            {
                var resp = new HeartbeatResponse();
                byte[] respBytes;
                using (var ms = new MemoryStream())
                {
                    Serializer.Serialize(ms, resp);
                    respBytes = ms.ToArray();
                }
                NetworkManager.Instance?.SimulateReceive((ushort)MsgID.HeartbeatResponse, respBytes);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[MockNetwork] SimulateHeartbeatResponse 异常: {ex}");
            }
        }
    }
}
