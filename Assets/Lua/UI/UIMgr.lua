-- Assets/Lua/UI/UIMgr.lua
-- Lua 侧 UI 管理器，负责调用 C# UIManager 并完成面板的分层挂载与实例化

local UIMgr = {}
local DEBUG_MODE = true

-- 调试输出
local function log(msg)
    if DEBUG_MODE then
        print("[UIMgr] " .. tostring(msg))
    end
end

-- 获取 C# 端单例
local function getUIManager()
    if not CS or not CS.UIManager then
        error("UIMgr: 无法获取 CS.UIManager")
    end
    return CS.UIManager.Instance
end

--- 显示一个面板
-- @param panelName string
-- @param params table|function
function UIMgr.ShowPanel(panelName, params)
    assert(type(panelName) == "string" and #panelName > 0,
            "UIMgr.ShowPanel: panelName 必须为非空字符串")
    if type(params) == "function" then
        params = { onLoaded = params }
    else
        params = params or {}
    end

    log("请求加载面板: " .. panelName)
    local mgr = getUIManager()

    mgr:ShowPanel(panelName, function(go)
        if not go or go:Equals(nil) then
            log("资源加载失败: " .. panelName)
            if type(params.onFailed) == "function" then
                pcall(params.onFailed, "加载失败")
            end
            return
        end

        log("Resources 加载完成: " .. go.name)

        -- 1. require 面板类
        local requirePath = "UI." .. panelName
        local ok, panelClassOrErr = pcall(require, requirePath)
        if not ok then
            log("require 失败: " .. requirePath .. " 错误: " .. tostring(panelClassOrErr))
            CS.UnityEngine.Object.Destroy(go)
            return
        end
        local panelClass = panelClassOrErr

        -- 2. 挂载层级
        local UILayer = require("UI.UILayer")
        local layerKey = panelClass.Layer or "Common"
        UILayer.SetPanelLayer(go, layerKey)

        -- 3. 实例化：显式传入类作为 self，确保调用 BasePanel:ctor
        log("调用 panelClass.New(panelClass, go) 实例化")
        -- 实例化：用 __call 语法糖
        local ok2, panelInstance = pcall(function()
            return panelClass(go)
        end)
        if not ok2 then
            log("panelClass.New 调用失败: " .. tostring(panelInstance))
            CS.UnityEngine.Object.Destroy(go)
            return
        end

        -- 4. onLoaded 回调
        if type(params.onLoaded) == "function" then
            pcall(params.onLoaded, panelInstance)
        end
    end)
end

--- 关闭一个面板
-- @param panelName string
function UIMgr.ClosePanel(panelName)
    assert(type(panelName) == "string" and #panelName > 0,
            "UIMgr.ClosePanel: panelName 必须为非空字符串")
    local mgr = getUIManager()
    mgr:ClosePanel(panelName)
end

return UIMgr
