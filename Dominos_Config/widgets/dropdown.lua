local _, Addon = ...

local function getItemValue(item)
	if type(item) == "table" then
		return item.value
	end
	return item
end

local function getItemLabel(item)
	if type(item) == "table" then
		local text = item.text

		if type(text) == "function" then
			return text(item.value)
		else
			return text or item.value
		end
	end

	return item
end

local function frame_OnEnter(self)
	self.HoverBackground:Show()
end

local function frame_OnLeave(self)
	self.HoverBackground:Hide()
end


local DropdownMixin = {}

function DropdownMixin:SetSavedValue(value) end

function DropdownMixin:GetSavedValue() end

function DropdownMixin:GetItems()
	if type(self.items) == "function" then
		return self:items()
	end

	return self.items
end

function DropdownMixin:GetItem(index)
	if type(self.items) == "function" then
		return self:items()[index]
	end

	return self.items[index]
end

function Addon:CreateDropdown(options)
	local frame = CreateFrame('Button', nil, options.parent, 'ResizeLayoutFrame')

	Mixin(frame, DropdownMixin)

	frame.items = options.items
	frame.SetSavedValue = options.set
	frame.GetSavedValue = options.get
	frame:SetHighlightTexture(self:CreateHoverBackground(frame))
	frame.leftPadding = 2
	frame.rightPadding = 2
	frame.topPadding = 2
	frame.bottomPadding = 2
	frame.expand = true

	local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")

	dropdown:SetPoint('RIGHT')
	dropdown.expand = true

	local function isSelected(index)
		local item = frame:GetItem(index)
		local value = getItemValue(item)

		return value == frame:GetSavedValue()
	end

	local function handleSelect(index)
		local item = frame:GetItem(index)
		local value = getItemValue(item)

		frame:SetSavedValue(value)
	end

	dropdown:SetupMenu(function(_, rootDescription)
		rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)

		for i, item in ipairs(frame:GetItems()) do
			rootDescription:CreateRadio(getItemLabel(item), isSelected, handleSelect, i)
		end
	end)

	frame.Dropdown = dropdown

	local label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')

	label:SetPoint('LEFT')
	label:SetJustifyH('LEFT')
	label:SetJustifyV('MIDDLE')
	label:SetText(options.name)
	label:SetSize(120, label:GetStringHeight())

	frame.Label = label

	frame:SetFixedHeight(max(dropdown:GetHeight() or -math.huge, label:GetStringHeight()))
	frame:MarkDirty()

	return frame
end
