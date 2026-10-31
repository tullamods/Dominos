if not QueueStatusButton then return end

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- bar
local QueueStatusBar = Addon:CreateClass('Frame', Addon.Frame)

function QueueStatusBar:New()
    return QueueStatusBar.proto.New(self, "queue")
end

function QueueStatusBar:GetDisplayName()
    return L.QueueStatusBarDisplayName
end

function QueueStatusBar:GetDefaults()
    return {
        displayLayer = 'MEDIUM',
        point = 'BOTTOMRIGHT',
        x = -250
    }
end

function QueueStatusBar:CanSetShowStates()
    return false
end

QueueStatusBar:Extend('OnAcquire', function(self)
    self:AttachChild(QueueStatusButton)
    self:Layout()
end)

function QueueStatusBar:Layout()
    local w, h = QueueStatusButton:GetSize()
    local pW, pH = self:GetPadding()

    self:TrySetSize(w + pW, h + pH)
end

-- export
Addon.QueueStatusBar = QueueStatusBar

-- module
local QueueStatusBarModule = Addon:NewModule('QueueStatusBar')

function QueueStatusBarModule:Load()
    self.frame = QueueStatusBar:New()
end

function QueueStatusBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function QueueStatusBarModule:OnFirstLoad()
    local method = (QueueStatusButton.UpdateDefaultAnchor and "UpdateDefaultAnchor")
        or (QueueStatusButton.UpdatePosition and "UpdatePosition")

    if method then
        hooksecurefunc(QueueStatusButton, method, function()
            if self.frame then
                self.frame:AttachChild(QueueStatusButton)
            end
        end)
    end
end
