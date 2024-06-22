if not PlayerPowerBarAlt then return end

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local EncounterBar = Addon:CreateClass('Frame', Addon.Frame)

function EncounterBar:New()
	local frame = EncounterBar.proto.New(self, 'encounter')

	frame:InitPlayerPowerBarAlt()
	frame:ShowInOverrideUI(true)
	frame:ShowInPetBattleUI(true)
	frame:Layout()

	return frame
end

function EncounterBar:GetDisplayName()
	return L.EncounterBarDisplayName
end

function EncounterBar:GetDefaults()
	return { point = 'CENTER', displayLayer = 'HIGH' }
end

-- always reparent + position the bar due to UIParent.lua moving it whenever its shown
function EncounterBar:Layout()
	local bar = self.__PlayerPowerBarAlt
	bar:ClearAllPoints()
	bar:SetParent(self)
	bar:SetPoint('CENTER', self)

	-- resize out of combat
	if not InCombatLockdown() then
		local width, height = bar:GetSize()
		local pW, pH = self:GetPadding()

		width = math.max(width, 36 * 6)
		height = math.max(height, 36)

		self:SetSize(width + pW, height + pH)
	end
end

-- grab a reference to the bar
-- and hook the scripts we need to hook
function EncounterBar:InitPlayerPowerBarAlt()
	if not self.__PlayerPowerBarAlt then
		local ppb = PlayerPowerBarAlt
		local layout = function() self:Layout() end

		if ppb:GetScript('OnSizeChanged') then
			ppb:HookScript('OnSizeChanged', layout)
		else
			ppb:SetScript('OnSizeChanged', layout)
		end

		if type(ppb.SetupPlayerPowerBarPosition) == "function" then
			hooksecurefunc(ppb, "SetupPlayerPowerBarPosition", function(bar)
				if bar:GetParent() ~= self then
					bar:SetParent(self)
					bar:ClearAllPoints()
					bar:SetPoint('CENTER', self)
				end
			end)
		end

		if type("UnitPowerBarAlt_SetUp") == "function" then
			hooksecurefunc("UnitPowerBarAlt_SetUp", function(bar)
				if bar.isPlayerBar and bar:GetParent() ~= self then
					bar:SetParent(self)
					bar:ClearAllPoints()
					bar:SetPoint('CENTER', self)
				end
			end)
		end

		self.__PlayerPowerBarAlt = ppb
	end
end

-- module
local EncounterBarModule = Addon:NewModule('EncounterBar', 'AceEvent-3.0')

function EncounterBarModule:Load()
	self.frame = Addon.EncounterBar:New()
end

function EncounterBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function EncounterBarModule:OnFirstLoad()
	-- tell blizzard that we don't it to manage this frame's position
	if not Addon:IsBuild("retail") then
		PlayerPowerBarAlt.ignoreFramePositionManager = true
	end

	-- the standard UI will check to see if the power bar is user placed before
	-- doing anything to its position, so mark as user placed to prevent that
	-- from happening
	PlayerPowerBarAlt:SetMovable(true)
	PlayerPowerBarAlt:SetUserPlaced(true)

	self:RegisterEvent("PLAYER_LOGOUT")
end

function EncounterBarModule:PLAYER_LOGOUT()
	-- SetUserPlaced is persistent, so revert upon logout
	PlayerPowerBarAlt:SetUserPlaced(false)
end

-- exports
Addon.EncounterBar = EncounterBar
