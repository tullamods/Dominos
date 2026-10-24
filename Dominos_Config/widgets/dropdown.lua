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

local DropdownMixin = {}

function DropdownMixin:Refresh()
	-- regenerating the menu re-reads the selected value
	if self.Dropdown:GetMenuDescription() then
		self.Dropdown:GenerateMenu()
	end
end

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
	frame.leftPadding = 2
	frame.rightPadding = 2
	frame.topPadding = 2
	frame.bottomPadding = 2
	frame.expand = true

	local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")

	dropdown.expand = true

	local function isSelected(index)
		local item = frame:GetItem(index)
		local value = getItemValue(item)

		return value == options.get()
	end

	local function handleSelect(index)
		local item = frame:GetItem(index)
		local value = getItemValue(item)

		options.set(value)
	end

	local function generateMenu(_, rootDescription)
		rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)

		for i, item in ipairs(frame:GetItems()) do
			local radio = rootDescription:CreateRadio(getItemLabel(item), isSelected, handleSelect, i)

			local initItem = options.initItem
			if initItem then
				local value = getItemValue(item)

				radio:AddInitializer(function(button)
					initItem(button, value)
				end)
			end
		end
	end

	-- SetupMenu generates the menu immediately, calling get before the panel
	-- has an owner. so defer it to the first show; the dropdown template
	-- regenerates the menu on subsequent shows
	frame:HookScript('OnShow', function()
		if not dropdown:GetMenuDescription() then
			dropdown:SetupMenu(generateMenu)
		end
	end)

	frame.Dropdown = dropdown

	local label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')

	label:SetPoint('LEFT')
	label:SetJustifyH('LEFT')
	label:SetJustifyV('MIDDLE')
	label:SetText(options.name or "PLACEHOLDER_TEXT")
	label:SetSize(120, label:GetStringHeight())

	frame.Label = label

	dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
	dropdown:SetPoint('RIGHT')

	frame:SetFixedHeight(max(dropdown:GetHeight() or -math.huge, label:GetStringHeight()))
	frame:MarkDirty()

	return frame
end
