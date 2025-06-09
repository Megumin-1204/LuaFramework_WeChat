using ProtoBuf;

namespace Game.Manager
{
	/// <summary>
	/// 模拟登录响应（仅用于本地 Mock 测试）。
	/// </summary>
	[ProtoContract]
	public class LoginResponse
	{
		[ProtoMember(1)]
		public bool Success { get; set; }

		[ProtoMember(2)]
		public string Message { get; set; }
	}
}