if not ExtraActionBarFrame then return end

local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)
local THEME_GROUP = 'Extra Bar'

local bar

local ExtraAbilityBar = Addon:CreateClass('Frame', Addon.Frame)

function ExtraAbilityBar:New()
    return ExtraAbilityBar.proto.New(self, 'extra')
end

function ExtraAbilityBar:GetDisplayName()
    return L.ExtraBarDisplayName
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

ExtraAbilityBar:Extend('OnAcquire', function(self)
    self:AttachChild(ExtraAbilityContainer or ExtraActionBarFrame)
    self:UpdateShowBlizzardTexture()
    self:Layout()
end)

function ExtraAbilityBar:Layout()
    local w, h = 256, 120
    local pW, pH = self:GetPadding()

    self:SetSize(w + pW, h + pH)
end

function ExtraAbilityBar:ShowingBlizzardTexture()
    return not self.sets.hideBlizzardTexture
end

function ExtraAbilityBar:ShowBlizzardTexture(show)
    self.sets.hideBlizzardTexture = not show
    self:UpdateShowBlizzardTexture()
end

function ExtraAbilityBar:UpdateShowBlizzardTexture()
    local show = self:ShowingBlizzardTexture()

    ExtraActionBarFrame.button.style:SetShown(show)

    if ZoneAbilityFrame then
        ZoneAbilityFrame.Style:SetShown(show)
    end

    self:ThemeBar(not show)
end

function ExtraAbilityBar:ThemeBar(enable)
    local themer = Addon:GetModule('ButtonThemer')
    local update = enable and themer.Register or themer.Unregister
    local hasExtraBar = C_ActionBar and C_ActionBar.HasExtraActionBar or HasExtraActionBar

    if hasExtraBar() then
        update(themer, ExtraActionBarFrame.button, THEME_GROUP)
    end

    if ZoneAbilityFrame then
        for button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
            update(themer, button, THEME_GROUP, { Icon = button.Icon })
        end
    end
end

ExtraAbilityBar.contextMenu = Addon.Frame.contextMenu:Extend{
    {
        insert = 'General',
        at = 'start',
        controls = {
            {
                type = 'check',
                name = 'ExtraBarShowBlizzardTexture',
                get = 'ShowingBlizzardTexture',
                set = 'ShowBlizzardTexture'
            }
        }
    }
}

local ExtraAbilityBarModule = Addon:NewModule('ExtraAbilityBar')

function ExtraAbilityBarModule:Load()
    bar = ExtraAbilityBar:New()
end

function ExtraAbilityBarModule:Unload()
    if bar then
        bar:Free()
        bar = nil
    end
end

function ExtraAbilityBarModule:OnFirstLoad()
    self:ApplyTitanPanelWorkarounds()

    -- the buttons don't exist until an ability shows up
    Addon:GetModule('ButtonThemer'):CreateGroup(THEME_GROUP)

    -- it can block the UI from being interactive
    ExtraActionBarFrame:EnableMouse(false)

    -- leaving quick keybind mode shows the style texture again
    if ExtraActionBar_CancelForceShow then
        hooksecurefunc('ExtraActionBar_CancelForceShow', function()
            if bar then
                bar:UpdateShowBlizzardTexture()
            end
        end)
    end

    if ExtraAbilityContainer then
        self:ClaimExtraAbilityContainer()
    else
        -- cata and wrath have no container
        ExtraActionBarFrame.ignoreFramePositionManager = true
    end

    if ZoneAbilityFrame then
        self:ClaimZoneAbilityFrame()
    end
end

function ExtraAbilityBarModule:ClaimExtraAbilityContainer()
    ExtraAbilityContainer.ignoreFramePositionManager = true

    -- turning theming off is handled by UpdateShowBlizzardTexture
    hooksecurefunc(ExtraAbilityContainer, 'AddFrame', function()
        if bar and not bar:ShowingBlizzardTexture() then
            bar:ThemeBar(true)
        end
    end)

    -- edit mode clears the flag and re-lists the container whenever a layout
    -- is applied
    hooksecurefunc(ExtraAbilityContainer, 'ApplySystemAnchor', function(frame)
        if bar then
            bar:AttachChild(frame)
        end
    end)
end

function ExtraAbilityBarModule:ClaimZoneAbilityFrame()
    -- its buttons are created after AddFrame
    if ZoneAbilityFrame.UpdateDisplayedZoneAbilities then
        hooksecurefunc(ZoneAbilityFrame, 'UpdateDisplayedZoneAbilities', function()
            if bar and not bar:ShowingBlizzardTexture() then
                bar:ThemeBar(true)
            end
        end)
    end
end

-- titan panel moves these frames unless told another addon is positioning them
function ExtraAbilityBarModule:ApplyTitanPanelWorkarounds()
    local adjust = _G.TitanMovable_AddonAdjust
    if not adjust then return end

    if ExtraAbilityContainer then
        adjust('ExtraAbilityContainer', true)
    end

    adjust("ExtraActionBarFrame", true)
end
