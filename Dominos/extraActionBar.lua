if not _G['ExtraActionBarFrame'] then
	return
end

--[[ Globals ]]--

local _G = _G
local Dominos = _G['Dominos']
local KeyBound = LibStub('LibKeyBound-1.0')


--[[ buttons ]]--

local ExtraActionButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)

do
	local unused = {}

	function ExtraActionButton:New(id)
		local button = self:Restore(id) or self:Create(id)

		Dominos.BindingsController:Register(button)
		button:UpdateHotkey()

		return button
	end

	function ExtraActionButton:Create(id)
		local b = self:Bind(_G['ExtraActionButton' .. id])

		if b then
			b.buttonType = 'EXTRAACTIONBUTTON'
			b:SetScript('OnEnter', self.OnEnter)
			b:Skin()

			return b
		end
	end

	--if we have button facade support, then skin the button that way
	--otherwise, apply the dominos style to the button to make it pretty
	function ExtraActionButton:Skin()
		if not Dominos:Masque('Extra Bar', self) then
			_G[self:GetName() .. 'Icon']:SetTexCoord(0.06, 0.94, 0.06, 0.94)
			self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
		end
	end

	function ExtraActionButton:Restore(id)
		local b = unused and unused[id]

		if b then
			unused[id] = nil
			b:Show()

			return b
		end
	end

	--saving them thar memories
	function ExtraActionButton:Free()
		unused[self:GetID()] = self

		self:SetParent(nil)
		self:Hide()

		Dominos.BindingsController:Unregister(self)
	end

	--keybound support
	function ExtraActionButton:OnEnter()
		if Dominos:ShouldShowTooltips() then
			ActionButton_SetTooltip(self)
			ActionBarButtonEventsFrame.tooltipOwner = self
			ActionBarActionEventsFrame.tooltipOwner = self
			ActionButton_UpdateFlyout(self)
		end

		KeyBound:Set(self)
	end
end


--[[ bar ]]--

local ExtraBar = Dominos:CreateClass('Frame', Dominos.Frame)

function ExtraBar:New()
	local f = Dominos.Frame.New(self, 'extra')
	
	f:LoadButtons()
	f:Layout()

	return f
end

function ExtraBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function ExtraBar:GetShowStates()
	return '[extrabar]show;hide'
end

function ExtraBar:NumButtons()
	return 1
end

function ExtraBar:AddButton(i)
	local b = ExtraActionButton:New(i)

	if b then
		b:SetAttribute('showgrid', 1)
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function ExtraBar:RemoveButton(i)
	local b = self.buttons[i]

	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end


--[[ module ]]--

local ExtraBarController = Dominos:NewModule('ExtraBar')

function ExtraBarController:OnInitialize()
	_G['ExtraActionBarFrame'].ignoreFramePositionManager = true
end

function ExtraBarController:Load()
	self.frame = ExtraBar:New()
end

function ExtraBarController:Unload()
	self.frame:Free()
end