--[[
	bindingsController.lua
		A bindable button manager

		Used for (hopefully) efficiently handling binding events,
		and also handling onkeypress buttons
--]]


--[[ globals ]]--

local _G = _G
local AddonName, Addon = ...
local Dominos = _G['Dominos']
local KeyBound = LibStub('LibKeyBound-1.0')
local UIModes = { "normal", "overrideui", "petbattleui" }


--[[ 
	virtual button:
		these exist purely so that we can bind to an action, without directly binding to the action
		by doing so, we can implement cast on keypress for things other than Blizzard action buttons
--]]

local VirtualButton = Dominos:CreateClass('Button')
local unusedButtons = {}

function VirtualButton:GetOrCreate()
	return self:Get() or self:Create()
end

function VirtualButton:Get()
	return table.remove(unusedButtons)
end

do
	local id = 1

	local function getNextName()
		local name = string.format('%sVirtualBindingButton%d', AddonName, id)		

		id = id + 1

		return name
	end

	function VirtualButton:Create()
		local button = self:Bind(CreateFrame('Button', getNextName(), nil, 'SecureHandlerStateTemplate, SecureActionButtonTemplate'))

		button:Hide()
		
		button:RegisterForClicks('anyDown')

		button:SetAttribute('type', 'macro')
		
		button:SetScript('OnMouseUp', button.OnMouseUp)
		button:SetScript('OnMouseDown', button.OnMouseDown)

		button:SetAttribute('_childupdate-uimode', [[
			self:RunAttribute('UpdateMacro')
		]])		

		button:SetAttribute('UpdateMacro', [[
			local parent = self:GetParent()
			local mode = parent and parent:GetAttribute('state-uimode') or 'normal'
			local macrotext = self:GetAttribute('macrotext--' .. mode) or self:GetAttribute('macrotext--normal')
			
			self:SetAttribute('macrotext', macrotext)
		]])

		return button	
	end
end

function VirtualButton:Free()
	self:SetParent(nil)

	self:SetAttribute('owner', nil)

	for i, uiMode in pairs(UIModes) do
		self:SetTarget(uiMode, nil)
	end

	table.insert(unusedButtons, self)
end

function VirtualButton:SetOwner(owner)
	local ownerName = owner:GetName()

	self:SetAttribute('owner', ownerName)
	self:SetTarget('normal', owner)
end

function VirtualButton:SetTarget(uiMode, target, macro)
	if not(uiMode and type(uiMode) == "string") then
		error(2, "Invalid ui mode")
	end

	self:SetAttribute('target--' .. uiMode, target)

	if target and macro then
		self:SetAttribute('macrotext--' .. uiMode, macro)
	elseif target then
		self:SetAttribute('macrotext--' .. uiMode, '/click ' .. target:GetName())
	else
		self:SetAttribute('macrotext--' .. uiMode, nil)
	end

	self:Execute([[ self:RunAttribute('UpdateMacro') ]])
end

function VirtualButton:GetTarget()
	local uiMode = self:GetAttribute('state-uimode') or 'normal'

	local result = self:GetAttribute('target--' .. uiMode) or self:GetAttribute('target--normal')

	if type(result) == 'function' then
		return result()
	end

	if type(result) == 'string' then
		return _G[result]
	end

	return result
end

function VirtualButton:OnMouseUp()
	local target = self:GetTarget()

	if target then
		target:SetButtonState('NORMAL')
	end
end

function VirtualButton:OnMouseDown()
	local target = self:GetTarget()

	if target then
		target:SetButtonState('PUSHED')
	end
end

function VirtualButton:SetCastOnKeyPress(enable)
	self:RegisterForClicks(enable and 'anyDown' or 'anyUp')
end


--[[ controller ]]--

local BindingsController = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate'); BindingsController:Hide()
Dominos.BindingsController = BindingsController

function BindingsController:Load()
	self.frames = {}

	self:SetupAttributeMethods()
	self:HookBindingMethods()
	self:RegisterEvents()

	Dominos.OverrideController:Add(self)
end

function BindingsController:SetupAttributeMethods()
	self:Execute([[ 
		myFrames = table.new()
	]])

	self:SetAttribute('_onstate-uimode', [[
		control:ChildUpdate('uimode', newstate or 'normal')	
	]])		

	self:SetAttribute('_onstate-overrideui', [[
		self:RunAttribute('UpdateUIMode')
	]])
	
	self:SetAttribute('_onstate-petbattleui', [[
		self:RunAttribute('UpdateUIMode')
	]])	

	self:SetAttribute('UpdateUIMode', [[
		local uiMode

		if self:GetAttribute('state-petbattleui') then
			uiMode = 'petbattleui'
		elseif self:GetAttribute('state-overrideui') then
			uiMode = 'overrideui'
		else
			uiMode = 'normal'
		end

		self:SetAttribute('state-uimode', uiMode)
	]])

	--[[ usage: LoadBindings() ]]--
	self:SetAttribute('LoadBindings', [[	
		self:ClearBindings() 
				
		for i, frame in ipairs(myFrames) do
			self:RunAttribute('LoadFrameBindings', i)
		end	
	]])

	--[[ usage: LoadFrameBindings(frameID) ]]--
	self:SetAttribute('LoadFrameBindings', [[
		local frame = myFrames[...]
		local frameName = frame:GetName()
		local targetName = frame:GetAttribute('owner')

		self:RunAttribute('SetBindings', frameName, self:RunAttribute('GetBindings', targetName))
		self:RunAttribute('SetBindings', frameName, self:RunAttribute('GetClickBindings', targetName))				
	]])
	
	--[[ usage: SetBindings(frameName, [binding1, binding2, ...]) ]]--
	self:SetAttribute('SetBindings', [[
		local frameName = (...)

		for i = 2, select('#', ...) do
			local key = (select(i, ...))

			self:SetBindingClick(true, key, frameName)
		end
	]])
	
	--[[ usage: GetBindings(frameName) ]]--
	self:SetAttribute('GetBindings', [[
		local frameName = (...)
		
		return GetBindingKey(frameName)
	]])		

	--[[ usage: GetClickBindings(frameName) ]]--
	self:SetAttribute('GetClickBindings', [[
		local frameName = (...)

		return GetBindingKey(format('CLICK %s:LeftButton', frameName))
	]])

	--[[ usage: ClearOverrideBindings([key1, key2, ...]) ]]--
	self:SetAttribute('ClearOverrideBindings', [[
		for i = 1, select('#', ...) do
			local key = (select(i, ...))

			self:ClearBinding(key)
		end
	]])	
end

function BindingsController:HookBindingMethods()
	local updateBindings = function() self:UpdateBindings() end

	hooksecurefunc('SetBinding', updateBindings)
	hooksecurefunc('SetBindingClick', updateBindings)
	hooksecurefunc('SetBindingItem', updateBindings)
	hooksecurefunc('SetBindingMacro', updateBindings)
	hooksecurefunc('SetBindingSpell', updateBindings)
	hooksecurefunc('LoadBindings', updateBindings)
end

function BindingsController:RegisterEvents()
	self:SetScript('OnEvent', self.OnEvent)

	self:RegisterEvent('UPDATE_BINDINGS')
	self:RegisterEvent('PLAYER_LOGIN')
	self:RegisterEvent('CVAR_UPDATE')
end

function BindingsController:OnEvent(event, ...)
	self[event](self, event, ...)
end

function BindingsController:UPDATE_BINDINGS(event)
	self:UnregisterEvent(event)
end

function BindingsController:PLAYER_LOGIN()
	self:UpdateCastOnKeyPress()
	self:UpdateBindings()
end

function BindingsController:CVAR_UPDATE(event, variableName)
	if variableName == 'ACTION_BUTTON_USE_KEY_DOWN' then
		self:UpdateCastOnKeyPress()
		self:UpdateBindings()
	end			
end

function BindingsController:Register(button)
	if self.frames[button] then
		return
	end

	button:UnregisterEvent('UPDATE_BINDINGS')

	local vButton = VirtualButton:GetOrCreate()
	vButton:SetParent(self)
	vButton:SetOwner(button)
	vButton:SetCastOnKeyPress(self:CastingOnKeyPress())

	self:SetFrameRef('frameToAdd', vButton)

	self:Execute([[ 		
		local frameToAdd = self:GetFrameRef('frameToAdd')

		for i, frame in pairs(myFrames) do
			if frame == frameToAdd then
				return
			end
		end

		table.insert(myFrames, frameToAdd)

		self:RunAttribute('LoadFrameBindings', #myFrames)
	]])
	
	vButton:Execute([[ self:RunAttribute('UpdateMacro') ]])

	self.frames[button] = vButton

	return vButton
end

function BindingsController:Unregister(button)
	if not self.frames[button] then
		return
	end

	local vButton = self.frames[button]

	self:SetFrameRef('frameToRemove', vButton)

	self:Execute([[
		local frameToRemove = self:GetFrameRef('frameToRemove')

		for i, frame in ipairs(myFrames) do
			if frame == frameToRemove then
				local targetName = frameToRemove:GetAttribute('owner')

				self:RunAttribute('ClearOverrideBindings', self:RunAttribute('GetBindings', targetName))
				self:RunAttribute('ClearOverrideBindings', self:RunAttribute('GetClickBindings', targetName))

				table.remove(myFrames, i)
				return
			end
		end
	]])
	
	vButton:Free()

	self.frames[button] = nil
end

--[[ note, i'm probably going to want to throttle this ]]--
function BindingsController:UpdateBindings()
	for button in pairs(self.frames) do
		button:UpdateHotkey()
	end

	self:Execute([[ self:RunAttribute('LoadBindings') ]])
end

function BindingsController:UpdateCastOnKeyPress()
	local castingOnKeyPress = self:CastingOnKeyPress()

	for button, vButton in pairs(self.frames) do
		vButton:SetCastOnKeyPress(castingOnKeyPress)
	end	
end

function BindingsController:CastingOnKeyPress()
	return GetCVarBool('ActionButtonUseKeyDown')
end

BindingsController:Load()