-- Assets/Lua/UI/UIMgr.lua
local UIMgr = {}
local DEBUG_MODE = true

local function log(msg)
    if DEBUG_MODE then print("[UIMgr] " .. tostring(msg)) end
end

local function getUIManager()
    if not CS or not CS.UIManager then
        log("无法获取 CS.UIManager")
        return nil
    end
    return CS.UIManager.Instance
end

-- params 现在只支持 { onLoaded=fn, onFailed=fn }
function UIMgr.ShowPanel(panelName, params)
    assert(type(panelName) == "string" and #panelName > 0, "panelName 必须是非空字符串")
    if type(params) == "function" then params = { onLoaded = params } end
    params = params or {}

    log("加载面板: " .. panelName)

    local mgr = getUIManager()
    assert(mgr, "UIManager 未初始化")

    local function callback(go)
        if not go or go:Equals(nil) then
            log("面板加载失败: " .. panelName)
            if type(params.onFailed) == "function" then pcall(params.onFailed, "加载失败") end
            return
        end

        -- 1. 先 require 出面板类
        local ok, panelClass = pcall(require, "UI." .. panelName)
        if not ok then
            log("找不到 Lua 面板类: UI." .. panelName .. " 错误: " .. tostring(panelClass))
            CS.UnityEngine.Object.Destroy(go)
            return
        end

        -- 2. 读取面板类的 Layer 字段，默认 Common
        local UILayer = require("UI.UILayer")
        local layerKey = panelClass.Layer or "Common"
        UILayer.SetPanelLayer(go, layerKey)

        -- 3. 实例化面板
        local panel = panelClass.New(go)

        -- 4. 回调
        if type(params.onLoaded) == "function" then
            pcall(params.onLoaded, panel)
        end
    end

    mgr:ShowPanel(panelName, callback)
end

function UIMgr.ClosePanel(panelName)
    local mgr = getUIManager()
    if mgr then mgr:ClosePanel(panelName) end
end

return UIMgr
