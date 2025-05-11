-- Assets/Lua/Core/ResourceManager.lua
-- 商业级 资源管理器（Lua 层封装）
-- 依赖 C# ResourceManager 提供的 Bundle/Asset 异步协程接口

local CS       = CS
local RM       = CS.ResourceManager.Instance
local GameRoot = CS.GameRoot.Instance
local ResourceManager = {}

-- 本地化 API，避免多次查表
local StartCoroutine = GameRoot and GameRoot.StartCoroutine or error("GameRoot.StartCoroutine 不可用")

--- 异步加载一个 AssetBundle（含所有依赖）  
-- @param bundleName string   Bundle 名称（不含路径，如 "ui_main"）
-- @param callback function   回调参数：success:boolean
function ResourceManager.LoadBundleAsync(bundleName, callback)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadBundleAsync: bundleName 必须是非空字符串")
    assert(type(callback) == "function",
            "LoadBundleAsync: callback 必须是函数")
    -- 启动 C# 的协程
    StartCoroutine(GameRoot, RM:LoadBundleAsync(bundleName, function(ok)
        -- 保护调用
        local success, err = pcall(callback, ok)
        if not success then
            print(string.format("[ResourceManager] LoadBundleAsync callback 错误: %s", err))
        end
    end))
end

--- 同步加载一个 AssetBundle（含所有依赖）  
-- @param bundleName string  
-- @return boolean success
function ResourceManager.LoadBundleSync(bundleName)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadBundleSync: bundleName 必须是非空字符串")
    local ok, result = pcall(function()
        return RM:LoadBundleSync(bundleName)
    end)
    if not ok then
        print(string.format("[ResourceManager] LoadBundleSync 异常: %s", result))
        return false
    end
    return result
end

--- 异步加载单个资源  
-- @param bundleName string  
-- @param assetPath string    Bundle 内部资源路径（如 "Assets/Resources/UI/Main.prefab"）  
-- @param callback function   回调参数：asset:Object
function ResourceManager.LoadAssetAsync(bundleName, assetPath, callback)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadAssetAsync: bundleName 必须是非空字符串")
    assert(type(assetPath) == "string" and assetPath ~= "",
            "LoadAssetAsync: assetPath 必须是非空字符串")
    assert(type(callback) == "function",
            "LoadAssetAsync: callback 必须是函数")
    StartCoroutine(GameRoot, RM:LoadAssetAsync(bundleName, assetPath, function(asset)
        local success, err = pcall(callback, asset)
        if not success then
            print(string.format("[ResourceManager] LoadAssetAsync callback 错误: %s", err))
        end
    end))
end

--- 同步加载单个资源  
-- @param bundleName string  
-- @param assetPath string  
-- @return Object|nil
function ResourceManager.LoadAssetSync(bundleName, assetPath)
    assert(type(bundleName) == "string" and bundleName ~= "" and
            type(assetPath) == "string" and assetPath ~= "",
            "LoadAssetSync: 参数必须为非空字符串")
    local ok, result = pcall(function()
        return RM:LoadAssetSync(bundleName, assetPath)
    end)
    if not ok then
        print(string.format("[ResourceManager] LoadAssetSync 异常: %s", result))
        return nil
    end
    return result
end

--- 卸载指定 Bundle（引用计数-1，0 时真正卸载）  
-- @param bundleName string
function ResourceManager.UnloadBundle(bundleName)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "UnloadBundle: bundleName 必须是非空字符串")
    local ok, err = pcall(function()
        RM:UnloadBundle(bundleName)
    end)
    if not ok then
        print(string.format("[ResourceManager] UnloadBundle 异常: %s", err))
    end
end

--- 卸载所有已加载 Bundle  
function ResourceManager.UnloadAll()
    local ok, err = pcall(function()
        RM:UnloadAll()
    end)
    if not ok then
        print(string.format("[ResourceManager] UnloadAll 异常: %s", err))
    end
end

return ResourceManager
