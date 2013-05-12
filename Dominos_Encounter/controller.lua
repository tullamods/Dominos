local AddonName, Addon = ...
local EncounterBarController = Dominos:NewModule('encounter')

function EncounterBarController:OnInitialize()
	_G['PlayerPowerBarAlt'].ignoreFramePositionManager = true
end

function EncounterBarController:Load()
	self.frame = Addon.EncounterBar:New()
end

function EncounterBarController:Unload()
	self.frame:Free()
end