-- UI/UIMgr.lua
local UIMgr = {}

-- 显示面板的Lua封装方法
function UIMgr.ShowPanel(panelName, params)
    -- 获取C#的UIManager单例
    local csUIMgr = CS.UIManager.Instance

    -- 定义Lua回调
    local callback = function(go)
        -- 动态加载对应的Lua面板逻辑
        local panelPath = "UI."..panelName
        local panelClass = require(panelPath)
        local panel = panelClass.New(go)

        -- 传递初始化参数
        if params then
            panel:OnInit(params)
        end
    end

    -- 调用C#层方法
    csUIMgr:ShowPanel(panelName, xlua.cs(callback))
end

-- 关闭面板
function UIMgr.ClosePanel(panelName)
    CS.UIManager.Instance:ClosePanel(panelName)
end

return UIMgr