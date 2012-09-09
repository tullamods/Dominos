local OverrideController = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate'); OverrideController:Hide()
Dominos.OverrideController = OverrideController

function OverrideController:Load()
	--[[ 
		Override UI Detection
	--]]
	
	local overrideUIWatcher = CreateFrame('Frame', nil, _G['OverrideActionBar'], 'SecureHandlerShowHideTemplate')
	overrideUIWatcher:SetFrameRef('controller', self)

	overrideUIWatcher:SetAttribute('_onshow', [[ 
		self:GetFrameRef('controller'):SetAttribute('state-isoverrideuishown', true)
	]])

	overrideUIWatcher:SetAttribute('_onhide', [[ 
		self:GetFrameRef('controller'):SetAttribute('state-isoverrideuishown', false)
	]])
	
	self:SetAttribute('state-isoverrideuishown', overrideUIWatcher:IsShown())
	
	self:SetAttribute('_onstate-isoverrideuishown', [[ 
		self:RunAttribute('updateOverrideUI') 
	]])

	self:SetAttribute('_onstate-useoverrideui', [[ 
		self:RunAttribute('updateOverrideUI') 
	]])

	self:SetAttribute('_onstate-overrideui', [[	
		local enabled = newstate == 'enabled'
		
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-overrideui', enabled)
		end
	]])
	
	self:SetAttribute('updateOverrideUI', [[
		local isOverrideUIVisible = self:GetAttribute('useoverrideui') and self:GetAttribute('state-isoverrideuishown')
		if isOverrideUIVisible then
			self:SetAttribute('state-overrideui', 'enabled')
		else
			self:SetAttribute('state-overrideui', 'disabled')
		end
	]])

	
	--[[ 
		Pet Battle UI Detection 
	--]]
	
	RegisterStateDriver(self, 'petbattleui', '[petbattle]enabled;disabled')
		
	self:SetAttribute('_onstate-petbattleui', [[	
		local enabled = newstate == 'enabled'
		
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-petbattleui', enabled)
		end
	]])
	
	
	--[[
		Override Page State Detection
	--]]
	
	RegisterStateDriver(self, 'override', '[possessbar]possess;[overridebar]override;[@vehicle,exists]vehicle;normal')
	RegisterStateDriver(self, 'overrideform', '[form]enabled;disabled')
	RegisterStateDriver(self, 'overridepet', '[@pet,exists]enabled;disabled')
	-- RegisterStateDriver(self, 'overridepants', '[mod]enabled;disabled')
	
	self:SetAttribute('_onstate-override', [[ 
		self:RunAttribute('updateOverridePage') 
	]])
	
	self:SetAttribute('_onstate-overrideform', [[ 
		self:RunAttribute('updateOverridePage') 
	]])
	
	self:SetAttribute('_onstate-overridepet', [[ 
		self:RunAttribute('updateOverridePage') 
	]])
	
	-- self:SetAttribute('_onstate-overridepants', [[ 
		-- self:RunAttribute('updateOverridePage') 
	-- ]])
	
	self:SetAttribute('_onstate-overridepage', [[	
		local newPage = newstate or 0
		
		for i, frame in pairs(myFrames) do
			frame:SetAttribute('state-overridepage', newPage)
		end
	]])
	
	self:SetFrameRef('MainActionBarController', _G['MainMenuBarArtFrame'])
	self:SetFrameRef('OverrideActionBarController', _G['OverrideActionBar'])
	
	self:SetAttribute('updateOverridePage', [[
		local overridePage = self:GetFrameRef('MainActionBarController'):GetAttribute('actionpage') or 0

		if overridePage <= 10 and self:GetAttribute('state-override') ~= 'normal' then
			overridePage = self:GetFrameRef('OverrideActionBarController'):GetAttribute('actionpage') or 0
		end
		
		if overridePage <= 10 then
			self:SetAttribute('state-overridepage', 0)
		else
			self:SetAttribute('state-overridepage', overridePage)
		end
	]])
	
	--[[
		Initialization
	--]]
	
	self:Execute([[ myFrames = table.new() ]])
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

OverrideController:Load()