using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// 与 LoadingPanel.prefab 配合使用，提供进度更新接口
/// </summary>
public class LoadingPanel : MonoBehaviour
{
	[SerializeField] private Slider progressBar;
	[SerializeField] private Text   progressText;

	/// <summary>更新进度条和文本显示（0~1）</summary>
	public void SetProgress(float value)
	{
		if (progressBar != null)
			progressBar.value = value;
		if (progressText != null)
			progressText.text = $"{Mathf.FloorToInt(value * 100)}%";
	}
}