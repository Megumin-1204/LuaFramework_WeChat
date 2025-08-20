-- Assets/Lua/UI/LoginPanel.lua
local BasePanel    = require("UI.BasePanel")
local EventManager = require("Core.EventManager")
local Class        = require("Core.Class")
local NetworkManager = require("Core.NetworkManager")
local MsgID        = require("Core.MsgID")
local LoginPanel   = Class("LoginPanel", BasePanel)

function LoginPanel:OnCreate()
    -- 1. 获取输入框和按钮组件
    self.inputUser = self:GetComponent("InputUser", typeof(CS.UnityEngine.UI.InputField))
    self.inputPass = self:GetComponent("InputPass", typeof(CS.UnityEngine.UI.InputField))
    self.btnLogin  = self:GetComponent("BtnLogin",  typeof(CS.UnityEngine.UI.Button))

    -- 2. 按钮点击时，调用 NetworkManager.Send 发送登录请求
    if self.btnLogin then
        self.btnLogin.onClick:AddListener(function()
            self:OnLoginClicked()
        end)
    end

    -- 3. 监听“登录成功”全局事件：关闭面板或跳到主界面
    EventManager.AddListener("LOGIN_SUCCESS", function(resp)
        -- resp 是 { Success = true, Message = "..." }
        CS.UnityEngine.Debug.Log("LoginPanel: 收到 LOGIN_SUCCESS，关闭登录面板")
        UIMgr:Close("LoginPanel")
        -- 这里可以打开主界面 / 切场景
        -- UIMgr:Open("MainPanel")
    end)

    -- 4. 监听“登录失败”全局事件：弹提示
    EventManager.AddListener("LOGIN_FAILED", function(resp)
        CS.UnityEngine.Debug.Log("LoginPanel: 收到 LOGIN_FAILED，消息：" .. tostring(resp.Message))
        -- 可以弹一个提示框，比如 UIMgr:Open("ErrorTip", resp.Message)
    end)
end

function LoginPanel:OnEnable(params)
    -- 每次打开时清空输入框
    if self.inputUser then self.inputUser.text = "" end
    if self.inputPass then self.inputPass.text = "" end
end

--- 用户点击登录按钮后的处理
function LoginPanel:OnLoginClicked()
    local u = self.inputUser and self.inputUser.text or ""
    local p = self.inputPass and self.inputPass.text or ""
    if u == "" or p == "" then
        CS.UnityEngine.Debug.Log("LoginPanel: 请输入用户名和密码")
        return
    end

    -- 调用 NetworkManager.Send，将 Lua table 转成二进制发给 C# MockNetwork
    local req = { Username = u, Password = p }
    NetworkManager.Send(MsgID.LoginRequest, req)

    -- 可选：显示一个 “正在登录…” 的 Loading UI
    -- UIMgr:Open("LoadingPanel", { text = "正在登录..." })
end

return LoginPanel
