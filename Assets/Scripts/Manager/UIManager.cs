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
                lock (typeof(UIManager))
                {
                    // 先尝试在场景里找
                    _instance = FindObjectOfType<UIManager>();
                    if (_instance == null)
                    {
                        // 如果找不到，就新建一个
                        var go = new GameObject("UIManager");
                        _instance = go.AddComponent<UIManager>();
                        DontDestroyOnLoad(go);
                    }
                    // **确保 _uiRoot 在第一次拿 Instance 的时候就被初始化**
                    _instance.InitializeUIRoot();
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
    public void InitializeUIRoot()
    {
        if (_uiRoot != null) return;    // 幂等
        // 场景中已存在的UIRoot检测
        var existingRoot = GameObject.Find("UIRoot");
        if (existingRoot != null)
        {
            _uiRoot = existingRoot.transform;
            Debug.Log("复用已有UIRoot");
            return;
        }

        // 创建新的 UIRoot
        CreateNewUIRoot();
    }
    
    void CreateNewUIRoot()
    {
        var rootGO = new GameObject("UIRoot");
        DontDestroyOnLoad(rootGO);
        _uiRoot = rootGO.transform;

        TryAddComponent<Canvas>(rootGO, canvas =>
        {
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        });

        TryAddComponent<CanvasScaler>(rootGO, scaler =>
        {
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            // 竖屏设计分辨率
            scaler.referenceResolution = new Vector2(1024, 1920);
            // 更偏重高度适配
            scaler.matchWidthOrHeight = 1f;
        });

        rootGO.AddComponent<GraphicRaycaster>();
        Debug.Log("UIRoot（竖屏1024×1920）创建成功");
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
        // 参数验证
        if (string.IsNullOrEmpty(panelName))
        {
            Debug.LogError("无效的面板名称");
            return;
        }

        // 协程安全启动
        StartCoroutine(LoadPanel(panelName, callback));
    }

    
    private IEnumerator LoadPanel(string panelName, LuaFunction onLoaded)
    {
        // 保险：如果 _uiRoot 尚未初始化，则主动初始化一次
        if (_uiRoot == null)
        {
            InitializeUIRoot();
        }

        // 此时 _uiRoot 应该已非 null
        if (_uiRoot == null)
        {
            Debug.LogError("[UIManager] 初始化 UIRoot 失败，无法加载面板：" + panelName);
            yield break;
        }

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

        // 实例化并手动挂到 UIRoot 下
        var panel = Instantiate(prefab);
        panel.transform.SetParent(_uiRoot, false);

        uiDict[panelName] = panel;

        // 回调
        if (onLoaded != null)
            onLoaded.Call(panel);
        else
            Debug.LogWarning($"[UIManager] onLoaded 为 null，面板 {panelName} 无回调被调用");
    }

}