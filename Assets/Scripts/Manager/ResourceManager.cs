using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class ResourceManager : MonoBehaviour
{
    public static ResourceManager Instance { get; private set; }

    // Manifest 与缓存
    private AssetBundleManifest _manifest;
    private readonly Dictionary<string, AssetBundle> _bundleCache = new();
    private readonly Dictionary<string, int>         _refCounts  = new();

    // 路径约定
    private string BundleRoot => Path.Combine(Application.streamingAssetsPath, "AssetBundles");
    private const   string ManifestBundleName = "AssetBundles";

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        LoadManifest();
    }

    private void LoadManifest()
    {
        // 同步加载主 manifest
        var manifestPath = Path.Combine(BundleRoot, ManifestBundleName);
        var bundle = AssetBundle.LoadFromFile(manifestPath);
        if (bundle == null) throw new Exception($"Failed to load manifest bundle at {manifestPath}");
        _manifest = bundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
        bundle.Unload(false);
        Debug.Log("[ResourceManager] Manifest loaded.");
    }

    /// <summary>异步加载一个 Bundle（含所有依赖）</summary>
    public IEnumerator LoadBundleAsync(string bundleName, Action<bool> onComplete)
    {
        if (_bundleCache.ContainsKey(bundleName))
        {
            // 已加载，增加引用
            _refCounts[bundleName]++;
            onComplete?.Invoke(true);
            yield break;
        }

        // 1) 加载依赖
        foreach (var dep in _manifest.GetAllDependencies(bundleName))
        {
            yield return LoadBundleAsync(dep, null);
        }

        // 2) 自己
        var path = Path.Combine(BundleRoot, bundleName);
        var req  = AssetBundle.LoadFromFileAsync(path);
        yield return req;
        var bundle = req.assetBundle;
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleAsync failed: {bundleName}");
            onComplete?.Invoke(false);
            yield break;
        }
        _bundleCache[bundleName] = bundle;
        _refCounts[bundleName]  = 1;
        onComplete?.Invoke(true);
    }

    /// <summary>同步加载一个 Bundle（含依赖）</summary>
    public bool LoadBundleSync(string bundleName)
    {
        if (_bundleCache.ContainsKey(bundleName))
        {
            _refCounts[bundleName]++;
            return true;
        }

        // 同步加载依赖
        foreach (var dep in _manifest.GetAllDependencies(bundleName))
            LoadBundleSync(dep);

        var path = Path.Combine(BundleRoot, bundleName);
        var bundle = AssetBundle.LoadFromFile(path);
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleSync failed: {bundleName}");
            return false;
        }
        _bundleCache[bundleName] = bundle;
        _refCounts[bundleName]  = 1;
        return true;
    }

    /// <summary>异步加载单个 Asset，并回调（确保所属 Bundle 已加载）</summary>
    public IEnumerator LoadAssetAsync<T>(string bundleName, string assetPath, Action<T> onLoaded) where T : UnityEngine.Object
    {
        // 确保 bundle
        yield return LoadBundleAsync(bundleName, null);

        var bundle = _bundleCache[bundleName];
        var req = bundle.LoadAssetAsync<T>(assetPath);
        yield return req;
        onLoaded?.Invoke(req.asset as T);
    }

    /// <summary>同步加载单个 Asset</summary>
    public T LoadAssetSync<T>(string bundleName, string assetPath) where T : UnityEngine.Object
    {
        if (!LoadBundleSync(bundleName)) return null;
        return _bundleCache[bundleName].LoadAsset<T>(assetPath);
    }

    /// <summary>卸载单个 Bundle（及其依赖），引用计数为 0 时真正卸载</summary>
    public void UnloadBundle(string bundleName, bool unloadAllLoadedObjects = false)
    {
        if (!_bundleCache.ContainsKey(bundleName)) return;
        _refCounts[bundleName]--;
        if (_refCounts[bundleName] > 0) return;

        // 卸载自身
        _bundleCache[bundleName].Unload(unloadAllLoadedObjects);
        _bundleCache.Remove(bundleName);
        _refCounts.Remove(bundleName);

        // 卸载依赖
        foreach (var dep in _manifest.GetAllDependencies(bundleName))
            UnloadBundle(dep, unloadAllLoadedObjects);
    }

    /// <summary>卸载所有 Bundle</summary>
    public void UnloadAll(bool unloadAllObjects = false)
    {
        foreach (var kv in _bundleCache)
            kv.Value.Unload(unloadAllObjects);
        _bundleCache.Clear();
        _refCounts.Clear();
        Debug.Log("[ResourceManager] All bundles unloaded.");
    }
}
