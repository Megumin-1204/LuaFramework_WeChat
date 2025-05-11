using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
using System;

public static class XLuaGenConfig
{
    // 需要生成wrap的C#类列表
    [LuaCallCSharp]
    public static List<System.Type> LuaCallCSharp = new List<System.Type>()
    {
        typeof(UIManager),        // 稍后会创建的UI管理器
        typeof(WeChatManager),   // 之前创建的微信管理器
        typeof(GameObject),
        typeof(Transform),
        typeof(Button),
        typeof(Canvas),
        typeof(System.Action),
        typeof(System.Func<>),
        typeof(GameRoot),
        typeof(ResourceManager),
        typeof(UnityEngine.AssetBundleManifest),
        typeof(Action<bool>),
        typeof(Action<UnityEngine.Object>),
        typeof(UIMaskManager),
    };
}