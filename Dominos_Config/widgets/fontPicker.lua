local AddonName, Addon = ...

-- wrapper around LSM in case i want to replace it with something else
-- in the future
local Fonts = {}
do
	local LSM = LibStub('LibSharedMedia-3.0')

	local fontObjects = setmetatable({}, {
		__index = function(t, k)
			local fontPath = LSM:Fetch("font", k, false)

			if fontPath then
				local fontName = ("%sFonts%s"):format(AddonName, k)
				local font = CreateFont(fontName)

				font:SetFont(fontPath, 12, "OUTLINE")

				t[k] = font

				return font
			end
		end
	})

	function Fonts:Get(key)
		if key and LSM:IsValid("font", key) then
			return LSM:Fetch("font", key)
		end

		return LSM:GetDefault("font")
	end

	function Fonts:GetAll()
		return ipairs(LSM:List("font"))
	end

	function Fonts:GetFontObject(key)
		return fontObjects[key]
	end
end

local FontPicker = Addon:CreateClass('Frame')

do
	function FontPicker:New(options)
		local menu = self:Bind(CreateFrame('Frame', nil, options.parent))

		menu.SetSavedValue = options.set
		menu.GetSavedValue = options.get

		local dropdownMenu = CreateFrame("DropdownButton", nil, menu, "WowStyle1DropdownTemplate")
		dropdownMenu:SetPoint('RIGHT', -8, 0)

		local ddWidth = 200

		dropdownMenu:SetupMenu(function(_, rootDescription)
			rootDescription:SetGridMode(MenuConstants.VerticalGridDirection);

			for index, fontID in Fonts:GetAll() do
				local radio = rootDescription:CreateRadio(
					fontID,
					function() return fontID == menu:GetSavedValue() end,
					function() menu:SetSavedValue(fontID) end,
					index
				)

				radio:AddInitializer(function(button)
					local font = Fonts:GetFontObject(fontID)
					if font then
						button.fontString:SetFontObject(font)
						button.fontString:SetText(fontID)
					end
				end);
			end
		end)

		dropdownMenu:SetWidth(ddWidth)

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

	function FontPicker:GetEffectiveSize()
		return self:GetSize()
	end

	--[[ Update Methods ]] --

	function FontPicker:SetSavedValue(value) end

	function FontPicker:GetSavedValue() end
end

Addon.FontPicker = FontPicker
