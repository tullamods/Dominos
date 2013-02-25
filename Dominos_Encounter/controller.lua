local AddonName, Addon = ...
local EncounterBarController = Dominos:NewModule('encounter')

function EncounterBarController:OnInitialize()
	self:RemovePlayerPowerBarAltFromManagedFramePositions()
end

function EncounterBarController:Load()
	self.frame = Addon.EncounterBar:New()
end

function EncounterBarController:Unload()
	self.frame:Free()
end

function EncounterBarController:RemovePlayerPowerBarAltFromManagedFramePositions()
	local mfp = _G['UIPARENT_MANAGED_FRAME_POSITIONS']
	
	if mfp then
		mfp.PlayerPowerBarAlt = nil
		
		for key, value in pairs(mfp) do
			if value.playerPowerBarAlt then
				value.playerPowerBarAlt = nil
			end
		end
	end
end