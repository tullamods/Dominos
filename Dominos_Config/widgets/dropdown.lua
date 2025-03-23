local _, Addon = ...

local Dropdown = Addon:CreateClass('Frame')
do
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

	function Dropdown:New(options)
		local menu = self:Bind(CreateFrame('Frame', nil, options.parent))

		menu.items = options.items
		menu.SetSavedValue = options.set
		menu.GetSavedValue = options.get

		local dropdownMenu = CreateFrame("DropdownButton", nil, menu, "WowStyle1DropdownTemplate")
		dropdownMenu:SetPoint('RIGHT', -8, 0)

		local function isSelected(index)
			local item = menu:GetItem(index)
			local value = getItemValue(item)

			return value == menu:GetSavedValue()
		end

		local function handleSelect(index)
			local item = menu:GetItem(index)
			local value = getItemValue(item)

			menu:SetSavedValue(value)
		end

		dropdownMenu:SetupMenu(function(dropdown, rootDescription)
			for i, item in ipairs(menu:GetItems()) do
				rootDescription:CreateRadio(getItemLabel(item), isSelected, handleSelect, i)
			end
		end)

		dropdownMenu:SetWidth(120)

		menu.dropdownMenu = dropdownMenu

		local text = menu:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLeft')
		text:SetPoint('LEFT')
		text:SetPoint('RIGHT', dropdownMenu, 'LEFT', -8, 0)
		text:SetText(options.name)
		menu.text = text

		local width = max(16 + text:GetWidth() + dropdownMenu:GetWidth(), 260)
		local height = 4 + max(dropdownMenu:GetHeight(), text:GetStringHeight())

		menu:SetSize(width, height)

		return menu
	end

	function Dropdown:GetEffectiveSize()
		return self:GetSize()
	end

	--[[ Update Methods ]] --

	function Dropdown:SetSavedValue(value) end

	function Dropdown:GetSavedValue() end

	function Dropdown:GetItems()
		if type(self.items) == "function" then
			return self:items()
		end

		return self.items
	end

	function Dropdown:GetItem(index)
		if type(self.items) == "function" then
			return self:items()[index]
		end

		return self.items[index]
	end
end

Addon.Dropdown = Dropdown
