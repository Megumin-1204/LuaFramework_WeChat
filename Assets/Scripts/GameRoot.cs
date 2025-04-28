using System;
using System.IO;
using UnityEngine;
using XLua;
using System.Collections;
using System.Collections.Generic;

[DisallowMultipleComponent] // 防止重复挂载
public class GameRoot : MonoBehaviour
{
    // 单例实例
    public static GameRoot Instance { get; private set; }
    
    // Lua虚拟机环境
    private LuaEnv _luaEnv;
    
    // 调试模式开关
    [SerializeField] private bool debugMode = true;

    void Awake()
    {
        InitializeSingleton();
        InitializeCoreFramework();
    }

    #region 初始化流程
    // 单例初始化 -----------------------------------------------------------------
    private void InitializeSingleton()
    {
        if (Instance != null)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        DontDestroyOnLoad(gameObject);
        Log("[CORE] GameRoot 单例初始化完成");
    }

    // 核心框架初始化 -------------------------------------------------------------
    private void InitializeCoreFramework()
    {
        StartCoroutine(InitializeStepByStep());
    }

// GameRoot.cs 修改初始化协程
    private IEnumerator InitializeStepByStep()
    {
        // 阶段1：初始化C#管理器
        Log("[INIT] 开始初始化C#管理器");
        InitializeManagers();
    
        // 阶段2：等待UIManager完全就绪
        int maxWaitFrames = 10;
        while (UIManager.Instance == null && maxWaitFrames-- > 0)
        {
            Log($"[INIT] 等待UIManager初始化 (剩余等待帧数: {maxWaitFrames})");
            yield return null;
        }
    
        if (UIManager.Instance == null)
        {
            Debug.LogError("UIManager初始化超时！");
            yield break;
        }

        // 阶段3：初始化Lua环境
        Log("[INIT] 开始初始化Lua虚拟机");
        InitializeLuaEnv();
    }

    // 管理器初始化 ---------------------------------------------------------------
    private void InitializeManagers()
    {
        Log("[CORE] 开始初始化管理器...");
        
        // 动态添加管理器组件
        AddManager<UIManager>();
        // AddManager<AudioManager>();
        // AddManager<NetworkManager>();
        
        Log("[CORE] 管理器初始化完成");
    }

    // Lua环境初始化 -------------------------------------------------------------
    private void InitializeLuaEnv()
    {
        Log("[LUA] 正在启动xLua虚拟机...");
        
        _luaEnv = new LuaEnv();
        ConfigureLuaLoader();
        
        // 启动Lua主逻辑
        SafeStartLua();
        
        Log("[LUA] 虚拟机启动完成");
    }
    #endregion

    #region 核心方法
    // 通用管理器添加方法 ---------------------------------------------------------
    private T AddManager<T>() where T : Component
    {
        var mgr = gameObject.AddComponent<T>();
        Log($"[MGR] 添加管理器: {typeof(T).Name} (ID: {mgr.GetInstanceID()})");
        return mgr;
    }

    // Lua加载器配置 -------------------------------------------------------------
    private void ConfigureLuaLoader()
    {
        _luaEnv.AddLoader((ref string filepath) => {
            // 优先加载xLua内置脚本
            if (filepath == "xlua") 
            {
                string xluaPath = "XLua.Resources.xlua";
                TextAsset asset = Resources.Load<TextAsset>(xluaPath);
                return asset.bytes;
            }

            // 原有加载逻辑
            string path = Path.Combine(Application.dataPath, "Lua", 
                filepath.Replace('.', '/') + ".lua");
            return File.Exists(path) ? File.ReadAllBytes(path) : null;
        });
    }

    // 安全的Lua启动 -------------------------------------------------------------
    private void SafeStartLua()
    {
        try
        {
            _luaEnv.DoString("require 'Main'");
        }
        catch (Exception ex)
        {
            Debug.LogError($"Lua入口执行失败: {ex.Message}");
            Debug.LogException(ex);
            ShutdownFramework();
        }
    }
    #endregion
    
    // 在GameRoot类中添加
    public void LuaInvoke(Action action, float delay)
    {
        StartCoroutine(InvokeRoutine(action, delay));
    }

    private IEnumerator InvokeRoutine(Action action, float delay)
    {
        yield return new WaitForSeconds(delay);
        action?.Invoke();
    }

    #region 生命周期管理
    void OnDestroy()
    {
        ShutdownFramework();
    }

    // 框架关闭流程 --------------------------------------------------------------
    private void ShutdownFramework()
    {
        Log("[CORE] 正在关闭框架...");
        
        if (_luaEnv != null)
        {
            _luaEnv.Dispose();
            _luaEnv = null;
            Log("[LUA] 虚拟机已释放");
        }
        
        // 其他资源释放操作...
    }
    #endregion

    #region 调试工具
    private void Log(string message)
    {
        if (debugMode) Debug.Log(message);
    }

    private void LogWarning(string message)
    {
        if (debugMode) Debug.LogWarning(message);
    }
    #endregion
}