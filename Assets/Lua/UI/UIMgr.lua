-- Assets/Lua/UI/UIMgr.lua
-- 商业级 UI 管理器：AssetBundle 驱动、支持异步/同步、栈管理、对象池、回调

local CS        = CS
local ResMgr    = require("Core.ResourceManager")
local UILayer   = require("UI.UILayer")
local UIStack   = require("UI.UIStack")
local UIPool    = require("UI.UIPool")
local BasePanel = require("UI.BasePanel")

local UIMgr = {}
local DEBUG = true
local function log(...) if DEBUG then print("[UIMgr]", ...) end end

-- 约定：bundle 名与 prefab 路径
local function bundleName(panelName)
    return "ui_" .. panelName:lower()
end
local function assetPath(panelName)
    return string.format("Assets/Resources/UI/%s.prefab", panelName)
end

--- 异步显示面板
-- @param panelName string
-- @param params table 或 function
--    params.onLoaded(panel), params.onFailed(err)
function UIMgr.ShowPanel(panelName, params)
    assert(type(panelName)=="string" and #panelName>0, "ShowPanel: panelName 必须是非空字符串")
    if type(params)=="function" then params={ onLoaded=params } end
    params = params or {}

    log("Async Load Panel:", panelName)
    local bndl = bundleName(panelName)
    local path = assetPath(panelName)

    -- 1) 异步加载 bundle
    ResMgr.LoadBundleAsync(bndl, function(ok)
        if not ok then
            log("Bundle 加载失败:", bndl)
            if type(params.onFailed)=="function" then pcall(params.onFailed, "Bundle load failed") end
            return
        end

        -- 2) 异步加载 prefab
        ResMgr.LoadAssetAsync(bndl, path, function(prefab)
            if not prefab then
                log("Prefab 加载失败:", path)
                if type(params.onFailed)=="function" then pcall(params.onFailed, "Prefab load failed") end
                return
            end

            -- 3) 实例化 GameObject
            local go = CS.UnityEngine.Object.Instantiate(prefab)
            go.name = panelName

            -- 4) 分层挂载
            local panelClass = require("UI."..panelName)
            UILayer.SetPanelLayer(go, panelClass.Layer or "Common")

            -- 5) 构建 BasePanel 对象
            log("Instantiate Panel:", panelName)
            local panel = panelClass.New(panelClass, go)

            -- 6) 触发 OnEnable
            if panel.OnEnable then
                local okEn, errEn = pcall(function() panel:OnEnable(params) end)
                if not okEn then log("OnEnable 错误:", errEn) end
            end

            -- 7) 入栈管理
            UIStack:Push(panel)

            -- 8) onLoaded 回调
            if type(params.onLoaded)=="function" then
                pcall(params.onLoaded, panel)
            end
        end)
    end)
end

--- 同步显示面板
-- @param panelName string
-- @param params table
-- @return panel instance
function UIMgr.ShowPanelSync(panelName, params)
    assert(type(panelName)=="string" and #panelName>0, "ShowPanelSync: panelName 必须是非空字符串")
    params = params or {}

    log("Sync Load Panel:", panelName)
    local bndl = bundleName(panelName)
    local path = assetPath(panelName)

    -- 1) 同步加载 bundle
    local okLoad = ResMgr.LoadBundleSync(bndl)
    if not okLoad then error("Sync LoadBundle 失败: "..bndl) end

    -- 2) 同步加载 prefab
    local prefab = ResMgr.LoadAssetSync(bndl, path)
    if not prefab then error("Sync LoadAsset 失败: "..path) end

    -- 3) 实例化 & 分层
    local go = CS.UnityEngine.Object.Instantiate(prefab)
    go.name = panelName
    local panelClass = require("UI."..panelName)
    UILayer.SetPanelLayer(go, panelClass.Layer or "Common")

    -- 4) 构建 BasePanel 对象
    local panel = panelClass.New(panelClass, go)

    -- 5) 触发 OnEnable
    if panel.OnEnable then pcall(function() panel:OnEnable(params) end) end

    -- 6) 入栈
    UIStack:Push(panel)

    return panel
end

--- 关闭面板
-- @param panelName string
function UIMgr.ClosePanel(panelName)
    assert(type(panelName)=="string" and #panelName>0, "ClosePanel: panelName 必须是非空字符串")
    log("Close Panel:", panelName)

    -- 1) 出栈并销毁
    local panel = UIStack:Pop(panelName)
    if panel then
        pcall(function() panel:Destroy() end)
    end

    -- 2) 对象池回收（可选）
    pcall(function() UIPool:Release(panelName) end)

    -- 3) 卸载 bundle
    local bndl = bundleName(panelName)
    pcall(function() ResMgr.UnloadBundle(bndl) end)
end

return UIMgr
