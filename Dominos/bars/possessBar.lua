--------------------------------------------------------------------------------
-- Possess bar
-- Handles the exit button for vehicles and taxis
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- missing APis in classic
local UnitControllingVehicle = UnitControllingVehicle or function() return false end
local CanExitVehicle = CanExitVehicle or function() return false end
local POSSESS_CANCEL_SLOT = POSSESS_CANCEL_SLOT or 2

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local function possessButton_OnClick(self)
    self:SetChecked(false)

    if UnitOnTaxi("player") then
        TaxiRequestEarlyLanding()

        -- Show that the request for landing has been received.
        self.icon:SetDesaturated(true)
        self:SetChecked(true)
        self:Disable()
    elseif CanExitVehicle() then
        VehicleExit()
    else
        CancelPetPossess()
    end
end

local function possessButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if UnitOnTaxi("player") then
        GameTooltip_SetTitle(GameTooltip, TAXI_CANCEL)
        GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    elseif UnitControllingVehicle("player") and CanExitVehicle() then
        GameTooltip_SetTitle(GameTooltip, LEAVE_VEHICLE)
    else
        GameTooltip:SetText(CANCEL)
    end

    GameTooltip:Show()
end

local function possessButton_OnLeave(self)
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

local function possessButton_OnCreate(self)
    self:SetScript("OnClick", possessButton_OnClick)
    self:SetScript("OnEnter", possessButton_OnEnter)
    self:SetScript("OnLeave", possessButton_OnLeave)

    Addon.BindableButton:AddQuickBindingSupport(self)
end

local function getOrCreatePossessButton(id)
    local name = ('%sPossessButton%d'):format(AddonName, id)
    local button = _G[name]

    if not button then
        if SmallActionButtonMixin then
            button = CreateFrame("CheckButton", name, nil, "SmallActionButtonTemplate", id)
            button.cooldown:SetSwipeColor(0, 0, 0)
        else
            button = CreateFrame("CheckButton", name, nil, "ActionButtonTemplate", id)
            button:SetSize(30, 30)
        end

        possessButton_OnCreate(button)
    end

    return button
end

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local DominosPossessBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function DominosPossessBar:New()
    return DominosPossessBar.proto.New(self, 'possess')
end

function DominosPossessBar:GetDisplayName()
    return L.PossessBarDisplayName
end

-- disable UpdateDisplayConditions as we're not using showstates for this
function DominosPossessBar:GetDisplayConditions()
    if Addon:IsBuild("retail") then
        return '[canexitvehicle][possessbar]show;hide'
    end

    if Addon:IsBuild("tbc") then
        local eye = C_Spell.GetSpellInfo(126)
        if eye then
            return ('[pet:%s][canexitvehicle][possessbar]show;hide'):format(eye.name)
        end
        return '[canexitvehicle][possessbar]show;hide'
    end

    return '[canexitvehicle][possessbar][bonusbar:5]show;hide'
end

function DominosPossessBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 244,
        y = 0,
        spacing = 4,
        padW = 2,
        padH = 2
    }
end

function DominosPossessBar:NumButtons()
    return 1
end

function DominosPossessBar:AcquireButton()
    return getOrCreatePossessButton(POSSESS_CANCEL_SLOT)
end

function DominosPossessBar:OnAttachButton(button)
    button:Show()

    Addon:GetModule('ButtonThemer'):Register(button, L.PossessBarDisplayName)
    Addon:GetModule('Tooltips'):Register(button)
end

function DominosPossessBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, L.PossessBarDisplayName)
    Addon:GetModule('Tooltips'):Unregister(button)
end

function DominosPossessBar:Update()
    local button = self.buttons[1]
    local texture = (GetPossessInfo(button:GetID()))
    local icon = button.icon

    if (UnitControllingVehicle("player") and CanExitVehicle()) or not texture then
        icon:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
        icon:SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
    else
        icon:SetTexture(texture)
        icon:SetTexCoord(0, 1, 0, 1)
    end

    icon:SetVertexColor(1, 1, 1)
    icon:SetDesaturated(false)

    button:SetChecked(false)
    button:Enable()
end

-- export
Addon.PossessBar = DominosPossessBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local PossessBarModule = Addon:NewModule('PossessBar', 'AceEvent-3.0')

function PossessBarModule:Load()
    self.bar = DominosPossessBar:New()

    self:RegisterEvent("UNIT_ENTERED_VEHICLE", "Update")
    self:RegisterEvent("UNIT_EXITED_VEHICLE", "Update")
    self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "Update")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
    self:RegisterEvent("VEHICLE_UPDATE", "Update")

    if not Addon:IsBuild("vanilla") then
        self:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR", "Update")
        self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "Update")
        self:RegisterEvent("UPDATE_POSSESS_BAR", "Update")
        self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "Update")
    end
end

function PossessBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
        self.bar = nil
    end
end

function PossessBarModule:OnFirstLoad()
    self.Update = Addon:Debounce(self.Update, 0.01, self)

    -- disable the possess bar
    if PossessActionBar then
        (PossessActionBar.HideBase or PossessActionBar.Hide)(PossessActionBar)
        PossessActionBar:SetParent(Addon.ShadowUIParent)
        PossessActionBar:UnregisterAllEvents()

        for _, button in pairs(PossessActionBar.actionButtons) do
            button:UnregisterAllEvents()
            button:SetAttributeNoHandler("statehidden", true)
            button:Hide()
        end
    elseif PossessBar then
        PossessBar:SetParent(Addon.ShadowUIParent)
        PossessBar:UnregisterAllEvents()
    end

    -- and the leave button (our bar handles both)
    local leaveButton = MainMenuBarVehicleLeaveButton
    if leaveButton then
        (leaveButton.HideBase or leaveButton.Hide)(leaveButton)
        leaveButton:SetParent(Addon.ShadowUIParent)
        leaveButton:UnregisterAllEvents()
    end
end

function PossessBarModule:Update()
    if self.bar then
        self.bar:Update()
    end
end
