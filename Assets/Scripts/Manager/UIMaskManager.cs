using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public class UIMaskManager : MonoBehaviour
{
    // 单例
    public static UIMaskManager Instance { get; private set; }

    // 遮罩对象池（可扩展为多重遮罩）
    private readonly Stack<GameObject> _maskPool = new Stack<GameObject>();
    private readonly Dictionary<GameObject, GameObject> _activeMasks = new Dictionary<GameObject, GameObject>();

    // 遮罩默认配置
    [SerializeField] private Color maskColor = new Color(0, 0, 0, 0.6f);
    [SerializeField] private string maskName = "UIMask";

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    /// <summary>
    /// 在 panel 前创建/复用一个遮罩
    /// </summary>
    /// <param name="panel">需要遮罩的面板 GameObject</param>
    public void Register(GameObject panel)
    {
        if (panel == null) return;
        // 已经注册过遮罩则跳过
        if (_activeMasks.ContainsKey(panel)) return;

        // 获取或创建一个遮罩对象
        GameObject mask = (_maskPool.Count > 0) ? _maskPool.Pop() : CreateMaskObject();
        // 将遮罩挂到与 panel 同一个父节点，保持 siblingIndex 在 panel 之前
        var parent = panel.transform.parent ?? panel.transform.root;
        mask.transform.SetParent(parent, false);

        // 计算 sortingOrder：取 panel 上 Canvas 的 order，如果没有则默认 0
        int panelOrder = 0;
        var panelCanvas = panel.GetComponent<Canvas>();
        if (panelCanvas != null) panelOrder = panelCanvas.sortingOrder;

        // 给遮罩添加/设置 Canvas，并放在 panel 之下一层
        var maskCanvas = mask.GetComponent<Canvas>();
        if (maskCanvas == null) maskCanvas = mask.AddComponent<Canvas>();
        maskCanvas.overrideSorting = true;
        maskCanvas.sortingOrder = panelOrder - 1;

        // 正确插入到 panel 前
        int panelIndex = panel.transform.GetSiblingIndex();
        mask.transform.SetSiblingIndex(Mathf.Max(0, panelIndex));

        // 记录映射
        _activeMasks[panel] = mask;
    }

    /// <summary>
    /// 移除指定 panel 的遮罩，并回收到池
    /// </summary>
    public void Unregister(GameObject panel)
    {
        if (panel == null) return;
        if (!_activeMasks.TryGetValue(panel, out var mask)) return;

        // 隐藏并回收
        mask.transform.SetParent(null, false);
        _maskPool.Push(mask);
        _activeMasks.Remove(panel);
    }

    /// <summary>
    /// 创建一个新的遮罩 GameObject
    /// </summary>
    private GameObject CreateMaskObject()
    {
        var go = new GameObject(maskName);
        // 半透明黑色 Image
        var img = go.AddComponent<Image>();
        img.color = maskColor;
        // 拉满父容器
        var rect = go.GetComponent<RectTransform>();
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;

        // 给遮罩添加 Canvas 与 Raycaster（可拦截点击）
        var canvas = go.AddComponent<Canvas>();
        canvas.overrideSorting = true;
        // sortingOrder 会在 Register 里设置
        go.AddComponent<GraphicRaycaster>();

        return go;
    }

    /// <summary>
    /// 清理所有活动遮罩（如场景切换时）
    /// </summary>
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
}
