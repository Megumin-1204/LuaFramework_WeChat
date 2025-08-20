-- Assets/Lua/UI/UIMgr.lua
-- Lua 端的 UI 管理器，只负责向 C# 请求弹窗并绑定 Lua 面板生命周期

local CS        = CS
local BasePanel = require("UI.BasePanel")
local PanelConfig = require("UI.PanelConfig")  -- 引入面板配置

local UIMgr = {}
local DEBUG = true
local function log(...)
    if DEBUG then print("[UIMgr]", ...) end
end

--- 异步显示面板（Lua 调用接口）
-- @param panelName string      面板名称，如 "LoginPanel"
-- @param params table|function 参数表或 onLoaded 回调函数
--        params.onLoaded(panelLua)   — 面板实例化并绑定完毕后的回调
--        params.onFailed(errorMsg)   — 加载或绑定失败时的回调
--        其他字段会原样传给 panel:OnEnable(params)
function UIMgr.ShowPanel(panelName, params)
    print(string.format("[UIMgr] *** Enter ShowPanel('%s') ***", panelName))
    assert(type(panelName) == "string" and #panelName > 0, "ShowPanel: panelName 必须为非空字符串")
    if type(params) == "function" then
        params = { onLoaded = params }
    end
    params = params or {}

    log("==> Enter ShowPanel:", panelName)
    local uiMgr = CS.UIManager.Instance

    -- 检查面板是否在配置中
    local config = PanelConfig[panelName]
    if not config then
        local errMsg = string.format("面板 '%s' 未在 PanelConfig 中配置", panelName)
        log(errMsg)
        if params.onFailed then
            pcall(params.onFailed, errMsg)
        end
        return
    end

    -- 调用专用接口 ShowPanelLua，避免与 Action 重载冲突
    uiMgr:ShowPanelLua(config.prefabPath, function(go)
        -- C# 实例化回调
        log("ShowPanelLua callback, go =", go)
        if not go or go:Equals(nil) then
            log("实例化返回 nil:", panelName)
            if params.onFailed then pcall(params.onFailed, "Instantiate returned nil") end
            return
        end

        -- 1) 加载 Lua 面板类
        local scriptPath = config.scriptPath
        log("加载面板脚本: " .. scriptPath)
        local ok, clsOrErr = pcall(require, scriptPath)
        if not ok then
            log("require 面板类失败:", clsOrErr)
            CS.UnityEngine.Object.Destroy(go)
            if params.onFailed then pcall(params.onFailed, clsOrErr) end
            return
        end
        local panelClass = clsOrErr

        -- 2) 构造 Lua 面板实例（调用 ctor + OnCreate）
        local panel = panelClass.New(panelClass, go)

        -- 3) 如果面板类没有指定层级，则使用配置中的层级
        if not panelClass.Layer and config.layer then
            panelClass.Layer = config.layer
            log(string.format("设置面板 %s 层级为: %s", panelName, config.layer))
        end

        -- 4) 触发 OnEnable（并传入 params）
        if panel.OnEnable then
            pcall(function() panel:OnEnable(params) end)
        end

        -- 5) 回调给上层
        if params.onLoaded then
            pcall(params.onLoaded, panel)
        end
    end)
end

--- 关闭面板（Lua 调用接口）
-- @param panelName string 面板名称
function UIMgr.ClosePanel(panelName)
    assert(type(panelName) == "string" and #panelName > 0, "ClosePanel: panelName 必须为非空字符串")

    -- 检查面板是否在配置中
    if not PanelConfig[panelName] then
        log(string.format("[WARNING] 关闭未配置的面板: %s", panelName))
    end

    CS.UIManager.Instance:ClosePanel(panelName)
end

--- 获取面板层级
function UIMgr.GetPanelLayer(panelName)
    if PanelConfig[panelName] then
        return PanelConfig[panelName].layer
    end
    return "Common" -- 默认层级
end

return UIMgr