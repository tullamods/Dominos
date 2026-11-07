if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem bar
-- Lets you move around the bar for totems
--------------------------------------------------------------------------------

local AddonName, Addon = ...

--------------------------------------------------------------------------------
-- Bar
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
    self:AttachChild(MultiCastActionBarFrame)
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
local bar

function TotemBarModule:Load()
    bar = TotemBar:New()
end

function TotemBarModule:Unload()
    if bar then
        bar:Free()
        bar = nil
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

    -- edit mode clears the flag whenever a layout is applied
    if MultiCastActionBarFrame.ApplySystemAnchor then
        hooksecurefunc(MultiCastActionBarFrame, 'ApplySystemAnchor', function(frame)
            if bar then
                bar:AttachChild(frame)
            end
        end)
    end

    if EditModeManagerFrame.UpdateBottomActionBarPositions then
        hooksecurefunc(EditModeManagerFrame, 'UpdateBottomActionBarPositions', function()
            if bar then
                bar:AttachChild(MultiCastActionBarFrame)
            end
        end)
    end
end
