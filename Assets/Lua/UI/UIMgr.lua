-- UI/UIMgr.lua
local UIMgr = {}

-- 调试模式开关
local DEBUG_MODE = true

-- 私有方法：记录调试日志
local function log(msg)
    if DEBUG_MODE then
        print("[UIMgr DEBUG] " .. tostring(msg))
    end
end

-- 私有方法：安全获取C# UIManager实例
local function getUIManager()
    if not CS or not CS.UIManager then
        log("CS.UIManager 命名空间不存在")
        return nil
    end

    local instance = CS.UIManager.Instance
    if not instance then
        log("UIManager实例尚未初始化")
    else
        log(string.format("成功获取UIManager实例 (C#对象: %s)", tostring(instance)))
    end

    return instance
end

-- 显示面板（强化版）
function UIMgr.ShowPanel(panelName, params)
    -- 参数验证
    if type(panelName) ~= "string" or string.len(panelName) == 0 then
        error("无效的panelName参数，必须为非空字符串")
    end

    params = params or {}
    
    local json = require("Third.json")
    -- 日志输出
    log(string.format("尝试加载面板: %s | 参数: %s", panelName, json.encode(params)))

    -- 获取C#管理器实例
    local csUIMgr = getUIManager()
    if not csUIMgr then
        error("UI系统尚未初始化完成，请检查UIManager是否已挂载")
    end

    -- 定义Lua回调（带资源清理机制）
    local callback = function(go)
        if not go or go:Equals(nil) then
            log(string.format("面板加载失败: %s", panelName))
            if params.onFailed then
                pcall(params.onFailed, "资源加载失败")
            end
            return
        end

        log(string.format("面板加载成功: %s (实例ID: %s)", panelName, go:GetInstanceID()))

        -- 动态绑定Lua逻辑
        local success, panelClass = pcall(require, "UI."..panelName)
        if not success then
            log(string.format("找不到Lua面板类: UI.%s", panelName))
            CS.UnityEngine.Object.Destroy(go)
            return
        end

        -- 初始化面板实例
        local panel = panelClass.New(go)
        if params.onLoaded then
            pcall(params.onLoaded, panel)
        end
    end

    -- 调用C#层方法（使用xlua的异常捕获）
    xlua.cast(csUIMgr, typeof(CS.UIManager)):ShowPanel(
            panelName,
            xlua.cs(callback)
    )
end

-- 关闭面板
function UIMgr.ClosePanel(panelName)
    local csUIMgr = getUIManager()
    if csUIMgr then
        log(string.format("关闭面板: %s", panelName))
        csUIMgr:ClosePanel(panelName)
    end
end

return UIMgr