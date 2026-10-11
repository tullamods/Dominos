local _, Addon = ...

function Addon:CreateButton(options)
	local button = CreateFrame('Button', nil, options.parent, 'UIPanelButtonTemplate')

	if options.name then
		button:SetText(options.name)
	end

	if options.width then
		button:SetWidth(options.width)
	end

	if options.height then
		button:SetHeight(options.height)
	end

	if options.click then
		button:SetScript('OnClick', options.click)
	end

	return button
end