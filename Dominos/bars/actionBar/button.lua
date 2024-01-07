local _, Addon = ...

local StockActionButtons = {}
if Addon:IsBuild("retail") then
    local function addBar(bar, page)
        if not (bar and bar.actionButtons) then return end

        page = page or bar:GetAttribute("actionpage")

        -- when assigning buttons, we skip bar 12 (totems)
        -- so shift pages above 12 down one
        if page > 12 then
            page = page - 1
        end

        local offset = (page - 1) * NUM_ACTIONBAR_BUTTONS

        for i, button in pairs(bar.actionButtons) do
            StockActionButtons[i + offset] = button
        end
    end

    addBar(MainMenuBar, 1) -- 1
    addBar(MultiBarRight) -- 3
    addBar(MultiBarLeft) -- 4
    addBar(MultiBarBottomRight) -- 5
    addBar(MultiBarBottomLeft) -- 6
    addBar(MultiBar5) -- 13
    addBar(MultiBar6) -- 14
    addBar(MultiBar7) -- 15
else
    local function addButton(button, page)
        page = page or button:GetParent():GetAttribute("actionpage")

        local index = button:GetID() + (page - 1) * NUM_ACTIONBAR_BUTTONS

        StockActionButtons[index] = button
    end

    for i = 1, NUM_ACTIONBAR_BUTTONS do
        addButton(_G['ActionButton' .. i], 1) -- 1
        addButton(_G['MultiBarRightButton' .. i]) -- 3
        addButton(_G['MultiBarLeftButton' .. i]) -- 4
        addButton(_G['MultiBarBottomRightButton' .. i]) -- 5
        addButton(_G['MultiBarBottomLeftButton' .. i]) -- 6
    end
end

local function Cooldown_OnDone(self)
    if self.requireCooldownUpdate and self:GetParent():IsVisible() then
        self:GetParent():UpdateCooldown()
    end
end

local ActionButton_OnDragStart = [[
    if IsModifiedClick("PICKUPACTION") and HasAction(self:GetAttribute("action")) then
        return "action", self:GetAttribute("action")
    end
]]

local ActionButton_OnReceiveDrag = [[
    if kind then
        self:SetAttribute("dragging", kind)
        return "action", self:GetAttribute("action")
    else
        self:SetAttribute("dragging", nil)
    end
]]

local ActionButton = Addon:CreateClass("CheckButton")

--[[ Script Handlers ]]--

function ActionButton:OnCreate(id)
    self.id = id
    self.prevAttributeValues = {}

    self:SetSize(ActionButton1:GetSize())

    -- click handlers
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterForClicks("AnyUp", "LeftButtonDown", "RightButtonDown")
    self:EnableMouseWheel()

    -- script handlers
    self:SetScript("OnAttributeChanged", self.OnAttributeChanged)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("PostClick", self.OnPostClick)
    self:SetAttributeNoHandler("_ondragstart", ActionButton_OnDragStart)
    self:SetAttributeNoHandler("_onreceivedrag", ActionButton_OnReceiveDrag)
    Addon.ActionButtonScriptHandler:Wrap(self)

    -- textures
    self.Icon = self:CreateTexture(nil, "BACKGROUND")
    self.Icon:SetAllPoints()

    self.IconMask = self:CreateMaskTexture()
    self.IconMask:SetTexture(4626072, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    self.IconMask:SetPoint("CENTER", self.Icon)
    self.Icon:AddMaskTexture(self.IconMask)

    self.SlotBackground = self:CreateTexture(nil, "BACKGROUND")
    self.SlotBackground:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
    self.SlotBackground:SetAllPoints()

    -- button.SlotArt = button:CreateTexture(nil, "BACKGROUND")
    -- button.SlotArt:SetAtlas("ui-hud-actionbar-iconframe-slot")
    -- button.SlotArt:SetAllPoints()

    self.NormalTexture = self:CreateTexture(nil, "OVERLAY")
    self.NormalTexture:SetAtlas("UI-HUD-ActionBar-IconFrame")
    self.NormalTexture:SetAllPoints()
    self:SetNormalTexture(self.NormalTexture)

    self.CheckedTexture = self:CreateTexture()
    self.CheckedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    self.CheckedTexture:SetAllPoints()
    self:SetCheckedTexture(self.CheckedTexture)

    self.PushedTexture = self:CreateTexture(nil, "OVERLAY")
    self.PushedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
    self.PushedTexture:SetPoint("TOPLEFT", self.NormalTexture, -1, 1)
    self.PushedTexture:SetPoint("BOTTOMRIGHT", self.NormalTexture, 1, -1)
    self:SetPushedTexture(self.PushedTexture)

    self.HighlightTexture = self:CreateTexture()
    self.HighlightTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    self.HighlightTexture:SetPoint("TOPLEFT", self.NormalTexture, -2, 2)
    self.HighlightTexture:SetPoint("BOTTOMRIGHT", self.NormalTexture, 2, -2)
    self:SetHighlightTexture(self.HighlightTexture)

    -- text
    self.HotKey = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.HotKey:SetPoint("TOPRIGHT", -3.5, -3)

    self.Count = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.Count:SetPoint("BOTTOMRIGHT", -3, 3.5)

    self.Name = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.Name:SetPoint("BOTTOMLEFT", 5, 5)

    -- frames
    self.Cooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    self.Cooldown:SetDrawBling(true)
    self.Cooldown:SetDrawEdge(false)
    self.Cooldown:SetPoint("TOPLEFT", self.Icon, 3, -3)
    self.Cooldown:SetPoint("BOTTOMRIGHT", self.Icon, -3, 3)
    self.Cooldown:SetScript("OnCooldownDone", Cooldown_OnDone)

	self.ChargeCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
	self.ChargeCooldown:SetHideCountdownNumbers(true)
	self.ChargeCooldown:SetDrawSwipe(false)
    self.ChargeCooldown:SetPoint("TOPLEFT", self.Icon, 3, -3)
    self.ChargeCooldown:SetPoint("BOTTOMRIGHT", self.Icon, -3, 3)

    -- attributes
	self:SetAttributeNoHandler("type", "action")
	self:SetAttributeNoHandler("typerelease", "actionrelease")
	self:SetAttributeNoHandler("useparent-checkbuttoncast", true)
	self:SetAttributeNoHandler("useparent-checkfocuscast", true)
	self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
	self:SetAttributeNoHandler("useparent-unit", true)

    -- aliases
    -- these are added for compatibility with other addons
    self.icon = self.Icon
    self.cooldown = self.Cooldown
    self.chargeCooldown = self.ChargeCooldown

    -- extensions
    local action = StockActionButtons[id]
    if action then
        local commandName = action.commandName

        if not commandName then
            if action.buttonType then
                commandName = action.buttonType .. action:GetID()
            else
                commandName = action:GetName():upper()
            end
        end

        if commandName then
            self.commandName = commandName
            self:SetOverrideBindings(GetBindingKey(commandName))
        end
    end

    Addon.SpellFlyout:Register(self)
    Addon.BindableButton:AddQuickBindingSupport(self)
    Addon:GetModule('Tooltips'):Register(self)

    -- initialization
    self:UpdateHotkeys()
end

function ActionButton:SetOverrideBindings(...)
    ClearOverrideBindings(self)

    for i = 1, select("#", ...) do
        SetOverrideBindingClick(self, false, select(i, ...), self:GetName(), "HOTKEY")
    end
end

function ActionButton:OnAttributeChanged(key, value)
    local prevValue = self.prevAttributeValues[key]

    if value ~= prevValue then
        self.prevAttributeValues[key] = value

        local method = self["OnAttributeChanged_" .. key]
        if type(method) == "function" then
            method(self, key, value, prevValue)
        end
    end
end

function ActionButton:OnAttributeChanged_action(_, action, prevAction)
    self.action = action

    Addon.ActionButtons:OnActionButtonActionChanged(self, action, prevAction)

    self:UpdateActive()
    -- self:UpdateCooldown()
    self:UpdateCount()
    -- self:UpdateHotKey()
    self:UpdateIcon()
    self:UpdateShown()
    self:UpdateUsable(true)
end

function ActionButton:OnEnter()
    if HasAction(self:GetAttribute("action")) then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        self:UpdateTooltip()
    end
end

function ActionButton:OnLeave()
    GameTooltip:Hide()
end

function ActionButton:UpdateTooltip()
    GameTooltip:SetAction(self:GetAttribute("action"))
end

function ActionButton:OnPreClick()
end

function ActionButton:OnPostClick()
    self:UpdateShown()
    self:UpdateActive()
end

--[[ Methods ]]--

function ActionButton:Update()
    self:UpdateActive()
    self:UpdateCooldown()
    self:UpdateCount()
    self:UpdateHotkeys()
    self:UpdateIcon()
    self:UpdateShown()
    self:UpdateUsable(true)
end

function ActionButton:OnSlotUpdated()
    self:UpdateActive()
    self:UpdateCount()
    self:UpdateIcon()
    self:UpdateShown()
    self:UpdateUsable(true)
end

function ActionButton:UpdateActive()
    local action = self:GetAttribute("action")

    local active = HasAction(action) and (
        IsCurrentAction(action)
        or IsAutoRepeatAction(action)
        and not C_ActionBar.IsAutoCastPetAction(action)
    )

    self:SetChecked(active)
end

ActionButton.UpdateCooldown = ActionButton_UpdateCooldown

function ActionButton:UpdateCount()
    local action = self:GetAttribute("action")

    if IsConsumableAction(action) or IsStackableAction(action) then
        local count = GetActionCount(action) or 0

        if count > 0 and count < 999 then
            self.Count:SetFormattedText("%d", count)
        else
            self.Count:SetText("")
        end
    else
        local charges, maxCharges = GetActionCharges(action)
        if maxCharges and maxCharges > 1 then
            self.Count:SetText(charges)
        else
            self.Count:SetText("")
        end
    end
end

function ActionButton:UpdateIcon()
    local action = self:GetAttribute("action")

    local icon = GetActionTexture(action)
    if icon == nil then
        self.Icon:Hide()
    else
        self.Icon:SetTexture(icon)
        self.Icon:Show()
    end
end

function ActionButton:UpdateShown()
    if HasAction(self.action) or (self.showgrid or 0) > 0 then
        self:SetAlpha(1)
    else
        self:SetAlpha(0)
    end
end

function ActionButton:UpdateUsable(refresh)
    if refresh then
        local action = self.action

        self.oor = IsActionInRange(action) == false

        local usable, oom = IsUsableAction(action)
        self.oom = oom
        self.unusuable = not usable
    end

    local oor = self.oor
    local oom = self.oom
    local unusuable = self.unusuable
    local icon = self.Icon

    if oom then
        icon:SetDesaturated(true)
        icon:SetVertexColor(0.4, 0.4, 1.0)
    elseif oor then
        icon:SetDesaturated(true)
        icon:SetVertexColor(1, 0.4, 0.4)
    elseif unusuable then
        icon:SetDesaturated(true)
        icon:SetVertexColor(0.4, 0.4, 0.4)
    else
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1)
    end

    if oor then
        self.HotKey:SetVertexColor(1, 0, 0)
    else
        self.HotKey:SetVertexColor(1, 1, 1)
    end
end

function ActionButton:SetShowGrid(reason, show, force)
    local value = self.showgrid or 0

    if show then
        value = bit.bor(value, reason)
    else
        value = bit.band(value, bit.bnot(reason))
    end

    if (self.showgrid ~= value) or force then
        self.showgrid = value
        self:UpdateShown()
    end
end

function ActionButton:SetInRange(hasRange, inRange)
    self.oor = hasRange and not inRange
    self:UpdateUsable()
end

function ActionButton:SetIsUsuable(usable, oom)
    self.unusuable = not usable
    self.oom = oom
    self:UpdateUsable()
end

-- exports
Addon.ActionButton = ActionButton
