using UnityEngine;
using UnityEngine.UI;
using XLua;
using System.Collections;
using System.Collections.Generic;

public class UIManager : MonoBehaviour
{
// 添加双重校验
    private static UIManager _instance;
    public static UIManager Instance {
        get {
            if (_instance == null) 
            {
                // 双重校验锁保证线程安全
                lock(typeof(UIManager))
                {
                    _instance = FindObjectOfType<UIManager>();
                    if (_instance == null)
                    {
                        var go = new GameObject("UIManager");
                        _instance = go.AddComponent<UIManager>();
                        DontDestroyOnLoad(go);
                    }
                }
            }
            return _instance;
        }
    }
    
    private Transform _uiRoot;
    private bool _isInitialized = false;
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
    }
    
    // 安全初始化UIRoot
    void InitializeUIRoot()
    {
        // 场景中已存在的UIRoot检测
        var existingRoot = GameObject.Find("UIRoot");
        if (existingRoot != null)
        {
            _uiRoot = existingRoot.transform;
            Debug.Log("复用已有UIRoot");
            return;
        }

        // 安全创建流程
        CreateNewUIRoot();
    }
    
    void CreateNewUIRoot()
    {
        // 分步创建对象
        var rootGO = new GameObject("UIRoot");
        if (rootGO == null)
        {
            Debug.LogError("UIRoot创建失败！");
            return;
        }

        // 立即设置不销毁
        DontDestroyOnLoad(rootGO);
        _uiRoot = rootGO.transform;

        // 分步添加组件
        TryAddComponent<Canvas>(rootGO, canvas =>
        {
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        });

        TryAddComponent<CanvasScaler>(rootGO, scaler =>
        {
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
        });

        rootGO.AddComponent<GraphicRaycaster>();
        
        Debug.Log("UIRoot创建成功");
    }
    
    // 安全组件添加方法
    void TryAddComponent<T>(GameObject target, System.Action<T> onAdded = null) where T : Component
    {
        if (target == null)
        {
            Debug.LogError("尝试给空对象添加组件: " + typeof(T).Name);
            return;
        }

        var comp = target.AddComponent<T>();
        if (comp == null)
        {
            Debug.LogError("组件添加失败: " + typeof(T).Name);
            return;
        }

        onAdded?.Invoke(comp);
    }

    public void ShowPanel(string panelName, LuaFunction callback)
    {
        // 如果 _uiRoot 还没初始化，就再跑一次
        if (_uiRoot == null)
        {
            Debug.LogWarning("[UIManager] _uiRoot 为 null，尝试在 ShowPanel 前重新初始化");
            InitializeUIRoot();
        }
    
        // 空引用检查
        if (string.IsNullOrEmpty(panelName))
        {
            Debug.LogError("无效的面板名称");
            return;
        }

        // 协程安全启动
        if (this == null) return;
        StartCoroutine(LoadPanel(panelName, callback));
    }


    IEnumerator LoadPanel(string panelName, LuaFunction onLoaded)
    {
        var path = "UI/" + panelName;
        Debug.Log($"[UIManager] ▶️ Resources.LoadAsync 正在尝试加载：\"{path}\"");
        var request = Resources.LoadAsync<GameObject>(path);
        yield return request;

        if (request.asset == null)
        {
            Debug.LogError($"资源加载失败：{path}");
            yield break;
        }

        var prefab = request.asset as GameObject;
        if (prefab == null)
        {
            Debug.LogError($"资源类型错误：{path} 不是GameObject");
            yield break;
        }

        // 1) 先 Instantiate 不附加父对象
        var panel = Instantiate(prefab);
        // 2) 打日志确认我们会挂到哪个 UIRoot 下
        if (_uiRoot == null)
            Debug.LogError("[UIManager] _uiRoot 为 null！请检查 InitializeUIRoot 是否执行");
        else
            Debug.Log($"[UIManager] 挂载到 UIRoot: {_uiRoot.name}");

        // 3) 手动 SetParent，并把位置/缩放都复位
        panel.transform.SetParent(_uiRoot, false);

        uiDict.Add(panelName, panel);

        // 4) 再打个日志，确认 parent 是否正确
        Debug.Log($"[UIManager] {panel.name} 的 parent: {panel.transform.parent.name}");

        if (onLoaded != null)
            onLoaded.Call(panel);
        else
            Debug.LogWarning($"[UIManager] onLoaded 为 null，面板 {panelName} 无回调被调用");
    }

}