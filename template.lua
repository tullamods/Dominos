local Dominos_AuraTemplate = {}
Dominos_TemplateManager = {}
local Masque = LibStub('Masque', true)

function Dominos_TemplateManager.Merge(source, destination)
	if not destination then
		destination = {}
	end
	if not source then
		return destination
	end
	for i, b in pairs(source) do
		if (type(b) == 'table') then
			destination[i] = Dominos_TemplateManager.Merge(b, destination[i])
		else
			destination[i] = b
		end
	end
	return destination
end

local allOverlays = {}

function Dominos_TemplateManager:New(self, kind)
	Dominos_TemplateManager.Merge(Dominos_AuraTemplate, self)
	self.kind = kind
	if Masque then
		self.masque = self.masque or Masque:Group("Dominos", kind)
	end
	self.allOverlays = self.allOverlays or {}
	self:CreateHeader()

	CreateFrame("Frame", "Goranaws_"..kind.."_Bar", self, "DominosAuraHeaderTemplate")

	self.headerAura:SetScript("OnEvent", function(s, event, ...)
		self.headerAura:Update(event, ...)
	end)

	self:Layout()
	self:UpdateFilter()
	self:UpdateTarget()
	self.headerAura:Update()
end

local temp = Dominos_AuraTemplate

function temp:NumButtons()
	return self.sets.columns * self.sets.rows
end

function temp:CreateHeader()
	CreateFrame("Frame", "Goranaws_"..self.kind.."_Bar", self, "DominosAuraHeaderTemplate")

	self:SetScript("OnUpdate", function(s, event, ...)
		self.headerAura:Update(event, ...)
	end)
end

function temp:ResetAura(overlay)
	if overlay and overlay:IsShown() then
		overlay.icon:SetTexture("");
		overlay.cooldown:SetCooldown(0, 0)
		overlay.cooldown:Hide()
		overlay.count:SetText("");
		overlay.name, overlay.Icon, overlay.QTY, overlay.debuffType, overlay.dura, overlay.expirationTime = nil, nil, nil, nil, nil, nil
	end
end

local r, b, g, a = 1,1,1,1
local texture = "Interface\\Addons\\Dominos_Auras\\cooldown"

local anchs = {[1] = {"Bottom", "Top"}, [2] = {"Center", "Center"}, [3] = {"Top", "Bottom"}}

function temp:ToggleCoolDownTexture()
	local sets = self.sets
	sets.anchorText = sets.anchorText or "Bottom"
	sets.textX = sets.textX or 0
	sets.textY = sets.textY or 0
	local hideCooldown, hideCooldownText, counter, anchorText, textX, textY = sets.hideCooldown, sets.hideCooldownText, sets.counter, sets.anchorText, sets.textX, sets.textY
	for i, overlay in pairs(self.allOverlays) do
		overlay.cooldown:SetSwipeColor(r, b, g, a ) 
		overlay.cooldown:SetSwipeTexture(texture)
		if hideCooldown then
			overlay.cooldown:SetDrawSwipe(false)
			overlay.cooldown:SetDrawEdge(false)
		else
			overlay.cooldown:SetDrawSwipe(true)
			overlay.cooldown:SetDrawEdge(false)
		end
			overlay.cooldown:SetHideCountdownNumbers(true)


		if counter then
			overlay.cooldown:SetReverse(false)
		else
			overlay.cooldown:SetReverse(true)
		end
		overlay.count:ClearAllPoints()
		overlay.count:SetPoint(anchorText, overlay.icon, textX, textY)
		
		
		overlay.cooldown.text:SetWidth(overlay:GetWidth())
		
		local val = self.sets.cdAnchor
		
		local point, oPoint = unpack(anchs[val] or anchs[2])
		overlay.cooldown.text:ClearAllPoints()
		overlay.cooldown.text:SetPoint(point, overlay, oPoint, self.sets.cdX or 0, self.sets.cdY or 0)
	end
end

function temp:UpdateFilter()
	self.headerAura:SetAttribute("filter", self:GetFilter()); -- to activate UNITAURA event refresh
	self.headerAura:Update()
end

function temp:GetSpacing()
	return self.sets.spacing
end

function temp:SetSpacing(value)
	self.sets.spacing = value
	self:Layout()
end

function temp:UpdateTarget()
	self:RegisterUnitEvent("UNIT_AURA", self:GetTarget());
	self.headerAura:SetAttribute("unit", self:GetTarget())
	self.headerAura:Update()
end

function temp:SetTarget(unit)
	self.sets.target = unit or "player"
	self:UpdateTarget()
end

function temp:GetTarget()
	return self.sets.target or "player"
end

function temp:Layout()
	if not InCombatLockdown() then
		local sets = self.sets
		local w,h = 30, 30
		
		local newWidth = max((((30 + sets.spacing) * sets.columns) - sets.spacing) +(sets.padding*2), 8)
		
		local space = sets.spacing
			
		if not _G["OmniCC"] and sets.cdAnchor ~= 2 then
			space = space + 12
		end
		
		local newHeight = max((((30 + space) * sets.rows) - space) +(sets.padding*2), 8)
		self:SetSize(newWidth, newHeight)
		local hori, vert, padhori, padvert = "Left", "Top", sets.padding, -sets.padding
		if  sets.isRightToLeft then
			hori, padhori = "Right", -sets.padding
		end
		if sets.isBottomToTop then
			vert, padvert = "Bottom", sets.padding
		end
		
		local Y = padvert
		if (not _G["OmniCC"]) and sets.cdAnchor == 1 then
			Y = Y - 12
		end
		
		self.headerAura:ClearAllPoints()
		self.headerAura:SetPoint(vert..hori, self, vert..hori, padhori, Y)
		local dir = "+"
		if (sets.direction == 1) or (sets.direction == true) then
			dir = "-"
		end

		do
			local spacing, cols, rows, LR, TB, method, direction = sets.spacing, sets.columns, sets.rows, sets.isRightToLeft, sets.isBottomToTop, sets.method, dir
			local head = self.headerAura
			local base = (30 + (spacing))
			head:SetAttribute("minWidth", base);
			head:SetAttribute("minHeight", base);
			head:SetAttribute("wrapAfter", cols);
			head:SetAttribute("maxWraps", rows);
			local hori, vert
			
			vert = LR and "Right" or "Left"
			head:SetAttribute("yOffset", 0);

			head:SetAttribute("xOffset", LR and -base or base);
			
			if not _G["OmniCC"] then
				if tonumber(self.sets.cdAnchor) ~= 2 then
					base = base + 12 --if cooldown text is above or below aura, add space for it between rows.
				end
			end
			hori = TB and "Bottom" or "Top"
			head:SetAttribute("wrapXOffset", 0)
			head:SetAttribute("wrapYOffset", TB and base or -base)

			head:SetAttribute("point", hori..vert)
			
			local items = {["1"] = "Time", ["2"] = "Index", ["3"] = "Name"}
			local m = items[tostring(method)] or method
			head:SetAttribute("sortMethod", string.upper(m)); -- INDEX or NAME or TIME
			head:SetAttribute("sortDirection", direction); -- - to reverse("+" or "-")
		end

		self.headerAura:Update()

		if 	self.HideBlizz then
			self:HideBlizz()
		end
		self:RegisterUnitEvent("UNIT_AURA", self:GetTarget());
		self:ToggleCoolDownTexture()
	end
end

local function NewSlider(panel, name, low, high, arg)
	local slider = panel:NewSlider({
		name = name,
		min = low,
		max = high,
		get = function(self) --Getter
			return panel.owner.sets[arg]
		end,
		set = function(self, value) --Setter
			local owner = panel.owner
			owner.sets[arg] = value
			owner:Layout()
			return owner.sets[arg]
		end,
	})
end

local function NewCheckButton(panel, name, arg)
	local c = panel:NewCheckButton{
		name = name,
		get = function() return panel.owner.sets[arg] end,
		set = function(self, enable)
			panel.owner.sets[arg] = self:GetChecked()
			panel.owner:Layout()
		end
	}
end

local function NewDropdown(panel, name, arg, items, func)
	local c = panel:NewDropdown{
		name = name,
		get = function()
			return panel.owner.sets[arg]
		end,
		set = function(_, value)
			panel.owner.sets[arg] = value
			if func then
				func()
			else
				panel.owner:Layout()
			end
		end,
		items = items
	}
end

local hideBlizz

function temp:OnCreateMenu(menu)
	do local panel = menu:NewPanel("Layout")
		NewSlider(panel, "Columns", 1, 20, "columns")
		NewSlider(panel, "Rows", 1, 20, "rows")
		panel:NewSpacingSlider()
		NewSlider(panel, "Padding", -13, 32, "padding")
		panel:NewScaleSlider()
	end

	do local panel = menu:NewPanel("Visibility")
		panel:NewFadeSlider()
		panel:NewOpacitySlider()
		menu:AddDisplayPanel(panel)
	end

	do local panel = menu:NewPanel("Cooldown")
		NewCheckButton(panel, "Hide Spiral", "hideCooldown")
		NewCheckButton(panel, "Hide Countdown", "hideCooldownText")
		NewCheckButton(panel, "Reverse Spin", "counter")
		
		if not _G["OmniCC"] then
			NewDropdown(panel, "Position", "cdAnchor", {
				{text = "Above",  value = 1},
				{text = "Center", value = 2},
				{text = "Below",  value = 3},
			})
		else
			local text = panel:NewHeader("OmniCC detected. |n Use OmniCC settings to adjust cooldown text.") -- |n = new line
			
			local b = CreateFrame("Button", "DomAuras_OmniCCButton", panel, "OptionsListButtonTemplate")
			b:SetText("OmniCC Settings")
			b:SetPoint("TopLeft", text, "BottomLeft", 0 , -10)
			b:SetScript("OnClick", function()
				OmniCC:ShowOptionsFrame()
			end)
		end
	end
	
	do local panel = menu:NewPanel("Stacks")
		NewDropdown(panel, "Count Anchor", "anchorText", {
			{text = "TopLeft", value = 'TopLeft'},
			{text = "Top", value = 'Top'},
			{text = "TopRight", value = 'TopRight'},
			{text = "Right", value = 'Right'},
			{text = "BottomRight", value = 'BottomRight'},
			{text = "Bottom", value = 'Bottom'},
			{text = "BottomLeft", value = 'BottomLeft'},
			{text = "Left", value = 'Left'}
		--	{text = "Center", value = 'Center'},
		})
		NewSlider(panel, "Text X", -30, 30, "textX")
		NewSlider(panel, "Text Y", -30, 30, "textY")
	end
	
	do local panel = menu:NewPanel("Sorting")
		NewCheckButton(panel, "Reverse", "direction")
		NewDropdown(panel, "Sort Method", "method", {
			{text = "Time", value = '1'},
			{text = "Index", value = '2'},
			{text = "Name", value = '3'},
		})
	end
	
	do local panel = menu:NewPanel("Advanced")
		if not hideBlizz then
		 --only add to one of the two frames.
			NewCheckButton(panel, "Disable Default Buffs", "hideBlizz")
			hideBlizz = true
		end

		NewCheckButton(panel, "Flip Vertical", "isRightToLeft")
		NewCheckButton(panel, "Flip Horizontal", "isBottomToTop")
		
		panel:NewClickThroughCheckbox()
		panel:NewShowInOverrideUICheckbox()
		panel:NewShowInPetBattleUICheckbox()
		
		NewDropdown(panel, "Target", "target", {
			{text = "Player",          value = "player"},
			{text = "Target",          value = "target"},
			{text = "Target's Target", value = "targettarget"},
			{text = "Focus",           value = "focus"},
			{text = "Focus' Target",   value = "focustarget"},
			{text = "Pet",             value = "pet"},
			{text = "Pet's Target",    value = "pettarget"},
			{text = "Boss1",           value = "boss1"},
			{text = "Boss2",           value = "boss2"},
			{text = "Boss3",           value = "boss3"},
			{text = "Boss4",           value = "boss4"},
		}, function() panel.owner:UpdateTarget() end)
	end

	self.menu = menu
end
