using System;
using System.IO;
using UnityEngine;
using XLua;
using System.Collections;
using System.Collections.Generic;

[DisallowMultipleComponent]
public class GameRoot : MonoBehaviour
{
    public static GameRoot Instance { get; private set; }
    private LuaEnv _luaEnv;
    [SerializeField] private bool debugMode = true;

    void Awake()
    {
        InitializeSingleton();
        InitializeCoreFramework();
    }

    #region 初始化流程
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

    private void InitializeCoreFramework()
    {
        StartCoroutine(InitializeStepByStep());
    }

    private IEnumerator InitializeStepByStep()
    {
        // Phase 1：初始化 C# 管理器
        Log("[INIT] 开始初始化 C# 管理器");
        InitializeManagers();

        // Phase 2：等待 UIManager 就绪
        int maxWaitFrames = 10;
        while (UIManager.Instance == null && maxWaitFrames-- > 0)
        {
            Log($"[INIT] 等待 UIManager 初始化 (剩余帧数: {maxWaitFrames})");
            yield return null;
        }
        if (UIManager.Instance == null)
        {
            Debug.LogError("UIManager 初始化超时！");
            yield break;
        }

        // Phase 3：初始化 Lua 环境
        Log("[INIT] 开始初始化 Lua VM");
        InitializeLuaEnv();
    }

    private void InitializeManagers()
    {
        Log("[CORE] 添加并初始化管理器...");

        // UI 管理器（负责面板加载/遮罩/栈管理）
        AddManager<UIManager>();
        // 定时器管理器（负责 Lua/CS 定时、心跳）
        AddManager<TimerManager>();
        // 微信平台集成
        AddManager<WeChatManager>();
        // UI 遮罩/交互拦截
        AddManager<UIMaskManager>();
        // 资源管理器
        AddManager<ResourceManager>();
        // ……按照需要继续挂载其它管理器，如 NetworkManager、AudioManager 等

        Log("[CORE] C# 管理器初始化完成");
    }

    private void InitializeLuaEnv()
    {
        Log("[LUA] 启动 xLua VM...");
        _luaEnv = new LuaEnv();
        ConfigureLuaLoader();
        SafeStartLua();
        Log("[LUA] VM 启动完成");
    }

    private T AddManager<T>() where T : Component
    {
        var mgr = gameObject.AddComponent<T>();
        Log($"[MGR] 添加管理器 {typeof(T).Name} (ID: {mgr.GetInstanceID()})");
        return mgr;
    }

    private void ConfigureLuaLoader()
    {
        _luaEnv.AddLoader((ref string filepath) => {
            if (filepath == "xlua")
            {
                var asset = Resources.Load<TextAsset>("XLua/Resources/xlua");
                return asset?.bytes;
            }
            var path = Path.Combine(Application.dataPath, "Lua", filepath.Replace('.', '/') + ".lua");
            return File.Exists(path) ? File.ReadAllBytes(path) : null;
        });
    }

    private void SafeStartLua()
    {
        try
        {
            _luaEnv.DoString("require 'Entry.Main'");
        }
        catch (Exception ex)
        {
            Debug.LogError($"Lua 启动失败: {ex.Message}");
            Debug.LogException(ex);
            ShutdownFramework();
        }
    }
    #endregion

    #region 调度辅助
    /// <summary>
    /// 给 Lua 提供一个延迟调用接口（若未来全部迁移到 TimerManager 可去掉）
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

    #region 框架关闭
    void OnDestroy()
    {
        ShutdownFramework();
    }

    private void ShutdownFramework()
    {
        Log("[CORE] 关闭框架...");

        // 清理所有 UI 面板
        try
        {
            UIManager.Instance?.ClearAllPanels();
            Log("[CORE] UI 面板已清理");
        }
        catch (Exception e)
        {
            LogWarning($"清理 UI 时出错: {e.Message}");
        }

        // 释放 Lua VM
        if (_luaEnv != null)
        {
            try
            {
                _luaEnv.Dispose();
                Log("[LUA] VM 已释放");
            }
            catch (Exception e)
            {
                LogWarning($"LuaEnv.Dispose 时出错: {e.Message}");
            }
            _luaEnv = null;
        }
    }
    #endregion

    #region 日志
    private void Log(string msg)    { if (debugMode) Debug.Log(msg); }
    private void LogWarning(string m){ if (debugMode) Debug.LogWarning(m); }
    #endregion
}
