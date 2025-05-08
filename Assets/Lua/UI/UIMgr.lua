-- Assets/Lua/UI/UIMgr.lua
local UIMgr = {}
local DEBUG = true
local function log(...) if DEBUG then print("[UIMgr]", ...) end end

local function getUIManager()
    assert(CS and CS.UIManager, "无法获取 CS.UIManager")
    return CS.UIManager.Instance
end

-- params = table with onLoaded, onFailed
function UIMgr.ShowPanel(panelName, params)
    assert(type(panelName)=="string" and #panelName>0, "panelName 必须是字符串")
    if type(params)=="function" then params={ onLoaded=params } end
    params = params or {}

    log("加载面板:", panelName)
    local mgr = getUIManager()
    mgr:ShowPanel(panelName, function(go)
        if not go or go:Equals(nil) then
            log("资源加载失败:", panelName)
            if type(params.onFailed)=="function" then pcall(params.onFailed,"加载失败") end
            return
        end

        -- 1. require 面板类
        local ok, clsOrErr = pcall(require, "UI."..panelName)
        if not ok then
            log("require失败:", clsOrErr)
            CS.UnityEngine.Object.Destroy(go)
            return
        end
        local panelClass = clsOrErr

        -- 2. 分层挂载
        local UILayer = require("UI.UILayer")
        UILayer.SetPanelLayer(go, panelClass.Layer or "Common")

        -- 3. 实例化（只调用 ctor/Init）
        log("实例化面板:", panelName)
        local panel = panelClass.New(panelClass, go)

        -- 4. 手动触发 OnEnable（避免放在 ctor 里被覆盖或漏调）
        if panel.OnEnable then
            log("触发 OnEnable:", panelName)
            -- 把 params 传给面板的 OnEnable
            pcall(function() panel:OnEnable(params) end)
        end

        -- 5. 最后 onLoaded 回调
        if type(params.onLoaded)=="function" then
            pcall(params.onLoaded, panel)
        end
    end)
end

function UIMgr.ClosePanel(panelName)
    local mgr = getUIManager()
    mgr:ClosePanel(panelName)
end

return UIMgr
