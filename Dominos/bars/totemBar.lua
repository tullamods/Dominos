if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem bar
-- Lets you move around the bar for totems
--------------------------------------------------------------------------------

local AddonName, Addon = ...

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local TotemBar = Addon:CreateClass('Frame', Addon.Frame)

function TotemBar:New()
    return TotemBar.proto.New(self, 'totem')
end

function TotemBar:GetDisplayName()
    return L.TotemBarDisplayName
end

function TotemBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2
    }
end

TotemBar:Extend('OnAcquire', function(self)
    if not InCombatLockdown() then
        MultiCastActionBarFrame:SetParent(self)
        MultiCastActionBarFrame:ClearAllPoints()
        MultiCastActionBarFrame:SetPoint('CENTER', self)
    end

    self:Layout()
end)

function TotemBar:Layout()
    local w, h = MultiCastActionBarFrame:GetSize()
    local pW, pH = self:GetPadding()

    self:SetSize(w + pW, h + pH)
end

-- export
Addon.TotemBar = TotemBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local TotemBarModule = Addon:NewModule('TotemBar')

function TotemBarModule:Load()
    self.bar = TotemBar:New()
end

function TotemBarModule:Unload()
    if self.bar then
        self.bar:Free()
        self.bar = nil
    end
end

function TotemBarModule:OnFirstLoad()
    MultiCastActionBarFrame.ignoreFramePositionManager = true

    -- onshow/hide call UpdateManagedFramePositions on the blizzard end so
    -- turn that bit off
    MultiCastActionBarFrame:SetScript("OnShow", nil)
    MultiCastActionBarFrame:SetScript("OnHide", nil)

    -- also, it is repositioned on every frame? that seems silly
    MultiCastActionBarFrame:SetScript("OnUpdate", nil)
end
