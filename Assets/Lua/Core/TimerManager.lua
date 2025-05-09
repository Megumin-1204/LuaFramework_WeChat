-- Core/TimerManager.lua
-- Lua 侧调用 C# 定时器

local CS          = CS
local CLR_Timer   = CS.TimerManager.Instance

local TimerManager = {}

--- 注册一次性定时器
-- @param delay number 秒
-- @param fn function 回调
-- @return int 定时器 ID
function TimerManager.ScheduleOnce(delay, fn)
    assert(type(delay) == "number", "delay must be number")
    assert(type(fn)    == "function", "fn must be function")
    -- C# Action 自动转换
    return CLR_Timer:ScheduleOnce(delay, fn)
end

--- 注册重复定时器
-- @param interval number 秒
-- @param fn function 回调
-- @return int 定时器 ID
function TimerManager.ScheduleRepeating(interval, fn)
    assert(type(interval) == "number", "interval must be number")
    assert(type(fn)       == "function", "fn must be function")
    return CLR_Timer:ScheduleRepeating(interval, fn)
end

--- 取消定时器
-- @param timerId int
function TimerManager.Cancel(timerId)
    assert(type(timerId) == "number", "timerId must be number")
    CLR_Timer:Cancel(timerId)
end

return TimerManager
