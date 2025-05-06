using UnityEngine;
using UnityEngine.UI;
using XLua;
using System.Collections;
using System.Collections.Generic;

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
                    // 第一次拿 Instance 时确保 _uiRoot 已建
                    _instance.InitializeUIRoot();
                    // 第一次拿 Instance 时确保各层根节点已建
                    _instance.InitializeLayers();
                }
            }
            return _instance;
        }
    }
    
    private Transform _uiRoot;
    private Dictionary<string, GameObject> uiDict = new Dictionary<string, GameObject>();

    void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        InitializeUIRoot();
        InitializeLayers();
    }

    // =================================
    // UIRoot & Layer 初始化
    // =================================

    // 确保只执行一次
    public void InitializeUIRoot()
    {
        if (_uiRoot != null) return;
        var existing = GameObject.Find("UIRoot");
        if (existing != null)
        {
            _uiRoot = existing.transform;
            Debug.Log("复用已有UIRoot");
        }
        else
        {
            CreateNewUIRoot();
        }
    }

    void CreateNewUIRoot()
    {
        var root = new GameObject("UIRoot");
        DontDestroyOnLoad(root);
        _uiRoot = root.transform;

        // Canvas + Scaler + Raycaster
        var canvas = root.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        var scaler = root.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1024, 1920);
        scaler.matchWidthOrHeight = 1f;

        root.AddComponent<GraphicRaycaster>();

        Debug.Log("UIRoot（竖屏1024×1920）创建成功");
    }

    // 定义层级名与 Order
    private readonly (string name, int order)[] _layers = new[]
    {
        ("BackgroundLayer", 0),
        ("CommonLayer",     10),
        ("PopupLayer",      20),
        ("TipsLayer",       30),
        ("SystemLayer",     100)
    };

    // 创建各层根节点
    public void InitializeLayers()
    {
        if (_uiRoot == null) InitializeUIRoot();

        foreach (var (name, order) in _layers)
        {
            // 如果已存在就跳过
            var exist = _uiRoot.Find(name);
            if (exist != null) continue;

            var go = new GameObject(name);
            go.transform.SetParent(_uiRoot, false);

            var canvas = go.AddComponent<Canvas>();
            canvas.overrideSorting = true;
            canvas.sortingOrder     = order;

            go.AddComponent<GraphicRaycaster>();
        }
        Debug.Log("UI 分层根节点初始化完成");
    }

    // =================================
    // 面板加载与管理
    // =================================

    public void ShowPanel(string panelName, LuaFunction callback)
    {
        if (string.IsNullOrEmpty(panelName))
        {
            Debug.LogError("ShowPanel: 无效的面板名称");
            return;
        }
        StartCoroutine(LoadPanel(panelName, callback));
    }

    private IEnumerator LoadPanel(string panelName, LuaFunction onLoaded)
    {
        // 确保根与层级已建
        if (_uiRoot == null) InitializeUIRoot();
        InitializeLayers();

        // 异步加载
        var path    = $"UI/{panelName}";
        var request = Resources.LoadAsync<GameObject>(path);
        yield return request;

        if (request.asset == null)
        {
            Debug.LogError($"[UIManager] 资源加载失败：{path}");
            yield break;
        }

        var prefab = request.asset as GameObject;
        var panel  = Instantiate(prefab);

        // 默认挂 Common 层，也可以让 Lua 传入 targetLayer 决定
        // 这里先挂到 CommonLayer，Lua 再可调整
        var commonRoot = _uiRoot.Find("CommonLayer");
        panel.transform.SetParent(commonRoot, false);

        uiDict[panelName] = panel;

        if (onLoaded != null)
            onLoaded.Call(panel);
        else
            Debug.LogWarning($"[UIManager] 面板 {panelName} 无 onLoaded 回调");
    }

    public void ClosePanel(string panelName)
    {
        if (uiDict.TryGetValue(panelName, out var panel))
        {
            Destroy(panel);
            uiDict.Remove(panelName);
        }
    }
}
