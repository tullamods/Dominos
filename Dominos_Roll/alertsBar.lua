if not AlertFrame then return end

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
local bar

function AlertsBarModule:Load()
	bar = AlertsBar:New()
end

function AlertsBarModule:Unload()
	if bar then
		bar:Free()
		bar = nil
	end
end
