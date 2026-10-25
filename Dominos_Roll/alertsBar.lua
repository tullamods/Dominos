--------------------------------------------------------------------------------
-- Alerts
-- A bar for moving the Alerts frame
--------------------------------------------------------------------------------

local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')

--------------------------------------------------------------------------------
-- bar
--------------------------------------------------------------------------------

local AlertsBar = Dominos:CreateClass('Frame', Dominos.Frame)

function AlertsBar:New()
	local bar = AlertsBar.proto.New(self, 'alerts')

	bar:Layout()

	return bar
end

function AlertsBar:GetDisplayName()
	return L.AlertsBarDisplayName
end

function AlertsBar:GetDefaults()
	return {
		point = 'LEFT',
		columns = 1,
		spacing = 2,
		showInPetBattleUI = true,
		showInOverrideUI = true,
	}
end

function AlertsBar:Layout()
	self:RepositionChildFrame()

	local pW, pH = self:GetPadding()
	self:SetSize(317 + pW, 119 + pH)
end

function AlertsBar:RepositionChildFrame()
	AlertFrame:ClearAllPoints()
	AlertFrame:SetPoint('BOTTOM', self)
end

--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

local AlertsBarModule = Dominos:NewModule('Alerts')

function AlertsBarModule:Load()
	if AlertFrame then
		self.alertsBar = AlertsBar:New()
	end
end

function AlertsBarModule:Unload()
	if self.alertsBar then
		self.alertsBar:Free()
		self.alertsBar = nil
	end
end

function AlertsBarModule:OnFirstLoad()
	if AlertFrame then
		AlertFrame.ignoreFramePositionManager = true

		hooksecurefunc(AlertFrame, "UpdateAnchors", function()
			if self.alertsBar then
				self.alertsBar:RepositionChildFrame()
			end
		end)
	end
end
