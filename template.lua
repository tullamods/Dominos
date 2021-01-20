local addonName, Addon = ...
local template = {}

local function AddMixin(source, destination)
	destination = destination or {}

	if not source then
		return destination
	end

	for i, b in pairs(source) do
		destination[i] = (type(b) == 'table') and AddMixin(b, destination[i]) or b
	end
	return destination
end

function Addon:New(self, kind)
	AddMixin(template, self)
	self.kind = kind

	self.headerAura = CreateFrame("Frame", Addon.parent.."_"..self.kind.."_Bar", self, "SecureAuraHeaderTemplate")
	self.headerAura:SetAttribute("template", Addon.parent.."AuraTemplate") --template must be defined in xml
	RegisterUnitWatch(self.headerAura) --seems to be required

	self:SetScript("OnUpdate", function(s, event, ...)
		local _time = GetTime()
		for i = 1, self:NumButtons() do
			local aura = self.headerAura:GetAttribute("child" .. i)
			if aura and aura:IsVisible() then
				aura:OnUpdate(_time)
			end
		end
		Addon.PulseIcons()
	end)
	
	self:Layout()
	self:UpdateFilter()
	self:UpdateTarget()
end

function template:NumButtons()
	return self.sets.columns * self.sets.rows
end

local r, b, g, a = 1,1,1,1 --might make user setting to adjust
local texture    = "Interface\\Cooldown\\starburst" --might make user setting to adjust

local anchors    = {[1] = {"Bottom", "Top"}, [2] = {"Center", "Center"}, [3] = {"Top", "Bottom"}}

function template:ToggleCoolDownTexture()
	self.sets.anchorText = self.sets.anchorText or "Bottom"
	self.sets.textX      = self.sets.textX or 0
	self.sets.textY      = self.sets.textY or 0
				
	Addon["onAuraLoad"..self:GetFilter()] = function(aura) --Store function, for use in aura buttons OnLoad function.
		if aura then
			aura.cooldown:SetDrawEdge(true)
			aura.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
			aura.cooldown:SetSwipeTexture(texture)
			--aura.cooldown:SetSwipeColor(r, b, g, a )
			aura.cooldown:SetSwipeColor(1, 0, 0)
			aura.cooldown:SetHideCountdownNumbers(true)--I've replaced the text that this function is hiding
			
			aura.cooldown:SetReverse(not self.sets.counter)
			aura.cooldown:SetDrawSwipe(not self.sets.hideSpiral)

			if self.sets.hideCooldownText then
				aura.cooldown.text:Hide()
			else
				aura.cooldown.text:Show()
			end
			aura.cooldown.text:SetWordWrap(false)
			aura.cooldown.text:SetWidth(aura:GetWidth())
			
			local point, oPoint = unpack(anchors[self.sets.cdAnchor] or anchors[2])
			aura.cooldown.text:ClearAllPoints()
			aura.cooldown.text:SetPoint(point, aura, oPoint)
			
			aura.count:ClearAllPoints()
			aura.count:SetPoint(self.sets.anchorText, aura.icon, self.sets.textX, self.sets.textY)
		end
	end	
	for i = 1, self:NumButtons() do	
		Addon["onAuraLoad"..self:GetFilter()](self.headerAura:GetAttribute("child" .. i))
	end
end

function template:UpdateFilter()
	self.headerAura:SetAttribute("filter", self:GetFilter()); -- to activate UNITAURA event refresh
end

function template:GetSpacing()
	return self.sets.spacing
end

function template:SetSpacing(value)
	self.sets.spacing = value
	self:Layout()
end

function template:UpdateTarget()
	self:RegisterUnitEvent("UNIT_AURA", self:GetTarget());
	self.headerAura:SetAttribute("unit", self:GetTarget())
end

function template:SetTarget(unit)
	self.sets.target = unit or "player"
	self:UpdateTarget()
end

function template:GetTarget()
	return self.sets.target or "player"
end

function template:Layout()
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

local hideBlizz --only add this option panel to buffs.

function template:OnCreateMenu(menu)
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
		--local _ = menu.AddDisplayPanel and menu:AddDisplayPanel(panel)
	end

	do local panel = menu:NewPanel("Cooldown")
		NewCheckButton(panel, "Hide Spiral", "hideSpiral")
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
