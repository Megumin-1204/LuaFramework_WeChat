using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class ResourceManager : MonoBehaviour
{
    public static ResourceManager Instance { get; private set; }

    private AssetBundleManifest _manifest;
    private readonly Dictionary<string, AssetBundle> _bundleCache = new Dictionary<string, AssetBundle>();
    private readonly Dictionary<string, int> _refCounts = new Dictionary<string, int>();

    private string BundleRoot => Path.Combine(Application.streamingAssetsPath, "AssetBundles");
    private const string ManifestBundleName = "AssetBundles";

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);

        try
        {
            LoadManifest();
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"[ResourceManager] 加载 Manifest 失败，跳过依赖加载: {ex.Message}");
            _manifest = null;
        }
    }

    private void LoadManifest()
    {
        var path = Path.Combine(BundleRoot, ManifestBundleName);
        var bundle = AssetBundle.LoadFromFile(path);
        if (bundle == null) throw new FileNotFoundException($"Manifest 文件不存在: {path}");
        _manifest = bundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
        bundle.Unload(false);
        Debug.Log("[ResourceManager] Manifest 加载完成");
    }

    public IEnumerator LoadBundleAsync(string bundleName, Action<bool> onComplete)
    {
        if (_bundleCache.ContainsKey(bundleName))
        {
            _refCounts[bundleName]++;
            onComplete?.Invoke(true);
            yield break;
        }

        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                yield return LoadBundleAsync(dep, null);
        }

        var path = Path.Combine(BundleRoot, bundleName);
        var req  = AssetBundle.LoadFromFileAsync(path);
        yield return req;

        var bundle = req.assetBundle;
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleAsync 失败: {bundleName}");
            onComplete?.Invoke(false);
            yield break;
        }

        _bundleCache[bundleName] = bundle;
        _refCounts[bundleName]   = 1;
        onComplete?.Invoke(true);
    }

    public bool LoadBundleSync(string bundleName)
    {
        if (_bundleCache.ContainsKey(bundleName))
        {
            _refCounts[bundleName]++;
            return true;
        }

        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                LoadBundleSync(dep);
        }

        var path   = Path.Combine(BundleRoot, bundleName);
        var bundle = AssetBundle.LoadFromFile(path);
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleSync 失败: {bundleName}");
            return false;
        }

        _bundleCache[bundleName] = bundle;
        _refCounts[bundleName]   = 1;
        return true;
    }

    // 非泛型 异步加载资源：先试完整路径，再试文件名
    public IEnumerator LoadAssetAsync(string bundleName, string assetPath, Action<UnityEngine.Object> onLoaded)
    {
        yield return LoadBundleAsync(bundleName, null);

        var bundle = _bundleCache[bundleName];

        // 1) 尝试按完整路径加载
        var req = bundle.LoadAssetAsync<UnityEngine.Object>(assetPath);
        yield return req;
        var asset = req.asset as UnityEngine.Object;

        // 2) 如果失败，再尝试按文件名加载
        if (asset == null)
        {
            var name = Path.GetFileNameWithoutExtension(assetPath);
            req = bundle.LoadAssetAsync<UnityEngine.Object>(name);
            yield return req;
            asset = req.asset as UnityEngine.Object;
        }

        if (asset == null)
            Debug.LogError($"[ResourceManager] LoadAssetAsync 未找到资源: {assetPath}");

        onLoaded?.Invoke(asset);
    }

    // 非泛型 同步加载
    public UnityEngine.Object LoadAssetSync(string bundleName, string assetPath)
    {
        if (!LoadBundleSync(bundleName)) return null;

        var bundle = _bundleCache[bundleName];
        // 1) 先按路径
        var asset = bundle.LoadAsset<UnityEngine.Object>(assetPath);
        // 2) 再按文件名
        if (asset == null)
        {
            var name = Path.GetFileNameWithoutExtension(assetPath);
            asset = bundle.LoadAsset<UnityEngine.Object>(name);
        }

        if (asset == null)
            Debug.LogError($"[ResourceManager] LoadAssetSync 未找到资源: {assetPath}");

        return asset;
    }

    // 泛型异步加载（可用，可留用）
    public IEnumerator LoadAssetAsync<T>(string bundleName, string assetPath, Action<T> onLoaded) where T : UnityEngine.Object
    {
        yield return LoadBundleAsync(bundleName, null);

        var bundle = _bundleCache[bundleName];
        T asset = null;

        // try path
        var req = bundle.LoadAssetAsync<T>(assetPath);
        yield return req;
        asset = req.asset as T;

        if (asset == null)
        {
            var name = Path.GetFileNameWithoutExtension(assetPath);
            req = bundle.LoadAssetAsync<T>(name);
            yield return req;
            asset = req.asset as T;
        }

        if (asset == null)
            Debug.LogError($"[ResourceManager] LoadAssetAsync<{typeof(T).Name}> 未找到: {assetPath}");

        onLoaded?.Invoke(asset);
    }

    // 泛型同步加载
    public T LoadAssetSync<T>(string bundleName, string assetPath) where T : UnityEngine.Object
    {
        if (!LoadBundleSync(bundleName)) return null;

        var bundle = _bundleCache[bundleName];
        T asset = bundle.LoadAsset<T>(assetPath);
        if (asset == null)
            asset = bundle.LoadAsset<T>(Path.GetFileNameWithoutExtension(assetPath));
        if (asset == null)
            Debug.LogError($"[ResourceManager] LoadAssetSync<{typeof(T).Name}> 未找到: {assetPath}");
        return asset;
    }

    public void UnloadBundle(string bundleName, bool unloadAllLoadedObjects = false)
    {
        if (!_bundleCache.ContainsKey(bundleName)) return;
        _refCounts[bundleName]--;
        if (_refCounts[bundleName] > 0) return;

        _bundleCache[bundleName].Unload(unloadAllLoadedObjects);
        _bundleCache.Remove(bundleName);
        _refCounts.Remove(bundleName);

        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                UnloadBundle(dep, unloadAllLoadedObjects);
        }
    }

    public void UnloadAll(bool unloadAllLoadedObjects = false)
    {
        foreach (var kv in _bundleCache)
            kv.Value.Unload(unloadAllLoadedObjects);
        _bundleCache.Clear();
        _refCounts.Clear();
        Debug.Log("[ResourceManager] 已卸载所有 AssetBundles");
    }
}
