-- An interface used to allow KeyBound to work transparently
-- both the stock blizzard bindings, and click bindings

local AddonName, Addon = ...
local KeyBound = LibStub('LibKeyBound-1.0')

local BindableButton = { }

-- used to wrap buttons, so that I can avoid stomping over possible mixin methods
local BindableButtonProxy = CreateFrame("Frame", AddonName .. "BinderProxy"); BindableButtonProxy:Hide()

-- returns the current hotkey assigned to the given button
function BindableButtonProxy:GetHotkey()
	local parent = self:GetParent()

	if parent then
		return BindableButton.GetHotkey(parent)
	end
end

function BindableButtonProxy:SetKey(key)
	local parent = self:GetParent()

	if parent then
		return BindableButton.SetKey(parent, key)
	end
end

function BindableButtonProxy:GetBindings()
	local parent = self:GetParent()

	if parent then
		return BindableButton.GetBindings(parent)
	end
end

function BindableButtonProxy:ClearBindings()
	local parent = self:GetParent()

	if parent then
		return BindableButton.ClearBindings(parent)
	end
end

-- what we're binding to, used for printing
function BindableButtonProxy:GetActionName()
	local parent = self:GetParent()

	if parent then
		local result

		if parent.buttonType then
			local id = parent:GetAttribute('bindingid') or parent:GetID()

			result = GetBindingName(parent.buttonType .. id)
		end

		return result or parent:GetName()
	end

	return UNKNOWN
end

-- keybound support
function BindableButton:Register(button)
	if button.UpdateHotkeys then
		hooksecurefunc(button, "UpdateHotkeys", BindableButton.UpdateHotkey)
	end

	button:HookScript("OnEnter", BindableButton.OnEnter)
end

function BindableButton:OnEnter()
	BindableButtonProxy:ClearAllPoints()
	BindableButtonProxy:SetAllPoints(self)
	BindableButtonProxy:SetParent(self)

	KeyBound:Set(BindableButtonProxy)
end

function BindableButton:UpdateHotkey(buttonType)
	local key = BindableButton.GetHotkey(self, buttonType)

	if key ~= ''  and Addon:ShowBindingText() then
		self.HotKey:SetText(key)
		self.HotKey:Show()
	else
		--blank out non blank text, such as RANGE_INDICATOR
		self.HotKey:SetText('')
		self.HotKey:Hide()
	end
end

--returns what hotkey to display for the button
function BindableButton:GetHotkey(buttonType)
	local key = BindableButton.GetBlizzBindings(self, buttonType)
			 or BindableButton.GetClickBindings(self)

	return key and KeyBound:ToShortKey(key) or ''
end

-- returns all blizzard bindings assigned to the button
function BindableButton:GetBlizzBindings(buttonType)
	buttonType = buttonType or self.buttonType

	if buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		return GetBindingKey(buttonType .. id)
	end
end

-- returns all click bindings assigned to the button
function BindableButton:GetClickBindings()
	return GetBindingKey(('CLICK %s:LeftButton'):format(self:GetName()))
end

-- returns a comma separated list of all bindings for the given action button
-- used for keybound support
do
    local buffer = {}

    local function addBindings(t, ...)
        for i = 1, select("#", ...) do
            local binding = select(i, ...)
            table.insert(t, GetBindingText(binding))
        end
    end

    function BindableButton:GetBindings()
        wipe(buffer)

        addBindings(buffer, BindableButton.GetBlizzBindings(self))
        addBindings(buffer, BindableButton.GetClickBindings(self))

        return table.concat(buffer, ", ")
    end
end

--set bindings (more keybound support)
function BindableButton:SetKey(key)
	if self.buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		SetBinding(key, self.buttonType .. id)
	else
		SetBindingClick(key, self:GetName(), 'LeftButton')
	end
end

--clears all bindings from the button (keybound support again)
do
	local function clearBindings(...)
		for i = 1, select('#', ...) do
			SetBinding(select(i, ...), nil)
		end
	end

	function BindableButton:ClearBindings()
		clearBindings(BindableButton.GetBlizzBindings(self))
		clearBindings(BindableButton.GetClickBindings(self))
	end
end

-- hook relevant methods
if ActionButton_UpdateHotkeys then
	hooksecurefunc("ActionButton_UpdateHotkeys", BindableButton.UpdateHotkey)
end

if PetActionButton_SetHotkeys then
	hooksecurefunc('PetActionButton_SetHotkeys', BindableButton.UpdateHotkey)
end

-- exports
Addon.BindableButton = BindableButton