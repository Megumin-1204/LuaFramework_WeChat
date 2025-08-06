using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using System.IO;

public class UIPrefabExporter : EditorWindow
{
    // 目标存放目录
    private const string TargetResourcesDir = "Assets/Resources/UI";

    [MenuItem("Tools/UI/Export Panel To Prefab and Unpack")]  // 更新菜单名称
    public static void OpenWindow()
    {
        GetWindow<UIPrefabExporter>("UI Prefab Exporter");
    }

    private void OnGUI()
    {
        GUILayout.Label("导出并覆盖当前场景 Canvas 下 Panel 为 Prefab", EditorStyles.boldLabel);
        if (GUILayout.Button("导出当前场景 Panel 并 Unpack"))
        {
            ExportAndUnpackPanel();
        }
    }

    private static void ExportAndUnpackPanel()
    {
        // 1. 确保目录存在
        if (!AssetDatabase.IsValidFolder(TargetResourcesDir))
        {
            Directory.CreateDirectory(Path.Combine(Application.dataPath, "Resources/UI"));
            AssetDatabase.Refresh();
        }

        // 2. 获取当前打开的场景
        Scene scene = EditorSceneManager.GetActiveScene();
        if (!scene.isLoaded)
        {
            Debug.LogError("未加载任何场景，请先打开一个 UI 场景");
            return;
        }
        string sceneName = scene.name;

        // 3. 查找 Canvas
        Canvas canvas = Object.FindObjectOfType<Canvas>();
        if (canvas == null)
        {
            Debug.LogError("场景中未找到 Canvas 对象");
            return;
        }

        // 4. 在 Canvas 下查找第一个名字与场景同名的 Panel
        Transform panelTransform = canvas.transform.Find(sceneName);
        if (panelTransform == null)
        {
            Debug.LogError($"在 Canvas 下未找到名为 '{sceneName}' 的 Panel");
            return;
        }
        GameObject panelGO = panelTransform.gameObject;

        // 5. 若为 Prefab 实例，则 Unpack 还原为普通 GameObject
        var prefabType = PrefabUtility.GetPrefabInstanceStatus(panelGO);
        if (prefabType == PrefabInstanceStatus.Connected || prefabType == PrefabInstanceStatus.Disconnected)
        {
            PrefabUtility.UnpackPrefabInstance(panelGO, PrefabUnpackMode.Completely, InteractionMode.UserAction);
            Debug.Log($"已对 Panel '{sceneName}' 进行 Unpack");
        }

        // 6. 构造预制体路径并覆盖已有 prefab
        string prefabPath = Path.Combine(TargetResourcesDir, sceneName + ".prefab").Replace("\\", "/");
        PrefabUtility.SaveAsPrefabAsset(panelGO, prefabPath);

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        Debug.Log($"[UI Prefab Exporter] 成功导出并覆盖 Prefab: {prefabPath}");
    }
}
