local DCB = Dominos:NewModule('CastingBar')
local CastBar = Dominos:CreateClass('Frame', Dominos.Frame)
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastingBar')

-- Module Code
function DCB:Load()
	self.frame = CastBar:New()
end

function DCB:Unload()
	self.frame:Free()
end

-- Core Code
function CastBar:New()
	local f = self.super.New(self, 'cast')
	if not self.cast then
		f.header:SetParent(nil)
		f.header:ClearAllPoints()
		f:SetWidth(240) 
		f:SetHeight(24)
	end
	
	f:CheckDefaults()
	f:Time()
	f:Layout()
	f:AdjustCastingBar()
	f:UpdateText()
	f:UpdateTexture()
	f:RegisterEvent("UNIT_SPELLCAST_START")
	f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(_, event) f.event = event end)
	f:HookScript("OnEvent", f.ForceShow)
	return f
end

function CastBar:ForceShow()
	local sets = self.sets.hidden
	local f = CastingBarFrame
	
	if ((sets and (sets == true)) or (not sets))
	and((f:GetScript("OnEvent") ~= CastingBarFrame_OnEvent)
	or (f:GetScript("OnShow") ~= CastingBarFrame_OnShow)
	or (f:GetScript("OnUpdate") ~= CastingBarFrame_OnUpdate))
	and(InCombatLockdown()~=true) then
		f:SetAttribute("unit", "player")
		f:SetScript("OnShow",  CastingBarFrame_OnShow)
		f:SetScript("OnEvent", CastingBarFrame_OnEvent)
		f:SetScript("OnUpdate", CastingBarFrame_OnUpdate)
		f:Show()
		if self.event then
			f:GetScript("OnEvent")(f, self.event)
			self.event = nil
		end
	end
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		height = 8,
		width = 28,
		padding = 0,
		showText = true,
		SetBlizzBorder = 1,
		texture = DEFAULT_STATUSBAR_TEXTURE,
	}
end

function CastBar:CheckDefaults()
	self.sets.texture = self.sets.texture or DEFAULT_STATUSBAR_TEXTURE
	self.sets.width = self.sets.width or 28
	self.sets.height = self.sets.height or 8
	self.sets.padding = self.sets.padding or 0
end

function CastBar:Layout()
	
	local height = ((self.sets.height*10) * (100/256))
	local width = ((self.sets.width * 10) * (206/256))

	self:SetSize(((width + (self.sets.padding )*2) - 14) , ((height + (self.sets.padding)*2) - 8) )

	if self.sets.border then
		self.widthAdjust, self.heightAdjust  = self.sets.width * 10,  self.sets.height *4
		self.time:SetJustifyH("LEFT")
	elseif self.sets.SetBlizzBorder then
		self.widthAdjust, self.heightAdjust  = self.sets.width * 10, self.sets.height * 10
		self.time:SetJustifyH("LEFT")
	else
		self.widthAdjust, self.heightAdjust  = self.sets.width * 9.85, self.sets.height * 9
		self.time:SetJustifyH("RIGHT")
	end

	
	CastingBarFrameBorderShield:SetSize(self.widthAdjust, self.heightAdjust)
	CastingBarFrame:SetSize( (self.sets.width * 10) * (47/64), (self.sets.height * 10) * (11/64))

	self:Configuration()
end

function CastBar:AdjustCastingBar()
	CastingBarFrameBorder:ClearAllPoints()
	CastingBarFrameBorder:SetAllPoints(CastingBarFrameBorderShield)
	
	CastingBarFrameFlash:ClearAllPoints()
	CastingBarFrameFlash:SetAllPoints(CastingBarFrameBorderShield)
	
	CastingBarFrameText:ClearAllPoints()
	CastingBarFrameText:SetAllPoints(CastingBarFrameBorderShield)
	
	CastingBarFrameBorderShield:ClearAllPoints()
	CastingBarFrameBorderShield:SetPoint("CENTER", self)


	CastingBarFrame:ClearAllPoints()
  	CastingBarFrame:SetParent(self)
	CastingBarFrame:SetPoint("CENTER", CastingBarFrameBorderShield)
end

function CastBar:Time()
	if not self.time then
		local time = CastingBarFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
		time:SetTextColor(1.0,1.0,1.0)
		time:SetPoint("RIGHT", CastingBarFrame, 0, 0)
		time:SetSize(30, 30)
		time:SetJustifyH("LEFT")
		self.time = time
	end



--[[ this script forces the cast bar to stay where we want it, And controls the time text.]]--
	self:SetScript("OnUpdate", function( self, elapsed)
		CastingBarFrame:ClearAllPoints()
  		CastingBarFrame:SetParent(self)
		CastingBarFrame:SetPoint("CENTER", CastingBarFrameBorderShield)
		if self.sets.showText then
			self.stop = select(6, UnitCastingInfo("player")) or select(6, UnitChannelInfo("player"))
			if self.stop then
				self.time:SetFormattedText("%.1f", (self.stop / 1000) - GetTime())
			else
				self.time:SetText("")
			end
		else
			self.time:SetText("")
		end
		if Dominos.locked == false then
			self.border:Show()
		else
			self.border:Hide()
		end
	end)
end

local function CreateWidthSlider(p)
	local s = p:NewSlider(L.Width, 10, 100, 1)
	s.OnShow = function(self)
		self:SetValue(ceil(self:GetParent().owner.sets.width))
	end
	s.UpdateValue = function(self, value)
		local f = self:GetParent().owner
		f.sets.width = value
		f:Layout()
	end
end

local function CreateHeightSlider(p)
	local s = p:NewSlider(L.Height, 5, 45, 1, OnShow)
	s.OnShow = function(self)
		self:SetValue(self:GetParent().owner.sets.height)
	end
	s.UpdateValue = function(self, value)
		local f = self:GetParent().owner
		f.sets.height = value
		f:Layout()
	end
end

local function CreatePaddingSlider(p)
	local s = p:NewSlider(L.Padding, -3, 32, 1, OnShow)
	s.OnShow = function(self)
		self:SetValue(self:GetParent().owner.sets.padding)
	end
	s.UpdateValue = function(self, value)
		local f = self:GetParent().owner
		f.sets.padding = value
		f:Layout()
	end
end

function CastBar:Configuration()
	if not self.border then
		--This texture allows the user to modify 
		--the cast bar and see what it will look 
		--like without having to cast a spell
		local border = self:CreateTexture(nil, 'BACKGROUND')
		border:SetAllPoints(CastingBarFrameBorder)
		border:SetTexture(CastingBarFrameBorder:GetTexture())
		border:SetBlendMode("BLEND")
		border:Hide()
		self.border = border
	end

	local FACTION = UnitFactionGroup("player")
	local texture
	local flash
	
	if self.sets.border then
		texture = "Interface\\UnitPowerBarAlt\\".. FACTION .."_Horizontal_Frame"
		flash = texture
	
	elseif self.sets.SetBlizzBorder then
		texture = "Interface\\CastingBar\\UI-CastingBar-Border"
		flash = "Interface\\CastingBar\\UI-CastingBar-Flash"
	else
		texture = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
		flash = "Interface\\CastingBar\\UI-CastingBar-Flash-Small"

	end

	CastingBarFrameBorder:SetTexture(texture)
	CastingBarFrameFlash:SetTexture(flash)
	self.border:SetTexture(CastingBarFrameBorder:GetTexture())

	if self.sets.border then
		CastingBarFrameFlash:SetVertexColor(0, 0, 1)
		CastingBarFrameFlash:SetDesaturated(1)
		CastingBarFrameFlash:SetBlendMode("BLEND")
	else
		CastingBarFrameFlash:SetVertexColor(1, 1, 1)
		CastingBarFrameFlash:SetDesaturated(nil)
		CastingBarFrameFlash:SetBlendMode("ADD")
	end
end

function CastBar:ToggleSetBlizzBorder(enable)
	self.sets.SetBlizzBorder = enable or nil
	self.sets.border = nil
	self:Layout()
end

function CastBar:ToggleBorder(enable)
	self.sets.border = enable or nil
	self.sets.SetBlizzBorder = nil
	self:Layout()
end

function CastBar:ToggleText(enable)
	self.sets.showText = enable or nil
	self:UpdateText()
end

function CastBar:UpdateText()
	if self.sets.showText then
		self.time:Show()
	else
		self.time:Hide()
	end
end
--[[ Menu Code ]]--

local function AddLayoutPanel(menu)
	local p = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	p:NewOpacitySlider()
	p:NewFadeSlider()
	CreateWidthSlider(p)
	CreateHeightSlider(p)
	p:NewScaleSlider()
	CreatePaddingSlider(p)

	
	local time = p:NewCheckButton(L.ShowTime)
	time:SetScript('OnClick', function(self) self:GetParent().owner:ToggleText(self:GetChecked()) end)
	time:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.showText) end)

	local faction = p:NewCheckButton("Faction Border") --Needs Translation
	local thin = p:NewCheckButton("Blizzard Border") --Needs Translation

	faction:SetScript('OnClick', function(self)
		thin:SetChecked(nil)
		self:GetParent().owner:ToggleBorder(self:GetChecked())
	end)
	faction:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.border) end)

	thin:SetScript('OnClick', function(self)
		faction:SetChecked(nil)
 		self:GetParent().owner:ToggleSetBlizzBorder(self:GetChecked())
 	end)
	thin:SetScript('OnShow', function(self) self:SetChecked(self:GetParent().owner.sets.SetBlizzBorder)  end)
end

local function AddAdvancedLayout(self)
	self:AddAdvancedPanel()
end

--[[
	Texture Picker 
	Derived from the code in Dominos XP, and modified
	slightly to work under any Dominos based addon.
	Aslo corrected the uncapitalized constants.
--]]

function CastBar:UpdateTexture()
	local LSM = LibStub('LibSharedMedia-3.0', true)

	local texture = (LSM and LSM:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
	CastingBarFrame:SetStatusBarTexture(texture)
	
	if CastingBarFrame:GetStatusBarTexture().SetHorizTile then
		CastingBarFrame:GetStatusBarTexture():SetHorizTile(false)
	end
end

function CastBar:SetTexture(texture)
	self.sets.texture = texture
	self:UpdateTexture()
end

local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 155, 20, 0

local function TextureButton_OnClick(self)
	self:GetParent().owner:SetTexture(self:GetText())
	self:GetParent():UpdateList()
end

local function TextureButton_OnMouseWheel(self, direction)
	local scrollBar = _G[self:GetParent().scroll:GetName() .. 'ScrollBar']
	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	parent:UpdateList()
end

local function TextureButton_Create(name, parent)
	local button = CreateFrame('Button', name, parent)
	button:SetWidth(WIDTH)
	button:SetHeight(HEIGHT)

	button.bg = button:CreateTexture()
	button.bg:SetAllPoints(button)

	local r, g, b = max(random(), 0.2), max(random(), 0.2), max(random(), 0.2)
	button.bg:SetVertexColor(r, g, b)
	button:EnableMouseWheel(true)
	button:SetScript('OnClick', TextureButton_OnClick)
	button:SetScript('OnMouseWheel', TextureButton_OnMouseWheel)
	button:SetNormalFontObject('GameFontNormalLeft')
	button:SetHighlightFontObject('GameFontHighlightLeft')
	return button
end

local function Panel_UpdateList(self)
	local SML = LibStub('LibSharedMedia-3.0')
	local textures = SML:List('statusbar')
	local currentTexture = self.owner.sets.texture

	local scroll = self.scroll
	FauxScrollFrame_Update(scroll, #textures, #self.buttons, HEIGHT + OFFSET)

	for i,button in pairs(self.buttons) do
		local index = i + scroll.offset

		if index <= #textures then
			button:SetText(textures[index])
			button.bg:SetTexture(SML:Fetch('statusbar', textures[index]))
			button:Show()
		else
			button:Hide()
		end
	end
end

local function AddTexturePanel(menu)
	local p = menu:NewPanel(L.Texture)
	p.UpdateList = Panel_UpdateList
	p:SetScript('OnShow', function() p:UpdateList() end)
	p.textures = LibStub('LibSharedMedia-3.0'):List('statusbar')

	local name = p:GetName()
	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', p, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function(self, arg1) FauxScrollFrame_OnVerticalScroll(self, arg1, HEIGHT + OFFSET, function() p:UpdateList() end) end)
	scroll:SetScript('OnShow', function() p.buttons[1]:SetWidth(WIDTH) end)
	scroll:SetScript('OnHide', function() p.buttons[1]:SetWidth(WIDTH + 20) end)
	scroll:SetPoint('TOPLEFT', 8, 0)
	scroll:SetPoint('BOTTOMRIGHT', -24, 2)
	p.scroll = scroll

	--add list buttons
	p.buttons = {}
	for i = 1, NUM_ITEMS do
		local b = TextureButton_Create(name .. i, p)
		if i == 1 then
			b:SetPoint('TOPLEFT', 4, 0)
		else
			b:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -OFFSET)
			b:SetPoint('TOPRIGHT', name .. i-1, 'BOTTOMRIGHT', 0, -OFFSET)
		end
		p.buttons[i] = b
	end

	p.height = 5 + (NUM_ITEMS * HEIGHT)
end

function CastBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)
	AddLayoutPanel(menu)
	AddTexturePanel(menu)
	self.menu = menu
end