-- Core/ResourceManager.lua
-- Lua 封装的资源管理器

local CS      = CS
local RM      = CS.ResourceManager.Instance
local coroutine = coroutine

local ResourceManager = {}

--- 异步加载 Bundle
-- @param bundleName string  bundle 文件名（含后缀）
-- @param callback function  function(success)
function ResourceManager.LoadBundleAsync(bundleName, callback)
    assert(type(bundleName) == "string",   "LoadBundleAsync: bundleName must be string")
    assert(type(callback)   == "function", "LoadBundleAsync: callback must be function")
    coroutine.start(function()
        local co = RM:LoadBundleAsync(bundleName, function(ok) callback(ok) end)
        -- C# 端自动调度，无需再 yield
    end)
end

--- 同步加载 Bundle
-- @param bundleName string
-- @return boolean success
function ResourceManager.LoadBundleSync(bundleName)
    assert(type(bundleName) == "string", "LoadBundleSync: bundleName must be string")
    return RM:LoadBundleSync(bundleName)
end

--- 异步加载 Asset
-- @param bundleName string
-- @param assetPath string   完整路径（相对于 bundle 内部）
-- @param callback function  function(asset)
function ResourceManager.LoadAssetAsync(bundleName, assetPath, callback)
    assert(type(bundleName) == "string",   "LoadAssetAsync: bundleName must be string")
    assert(type(assetPath)  == "string",   "LoadAssetAsync: assetPath must be string")
    assert(type(callback)   == "function", "LoadAssetAsync: callback must be function")
    coroutine.start(function()
        RM:LoadAssetAsync(bundleName, assetPath, callback)
    end)
end

--- 同步加载 Asset
-- @param bundleName string
-- @param assetPath  string
-- @return Object
function ResourceManager.LoadAssetSync(bundleName, assetPath)
    assert(type(bundleName) == "string" and type(assetPath) == "string")
    return RM:LoadAssetSync(bundleName, assetPath)
end

--- 卸载 Bundle
-- @param bundleName string
function ResourceManager.UnloadBundle(bundleName)
    assert(type(bundleName) == "string", "UnloadBundle: bundleName must be string")
    RM:UnloadBundle(bundleName)
end

--- 卸载所有
function ResourceManager.UnloadAll()
    RM:UnloadAll()
end

return ResourceManager
