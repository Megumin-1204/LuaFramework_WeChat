--package.cpath = package.cpath .. ';C:/Users/Administrator/AppData/Roaming/JetBrains/Rider2024.3/plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
--local dbg = require('emmy_core')
--dbg.tcpConnect('localhost', 9966)

print("===== xLua环境验证 =====")
print("xlua类型:", type(xlua))
print("cs函数类型:", type(xlua.cs))

-- Main.lua
local Class = require("Core.Class")
print("======= System Boot =======")
_G.Class = require("Core.Class")

-- 初始化核心模块 --------------------------------------------------
local ModuleManager = require("Core.ModuleManager")
local EventManager = require("Core.EventManager")
local UIMgr = require("UI.UIMgr")

-- 模块注册 --------------------------------------------------------
-- 注册登录模块（示例）
local LoginModule = Class("LoginModule")
function LoginModule:Enter()
    print("[Module] Enter LoginModule")

    -- 测试UI加载
    UIMgr.ShowPanel("TestPanel", function(go)
        -- 绑定Lua逻辑
        local panel = require("UI.TestPanel").New(go)

        -- 测试按钮回调
        panel:SetClickCallback(function()
            print("[UI] Button clicked! Switching to MainModule...")
            ModuleManager.Switch("Main")
        end)
    end)
end
function LoginModule:Exit()
    print("[Module] Exit LoginModule")
    UIMgr.ClosePanel("TestPanel")
end
ModuleManager.Register("Login", LoginModule)

-- 注册主界面模块（示例）
local MainModule = Class("MainModule")
function MainModule:Enter()
    print("[Module] Enter MainModule")
    -- 这里可以添加主界面初始化逻辑
end
function MainModule:Exit()
    print("[Module] Exit MainModule")
end
ModuleManager.Register("Main", MainModule)

-- 事件系统测试 ----------------------------------------------------
EventManager.AddListener("TEST_EVENT", function(data)
    print("[Event] Received:", data.msg, "Code:", data.code)
end)

-- 初始化完成 ------------------------------------------------------
-- 进入初始模块
ModuleManager.Switch("Login")

-- 派发测试事件（延迟3秒执行）
local gameRoot = CS.GameRoot.Instance
gameRoot:LuaInvoke(function()
    EventManager.Dispatch("TEST_EVENT", {
        msg = "System Initialized",
        code = 200
    })
end, 3)


print("======= System Ready =======")