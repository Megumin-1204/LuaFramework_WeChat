using UnityEngine;
using UnityEngine.UI;
using XLua;
using System.Collections;
using System.Collections.Generic;

public class UIManager : MonoBehaviour
{
    public static UIManager Instance { get; private set; }
    
    private Transform _uiRoot;
    private bool _isRootCreated = false; // 新增状态标记
    private Dictionary<string, GameObject> uiDict = new Dictionary<string, GameObject>();
    
    void Awake()
    {
        if (Instance != null)
        {
            Destroy(gameObject);
            return;
        }
        
        Instance = this;
        DontDestroyOnLoad(gameObject);
        
        // 确保只创建一次
        if (!_isRootCreated)
        {
            Create_uiRoot();
            _isRootCreated = true;
        }
    }
    
    void Create_uiRoot()
    {
        // 检查是否已存在
        var existingRoot = GameObject.Find("_uiRoot");
        if (existingRoot != null)
        {
            _uiRoot = existingRoot.transform;
            return;
        }

        // 安全创建流程
        _uiRoot = new GameObject("_uiRoot").transform;
        DontDestroyOnLoad(_uiRoot.gameObject);
        
        var canvas = _uiRoot.gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        
        // 添加必要组件
        var scaler = _uiRoot.gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920, 1080);
        
        _uiRoot.gameObject.AddComponent<GraphicRaycaster>();
        
        // 设置层级
        _uiRoot.SetAsLastSibling();
        
        Debug.Log("_uiRoot Created Successfully");
    }

    public void ShowPanel(string panelName, LuaFunction onLoaded)
    {
        if (uiDict.ContainsKey(panelName))
        {
            onLoaded.Call(uiDict[panelName]);
            return;
        }

        StartCoroutine(LoadPanel(panelName, onLoaded));
    }

    private IEnumerator LoadPanel(string panelName, LuaFunction onLoaded)
    {
        // 从Resources加载
        var request = Resources.LoadAsync<GameObject>("UI/" + panelName);
        yield return request;
        
        var panel = Instantiate(request.asset as GameObject, _uiRoot);
        uiDict.Add(panelName, panel);
        
        // 调用Lua回调
        onLoaded.Call(panel);
    }
}