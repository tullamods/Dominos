if not (PlayerPowerBarAlt or UIWidgetPowerBarContainerFrame) then return end

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local PowerBar = Addon:CreateClass('Frame', Addon.Frame)

function PowerBar:New()
	local frame = PowerBar.proto.New(self, 'encounter')

	frame:ShowInOverrideUI(true)
	frame:ShowInPetBattleUI(true)
	frame:Layout()

	return frame
end

PowerBar:Extend('OnCreate', function(self)
	self.frames = {}

	local ppb = PlayerPowerBarAlt
	if ppb then
		ppb:ClearAllPoints()
		ppb:SetParent(self)
		ppb:SetPoint('CENTER', self)

		if type(ppb.SetupPlayerPowerBarPosition) == "function" then
			hooksecurefunc(ppb, "SetupPlayerPowerBarPosition", function(bar)
				if bar:GetParent() ~= self then
					bar:SetParent(self)
					bar:ClearAllPoints()
					bar:SetPoint('CENTER', self)
				end
			end)
		end

		if type(UnitPowerBarAlt_SetUp) == "function" then
			hooksecurefunc("UnitPowerBarAlt_SetUp", function(bar)
				if bar.isPlayerBar and bar:GetParent() ~= self then
					bar:SetParent(self)
					bar:ClearAllPoints()
					bar:SetPoint('CENTER', self)
				end
			end)
		end

		ppb:HookScript("OnSizeChanged", function() self:Layout() end)

		self.frames[#self.frames+1] = ppb
	end

	local uiPowerBar = UIWidgetPowerBarContainerFrame
	if uiPowerBar then
		uiPowerBar:ClearAllPoints()
		uiPowerBar:SetParent(self)
		uiPowerBar:SetPoint('CENTER', self)

		uiPowerBar:HookScript("OnSizeChanged", function() self:Layout() end)

		self.frames[#self.frames+1] = uiPowerBar
	end
end)

function PowerBar:GetDisplayName()
	return L.EncounterBarDisplayName
end

function PowerBar:GetDefaults()
	return { point = 'CENTER', displayLayer = 'HIGH' }
end

-- always reparent + position the bar due to UIParent.lua moving it whenever its shown
function PowerBar:Layout()
	local width, height = 0, 0

	for _, frame in pairs(self.frames) do
		local w, h = frame:GetSize()

		width = math.max(w, width)
		height = math.max(h, height)
	end

	if width > 0 and height > 0 then
		local pW, pH = self:GetPadding()
		self:TrySetSize(width + pW, height + pH)
	else
		self:TrySetSize(36 * 6, 36)
	end
end

-- module
local PowerBarModule = Addon:NewModule('EncounterBar', 'AceEvent-3.0')

function PowerBarModule:Load()
	if self.frame == nil then
		self.frame = PowerBar:New()
	end
end

function PowerBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function PowerBarModule:OnFirstLoad()
	local ppb = PlayerPowerBarAlt
	if ppb then
		-- the standard UI will check to see if the power bar is user placed before
		-- doing anything to its position, so mark as user placed to prevent that
		-- from happening
		ppb:SetMovable(true)
		ppb:SetUserPlaced(true)

		-- tell blizzard that we don't it to manage this frame's position
		if not Addon:IsBuild("retail") then
			ppb.ignoreFramePositionManager = true
		end

		self:RegisterEvent("PLAYER_LOGOUT")
	end
end

-- SetUserPlaced is persistent, so revert upon logout
function PowerBarModule:PLAYER_LOGOUT()
	local ppb = PlayerPowerBarAlt
	if ppb then
		ppb:SetUserPlaced(false)
	end
end

-- exports
Addon.EncounterBar = PowerBar
