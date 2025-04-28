using UnityEngine;
using UnityEngine.UI;
using XLua;
using System.Collections;
using System.Collections.Generic;

public class UIManager : MonoBehaviour
{
    public static UIManager Instance;
    
    private Transform uiRoot;
    private Dictionary<string, GameObject> uiDict = new Dictionary<string, GameObject>();

    void Awake()
    {
        Instance = this;
        CreateUIRoot();
    }

    void CreateUIRoot()
    {
        uiRoot = new GameObject("UIRoot").transform;
        var canvas = uiRoot.gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        uiRoot.gameObject.AddComponent<CanvasScaler>();
        uiRoot.gameObject.AddComponent<GraphicRaycaster>();
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
        
        var panel = Instantiate(request.asset as GameObject, uiRoot);
        uiDict.Add(panelName, panel);
        
        // 调用Lua回调
        onLoaded.Call(panel);
    }
}