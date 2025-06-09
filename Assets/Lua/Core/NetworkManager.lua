-- Assets/Lua/Core/NetworkManager.lua

-- 一定要拿到单例实例，而不是类型本身
local NetCS   = CS.Game.Manager.NetworkManager.Instance
local MsgID   = require("Core.MsgID")

local NetworkManager = {}

--- 发送消息：Lua table → C# 对象 → C# Encode → C# 发送
-- @param msgID number C# 枚举值
-- @param tbl   table  要发送的数据
function NetworkManager.Send(msgID, tbl)
    local msgObj
    if msgID == MsgID.LoginRequest then
        msgObj = CS.Game.Manager.LoginRequest()
        msgObj.Username = tbl.Username
        msgObj.Password = tbl.Password

    elseif msgID == MsgID.HeartbeatRequest then
        msgObj = CS.Game.Manager.HeartbeatRequest()

    else
        error("Unsupported Send msgID: " .. tostring(msgID))
    end

    -- 调用 C# 端静态 Encode 方法
    local bytes = CS.Game.Manager.NetworkManager.Encode(msgObj)
    -- 再调用实例方法 SendRaw
    NetCS:SendRaw(msgID, bytes)
end

--- 注册消息回调：C# 收到 byte[] → C# Decode → Lua table → handler
-- @param msgID   number 消息 ID
-- @param handler function 回调，接收一个纯 Lua table
function NetworkManager.RegisterHandler(msgID, handler)
    NetCS:RegisterHandler(msgID, function(body)
        -- 调用 C# 静态 Decode 方法
        local respObj = CS.Game.Manager.NetworkManager.Decode(msgID, body)
        -- 再把 C# 对象字段拷到 Lua table
        local tbl = {}
        if msgID == MsgID.LoginResponse then
            tbl.Success = respObj.Success
            tbl.Message = respObj.Message

        elseif msgID == MsgID.HeartbeatResponse then
            -- nothing to copy for heartbeat

        else
            error("Unsupported RegisterHandler msgID: " .. tostring(msgID))
        end

        handler(tbl)
    end)
end

return NetworkManager
