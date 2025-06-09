-- Assets/Lua/Entry/Main.lua
-- 框架启动入口，带最全日志

-- 1) (可选) EmmyLua 调试
-- package.cpath = package.cpath .. ';.../emmy/windows/x64/?.dll'
-- local dbg = require("emmy_core")
-- dbg.tcpConnect("localhost", 9966)

-- 2) 全局 Class
local Class = require("Core.Class")
_G.Class = Class
print("======= System Boot =======")

-- 3) 加载核心管理器
local ModuleManager   = require("Core.ModuleManager")
local EventManager    = require("Core.EventManager")
local TimerManager    = require("Core.TimerManager")
local ResMgr          = require("Core.ResourceManager")
local UIMgr           = require("UI.UIMgr")
-- **引入 NetworkManager 和 MsgID**
local NetworkManager  = require("Core.NetworkManager")
local MsgID           = require("Core.MsgID")

print("[Main] Loaded managers:", ModuleManager, EventManager, TimerManager, ResMgr, UIMgr, NetworkManager)

-- 4) 注册核心模块
ModuleManager:RegisterCore("Event", EventManager)
ModuleManager:RegisterCore("Timer", TimerManager)
ModuleManager:RegisterCore("UI",    UIMgr)
ModuleManager:RegisterCore("Res",   ResMgr)
print("[Main] Core modules registered")

-- 5) 启动核心模块
ModuleManager:StartCore()
print("[Main] Core modules started")

-- 6) 网络初始化（加载 all.pb 描述，必须在任何 Send/Receive 之前完成）
--NetworkManager.Init()
--print("[Main] NetworkManager initialized (all.pb loaded)")
NetworkManager.RegisterHandler(MsgID.LoginResponse, function(resp)
    if resp.Success then
        print("登录成功：" .. resp.Message)
        EventManager.Dispatch("LOGIN_SUCCESS", resp)
    else
        print("登录失败：" .. resp.Message)
        EventManager.Dispatch("LOGIN_FAILED", resp)
    end
end)

-- 7) 注册登录响应回调
NetworkManager.RegisterHandler(MsgID.LoginResponse, function(resp)
    -- resp 是一个 Lua table，字段 { Success=bool, Message=string }
    if resp.Success then
        print("[Main] 登录成功，消息：" .. tostring(resp.Message))
        -- 派发全局“登录成功”事件，供其他模块/UI 监听
        EventManager.Dispatch("LOGIN_SUCCESS", resp)
    else
        print("[Main] 登录失败，原因：" .. tostring(resp.Message))
        EventManager.Dispatch("LOGIN_FAILED", resp)
    end
end)

-- 8) 注册心跳响应回调（可选，仅做测试）
NetworkManager.RegisterHandler(MsgID.HeartbeatResponse, function(_)
    print("[Main] 收到心跳回包")
end)

-- 9) 注册业务模块
local LoginModule = require("Game.Login.LoginController")
ModuleManager:RegisterBusiness("Login", LoginModule)
-- 你还可以继续注册 Test/其他模块
print("[Main] Business modules registered")

-- 10) 启动登录模块 → 会打开登录面板
ModuleManager:StartModule("Login")
print("[Main] Started Login module")

print("======= System Ready =======")
