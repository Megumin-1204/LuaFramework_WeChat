using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using XLua;

[DisallowMultipleComponent]
[LuaCallCSharp]  // 如果你需要在 Lua 直接访问 ResourceManager
public class ResourceManager : MonoBehaviour
{
    // —— 单例 —— 
    private static ResourceManager _instance;
    public static ResourceManager Instance
    {
        get
        {
            if (_instance == null)
            {
                // 尝试场景查找
                _instance = FindObjectOfType<ResourceManager>();
                if (_instance == null)
                {
                    // 自动创建
                    var go = new GameObject("ResourceManager");
                    _instance = go.AddComponent<ResourceManager>();
                    DontDestroyOnLoad(go);
                    Debug.Log("[ResourceManager] 自动创建单例实例");
                }
            }
            return _instance;
        }
    }

    /// <summary>
    /// 运行时是否使用 AssetBundle。编辑器下为 false，打包后为 true。
    /// </summary>
    public static bool UseAssetBundles { get; private set; }

    // AssetBundle manifest & 缓存
    private AssetBundleManifest _manifest;
    private readonly Dictionary<string, AssetBundle> _bundles   = new Dictionary<string, AssetBundle>();
    private readonly Dictionary<string, int>         _refCounts = new Dictionary<string, int>();

    // 根目录
    private string BundleRoot => Path.Combine(Application.streamingAssetsPath, "AssetBundles");
    private const string ManifestName = "AssetBundles";

    void Awake()
    {
        // 单例保护
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        // 编辑器模式下不走 AB，方便调试
#if UNITY_EDITOR
        UseAssetBundles = false;
#else
        UseAssetBundles = true;
#endif

        if (UseAssetBundles)
        {
            try
            {
                var path = Path.Combine(BundleRoot, ManifestName);
                var bundle = AssetBundle.LoadFromFile(path);
                _manifest = bundle?.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
                bundle?.Unload(false);
                Debug.Log("[ResourceManager] Loaded AssetBundleManifest");
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[ResourceManager] Failed to load manifest: {ex.Message}");
                _manifest = null;
            }
        }
        else
        {
            Debug.Log("[ResourceManager] 编辑器模式：UseAssetBundles = false");
        }
    }

    [LuaCallCSharp]
    public IEnumerator LoadBundleAsync(string bundleName, Action<bool> onComplete)
    {
        Debug.Log($"[ResourceManager] LoadBundleAsync 请求: {bundleName}");
        if (!UseAssetBundles)
        {
            onComplete?.Invoke(true);
            yield break;
        }

        if (_bundles.ContainsKey(bundleName))
        {
            _refCounts[bundleName]++;
            Debug.Log($"[ResourceManager] Bundle 已缓存，引用计数++: {bundleName} = {_refCounts[bundleName]}");
            onComplete?.Invoke(true);
            yield break;
        }

        // 加载依赖
        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                yield return LoadBundleAsync(dep, null);
        }

        var bundlePath = Path.Combine(BundleRoot, bundleName);
        var req = AssetBundle.LoadFromFileAsync(bundlePath);
        yield return req;

        var bundle = req.assetBundle;
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleAsync 失败: {bundleName}");
            onComplete?.Invoke(false);
            yield break;
        }

        _bundles[bundleName]   = bundle;
        _refCounts[bundleName] = 1;
        Debug.Log($"[ResourceManager] Bundle 加载成功: {bundleName}");
        onComplete?.Invoke(true);
    }

    [LuaCallCSharp]
    public bool LoadBundleSync(string bundleName)
    {
        Debug.Log($"[ResourceManager] LoadBundleSync 请求: {bundleName}");
        if (!UseAssetBundles)
            return true;

        if (_bundles.ContainsKey(bundleName))
        {
            _refCounts[bundleName]++;
            Debug.Log($"[ResourceManager] Bundle 已缓存，引用计数++: {bundleName} = {_refCounts[bundleName]}");
            return true;
        }

        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                LoadBundleSync(dep);
        }

        var bundlePath = Path.Combine(BundleRoot, bundleName);
        var bundle = AssetBundle.LoadFromFile(bundlePath);
        if (bundle == null)
        {
            Debug.LogError($"[ResourceManager] LoadBundleSync 失败: {bundleName}");
            return false;
        }

        _bundles[bundleName]   = bundle;
        _refCounts[bundleName] = 1;
        Debug.Log($"[ResourceManager] Bundle 同步加载成功: {bundleName}");
        return true;
    }

    [LuaCallCSharp]
    public IEnumerator LoadAssetAsync(string bundleName, string assetName, Action<UnityEngine.Object> onLoaded)
    {
        Debug.Log($"[ResourceManager] LoadAssetAsync 请求: {bundleName} -> {assetName}");
        if (!UseAssetBundles)
        {
            var res = Resources.Load("UI/" + assetName);
            Debug.Log($"[ResourceManager] 直接 Resources.Load: {assetName} => {res}");
            onLoaded?.Invoke(res);
            yield break;
        }

        // 确保 bundle 已加载
        yield return LoadBundleAsync(bundleName, null);

        if (_bundles.TryGetValue(bundleName, out var bundle))
        {
            var req = bundle.LoadAssetAsync<UnityEngine.Object>(assetName);
            yield return req;
            if (req.asset != null)
            {
                Debug.Log($"[ResourceManager] 从 Bundle 加载资源成功: {assetName}");
                onLoaded?.Invoke(req.asset);
                yield break;
            }
        }

        // 回退 Resources
        Debug.LogWarning($"[ResourceManager] Bundle 中未找到 {assetName}，回退 Resources");
        var fallback = Resources.Load("UI/" + assetName);
        onLoaded?.Invoke(fallback);
    }

    [LuaCallCSharp]
    public UnityEngine.Object LoadAssetSync(string bundleName, string assetName)
    {
        Debug.Log($"[ResourceManager] LoadAssetSync 请求: {bundleName} -> {assetName}");
        if (!UseAssetBundles)
            return Resources.Load("UI/" + assetName);

        if (!LoadBundleSync(bundleName))
            return null;

        if (_bundles.TryGetValue(bundleName, out var bundle))
        {
            var asset = bundle.LoadAsset<UnityEngine.Object>(assetName);
            if (asset != null)
            {
                Debug.Log($"[ResourceManager] 同步从 Bundle 加载成功: {assetName}");
                return asset;
            }
        }

        Debug.LogWarning($"[ResourceManager] 同步资源未在 Bundle 中找到 {assetName}，回退 Resources");
        return Resources.Load("UI/" + assetName);
    }

    [LuaCallCSharp]
    public void UnloadBundle(string bundleName, bool unloadAllLoadedObjects = false)
    {
        if (!UseAssetBundles) return;

        if (!_bundles.ContainsKey(bundleName)) return;

        _refCounts[bundleName]--;
        Debug.Log($"[ResourceManager] UnloadBundle 引用计数--: {bundleName} = {_refCounts[bundleName]}");
        if (_refCounts[bundleName] > 0) return;

        _bundles[bundleName].Unload(unloadAllLoadedObjects);
        _bundles.Remove(bundleName);
        _refCounts.Remove(bundleName);
        Debug.Log($"[ResourceManager] Bundle 已卸载: {bundleName}");

        if (_manifest != null)
        {
            foreach (var dep in _manifest.GetAllDependencies(bundleName))
                UnloadBundle(dep, unloadAllLoadedObjects);
        }
    }

    [LuaCallCSharp]
    public void UnloadAll(bool unloadAllLoadedObjects = false)
    {
        if (!UseAssetBundles) return;

        foreach (var kv in _bundles)
            kv.Value.Unload(unloadAllLoadedObjects);

        _bundles.Clear();
        _refCounts.Clear();
        Debug.Log("[ResourceManager] 已卸载所有 Bundle");
    }
}
