local OverrideController = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate'); OverrideController:Hide()
Dominos.OverrideController = OverrideController

local overrideBarStates = {
	overridebar = '[overridebar]1;0',
	possessbar = '[possessbar]1;0',
	vehicleui = '[vehicleui]1;0',
	vehicle = '[@vehicle,exists]1;0',
	sstemp = '[bonusbar:5]1;0',
	form = '[form]1;0',
	modifier = '[mod]1;0'
}

function OverrideController:Load()
	--[[ 
		Override UI Detection
	--]]
	
	local overrideUIWatcher = CreateFrame('Frame', nil, _G['OverrideActionBar'], 'SecureHandlerShowHideTemplate')
	overrideUIWatcher:SetFrameRef('controller', self)
	self.overrideUIWatcher = overrideUIWatcher

	overrideUIWatcher:SetAttribute('_onshow', [[ 
		self:GetFrameRef('controller'):SetAttribute('state-isoverrideuishown', true)
	]])

	overrideUIWatcher:SetAttribute('_onhide', [[ 
		self:GetFrameRef('controller'):SetAttribute('state-isoverrideuishown', false)
	]])
	
	self:SetAttribute('_onstate-isoverrideuishown', [[ 
		self:RunAttribute('updateOverrideUI') 
	]])

	self:SetAttribute('_onstate-useoverrideui', [[ 
		self:RunAttribute('updateOverrideUI') 
	]])

	self:SetAttribute('_onstate-overrideui', [[	
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-overrideui', newstate)
		end
	]])
	
	self:SetAttribute('updateOverrideUI', [[
		local isOverrideUIVisible = self:GetAttribute('state-useoverrideui') and self:GetAttribute('state-isoverrideuishown')
		
		self:SetAttribute('state-overrideui', isOverrideUIVisible)
	]])
	
	
	--[[ 
		Pet Battle UI Detection 
	--]]
			
	self:SetAttribute('_onstate-petbattleui', [[
		local hasPetBattleUI = newstate == 1
		
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-petbattleui', hasPetBattleUI)
		end
	]])
	
	
	--[[
		Override Page State Detection
	--]]
	
	--hack: make the MainMenuBarArtFrame secure so that we can read its state in combat
	self:SetFrameRef('MainActionBarController', self:MakeSecure(_G['MainMenuBarArtFrame']))
	self:SetFrameRef('OverrideActionBarController', _G['OverrideActionBar'])
	
	self:SetAttribute('_onstate-overridepage', [[	
		local overridePage = newstate or 0	
		
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-overridepage', overridePage)
		end
	]])
	
	for state in pairs(overrideBarStates) do
		self:SetAttribute('_onstate-' .. state, [[ self:RunAttribute('updateOverridePage') ]])
	end
	
	self:SetAttribute('updateOverridePage', [[
		local hasOverrideBar = self:GetAttribute('state-overridebar') == 1
		local inVehicle = (self:GetAttribute('state-vehicleui') == 1) or (self:GetAttribute('state-vehicle') == 1)
		
		local overridePage = self:GetFrameRef('MainActionBarController'):GetAttribute('actionpage') or 0
		if overridePage <= 10 and (hasOverrideBar or inVehicle) then
			overridePage = self:GetFrameRef('OverrideActionBarController'):GetAttribute('actionpage') or 0
		end
		
		self:SetAttribute('state-overridepage', overridePage)
	]])
	
	--[[
		Initialization
	--]]
	
	self:Execute([[ myFrames = table.new() ]])
	
	self:SetAttribute('state-isoverrideuishown', self.overrideUIWatcher:IsShown())
	
	RegisterStateDriver(self, 'petbattleui', '[petbattle]1;0')
		
	for state, values in pairs(overrideBarStates) do
		RegisterStateDriver(self, state, values)
	end
end

function OverrideController:Add(frame)
	self:SetFrameRef('FrameToRegister', frame)
	self:Execute([[ 
		local frame = self:GetFrameRef('FrameToRegister')
		
		table.insert(myFrames, frame)		
	]])
	
	--load states
	frame:SetAttribute('state-overrideui', self:GetAttribute('state-overrideui') == 'enabled')
	frame:SetAttribute('state-petbattleui', self:GetAttribute('state-petbattleui') == 'enabled')
	frame:SetAttribute('state-overridepage', self:GetAttribute('state-overridepage') or 0)
end

function OverrideController:Remove(frame)
	self:SetFrameRef('FrameToUnregister', frame)
	self:Execute([[ 
		local frameToUnregister = self:GetFrameRef('FrameToUnregister')
		for i, frame in pairs(myFrames) do
			if frame == frameToUnregister then
				table.remove(myFrames, i)
				break
			end
		end
	]])
end

function OverrideController:DumpStates()
	Dominos:Print('Active States:')
	print('------------------------------')
	for state in pairs(overrideBarStates) do
		local stateValue = self:GetAttribute('state-' .. state) == 1
		if stateValue then
			print(state)
		end
	end
	print('------------------------------')
end

function OverrideController:MakeSecure(frame)
	CreateFrame('Frame', nil, frame, 'SecureFrameTemplate')
	return frame
end

OverrideController:Load()