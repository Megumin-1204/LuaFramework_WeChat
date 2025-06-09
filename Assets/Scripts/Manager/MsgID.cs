namespace Game.Manager
{
	/// <summary>
	/// 所有消息 ID 枚举，客户端与服务器（或 Mock）需要保持一致。
	/// </summary>
	public enum MsgID : ushort
	{
		LoginRequest      = 1,
		LoginResponse     = 2,
		HeartbeatRequest  = 3,
		HeartbeatResponse = 4,
		// ───────────────────────────────────────────
		// 后续游戏业务消息统一往下追加，例如：
		// PlayerInfoUpdate = 5,
		// ChatMessage      = 6,
		// ……
	}
}