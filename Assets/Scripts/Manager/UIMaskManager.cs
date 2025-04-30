using UnityEngine;
using UnityEngine.UI;

public class UIMaskManager : MonoBehaviour
{
    private GameObject maskPanel;
    
    public void CreateMask(Transform parent, int depth)
    {
        if (maskPanel == null)
        {
            maskPanel = new GameObject("UIMask");
            var image = maskPanel.AddComponent<Image>();
            image.color = new Color(0,0,0, 0.6f);
        }
        
        maskPanel.transform.SetParent(parent);
        maskPanel.transform.SetAsFirstSibling();
        maskPanel.GetComponent<Canvas>().overrideSorting = true;
        maskPanel.GetComponent<Canvas>().sortingOrder = depth - 1;
    }

    public void RemoveMask()
    {
        if (maskPanel != null)
            maskPanel.transform.SetParent(null);
    }
}