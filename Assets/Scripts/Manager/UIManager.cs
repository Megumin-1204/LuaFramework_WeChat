using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;

public class UIManager : MonoBehaviour
{
    private static UIManager _instance;
    public static UIManager Instance {
        get {
            if (_instance == null) 
            {
                lock (typeof(UIManager))
                {
                    _instance = FindObjectOfType<UIManager>();
                    if (_instance == null)
                    {
                        var go = new GameObject("UIManager");
                        _instance = go.AddComponent<UIManager>();
                        DontDestroyOnLoad(go);
                    }
                    _instance.InitializeUIRoot();
                    _instance.InitializeLayers();
                }
            }
            return _instance;
        }
    }
    
    private Transform _uiRoot;
    private Dictionary<string, GameObject> uiDict = new Dictionary<string, GameObject>();
    private UIMaskManager _maskMgr;

    void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        InitializeUIRoot();
        InitializeLayers();
        _maskMgr = GetComponent<UIMaskManager>();
    }

    // ================================
    // UIRoot & Layer 初始化
    // ================================

    public void InitializeUIRoot()
    {
        if (_uiRoot != null) return;
        var existing = GameObject.Find("UIRoot");
        if (existing != null)
        {
            _uiRoot = existing.transform;
            Debug.Log("[UIManager] Reuse existing UIRoot");
        }
        else
        {
            CreateNewUIRoot();
        }
    }

    private void CreateNewUIRoot()
    {
        var root = new GameObject("UIRoot");
        DontDestroyOnLoad(root);
        _uiRoot = root.transform;

        var canvas = root.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        var scaler = root.AddComponent<CanvasScaler>();
        scaler.uiScaleMode      = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1024, 1920);
        scaler.matchWidthOrHeight  = 1f;

        root.AddComponent<GraphicRaycaster>();
        Debug.Log("[UIManager] Created UIRoot (1024×1920)");
    }

    private readonly (string name, int order)[] _layers = new[]
    {
        ("BackgroundLayer",  0),
        ("CommonLayer",     10),
        ("PopupLayer",      20),
        ("TipsLayer",       30),
        ("SystemLayer",    100),
    };

    public void InitializeLayers()
    {
        if (_uiRoot == null) InitializeUIRoot();

        foreach (var (name, order) in _layers)
        {
            if (_uiRoot.Find(name)) continue;

            var go = new GameObject(name);
            go.transform.SetParent(_uiRoot, false);

            var canvas = go.AddComponent<Canvas>();
            canvas.overrideSorting = true;
            canvas.sortingOrder    = order;

            go.AddComponent<GraphicRaycaster>();
        }
        Debug.Log("[UIManager] UI layers initialized");
    }

    // ================================
    // 面板加载与管理（AssetBundle）
    // ================================

    /// <summary>
    /// 异步显示一个面板。Lua 调用时传入 LuaFunction 回调。
    /// </summary>
    public void ShowPanel(string panelName, LuaFunction luaCallback)
    {
        if (string.IsNullOrEmpty(panelName))
        {
            Debug.LogError("[UIManager] ShowPanel: invalid panelName");
            return;
        }
        StartCoroutine(LoadPanelRoutine(panelName, luaCallback));
    }

    private IEnumerator LoadPanelRoutine(string panelName, LuaFunction luaCallback)
    {
        // 1) 确保根 & 层级
        if (_uiRoot == null) InitializeUIRoot();
        InitializeLayers();

        // 2) 异步加载 Bundle
        var bundleName = $"ui_{panelName.ToLower()}";
        bool bundleOk = false;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadBundleAsync(bundleName, success => bundleOk = success)
        );
        if (!bundleOk)
        {
            Debug.LogError($"[UIManager] LoadBundle failed: {bundleName}");
            yield break;
        }

        // 3) 异步加载 Prefab
        GameObject prefab = null;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadAssetAsync<GameObject>(
                bundleName,
                $"Assets/Resources/UI/{panelName}.prefab",
                go => prefab = go
           )
        );
        if (prefab == null)
        {
            Debug.LogError($"[UIManager] LoadAsset failed: {panelName}");
            yield break;
        }

        // 4) 实例化 & 挂到 UIRoot
        var goInstance = Instantiate(prefab, _uiRoot);
        goInstance.name = panelName;

        // 5) 遮罩 & UI 栈 管理
        _maskMgr?.Register(goInstance);

        // 6) 回调给 Lua
        luaCallback?.Call(goInstance);
    }

    /// <summary>
    /// 关闭面板：销毁 GameObject、取消遮罩，再卸载对应的 Bundle。
    /// </summary>
    public void ClosePanel(string panelName)
    {
        if (string.IsNullOrEmpty(panelName)) return;

        if (uiDict.TryGetValue(panelName, out var panel))
        {
            _maskMgr?.Unregister(panel);
            Destroy(panel);
            uiDict.Remove(panelName);
        }
        // 卸载 Bundle
        var bundleName = $"ui_{panelName.ToLower()}";
        ResourceManager.Instance.UnloadBundle(bundleName);
    }

    /// <summary>
    /// 清理所有面板
    /// </summary>
    public void ClearAllPanels()
    {
        foreach (var kv in uiDict)
        {
            if (kv.Value != null)
                Destroy(kv.Value);
        }
        uiDict.Clear();
    }
}
