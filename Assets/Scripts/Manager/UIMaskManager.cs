using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

[DisallowMultipleComponent]
public class UIMaskManager : MonoBehaviour
{
    public static UIMaskManager Instance { get; private set; }

    private readonly Stack<GameObject> _maskPool    = new Stack<GameObject>();
    private readonly Dictionary<GameObject, GameObject> _activeMasks = new Dictionary<GameObject, GameObject>();

    [SerializeField] private Color maskColor = new Color(0, 0, 0, 0.6f);
    [SerializeField] private string maskName = "UIMask";

    private Camera _uiCamera;

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);

        // 缓存 UI 摄像机（UIRoot 下的 UICamera）
        var uiRoot = GameObject.Find("UIRoot");
        if (uiRoot != null)
            _uiCamera = uiRoot.GetComponentInChildren<Camera>();
    }

    /// <summary>
    /// 在 panel 前创建/复用一个遮罩，并确保 panel 在上层
    /// </summary>
    public void Register(GameObject panel)
    {
        if (panel == null || _activeMasks.ContainsKey(panel)) return;

        // 获取或创建遮罩
        GameObject mask = _maskPool.Count > 0
            ? _maskPool.Pop()
            : CreateMaskObject();

        // 父节点：和 panel 同父
        var parent = panel.transform.parent ?? panel.transform.root;
        mask.transform.SetParent(parent, false);

        // 先把 mask 放到 panel 之前
        int panelIdx = panel.transform.GetSiblingIndex();
        mask.transform.SetSiblingIndex(panelIdx);

        // 再把 panel 挪到末尾，确保 panel 在上
        panel.transform.SetAsLastSibling();

        // Canvas 排序：和 panel 同一父 Canvas，layerOrder-1
        int panelOrder = 0;
        var panelCanvas = panel.GetComponentInParent<Canvas>();
        if (panelCanvas != null) panelOrder = panelCanvas.sortingOrder;

        var maskCanvas = mask.GetComponent<Canvas>();
        maskCanvas.overrideSorting = true;
        maskCanvas.sortingOrder    = panelOrder - 1;
        maskCanvas.worldCamera     = _uiCamera;  // 关键：让 ScreenSpace–Camera 模式下也能渲染

        _activeMasks[panel] = mask;
    }

    public void Unregister(GameObject panel)
    {
        if (panel == null || !_activeMasks.TryGetValue(panel, out var mask)) return;
        mask.transform.SetParent(null, false);
        _maskPool.Push(mask);
        _activeMasks.Remove(panel);
    }

    public void ClearAll()
    {
        foreach (var kv in _activeMasks)
        {
            var mask = kv.Value;
            mask.transform.SetParent(null, false);
            _maskPool.Push(mask);
        }
        _activeMasks.Clear();
    }

    private GameObject CreateMaskObject()
    {
        var go = new GameObject(maskName);
        go.layer = LayerMask.NameToLayer("UI");

        // 全屏 RectTransform
        var rt = go.AddComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = rt.offsetMax = Vector2.zero;

        // 半透明黑色背景
        var img = go.AddComponent<Image>();
        img.color = maskColor;

        // Canvas + Raycaster
        var canvas = go.AddComponent<Canvas>();
        canvas.renderMode        = RenderMode.ScreenSpaceCamera;
        canvas.worldCamera       = _uiCamera;
        canvas.overrideSorting   = true;
        go.AddComponent<GraphicRaycaster>();

        return go;
    }
}
