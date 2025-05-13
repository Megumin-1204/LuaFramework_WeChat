-- Assets/Lua/Entry/Main.lua
-- 框架启动入口，带最全日志

-- 1) 调试器（EmmyLua 可选）
-- package.cpath = package.cpath .. ';.../emmy/windows/x64/?.dll'
-- local dbg = require("emmy_core")
-- dbg.tcpConnect("localhost", 9966)

-- 2) 全局 Class
local Class = require("Core.Class")
_G.Class = Class
print("======= System Boot =======")

-- 3) 加载核心管理器
local ModuleManager = require("Core.ModuleManager")
local EventManager  = require("Core.EventManager")
local TimerManager  = require("Core.TimerManager")
local ResMgr        = require("Core.ResourceManager")
local UIMgr         = require("UI.UIMgr")
print("[Main] Loaded managers:", ModuleManager, EventManager, TimerManager, ResMgr, UIMgr)

-- 4) 注册核心模块
ModuleManager:RegisterCore("Event", EventManager)
ModuleManager:RegisterCore("Timer", TimerManager)
ModuleManager:RegisterCore("UI",    UIMgr)
ModuleManager:RegisterCore("Res",   ResMgr)
print("[Main] Core modules registered")

-- 5) 启动核心模块
ModuleManager:StartCore()

-- 6) 注册业务模块
local LoginModule = require("Game.Login.LoginController")
ModuleManager:RegisterBusiness("Login", LoginModule)
-- 你还可以继续注册 Test/其他模块
print("[Main] Business modules registered")

-- 7) 启动登陆模块
ModuleManager:StartModule("Login")

print("======= System Ready =======")
