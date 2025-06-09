using UnityEngine;
using ProtoBuf;  // 验证此次能否正常引用

namespace Game.Manager
{
	public class TestProto : MonoBehaviour
	{
		[ProtoContract]
		public class Dummy
		{
			[ProtoMember(1)]
			public int X { get; set; }
		}

		void Start()
		{
			var d = new Dummy { X = 1234 };
			byte[] bytes;
			using (var ms = new System.IO.MemoryStream())
			{
				Serializer.Serialize(ms, d);
				bytes = ms.ToArray();
			}
			var d2 = Serializer.Deserialize<Dummy>(new System.IO.MemoryStream(bytes));
			Debug.Log($"[TestProto] 成功反序列化 Dummy.X = {d2.X}");
		}
	}
}