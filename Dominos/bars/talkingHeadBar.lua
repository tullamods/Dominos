if not TalkingHeadFrame then return; end

--------------------------------------------------------------------------------
-- Talking Head Bar
-- Lets you move around the talking heads display
--------------------------------------------------------------------------------

local AddonName, Addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

-- bar
local TalkingHeadBar = Addon:CreateClass('Frame', Addon.Frame)

function TalkingHeadBar:New()
    return TalkingHeadBar.proto.New(self, 'talk')
end

function TalkingHeadBar:GetDisplayName()
    return L.TalkingHeadBarDisplayName
end

function TalkingHeadBar:GetDefaults()
    return {
        point = 'BOTTOM',
        x = 0,
        y = 74,
        displayLayer = 'LOW',
        showInPetBattleUI = true,
        showInOverrideUI = true
    }
end

TalkingHeadBar:Extend('OnAcquire', function(self)
    self:Layout()
end)

function TalkingHeadBar:Layout()
    self:AttachChild(TalkingHeadFrame)
    local width, height = TalkingHeadFrame:GetSize()

    local pW, pH = self:GetPadding()
    self:SetSize(width + pW, height + pH)
end

function TalkingHeadBar:OnPlay()
    if self:IsMuted() and TalkingHeadFrame.voHandle then
        StopSound(TalkingHeadFrame.voHandle, 0)
        TalkingHeadFrame.voHandle = nil
    end
end

function TalkingHeadBar:IsMuted()
    return self.sets.muteSounds and true
end

function TalkingHeadBar:SetMuted(enable)
    self.sets.muteSounds = (enable and true) or nil

    -- mute if currently playing
    if enable and TalkingHeadFrame and TalkingHeadFrame.voHandle then
        StopSound(TalkingHeadFrame.voHandle, 0)
        TalkingHeadFrame.voHandle = nil
    end
end

TalkingHeadBar.contextMenu = Addon.Frame.contextMenu:Extend {
    {
        insert = 'General',
        at = 'start',
        controls = {
            {
                type = 'check',
                name = _G.MUTE,
                get = 'IsMuted',
                set = 'SetMuted'
            }
        }
    }
}

-- module
local TalkingHeadBarModule = Addon:NewModule('TalkingHeadBar')
local bar

function TalkingHeadBarModule:Load()
    bar = TalkingHeadBar:New()
    Addon:SetAlertAnchorRedirect(TalkingHeadFrame, true)
end

function TalkingHeadBarModule:Unload()
    Addon:SetAlertAnchorRedirect(TalkingHeadFrame, false)

    if bar then
        bar:Free()
        bar = nil
    end
end

function TalkingHeadBarModule:OnFirstLoad()
    -- blizzard's OnHide drops the frame from the managed list if edit mode
    -- added it
    TalkingHeadFrame.ignoreFramePositionManager = true

    hooksecurefunc(TalkingHeadFrame, 'PlayCurrent', function()
        if bar then
            bar:OnPlay()
        end
    end)

    -- edit mode clears the flag whenever a layout is applied
    hooksecurefunc(TalkingHeadFrame, 'ApplySystemAnchor', function(frame)
        if bar then
            bar:AttachChild(frame)
        end
    end)
end
