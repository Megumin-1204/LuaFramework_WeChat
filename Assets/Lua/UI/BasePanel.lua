local BasePanel = Class("BasePanel")

function BasePanel:ctor(go)
    self.gameObject = go
    self.transform = go.transform
    self:OnInit()
end

-- 虚方法：子类需实现
function BasePanel:OnInit()
    -- 绑定组件示例：
    -- self.btnClose = self.transform:Find("BtnClose"):GetComponent("Button")
end

function BasePanel:Show()
    self.gameObject:SetActive(true)
end

function BasePanel:Hide()
    self.gameObject:SetActive(false)
end

return BasePanel