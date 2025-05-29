-- Assets/Lua/Core/NetworkManager.lua
local CSNet   = CS.Game.Manager.NetworkManager.Instance
local protoc  = require "Third.protobuf.protoc".new()
local serpent = require "Third.protobuf.serpent"

local NetworkManager = {}

--- 初始化：加载 all.pb 描述文件
function NetworkManager.Init()
    local path = CS.UnityEngine.Application.streamingAssetsPath .. "/Proto/all.pb"
    local desc = CS.System.IO.File.ReadAllBytes(path)
    assert(protoc:load(desc), "Failed to load Protobuf descriptor")
    -- 可选：打印所有消息类型
    -- print("Proto types:", serpent.block(protoc:msg_types()))
end

--- 发送消息：Lua 表 → Protobuf 二进制 → C# 发送
-- @param msgID number 消息 ID，对应 .proto 中的 message 名称或枚举
-- @param tbl table  要发送的数据表
function NetworkManager.Send(msgID, tbl)
    local body = protoc:encode(msgID, tbl)
    CSNet:SendRaw(msgID, body)
end

--- 注册消息处理器：C# 收到 byte[] → 调用 handler(table)
-- @param msgID number 消息 ID
-- @param handler function 当收到该消息时的回调，接收一个 Lua table 参数
function NetworkManager.RegisterHandler(msgID, handler)
    CSNet:RegisterHandler(msgID, function(body)
        local ok, msg = pcall(protoc.decode, protoc, msgID, body)
        if ok then
            handler(msg)
        else
            error("Protobuf decode error for msg " .. msgID .. ": " .. tostring(msg))
        end
    end)
end

return NetworkManager
