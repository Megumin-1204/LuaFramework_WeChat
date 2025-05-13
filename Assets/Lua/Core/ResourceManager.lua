-- Assets/Lua/Core/ResourceManager.lua
-- Lua 层资源管理器，只对接 C# 的 ResourceManager

local CS       = CS
local RM       = CS.ResourceManager.Instance
local GameRoot = CS.GameRoot.Instance

local ResourceManager = {}

-- 调用 C# 协程：传入一个 IEnumerator
local function startCo(co)
    -- GameRoot:StartCoroutine 方法由 XLua 绑定，直接用冒号调用
    GameRoot:StartCoroutine(co)
end

--- 异步加载 AssetBundle（含依赖）
-- @param bundleName string  如 "ui_testpanel"
-- @param callback function(success:boolean)
function ResourceManager.LoadBundleAsync(bundleName, callback)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadBundleAsync: bundleName 必须是非空字符串")
    assert(type(callback) == "function",
            "LoadBundleAsync: callback 必须是函数")

    startCo(RM:LoadBundleAsync(bundleName, function(ok)
        local succ, err = pcall(callback, ok)
        if not succ then
            print("[ResourceManager] LoadBundleAsync callback 错误:", err)
        end
    end))
end

--- 同步加载 AssetBundle（含依赖）
-- @param bundleName string
-- @return boolean
function ResourceManager.LoadBundleSync(bundleName)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadBundleSync: bundleName 必须是非空字符串")
    local ok, ret = pcall(function()
        return RM:LoadBundleSync(bundleName)
    end)
    if not ok then
        print("[ResourceManager] LoadBundleSync 异常:", ret)
        return false
    end
    return ret
end

--- 异步加载资源（仅从 AB）
-- @param bundleName string
-- @param assetName  string   资源在 Bundle 中的名称（纯文件名，无路径/后缀）
-- @param callback   function(obj:Object)
function ResourceManager.LoadAssetAsync(bundleName, assetName, callback)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "LoadAssetAsync: bundleName 必须是非空字符串")
    assert(type(assetName) == "string" and assetName ~= "",
            "LoadAssetAsync: assetName 必须是非空字符串")
    assert(type(callback) == "function",
            "LoadAssetAsync: callback 必须是函数")

    startCo(RM:LoadAssetAsync(bundleName, assetName, function(obj)
        local succ, err = pcall(callback, obj)
        if not succ then
            print("[ResourceManager] LoadAssetAsync callback 错误:", err)
        end
    end))
end

--- 同步加载资源（仅从 AB）
-- @param bundleName string
-- @param assetName  string
-- @return Object|nil
function ResourceManager.LoadAssetSync(bundleName, assetName)
    assert(type(bundleName) == "string" and bundleName ~= "" and
            type(assetName)  == "string" and assetName ~= "",
            "LoadAssetSync: 参数必须为非空字符串")
    local ok, ret = pcall(function()
        return RM:LoadAssetSync(bundleName, assetName)
    end)
    if not ok then
        print("[ResourceManager] LoadAssetSync 异常:", ret)
        return nil
    end
    return ret
end

--- 卸载指定 Bundle
-- @param bundleName string
function ResourceManager.UnloadBundle(bundleName)
    assert(type(bundleName) == "string" and bundleName ~= "",
            "UnloadBundle: bundleName 必须是非空字符串")
    local ok, err = pcall(function()
        RM:UnloadBundle(bundleName)
    end)
    if not ok then
        print("[ResourceManager] UnloadBundle 异常:", err)
    end
end

--- 卸载所有 Bundle
function ResourceManager.UnloadAll()
    local ok, err = pcall(function()
        RM:UnloadAll()
    end)
    if not ok then
        print("[ResourceManager] UnloadAll 异常:", err)
    end
end

return ResourceManager
