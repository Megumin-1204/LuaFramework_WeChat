using System;
using System.IO;
using System.Collections.Generic;
using System.Security.Cryptography;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 商业级 AssetBundle 打包工具
/// 1. 自动清理上次打包产物  
/// 2. 批量给指定目录下资源贴 bundle 名称  
/// 3. 支持不同平台输出到不同子目录  
/// 4. 生成简易版本清单（JSON）  
/// </summary>
public static class BuildAssetBundles
{
    // 要打包的资源根目录（可按模块拆分多个）
    private static readonly string[] AssetFolders = new[]
    {
        "Assets/Resources/UI",
        "Assets/Prefabs",
        "Assets/Arts/Sprites",
        // … 根据项目需要添加更多
    };

    // 输出根目录（StreamingAssets 下）
    private const string OutputRoot = "Assets/StreamingAssets/AssetBundles";

    // 版本清单文件名
    private const string VersionFileName = "version_manifest.json";

    [MenuItem("Tools/AssetBundle/Build All Bundles")]
    public static void BuildAll()
    {
        // 1. 清理旧的 bundle
        if (Directory.Exists(OutputRoot))
        {
            Directory.Delete(OutputRoot, true);
            File.Delete(OutputRoot + ".manifest");
        }
        Directory.CreateDirectory(OutputRoot);

        // 2. 贴 assetBundleName
        ClearBundleNames();
        AssignBundleNames();

        // 3. 构建（LZ4 增量压缩，严格模式，不允许按文件名动态加载）
        var options = BuildAssetBundleOptions.ChunkBasedCompression
                    | BuildAssetBundleOptions.StrictMode
                    | BuildAssetBundleOptions.DisableLoadAssetByFileName;
        var target  = EditorUserBuildSettings.activeBuildTarget;
        var manifest = BuildPipeline.BuildAssetBundles(OutputRoot, options, target);

        if (manifest == null)
        {
            Debug.LogError("[BuildAssetBundles] 打包失败！");
            return;
        }

        // 4. 生成版本清单
        GenerateVersionManifest(manifest);

        // 5. 刷新 AssetDatabase
        AssetDatabase.RemoveUnusedAssetBundleNames();
        AssetDatabase.Refresh();
        Debug.Log("[BuildAssetBundles] 完成，输出目录：" + OutputRoot);
    }

    /// <summary>
    /// 清除所有已有的 assetBundleName
    /// </summary>
    private static void ClearBundleNames()
    {
        var names = AssetDatabase.GetAllAssetBundleNames();
        foreach (var name in names)
            AssetDatabase.RemoveAssetBundleName(name, true);
    }

    /// <summary>
    /// 遍历需要打包的目录，给所有文件自动贴 bundle 名
    /// bundle 名规则：<模块>_<小写资源名>
    /// 例如：Assets/Resources/UI/TestPanel.prefab → ui_testpanel
    /// </summary>
    private static void AssignBundleNames()
    {
        foreach (var folder in AssetFolders)
        {
            if (!Directory.Exists(folder)) continue;
            var files = Directory.GetFiles(folder, "*.*", SearchOption.AllDirectories);
            foreach (var file in files)
            {
                if (file.EndsWith(".meta") || file.EndsWith(".cs")) continue;
                var relPath = file.Replace("\\", "/");
                var assetPath = relPath.Substring(relPath.IndexOf("Assets/"));
                var nameWithoutExt = Path.GetFileNameWithoutExtension(assetPath);

                // 模块名取第二层文件夹名，如 Assets/Resources/UI → "ui"
                var segments = assetPath.Split('/');
                var module = segments.Length >= 3 ? segments[2] : "common";
                module = module.ToLower();

                var bundleName = $"{module}_{nameWithoutExt.ToLower()}";
                var importer = AssetImporter.GetAtPath(assetPath);
                importer.assetBundleName = bundleName;
                importer.assetBundleVariant = "";
            }
        }
    }

    /// <summary>
    /// 生成简易版本清单 JSON，记录每个 bundle 的 MD5 与大小
    /// 便于热更新时比对
    /// </summary>
    private static void GenerateVersionManifest(AssetBundleManifest manifest)
    {
        var bundles = manifest.GetAllAssetBundles();
        var entries = new List<VersionEntry>(bundles.Length);
        foreach (var b in bundles)
        {
            var path = Path.Combine(OutputRoot, b);
            if (!File.Exists(path)) continue;
            var bytes = File.ReadAllBytes(path);
            var md5 = MD5Util.CalculateMD5(bytes);
            var size = bytes.Length;
            entries.Add(new VersionEntry { name = b, md5 = md5, size = size });
        }

        var manifestObj = new VersionManifest { bundles = entries.ToArray() };
        var json = JsonUtility.ToJson(manifestObj, true);
        File.WriteAllText(Path.Combine(OutputRoot, VersionFileName), json);
        Debug.Log("[BuildAssetBundles] 版本清单已生成：" + VersionFileName);
    }

    [Serializable]
    private class VersionManifest
    {
        public VersionEntry[] bundles;
    }

    [Serializable]
    private class VersionEntry
    {
        public string name;
        public string md5;
        public int    size;
    }

    /// <summary>
    /// 简易 MD5 工具
    /// </summary>
    private static class MD5Util
    {
        public static string CalculateMD5(byte[] bytes)
        {
            using (var md5 = MD5.Create())
            {
                var hash = md5.ComputeHash(bytes);
                return BitConverter.ToString(hash).Replace("-", "").ToLower();
            }
        }
    }
}
