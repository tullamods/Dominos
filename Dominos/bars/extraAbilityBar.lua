if not (ExtraAbilityContainer or ExtraActionBarFrame) then return end

local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local BAR_ID = 'extra'
local EXTRA_ACTION_EVENTS = {
    'PLAYER_ENTERING_WORLD',
    'UPDATE_EXTRA_ACTIONBAR'
}

local ExtraAbilityBar = Addon:CreateClass('Frame', Addon.Frame)

local function hasExtraActionBar()
    if C_ActionBar and type(C_ActionBar.HasExtraActionBar) == 'function' then
        return C_ActionBar.HasExtraActionBar()
    end

    if type(HasExtraActionBar) == 'function' then
        return HasExtraActionBar()
    end

    return false
end

local function hasNativeExtraActionRelay()
    return Addon.IsAfterMidnight and Addon:IsAfterMidnight()
end

local function getExtraAbilityContainer()
    return ExtraAbilityContainer or ExtraActionBarFrame
end

local function getExtraActionButton()
    return ExtraActionBarFrame and ExtraActionBarFrame.button
end

local function setFramePoint(frame, point, relativeFrame)
    if frame.ClearAllPointsBase and frame.SetPointBase then
        frame:ClearAllPointsBase()
        frame:SetPointBase(point, relativeFrame)
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(point, relativeFrame)
end

local function setFrameShown(frame, show)
    if not frame then
        return
    end

    if frame.SetShown then
        frame:SetShown(show and true or false)
    elseif show then
        frame:Show()
    else
        frame:Hide()
    end
end

local function applyExtraActionButtonSafety()
    if not hasNativeExtraActionRelay() then
        return
    end

    local actionButtons = Addon.ActionButtons
    if not actionButtons or type(actionButtons.ApplyMidnightActionButtonSafety) ~= 'function' then
        return
    end

    actionButtons:ApplyMidnightActionButtonSafety(getExtraActionButton())
end

local function themeButton(button, enable, styleInfo)
    if not button then
        return
    end

    local themer = Addon:GetModule('ButtonThemer', true)
    if not themer then
        return
    end

    if enable then
        themer:Register(button, 'Extra Bar', styleInfo)
    else
        themer:Unregister(button, 'Extra Bar')
    end
end

function ExtraAbilityBar:New()
    return ExtraAbilityBar.proto.New(self, BAR_ID)
end

function ExtraAbilityBar:GetDisplayName()
    return L.ExtraBarDisplayName
end

ExtraAbilityBar:Extend('OnAcquire',  function(self)
    self:RepositionExtraAbilityContainer()
    self:UpdateShowBlizzardTexture()
    self:Layout()
end)

function ExtraAbilityBar:ThemeBar(enable)
    if hasExtraActionBar() then
        applyExtraActionButtonSafety()
        themeButton(getExtraActionButton(), enable)
    end

    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer
       and type(ZoneAbilityFrame.SpellButtonContainer.EnumerateActive) == 'function' then
        for button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
            themeButton(button, enable, { Icon = button.Icon })
        end
    end
end

function ExtraAbilityBar:GetDefaults()
    return {
        point = 'BOTTOM',
        displayLayer = 'HIGH',
        x = 0,
        y = 160,
        showInPetBattleUI = true,
        showInOverrideUI = true
    }
end

function ExtraAbilityBar:Layout()
    local w, h = 256, 120
    local pW, pH = self:GetPadding()

    self:SetSize(w + pW, h + pH)
end

function ExtraAbilityBar:RepositionExtraAbilityContainer()
    if InCombatLockdown() then
        return false
    end

    local container = getExtraAbilityContainer()
    if not container then
        return false
    end

    if container:GetParent() ~= self then
        container:SetParent(self)
    end

    setFramePoint(container, 'CENTER', self)
    return true
end

function ExtraAbilityBar:OnCreateMenu(menu)
    self:AddLayoutPanel(menu)

    menu:AddFadingPanel()
    menu:AddAdvancedPanel(true)
end

function ExtraAbilityBar:AddLayoutPanel(menu)
    local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(l.Layout)

    panel:NewCheckButton{
        name = l.ExtraBarShowBlizzardTexture,
        get = function()
            return panel.owner:ShowingBlizzardTexture()
        end,
        set = function(_, enable)
            panel.owner:ShowBlizzardTexture(enable)
        end
    }

    panel:AddBasicLayoutOptions()
end

function ExtraAbilityBar:ShowBlizzardTexture(show)
    self.sets.hideBlizzardTeture = not show
    self.sets.hideBlizzardTexture = not show

    self:UpdateShowBlizzardTexture()
end

function ExtraAbilityBar:ShowingBlizzardTexture()
    if self.sets.hideBlizzardTexture ~= nil then
        return not self.sets.hideBlizzardTexture
    end

    return not self.sets.hideBlizzardTeture
end

function ExtraAbilityBar:UpdateShowBlizzardTexture()
    local showTexture = self:ShowingBlizzardTexture()
    local button = getExtraActionButton()

    if button and button.style then
        setFrameShown(button.style, showTexture)
    end

    if ZoneAbilityFrame and ZoneAbilityFrame.Style then
        setFrameShown(ZoneAbilityFrame.Style, showTexture)
    end

    self:ThemeBar(not showTexture)
end

local ExtraAbilityBarModule = Addon:NewModule('ExtraAbilityBar')

function ExtraAbilityBarModule:Load()
    applyExtraActionButtonSafety()
    self.frame = ExtraAbilityBar:New()
    self:RefreshNativeExtraActionBar()
end

function ExtraAbilityBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function ExtraAbilityBarModule:OnFirstLoad()
    self:ApplyTitanPanelWorkarounds()
    self:InstallExtraActionRelay()
    applyExtraActionButtonSafety()

    -- Disable mouse interactions on the container frame only.  The actual
    -- ExtraActionButton1 child must remain clickable and secure.
    if ExtraActionBarFrame and ExtraActionBarFrame:IsMouseEnabled() then
        ExtraActionBarFrame:EnableMouse(false)
    end

    -- OnShow/OnHide call UpdateManagedFramePositions on the Blizzard end, so
    -- turn that bit off while Dominos owns placement.
    if ExtraAbilityContainer then
        ExtraAbilityContainer:SetScript('OnShow', nil)
        ExtraAbilityContainer:SetScript('OnHide', nil)

        -- Watch for new frames to be added to the container as we will want to
        -- possibly theme them later (if they're new buttons).
        hooksecurefunc(ExtraAbilityContainer, 'AddFrame', function()
            if self.frame then
                self.frame:ThemeBar(not self.frame:ShowingBlizzardTexture())
            end
        end)

        -- Also reposition whenever Edit Mode tries to do so.
        if type(ExtraAbilityContainer.ApplySystemAnchor) == 'function' then
            hooksecurefunc(ExtraAbilityContainer, 'ApplySystemAnchor', function()
                self:RepositionExtraAbilityContainer()
            end)
        end
    elseif ExtraActionBarFrame then
        ExtraActionBarFrame.ignoreFramePositionManager = true
    end
end

function ExtraAbilityBarModule:InstallExtraActionRelay()
    if self.extraActionRelay or not hasNativeExtraActionRelay() then
        return
    end

    if type(ExtraActionBar_Update) ~= 'function' then
        return
    end

    local relay = CreateFrame('Frame')
    for _, event in ipairs(EXTRA_ACTION_EVENTS) do
        relay:RegisterEvent(event)
    end

    relay:SetScript('OnEvent', function()
        self:RefreshNativeExtraActionBar()
    end)

    self.extraActionRelay = relay
end

function ExtraAbilityBarModule:RefreshNativeExtraActionBar()
    applyExtraActionButtonSafety()

    -- Midnight Dominos intentionally disables Blizzard's ActionBarController to
    -- avoid hidden native main-bar taint.  That also removes Blizzard's native
    -- UPDATE_EXTRA_ACTIONBAR dispatcher, so restore only this safe, narrow path.
    if hasNativeExtraActionRelay() and type(ExtraActionBar_Update) == 'function' then
        ExtraActionBar_Update()
    end

    if self.frame then
        self.frame:RepositionExtraAbilityContainer()
        self.frame:UpdateShowBlizzardTexture()
    end
end

function ExtraAbilityBarModule:RepositionExtraAbilityContainer()
    if not self.frame then
        return
    end

    local container = getExtraAbilityContainer()
    if not container then
        return
    end

    local _, relFrame = container:GetPoint()
    if self.frame ~= relFrame then
        self.frame:RepositionExtraAbilityContainer()
    end
end

-- Titan panel will attempt to take control of the ExtraActionBarFrame and break
-- its position and ability to be usable. This is because Titan Panel doesn't
-- check to see if another addon has taken control of the bar.
--
-- To resolve this, we call TitanMovable_AddonAdjust() for the extra ability bar
-- frames to let Titan Panel know we are handling positions for the extra bar.
function ExtraAbilityBarModule:ApplyTitanPanelWorkarounds()
    local adjust = _G.TitanMovable_AddonAdjust
    if not adjust then return end

    if ExtraAbilityContainer then
        adjust('ExtraAbilityContainer', true)
    end

    adjust('ExtraActionBarFrame', true)
    return true
end
