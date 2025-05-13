using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.UI;
using XLua;

[DisallowMultipleComponent]
[RequireComponent(typeof(UIMaskManager))]
[LuaCallCSharp]
public class UIManager : MonoBehaviour
{
    // —— 单例 —— 
    private static UIManager _instance;
    public static UIManager Instance {
        get {
            if (_instance == null) {
                _instance = FindObjectOfType<UIManager>();
                if (_instance == null) {
                    var go = new GameObject("UIManager");
                    _instance = go.AddComponent<UIManager>();
                }
                DontDestroyOnLoad(_instance.gameObject);
                _instance.InitializeUIRoot();
                _instance.InitializeLayers();
            }
            return _instance;
        }
    }

    [Header("调试日志开关")]
    [SerializeField] private bool _debugLogs = true;
    private void Log(string msg) { if (_debugLogs) Debug.Log("[UIManager] " + msg); }

    private bool _initialized = false;
    private Transform _uiRoot;
    private Camera    _uiCamera;
    private UIMaskManager _maskMgr;
    private Dictionary<string, GameObject> _uiDict = new Dictionary<string, GameObject>();

    [Serializable]
    private struct LayerInfo { public string name; public int order; }
    [SerializeField]
    private LayerInfo[] _layers = new[] {
        new LayerInfo { name="BackgroundLayer", order=0 },
        new LayerInfo { name="CommonLayer",     order=10 },
        new LayerInfo { name="PopupLayer",      order=20 },
        new LayerInfo { name="TipsLayer",       order=30 },
        new LayerInfo { name="SystemLayer",     order=100 },
    };

    private const string UILayerName   = "UI";
    private const int    UICameraDepth = 100;

    void Awake()
    {
        if (_instance != null && _instance != this) {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        _maskMgr = GetComponent<UIMaskManager>();
        InitializeUIRoot();
        InitializeLayers();
    }

    #region 对外接口

    public void InitializeUIRoot()
    {
        if (_initialized) return;
        CreateUIRootAndCamera();
    }

    public void InitializeLayers()
    {
        if (!_initialized) {
            CreateUIRootAndCamera();
            _initialized = true;
        }
        CreateLayers();
    }

    public void ShowPanel(string panelName, Action<GameObject> onLoaded)
    {
        Log($"ShowPanel(C#) 被调用：{panelName}");
        StartCoroutine(ShowPanelRoutine(panelName, onLoaded));
    }

    public void ShowPanelLua(string panelName, LuaFunction luaCallback)
    {
        Debug.Log($"[UIManager] ShowPanelLua 收到调用: {panelName}");
        StartCoroutine(ShowPanelRoutine(panelName, luaCallback));
    }

    public void ClosePanel(string panelName)
    {
        if (_uiDict.TryGetValue(panelName, out var go)) {
            _maskMgr.Unregister(go);
            Destroy(go);
            _uiDict.Remove(panelName);
        }
        ResourceManager.Instance.UnloadBundle($"ui_{panelName.ToLower()}");
    }

    public void ClearAllPanels()
    {
        foreach (var kv in _uiDict) {
            if (kv.Value) {
                _maskMgr.Unregister(kv.Value);
                Destroy(kv.Value);
            }
        }
        _uiDict.Clear();
    }

    #endregion

    #region 协程实现

    private IEnumerator ShowPanelRoutine(string panelName, Action<GameObject> onLoaded)
    {
        InitializeUIRoot(); InitializeLayers();
        Log($"开始加载面板（C#）：{panelName}");

        // 1) 加载 Bundle
        bool ok = false;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadBundleAsync($"ui_{panelName.ToLower()}", s => ok = s)
        );
        Log($"Bundle 加载结果（C#）：{ok}");
        // 不成功就回退 Resources
        if (!ok) {
            Debug.LogWarning($"[UIManager] AB 加载失败，回退 Resources: {panelName}");
        }

        // 2) 加载 Prefab
        UnityEngine.Object prefab = null;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadAssetAsync($"ui_{panelName.ToLower()}", panelName, o => prefab = o)
        );
        Log($"Prefab 加载结果（C#）：{(prefab != null)} prefab={prefab}");
        if (prefab == null) {
            // 资源回退 Resources.Load
            prefab = Resources.Load<GameObject>("UI/" + panelName);
            if (prefab == null) {
                Debug.LogError($"[UIManager] Resources.Load 也失败：{panelName}");
                yield break;
            }
            Log($"资源回退成功（C#）：{prefab}");
        }

        // 3) 查找父节点
        var parent = _uiRoot.Find("PopupLayer");
        if (parent == null) {
            Debug.LogWarning($"[UIManager] PopupLayer 不存在，{panelName} 挂载到 UIRoot");
            parent = _uiRoot;
        } else {
            Log($"挂载到层：{parent.name}");
        }

        // 4) 实例化
        var go = Instantiate(prefab, parent) as GameObject;
        go.name  = panelName;
        go.layer = LayerMask.NameToLayer(UILayerName);
        Log($"实例化完成：{go.name} (pos={go.transform.localPosition}, scale={go.transform.localScale})");

        _maskMgr.Register(go);
        _uiDict[panelName] = go;

        onLoaded?.Invoke(go);
    }

    private IEnumerator ShowPanelRoutine(string panelName, LuaFunction luaCallback)
    {
        InitializeUIRoot(); InitializeLayers();
        Log($"开始加载面板（Lua）：{panelName}");

        bool ok = false;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadBundleAsync($"ui_{panelName.ToLower()}", s => ok = s)
        );
        Log($"Bundle 加载结果（Lua）：{ok}");
        if (!ok) {
            Debug.LogWarning($"[UIManager] AB 加载失败，回退 Resources: {panelName}");
        }

        UnityEngine.Object prefab = null;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadAssetAsync($"ui_{panelName.ToLower()}", panelName, o => prefab = o)
        );
        Log($"Prefab 加载结果（Lua）：{(prefab != null)} prefab={prefab}");
        if (prefab == null) {
            prefab = Resources.Load<GameObject>("UI/" + panelName);
            if (prefab == null) {
                Debug.LogError($"[UIManager] Resources.Load 也失败：{panelName}");
                yield break;
            }
            Log($"资源回退成功（Lua）：{prefab}");
        }

        var parent = _uiRoot.Find("PopupLayer");
        if (parent == null) {
            Debug.LogWarning($"[UIManager] PopupLayer 不存在，{panelName} 挂载到 UIRoot");
            parent = _uiRoot;
        } else {
            Log($"挂载到层：{parent.name}");
        }

        var go = Instantiate(prefab, parent) as GameObject;
        go.name  = panelName;
        go.layer = LayerMask.NameToLayer(UILayerName);
        Log($"实例化完成：{go.name} (pos={go.transform.localPosition}, scale={go.transform.localScale})");

        _maskMgr.Register(go);
        _uiDict[panelName] = go;

        luaCallback.Call(go);
    }

    #endregion

    #region 根与层 私有实现

    private void CreateUIRootAndCamera()
    {
        if (_uiRoot != null) return;

        var exist = GameObject.Find("UIRoot");
        if (exist != null) {
            _uiRoot   = exist.transform;
            _uiCamera = _uiRoot.GetComponentInChildren<Camera>();
            Log("复用已有 UIRoot");
        } else {
            var root = new GameObject("UIRoot");
            root.layer = LayerMask.NameToLayer(UILayerName);
            DontDestroyOnLoad(root);
            _uiRoot = root.transform;
            Log("创建 UIRoot");

            var cam = new GameObject("UICamera");
            cam.layer = LayerMask.NameToLayer(UILayerName);
            cam.transform.SetParent(_uiRoot, false);
            _uiCamera = cam.AddComponent<Camera>();
            _uiCamera.clearFlags      = CameraClearFlags.SolidColor;
            _uiCamera.backgroundColor = Color.black;
            _uiCamera.cullingMask     = 1 << LayerMask.NameToLayer(UILayerName);
            _uiCamera.depth           = UICameraDepth;
            Log("创建 UICamera");

            var cvs = root.AddComponent<Canvas>();
            cvs.renderMode      = RenderMode.ScreenSpaceCamera;
            cvs.worldCamera     = _uiCamera;
            cvs.planeDistance   = 1;
            cvs.gameObject.layer = LayerMask.NameToLayer(UILayerName);

            var scaler = root.AddComponent<CanvasScaler>();
            scaler.uiScaleMode         = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight  = 1f;
            root.AddComponent<GraphicRaycaster>();
            Log("配置根 Canvas");
        }
    }

    private void CreateLayers()
    {
        if (_uiRoot == null) CreateUIRootAndCamera();

        foreach (var info in _layers)
        {
            var child = _uiRoot.Find(info.name);
            if (child != null) {
                Log($"层 {info.name} 已存在，跳过");
                continue;
            }
            var go = new GameObject(info.name);
            go.layer = LayerMask.NameToLayer(UILayerName);
            go.transform.SetParent(_uiRoot, false);
            var c = go.AddComponent<Canvas>();
            c.overrideSorting = true;
            c.sortingOrder    = info.order;
            go.AddComponent<GraphicRaycaster>();
            Log($"创建层 {info.name} order={info.order}");
        }

        Log("层结构检查：");
        foreach (Transform t in _uiRoot)
            Log($"  子节点: {t.name}");
    }

    #endregion
}
