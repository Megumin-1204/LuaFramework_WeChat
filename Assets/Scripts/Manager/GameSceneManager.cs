using System;
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameSceneManager : MonoBehaviour
{
    public static GameSceneManager Instance { get; private set; }

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
    /// 异步加载场景全流程：
    /// 1. 清理现有 UI & 资源  
    /// 2. 预加载场景的 AssetBundle  
    /// 3. 弹出 LoadingPanel 并更新进度  
    /// 4. 场景激活后隐藏 LoadingPanel  
    /// </summary>
    /// <param name="sceneName">场景名称（需与 Bundle 命名规则 scene_{lower} 对应）</param>
    /// <param name="onComplete">加载完毕后的回调</param>
    public void LoadScene(string sceneName, Action onComplete = null)
    {
        StartCoroutine(LoadSceneRoutine(sceneName, onComplete));
    }

    private IEnumerator LoadSceneRoutine(string sceneName, Action onComplete)
    {
        // 1) 清理 UI & 资源
        UIManager.Instance.ClearAllPanels();
        UIMaskManager.Instance.ClearAll();
        ResourceManager.Instance.UnloadAll();

        // 2) 加载场景 Bundle
        string bundle = $"scene_{sceneName.ToLower()}";
        bool bundleOk = false;
        yield return StartCoroutine(
            ResourceManager.Instance.LoadBundleAsync(bundle, ok => bundleOk = ok)
        );
        if (!bundleOk)
            yield break;

        // 3) 弹出 LoadingPanel，获取实例
        GameObject loadingGo = null;
        UIManager.Instance.ShowPanel("LoadingPanel", go => loadingGo = go);

        // 4) 异步加载场景
        var op = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Single);
        op.allowSceneActivation = false;

        while (op.progress < 0.9f)
        {
            if (loadingGo != null)
            {
                var lp = loadingGo.GetComponent<LoadingPanel>();
                if (lp != null)
                    lp.SetProgress(op.progress);
            }
            yield return null;
        }

        // 通知可以激活新场景
        op.allowSceneActivation = true;
        yield return op;

        // 5) 关闭 LoadingPanel
        UIManager.Instance.ClosePanel("LoadingPanel");

        // 6) 回调给调用者
        onComplete?.Invoke();
    }
}
