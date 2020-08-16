-- Binding code that's shared between the various flavors of action buttons
local AddonName, Addon = ...
local KeyBound = LibStub('LibKeyBound-1.0')

-- binding method definitions
-- returns the binding action associated with the button
local function getButtonBindingAction(button)
	local buttonType = button.buttonType or button:GetAttribute("buttonType")

	if buttonType then
		local id = math.max(button:GetID(), button:GetAttribute('bindingid') or 0)
		if id > 0 then
			return buttonType .. id
		end
	end

	return ('CLICK %s:LeftButton'):format(button:GetName())
end

local function getButtonActionName(button)
	local action = getButtonBindingAction(button)
	local bindingName = GetBindingName(action)

	if bindingName and bindingName ~= action then
		return bindingName
	end

	return button:GetName()
end

local function getButtonBindings(button)
	return GetBindingKey(getButtonBindingAction(button))
end

-- returns what hotkey to display for the button
local function getButtonHotkey(button)
	local key = (getButtonBindings(button))

	if key then
		return KeyBound:ToShortKey(key)
	end

	return ''
end

-- returns a space separated list of all bindings for the given button
local function getButtonBindingsList(button)
	return strjoin(' ', getButtonBindings(button))
end

-- set bindings
local function setButtonBinding(button, key)
	return SetBinding(key, getButtonBindingAction(button))
end

-- clears all bindings from the button
local function clearButtonBindings(button)
	local key = (getButtonBindings(button))

	while key do
		SetBinding(key, nil)
		key = (getButtonBindings(button))
	end
end

-- used to implement keybinding support without applying all of the LibKeyBound
-- interface methods via a mixin
local BindableButtonProxy = Addon:CreateHiddenFrame("Frame", AddonName .. "BindableButtonProxy")

-- call a thing if the thing exists
local function whenExists(obj, func, ...)
	if obj then
		return func(obj, ...)
	end
end

function BindableButtonProxy:GetHotkey()
	return whenExists(self:GetParent(), getButtonHotkey)
end

function BindableButtonProxy:SetKey(key)
	return whenExists(self:GetParent(), setButtonBinding, key)
end

function BindableButtonProxy:GetBindings()
	return whenExists(self:GetParent(), getButtonBindingsList)
end

function BindableButtonProxy:ClearBindings()
	return whenExists(self:GetParent(), clearButtonBindings)
end

function BindableButtonProxy:GetActionName()
	return whenExists(self:GetParent(), getButtonActionName) or UNKNOWN
end

BindableButtonProxy:SetScript("OnLeave", function(self)
	print("OnLeave", self:GetName())

	self:ClearAllPoints()
	self:SetParent(nil)
end)

-- methods to inject onto a bar to add in common binding functionality
-- previously, this was a mixin
local BindableButton = {}

function BindableButton:Inject(button)
	button:HookScript("OnEnter", BindableButton.OnEnter)

	if button.UpdateHotkeys then
		hooksecurefunc(button, "UpdateHotkeys", BindableButton.UpdateHotkeys)
	else
		button.UpdateHotkeys = BindableButton.UpdateHotkeys
	end
end

function BindableButton:UpdateHotkeys()
	local key = getButtonHotkey(self)

	if key ~= ''  and Addon:ShowBindingText() then
		self.HotKey:SetText(key)
		self.HotKey:Show()
	else
		-- blank out non blank text, such as RANGE_INDICATOR
		self.HotKey:SetText('')
		self.HotKey:Hide()
	end
end

function BindableButton:OnEnter()
	if not KeyBound:IsShown() then return end

	BindableButtonProxy:ClearAllPoints()
	BindableButtonProxy:SetAllPoints(self)
	BindableButtonProxy:SetParent(self)

	KeyBound:Set(BindableButtonProxy)
end

-- exports
Addon.BindableButton = BindableButton

