using System;
using System.Collections;
using System.IO;
using UnityEngine;
using XLua;
using Game.Manager;    // ← 为了引用 NetworkManager

[DisallowMultipleComponent]
[LuaCallCSharp]  // 导出给 Lua
public class GameRoot : MonoBehaviour
{
    // —— 单例 —— 
    private static GameRoot _instance;
    public static GameRoot Instance
    {
        get
        {
            if (_instance == null)
            {
                // 尝试场景中查找
                _instance = FindObjectOfType<GameRoot>();
                if (_instance == null)
                {
                    // 如果场景里没有，就自动创建一个
                    var go = new GameObject("GameRoot");
                    _instance = go.AddComponent<GameRoot>();
                    DontDestroyOnLoad(go);
                    Debug.Log("[GameRoot] 自动创建单例实例");
                }
            }
            return _instance;
        }
    }

    private LuaEnv _luaEnv;
    [SerializeField] private bool debugMode = true;

    void Awake()
    {
        // 单例保护
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        Log("[CORE] GameRoot Awake");

        // 1) 初始化所有 C# 管理器
        InitializeManagers();

        // 2) 启动 Lua 环境并执行入口脚本
        InitializeLuaEnv();
    }

    #region C# 管理器初始化

    private void InitializeManagers()
    {
        Log("[INIT] 开始初始化 C# 管理器");

        // 网络模块：保证 NetworkManager.Instance 不为 null
        AddManager<NetworkManager>();
        // 资源管理
        AddManager<ResourceManager>();
        // UI 管理
        AddManager<UIManager>();
        // UI 遮罩
        AddManager<UIMaskManager>();
        // 定时器管理
        AddManager<TimerManager>();
        // （如有其它全局管理器，按需继续 AddManager<T>() ）

        Log("[INIT] C# 管理器初始化完成");
    }

    /// <summary>
    /// 尝试从场景中获取 T，如果没有则创建一个并挂到 GameRoot 下
    /// </summary>
    private T AddManager<T>() where T : Component
    {
        // 优先查找已有实例
        T mgr = FindObjectOfType<T>();
        if (mgr != null)
        {
            Log($"[MGR] 复用已有管理器 {typeof(T).Name}");
        }
        else
        {
            // 新建一个 GameObject 承载它
            var go = new GameObject(typeof(T).Name);
            go.transform.SetParent(transform, false);
            mgr = go.AddComponent<T>();
            DontDestroyOnLoad(go);
            Log($"[MGR] 自动创建管理器 {typeof(T).Name}");
        }
        return mgr;
    }

    #endregion

    #region Lua 环境初始化

    private void InitializeLuaEnv()
    {
        Log("[LUA] 启动 xLua 虚拟机");
        _luaEnv = new LuaEnv();
        ConfigureLuaLoader();

        Log("[LUA] 正在执行 require 'Entry.Main'");
        try
        {
            _luaEnv.DoString("require 'Entry.Main'");
            Log("[LUA] Lua 主入口执行完成");
        }
        catch (Exception ex)
        {
            Debug.LogError($"[GameRoot] Lua 执行失败: {ex}");
        }
    }

    private void ConfigureLuaLoader()
    {
        _luaEnv.AddLoader((ref string filepath) =>
        {
            // filepath 形式："Entry.Main"
            var luaPath = Path.Combine(Application.dataPath, "Lua",
                                      filepath.Replace('.', '/') + ".lua");
            return File.Exists(luaPath)
                ? File.ReadAllBytes(luaPath)
                : null;
        });
    }

    #endregion

    #region XLua 延迟接口

    /// <summary>
    /// 供 Lua 层通过 Wrap 调用，实现延迟执行
    /// </summary>
    public void LuaInvoke(Action action, float delay)
    {
        StartCoroutine(InvokeRoutine(action, delay));
    }

    private IEnumerator InvokeRoutine(Action action, float delay)
    {
        yield return new WaitForSeconds(delay);
        action?.Invoke();
    }

    #endregion

    #region 日志

    private void Log(string msg)
    {
        if (debugMode) Debug.Log("[GameRoot] " + msg);
    }

    #endregion
}
