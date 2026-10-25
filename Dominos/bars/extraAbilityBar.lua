if not (ExtraAbilityContainer or ExtraActionBarFrame) then return end

local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local BAR_ID = 'extra'

local ExtraAbilityBar = Addon:CreateClass('Frame', Addon.Frame)

function ExtraAbilityBar:New()
    return ExtraAbilityBar.proto.New(self, BAR_ID)
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
    self:RepositionExtraAbilityContainer()
    self:UpdateShowBlizzardTexture()
    self:Layout()
end)

function ExtraAbilityBar:Layout()
    local w, h = 256, 120
    local pW, pH = self:GetPadding()

    self:SetSize(w + pW, h + pH)
end

function ExtraAbilityBar:RepositionExtraAbilityContainer()
    if InCombatLockdown() then return end

    local container = ExtraAbilityContainer or ExtraActionBarFrame

    container:SetParent(self)

    if container.ClearAllPointsBase then
        container:ClearAllPointsBase()
        container:SetPointBase('CENTER', self)
    else
        container:ClearAllPoints()
        container:SetPoint('CENTER', self)
    end
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

local function themeButton(button, enable, info)
    local themer = Addon:GetModule('ButtonThemer')

    if enable then
        themer:Register(button, 'Extra Bar', info)
    else
        themer:Unregister(button, 'Extra Bar')
    end
end

function ExtraAbilityBar:ThemeBar(enable)
    if HasExtraActionBar() then
        local button = ExtraActionBarFrame and ExtraActionBarFrame.button
        if button then
            themeButton(button, enable)
        end
    end

    local zoneAbilities = C_ZoneAbility and C_ZoneAbility.GetActiveAbilities()
    if type(zoneAbilities) == "table" and #zoneAbilities > 0 then
        for button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
            themeButton(button, enable, { Icon = button.Icon })
        end
    end
end

ExtraAbilityBar.contextMenu = Addon.Frame.contextMenu:Extend {
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
    self.frame = ExtraAbilityBar:New()
end

function ExtraAbilityBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function ExtraAbilityBarModule:OnFirstLoad()
    self:ApplyTitanPanelWorkarounds()

    -- disable mouse interactions on the extra action bar
    -- as it can sometimes block the UI from being interactive
    if ExtraActionBarFrame:IsMouseEnabled() then
        ExtraActionBarFrame:EnableMouse(false)
    end

    -- onshow/hide call UpdateManagedFramePositions on the blizzard end so
    -- turn that bit off
    if ExtraAbilityContainer then
        ExtraAbilityContainer:SetScript("OnShow", nil)
        ExtraAbilityContainer:SetScript("OnHide", nil)

        -- watch for new frames to be added to the container as we will want to
        -- possibly theme them later (if they're new buttons)
        hooksecurefunc(
            ExtraAbilityContainer, 'AddFrame', function()
                if self.frame then
                    self.frame:ThemeBar(not self.frame:ShowingBlizzardTexture())
                end
            end
        )

        -- also reposition whenever edit mode tries to do so
        hooksecurefunc(ExtraAbilityContainer, 'ApplySystemAnchor', function()
            self:RepositionExtraAbilityContainer()
        end)
    else
        ExtraActionBarFrame.ignoreFramePositionManager = true
    end
end

-- Titan panel will attempt to take control of the ExtraActionBarFrame and break
-- its position and ability to be usable. This is because Titan Panel doesn't
-- check to see if another addon has taken control of the bar
--
-- To resolve this, we call TitanMovable_AddonAdjust() for the extra ability bar
-- frames to let titan panel know we are handling positions for the extra bar
function ExtraAbilityBarModule:ApplyTitanPanelWorkarounds()
    local adjust = _G.TitanMovable_AddonAdjust
    if not adjust then return end

    if ExtraAbilityContainer then
        adjust('ExtraAbilityContainer', true)
    end

    adjust("ExtraActionBarFrame", true)
    return true
end

function ExtraAbilityBarModule:RepositionExtraAbilityContainer()
    if (not self.frame) then return end

    local _, relFrame = ExtraAbilityContainer:GetPoint()

    if self.frame ~= relFrame then
        self.frame:RepositionExtraAbilityContainer()
    end
end
