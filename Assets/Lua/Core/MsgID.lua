-- Assets/Lua/Core/MsgID.lua

-- 这个表的键名需与 C# MsgID 枚举成员同名，值与其在 C# 中的 ushort 值保持一致
local MsgID = {
    LoginRequest      = 1,
    LoginResponse     = 2,
}

-- 同时再导出一个列表，把名字映射给自己
MsgID.name = {
    [1] = "LoginRequest",
    [2] = "LoginResponse",
}
return MsgID
