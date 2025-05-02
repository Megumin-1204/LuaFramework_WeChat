-- Assets/Lua/Third/Json.lua
-- 使用极简Json实现

local Json = {}

-- 为了不遮蔽全局 type，先把它本地化
local _type = type

function Json.encode(data)
    local t = _type(data)
    if t == "table" then
        local s = "{"
        for k, v in pairs(data) do
            local keyStr
            if _type(k) ~= "number" then
                keyStr = '"' .. tostring(k) .. '"'
            else
                keyStr = tostring(k)
            end
            s = s .. "[" .. keyStr .. "]=" .. Json.encode(v) .. ","
        end
        -- 去掉最后多余一个逗号，如果只有一个元素也能处理
        if s:sub(-1) == "," then
            s = s:sub(1, -2)
        end
        return s .. "}"
    elseif t == "string" then
        return '"' .. data .. '"'
    else
        return tostring(data)
    end
end

return Json
