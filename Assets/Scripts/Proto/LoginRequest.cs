using ProtoBuf;

namespace Game.Manager
{
	/// <summary>
	/// 模拟登录请求（仅用于本地 Mock 测试）。
	/// </summary>
	[ProtoContract]
	public class LoginRequest
	{
		[ProtoMember(1)]
		public string Username { get; set; }

		[ProtoMember(2)]
		public string Password { get; set; }
	}
}