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


--[[ 
	virtual button:
		these exist purely so that we can bind to an action, without directly binding to the action
		by doing so, we can implement cast on keypress for things other than Blizzard action buttons
--]]

local VirtualButton = Dominos:CreateClass('Button')
local unusedButtons = {}

function VirtualButton:GetOrCreate(target, parent)
	local button = self:Get() or self:Create()

	button:SetTarget(target)
	button:SetParent(parent)

	return button
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
		local button = self:Bind(CreateFrame('Button', getNextName(), nil, 'SecureHandlerBaseTemplate, SecureActionButtonTemplate'))

		button:Hide()
		
		button:RegisterForClicks('anyDown')

		button:SetAttribute('type', 'click')
		
		button:SetScript('OnMouseUp', button.OnMouseUp)
		button:SetScript('OnMouseDown', button.OnMouseDown)

		return button	
	end
end

function VirtualButton:Free()
	self:SetTarget(nil)
	self:SetParent(nil)

	table.insert(unusedButtons, self)
end

function VirtualButton:SetTarget(target)
	self.target = target
	self:SetAttribute('clickbutton', target)
end

function VirtualButton:OnMouseUp()
	self.target:SetButtonState('NORMAL')
end

function VirtualButton:OnMouseDown()
	self.target:SetButtonState('PUSHED')
end

function VirtualButton:SetCastOnKeyPress(enable)
	self:RegisterForClicks(enable and 'anyDown' or 'anyUp')
end

--[[ controller ]]--

local BindingsController = CreateFrame('Frame', nil, _G['UIParent'], 'SecureHandlerBaseTemplate, SecureHandlerStateTemplate')
Dominos.BindingsController = BindingsController

BindingsController.frames = {}

function BindingsController:Load()
	self:SetupAttributeMethods()

	self:SetScript('OnEvent', self.OnEvent)
	self:RegisterEvent('UPDATE_BINDINGS')
	self:RegisterEvent('PLAYER_LOGIN')
	self:RegisterEvent('CVAR_UPDATE')

	local OnBindingEvent = function() self:UpdateBindings() end

	hooksecurefunc('SetBinding', OnBindingEvent)
	hooksecurefunc('SetBindingClick', OnBindingEvent)
	hooksecurefunc('SetBindingItem', OnBindingEvent)
	hooksecurefunc('SetBindingMacro', OnBindingEvent)
	hooksecurefunc('SetBindingSpell', OnBindingEvent)
	hooksecurefunc('LoadBindings', OnBindingEvent)
end

function BindingsController:SetupAttributeMethods()
	self:Execute([[ 
		Frames = table.new() 
		Targets = table.new()
	]])
	
	self:SetAttribute('AddFrame', [[
		table.insert(Frames, self:GetFrameRef('frameToAdd'))
		table.insert(Targets, self:GetFrameRef('targetToAdd'))
	]])

	self:SetAttribute('RemoveFrame', [[
		local frameToRemove = self:GetFrameRef('frameToRemove')

		for frameID, frame in pairs(Frames) do
			if frame == frameToRemove then
				table.remove(Frames, frameID)
				table.remove(Targets, frameID)
				break
			end
		end

		self:RunAttribute('LoadBindings')
	]])
	
	self:SetAttribute('LoadBindings', [[	
		self:ClearBindings() 
				
		for frameID in ipairs(Frames) do
			self:RunAttribute('SetFrameBindings', frameID, self:RunAttribute('GetFrameBindings', frameID))
			self:RunAttribute('SetFrameBindings', frameID, self:RunAttribute('GetFrameClickBindings', frameID))
		end	
	]])
	
	self:SetAttribute('SetFrameBindings', [[
		local frameID = (...)

		for i = 2, select('#', ...) do
			self:RunAttribute('SetFrameBinding', frameID, (select(i, ...)))
		end
	]])
	
	self:SetAttribute('SetFrameBinding', [[
		local frameID, key = ...
		local frame = Frames[frameID]				
			
		self:SetBindingClick(true, key, frame:GetName())
	]])
	
	self:SetAttribute('GetFrameBindings', [[
		local frameID = ...
		local bindingID = Targets[frameID]:GetName()
		
		return GetBindingKey(bindingID)
	]])		

	self:SetAttribute('GetFrameClickBindings', [[
		local frameID = ...
		local bindingID = format('CLICK %s:LeftButton', Targets[frameID]:GetName())

		return GetBindingKey(bindingID)
	]])
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


	local vButton = VirtualButton:GetOrCreate(button, self)

	self:SetFrameRef('frameToAdd', vButton)
	self:SetFrameRef('targetToAdd', button)
	self:Execute([[ self:RunAttribute('AddFrame') ]])

	vButton:SetCastOnKeyPress(self:CastingOnKeyPress())

	self.frames[button] = vButton
end

function BindingsController:Unregister(button)
	if not self.frames[button] then
		return
	end

	local vButton = self.frames[button]

	self:SetFrameRef('frameToRemove', vButton)
	self:Execute([[ self:RunAttribute('RemoveFrame') ]])

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