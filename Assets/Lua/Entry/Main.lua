-- Entry/Main.lua

-- 调试器接入（EmmyLua）
package.cpath = package.cpath .. ';C:/Users/Administrator/AppData/Roaming/JetBrains/Rider2024.3/plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
local dbg = require("emmy_core")
dbg.tcpConnect("localhost", 9966)

-- 全局 Class
local Class = require("Core.Class")
_G.Class = Class

print("======= System Boot =======")

-- 加载核心管理器
local ModuleManager = require("Core.ModuleManager")
local EventManager  = require("Core.EventManager")
local UIMgr         = require("UI.UIMgr")
local Timer         = require("Core.TimerManager")

-- =========================
-- 1. 注册业务模块
-- =========================

-- 登录模块
local LoginModule = Class("LoginModule")
function LoginModule:OnStart()
    print("[LoginModule] OnStart")
end
function LoginModule:Enter()
    print("[Module] Enter LoginModule")
    -- 弹出登录面板
    UIMgr.ShowPanel("TestPanel", { foo = "bar" })
end
function LoginModule:Exit()
    print("[Module] Exit LoginModule")
    UIMgr.ClosePanel("TestPanel")
end
ModuleManager:RegisterModule("Login", LoginModule)

-- 主界面模块
local MainModule = Class("MainModule")
function MainModule:OnStart()
    print("[MainModule] OnStart")
end
function MainModule:Enter()
    print("[Module] Enter MainModule")
    -- 这里可以初始化主界面逻辑，比如加载主面板、绑定按钮等
    -- UIMgr:ShowPanel("MainPanel")
end
function MainModule:Exit()
    print("[Module] Exit MainModule")
    -- UIMgr:ClosePanel("MainPanel")
end
ModuleManager:RegisterModule("Main", MainModule)

-- =========================
-- 2. 启动核心系统模块
--    （在这里注册 Event/Timer/UI/Net 等，也可以放到 ModuleManager:BootCoreModules） 
-- =========================
ModuleManager:RegisterModule("Event", EventManager)
ModuleManager:RegisterModule("Timer", Timer)
ModuleManager:RegisterModule("UI", UIMgr)
-- 如果有网络模块，请类似：
-- ModuleManager:RegisterModule("Net", require("Core.NetManager"))

-- 按顺序启动必要的系统模块
ModuleManager:StartModule("Event")
ModuleManager:StartModule("Timer")
ModuleManager:StartModule("UI")
-- ModuleManager:StartModule("Net")

-- =========================
-- 3. 注册并进入首个业务模块
-- =========================
ModuleManager:StartModule("Login")

-- =========================
-- 4. 事件系统测试
-- =========================
EventManager.AddListener("TEST_EVENT", function(data)
    print("[Event] Received:", data.msg, "Code:", data.code)
end)

-- 延迟 3 秒触发测试事件（使用 EventManager.DispatchLater）
EventManager.DispatchLater(3.0, "TEST_EVENT", {
    msg  = "System Initialized",
    code = 200,
})

print("======= System Ready =======")
