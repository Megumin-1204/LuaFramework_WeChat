local BasePanel = require("UI.BasePanel")
local LoginView = Class("LoginView", BasePanel)
LoginView.Layer = "Common"

function LoginView:OnCreate()
    -- UI组件缓存由基类完成
    -- 可以把 InputField 也包装到通用事件里
    self.usernameInput = self:GetComponent("InputUsername", typeof(CS.UnityEngine.UI.InputField))
    self.passwordInput = self:GetComponent("InputPassword", typeof(CS.UnityEngine.UI.InputField))
end

-- OnEnable 会在 UIMgr.ShowPanel 后被调用
function LoginView:OnEnable(params)
    -- 这里不绑按钮，交给 Controller 去 BindEvents
end

function LoginView:GetInput(name)
    local input = self:GetComponent(name, typeof(CS.UnityEngine.UI.InputField))
    return input and input.text or ""
end

return LoginView
