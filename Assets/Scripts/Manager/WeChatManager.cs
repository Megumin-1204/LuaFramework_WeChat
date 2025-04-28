using UnityEngine;
using XLua;

public class WeChatManager : MonoBehaviour
{
    [CSharpCallLua]
    public delegate void LoginCallback(bool success, string code);

    public static void Login(LoginCallback callback)
    {
        // 微信SDK调用示例
        // WX.Login(new LoginOption {
        //     success = res => callback(true, res.code),
        //     fail = res => callback(false, "")
        // });
    }
}