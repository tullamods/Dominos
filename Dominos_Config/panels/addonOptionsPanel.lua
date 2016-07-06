local AddonName, Addon = ...

local AddonOptionsPanel = CreateFrame('Frame', 'DominosAddonOptions')
do
	local nextName = Addon:CreateNameGenerator('AddonOptionsPanel')

	do
		AddonOptionsPanel.panels = {}
		AddonOptionsPanel.name = 'Dominos'
		AddonOptionsPanel:Hide()

		AddonOptionsPanel:SetScript('OnShow', function(self)
			InterfaceOptionsFrame_OpenToCategory(self.panels[1])
		end)

		InterfaceOptions_AddCategory(AddonOptionsPanel)
	end

	function AddonOptionsPanel:New(settings)
		local f = CreateFrame('Frame', nextName())
		f:Hide()
		
		f.name = settings.name
		f.parent = settings.parent or self
		f.Add = self.Add


		local titleText = f:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		titleText:SetPoint('TOPLEFT', 16, -16)
		if icon then
			titleText:SetFormattedText('|T%s:%d|t %s', settings.icon, 32, settings.name)
		else
			titleText:SetText(settings.name)
		end

		if settings.description then
			local descriptionText = f:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
			descriptionText:SetHeight(32)
			descriptionText:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -8)
			descriptionText:SetPoint('RIGHT', f, -32, 0)
			descriptionText:SetNonSpaceWrap(true)
			descriptionText:SetJustifyH('LEFT')
			descriptionText:SetJustifyV('TOP')
			descriptionText:SetText(settings.description)
		end

		InterfaceOptions_AddCategory(f)

		table.insert(self.panels, f)
		return f
	end

	function AddonOptionsPanel:Add(type, options)
		local options = options or {}

		options.parent = self

		return Addon[type]:New(options)
	end
end

Addon.AddonOptionsPanel = AddonOptionsPanel

function Addon:ShowAddonPanel()
	InterfaceOptionsFrame_Show()
	InterfaceOptionsFrame_OpenToCategory(AddonOptionsPanel)
end