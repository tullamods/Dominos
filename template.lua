local Goranaws_AuraTemplate = {}
Goranaws_TemplateManager = {}
local Masque = LibStub('Masque', true)

function Goranaws_TemplateManager.Merge(source, destination)
	if not destination then
		destination = {}
	end
	if not source then
		return destination
	end
	for i, b in pairs(source) do
		if (type(b) == 'table') then
			destination[i] = Merge(b, destination[i])
		else
			destination[i] = b
		end
	end
	return destination
end

local allOverlays = {}

function Goranaws_TemplateManager:New(self, kind)
	Goranaws_TemplateManager.Merge(Goranaws_AuraTemplate, self)
	self.kind = kind
	if Masque then
		self.masque = self.masque or Masque:Group("Dominos", kind)
	end
	self.allOverlays = self.allOverlays or {}
	self:CreateHeader()
	self:GetOverlays()
	self:Layout()
	self:UpdateFilter()
	self:UpdateTarget()
	self:UpdateAuras()
end

local temp = Goranaws_AuraTemplate

function temp:NumButtons()
	return self:NumColumns() * self:NumRows()
end

function temp:NumColumns()
	return self.sets.columns
end

function temp:NumRows()
	return self.sets.rows
end

function temp:UpdateAuraLayout(spacing, cols, rows, LR, TB, method, direction)
	local self = self.headerAura
	local base = (30 + spacing)
	self:SetAttribute("minWidth", base);
	self:SetAttribute("minHeight", base);
	self:SetAttribute("wrapAfter", cols);
	self:SetAttribute("maxWraps", rows);
	local hori, vert
	if not LR then
		vert = "Left"
		self:SetAttribute("xOffset", base);
		self:SetAttribute("yOffset", 0);
	else
		vert = "Right"
		self:SetAttribute("xOffset", -base);
		self:SetAttribute("yOffset", 0);
	end
	if not TB then
		hori = "Top"
		self:SetAttribute("wrapXOffset", 0);
		self:SetAttribute("wrapYOffset", -base);
	else
		hori = "Bottom"
		self:SetAttribute("wrapXOffset", 0);
		self:SetAttribute("wrapYOffset", base);
	end
	self:SetAttribute("point", hori..vert);
	local items = {["1"] = "Time", ["2"] = "Index", ["3"] = "Name"}
	local m = items[tostring(method)] or method
	self:SetAttribute("sortMethod", string.upper(m)); -- INDEX or NAME or TIME
	self:SetAttribute("sortDirection", direction); -- - to reverse
end

function temp:CreateHeader()
	self.headerAura = self.headerAura or CreateFrame("Frame", "Goranaws_"..self.kind.."_Bar", self, "SecureAuraHeaderTemplate")
	self.total = self.total or 0
	RegisterUnitWatch(self.headerAura)
	self.headerAura:SetScript("OnShow", function()
		self:UpdateAuras()
	end)
	self:SetScript("OnUpdate", function(s, event, ...)
		self:OnEvent(event, ...)
	end)
	self.headerAura:SetAttribute("template", "GoranawsAuraTemplate"); -- must be the template name of your XML
	local headerAura = self.headerAura
	self.headerAura.UpdateLayout = function()
		if self.sets then
			local sets = self.sets
			local dir = "+"
			if (sets.direction == 1) or (sets.direction == true) then
				dir = "-"
			end
			self:UpdateAuraLayout(sets.spacing, sets.columns, sets.rows, sets.isRightToLeft, sets.isBottomToTop, sets.method, dir)
		else
			self:UpdateAuraLayout(3, "TopLeft", 4, 4, true, true,"Time", "+")
		end
	end
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("UNIT_TARGET");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterUnitEvent("UNIT_AURA", "player", "vehicle");
	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	self.headerAura:UpdateLayout(3, "TopLeft", 4, 4, true, true,"Time", "+")
	self:UpdateAuras()
end

local index = 1
local function GetOverlay(self)
	if _G["Goranaws_OverlayButton_"..index] then
		index = index + 1
		return GetOverlay(self)
	end
	local overlay = CreateFrame("Button", "Goranaws_OverlayButton_"..index , self, "GoranawsOverlayAuraTemplate")
	overlay:EnableMouse(false)
	if self.masque then
		self.masque:AddButton(overlay, {Icon = overlay.icon, Cooldown = overlay.cooldown})
	end
	overlay.index = index
	overlay.cooldown:SetHideCountdownNumbers(true)
	overlay.cooldown:SetAllPoints(overlay.icon)
	overlay.txt:ClearAllPoints()
	tinsert(self.allOverlays, overlay)
	index = index + 1
	return overlay
end

function temp:GetOverlays()
	self.numoverButtons = self.numoverButtons or 0
	local numButtons = self:NumButtons()
	if (numButtons > self.numoverButtons) then
		for i = self.numoverButtons+1, numButtons do
			local overlay = GetOverlay(self)
		end
		self.numoverButtons = self:NumButtons()
	end
end

function temp:ResetOverlay(overlay)
	if overlay and overlay:IsShown() then
		overlay:ClearAllPoints()
		overlay.icon:SetTexture("");
		overlay.cooldown:SetCooldown(0, 0)
		overlay.cooldown:Hide()
		overlay.txt:SetText("");
		overlay:Hide()
		overlay.name, overlay.Icon, overlay.count, overlay.debuffType, overlay.dura, overlay.expirationTime = nil, nil, nil, nil, nil, nil
	end
end

local r, b, g, a = 1,1,1,1
local texture = "Interface\\Addons\\Dominos_Auras\\cooldown"

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
		if hideCooldownText or  _G["OmniCC"] then
			overlay.cooldown:SetHideCountdownNumbers(true)
		else
			overlay.cooldown:SetHideCountdownNumbers(false)
		end

		if counter then
			overlay.cooldown:SetReverse(false)
		else
			overlay.cooldown:SetReverse(true)
		end
		overlay.txt:ClearAllPoints()
		overlay.txt:SetPoint(anchorText, overlay.icon, textX, textY)
	end
end


local duration = 1.5
local function GetAlpha(seconds, low, high)
	return math.floor(low + ((math.abs(((seconds - (duration/2))/1) * 100)*(high - low))/100)) / 100
end
local _time
local pulsing = {}
local isPulsing
local function PulseIcons()
	_time = _time or GetTime()
	if not Pulsing then --don't pulse if function is already being run.
		Pulsing = true
		local seconds = GetTime() - _time		
		if seconds > duration then
			_time,Pulsing  = nil, nil
			return PulseIcons()
		end
		local alpha = GetAlpha(seconds, 30, 100)
		local swipe = GetAlpha(seconds, 20, 50)
		for i, icon in pairs(pulsing) do
			icon:SetAlpha(alpha)
			icon.cooldown:SetSwipeColor(1,1,1,swipe)--swipeAlpha)
			Pulsing = nil
		end
		Pulsing = nil
	end	
end

local function StartPulse(icon)
	pulsing[icon.index] = pulsing[icon.index] or icon
end

local function EndPulse(icon)
	if pulsing[icon.index] then
		pulsing[icon.index] = nil
		icon:SetAlpha(1)
		icon.cooldown:SetSwipeColor(1,1,1,.5)
	end
end


function temp:UpdateAuras()
	self.total = 1
	local t = 1
	for i, overlay in pairs(self.allOverlays) do
		local aura = self.headerAura:GetAttribute("child" .. i)
		if aura and aura:IsShown() then
			overlay:SetAllPoints(aura)
			local name, icon, count, debuffType, dura, expirationTime = UnitAura(self.headerAura:GetAttribute("unit"), aura:GetID(), self.headerAura:GetAttribute("filter"))
			if name then
				if (name ~= overlay.name) or (icon ~= overlay.Icon) or (count ~= overlay.count) or (debuffType ~= overlay.debuffType) or (dura ~= overlay.dura) or (expirationTime ~= overlay.expirationTime) then
					overlay.icon:SetTexture(icon);
					if self.sets.hideCooldownText or  _G["OmniCC"] then
						overlay.cooldown:SetHideCountdownNumbers(true)
					else
						overlay.cooldown:SetHideCountdownNumbers(false)
					end

					
					if (dura or expirationTime) and ((dura>0) or (expirationTime>0)) then
						overlay.cooldown:SetCooldown(expirationTime - dura, dura);
					else
						overlay.cooldown:SetCooldown(0, 0)
						overlay.cooldown:Hide()
					end
					if not (count>1)then count=""end
					overlay.txt:SetText(count);
					overlay:Show()
				end
					
					local t = expirationTime - GetTime()
					
					if (t > 0) and (t < 10) then --pulse
						StartPulse(overlay)
					else
						EndPulse(overlay)
					end
				overlay.name, overlay.Icon, overlay.count, overlay.debuffType, overlay.dura, overlay.expirationTime = name, icon, count, debuffType, dura, expirationTime
			else
				self:ResetOverlay(overlay)
				if not aura then
					break
				end
			end
		else
			self:ResetOverlay(overlay)
			if not aura then
				break
			end
		end
	end
PulseIcons()
end

function temp:UpdateFilter()
	self.headerAura:SetAttribute("filter", self:GetFilter()); -- to activate UNITAURA event refresh
	self:UpdateAuras()
end

function temp:GetTarget()
	return self.sets.target or "player"
end

function temp:UpdateTarget()
	self:RegisterUnitEvent("UNIT_AURA", self:GetTarget());
	self.headerAura:SetAttribute("unit", self:GetTarget())
	self:UpdateAuras()
end

function temp:SetTarget(unit)
	self.sets.target = unit or "player"
	self:UpdateTarget()
end

function temp:GetSpacing()
	return self.sets.spacing
end

function temp:SetSpacing(spacing)
	self.sets.spacing = spacing
	self:Layout()
end

function temp:OnEvent(event, ...)
	self:UpdateAuras()
end


function temp:Layout()
	if not InCombatLockdown() then
		local sets = self.sets
		local w,h = 30, 30
		local newWidth = max((((30 + sets.spacing) * sets.columns) - sets.spacing) +(sets.padding*2), 8)
		local newHeight = max((((30 + sets.spacing) * sets.rows) - sets.spacing) +(sets.padding*2), 8)
		self:SetSize(newWidth, newHeight)
		local hori, vert, padhori, padvert = "Left", "Top", sets.padding, -sets.padding
		if  sets.isRightToLeft then
			hori, padhori = "Right", -sets.padding
		end
		if sets.isBottomToTop then
			vert, padvert = "Bottom", sets.padding
		end
		self.headerAura:ClearAllPoints()
		self.headerAura:SetPoint(vert..hori, self, vert..hori, padhori, padvert)
		local dir = "+"
		if (sets.direction == 1) or (sets.direction == true) then
			dir = "-"
		end
		self:UpdateAuraLayout(sets.spacing, sets.columns, sets.rows, sets.isRightToLeft, sets.isBottomToTop, sets.method, dir)
		self:GetScript("OnUpdate")()
		self:GetOverlays()
		if 	self.HideBlizz then
			self:HideBlizz()
		end
		self:RegisterUnitEvent("UNIT_AURA", self:GetTarget());
		self:ToggleCoolDownTexture()
	end
end

local function NewSlider(panel, name, min, max, arg)
	local slider = panel:NewSlider({
		name = name,
		min = min,
		max = max,
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

local function NewDropdown(panel, name, arg, items)
	local c = panel:NewDropdown{
		name = name,
		get = function()
			return panel.owner.sets[arg]
		end,
		set = function(_, value)
			panel.owner.sets[arg] = value
			panel.owner:Layout()
		end,
		items = items
	}
end

local function addCDPanel(menu)
	local p = menu:NewPanel("Cooldown")
	NewCheckButton(p, "Hide Spiral", "hideCooldown")
	NewCheckButton(p, "Hide Countdown", "hideCooldownText")
	NewCheckButton(p, "Reverse Spin", "counter")
	
	
end

local function AddLayoutPanel(menu)
	local p = menu:NewPanel("Layout")
	NewCheckButton(p, "Flip Vertical", "isRightToLeft")
	NewCheckButton(p, "Flip Horizontal", "isBottomToTop")
	p:NewScaleSlider()
	NewSlider(p, "Padding", -13, 32, "padding")
	NewSlider(p, "Columns", 1, 20, "columns")
	NewSlider(p, "Rows", 1, 20, "rows")
	p:NewSpacingSlider()
	p:NewFadeSlider()
	p:NewOpacitySlider()
end

--viable unit check
local base = {
	"player",
	"target",
	"pet",
	"focus",
	"arena%d+",
	"boss%d+",
	"party%d+",
	"partypet%d+",
	"raid%d+",
	"raidpet%d+",
	"mouseover",
}
local max = {
	raid = 40,
	raidpet = 40,
	arena = 4,
	boss = 4,
	party = 4,
	partypet = 4,
}

local function IsViable(unit)
	local keep = unit
	unit = string.lower(unit)
	local count = 0
	if string.match (unit, "target" , 2) then
		_, count = string.gsub(string.sub (unit, 2, string.len(unit)), "target", "")
		if (unit == "player") and count > 0 then
			return nil
		else
			unit = string.gsub (unit, "target", "", count)
		end
	end
	local can
	for test, match in pairs(base) do
		if string.match(string.gsub(match, "%d+", ""), string.gsub(unit, "%d+", "") ) then
			hasLimit = max[string.gsub( unit, "%d+", "" ) ]
			if hasLimit then
				local o = string.gsub(unit, string.gsub(unit, "%d+", ""),"")
				o = tonumber(o)
				if o and ( (o < 1) or (o>hasLimit) ) then
					return nil
				end
			end
			return string.lower(keep)
		end
	end
end

local hideBlizz

local function HideBlizz(panel)
	if not hideBlizz then
		NewCheckButton(panel, "Disable Default Buffs", "hideBlizz")
		hideBlizz = true
	end
end

local function AddAdvancedOptions(menu)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
	local panel = menu:NewPanel(L.Advanced)
	HideBlizz(panel)
	panel:NewClickThroughCheckbox()
	panel:NewShowInOverrideUICheckbox()
	panel:NewShowInPetBattleUICheckbox()
	panel.TargetingEditBox = panel:NewTextInput{
		name = "Target",
		multiline = true,
		width = 290,
		height = 64,
		get = function() return panel.owner:GetTarget() or '' end,
		set = function(self, value)
			local text = value
			if IsViable(text) then
				panel.owner:SetTarget(text ~= '' and text or nil)
			else
				print("Invalid Unit: "..text)
			end
			panel.TargetingEditBox.editBox:ClearFocus()
		end
	}
	local editBox = panel.TargetingEditBox.editBox
	editBox:SetScript('OnShow',            function(self) self:SetText(self.owner:GetSavedValue() or '') end)
	editBox:SetScript('OnEscapePressed',   function(self) self:ClearFocus() end)
	editBox:SetScript('OnEnterPressed',    function(self) self:Save() self:ClearFocus() end)
	editBox:SetScript('OnTextChanged', nil)
	editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() self.owner:OnEditFocusGained() end)
	editBox:SetScript('OnEditFocusLost',   function(self) self:HighlightText(0, 0) self:Save() end)
end

local function AddSortPanel(self)
	local p = self:NewPanel("Sorting")
	NewCheckButton(p, "Reverse", "direction")
	NewDropdown(p, "Sort Method", "method", {
		{text = "Time", value = '1'},
		{text = "Index", value = '2'},
		{text = "Name", value = '3'},
	})
	return p
end

local function AddStacksPanel(self)
	local p = self:NewPanel("Stacks")
		NewDropdown(p, "Count Anchor", "anchorText", {
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
	NewSlider(p, "Text X", -30, 30, "textX")
	NewSlider(p, "Text Y", -30, 30, "textY")

	
	return p
end

    local L 
	local showStates = {}
	local function addStates(categoryName, stateType)
		L = L or LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
        local states =
            Dominos.BarStates:map(
            function(s)
                return s.type == stateType
            end
        )

        if #states == 0 then
            return
        end
		
        for _, state in ipairs(states) do
            local id = state.id
            local name = state.text
            if type(name) == 'function' then
                name = name()
            elseif not name then
                name = L['State_' .. id:upper()]
            end			
			tinsert(showStates,  {value = id, text = name})
		end
	end

    local function addShowStatePanel(menu)
		L = L or LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
        local panel = menu:NewPanel("Show States")

        addStates( UnitClass('player'), 'class')
        addStates( L.Modifiers, 'modifier')
        addStates( L.Targeting, 'target')
        addStates( "Combat", 'combat')

		panel:NewDropdown {
			name = "State",
			items = showStates,
			get = function()	
				return panel.owner:GetDisplayStateID()
			end,
			set = function(_, value)
				panel.owner:SetDisplayStateID(value)
				panel.showStatesEditBox.editBox:OnShow()
			end
		}

		panel:NewDropdown {
			name = "Display",
			items = {
				{value = "disable", text = _G.DISABLE},
				{value = "Hide", text = _G.HIDE},
				{value = "Show", text = _G.SHOW},
			},
			get = function()				
				return panel.owner:GetDisplayStateValue()
			end,
			set = function(_, value)
				panel.owner:SetDisplayStateValue(value)
				panel.showStatesEditBox.editBox:OnShow()
			end
		}

		panel.showStatesEditBox = panel:NewTextInput{
			name = L.ShowStates,
			multiline = true,
			width = 268,
			height = 64,
			get = function() return panel.owner:GetShowStates() end,
			set = function(_, value) panel.owner:SetShowStates(value) end
		}

        return panel
    end

	
function temp:OnCreateMenu(menu)
	AddLayoutPanel(menu)
	addCDPanel(menu)
	AddStacksPanel(menu)
	AddSortPanel(menu)
	addShowStatePanel(menu)
	AddAdvancedOptions(menu)
	self.menu = menu
end





















-- --------------------------------------------------------------------------------
-- --	
-- --------------------------------------------------------------------------------

-- local AddonName, Addon = ...

-- -- register buttons for use later
-- local BagButtons = {}

-- local Template = Addon:CreateClass('Frame', Addon.ButtonBar)

-- function Template:New()
    -- return Template.proto.New(self, 'bags')
-- end

-- function Template:GetDefaults()
    -- return {
        -- point = 'BOTTOMRIGHT',
        -- oneBag = false,
        -- keyRing = true,
        -- spacing = 2
    -- }
-- end



-- --advanced showstates
-- local showStates = {
	-- Hide = "hide;show",
	-- Show = "show;hide",
-- }

-- function Template:GetDisplayStateID()
	-- if not self.sets.showcondition then return end
	-- for i, b in pairs(Addon.BarStates.coversion) do
		-- if b == self.sets.showcondition[1] then
			-- return i
		-- end
	-- end
-- end

-- function Template:SetDisplayStateID(stateId)
	-- stateId = type(stateId) == "string" and stateId or stateId()

	-- stateId = Addon.BarStates.coversion[stateId] or stateId

	-- self.sets.showcondition = self.sets.showcondition or {}
	
	-- self.sets.showcondition[1] = stateId

	-- if self.sets.showcondition then
		-- local condition
		-- local stateId, displayState = unpack(self.sets.showcondition)
			-- if not displayState then
				-- displayState = "show"
			-- end
			-- if stateId and showStates[displayState] then
				-- condition = stateId..showStates[displayState]
			-- end
		-- self:SetShowStates(condition)
	-- end
-- end

-- function Template:SetDisplayStateValue(state)

	-- self.sets.showcondition = self.sets.showcondition or {}
	
	-- self.sets.showcondition[2] = state

	-- if self.sets.showcondition then
		-- local condition
		-- local state, displayState = unpack(self.sets.showcondition)
			
		-- if not displayState then
			-- displayState = "Show"
		-- end
		-- if state and showStates[displayState] then
			-- condition = state..showStates[displayState]
		-- end		
		-- self:SetShowStates(condition)
	-- end
-- end

-- function Template:GetDisplayStateValue()
	-- return self.sets.showcondition and self.sets.showcondition[2]
-- end

-- -- Frame Overrides
-- function Template:AcquireButton(index)
    -- if index < 1 then
        -- return nil
    -- end

    -- local keyRingIndex = self:ShowKeyRing() and 1 or 0

    -- local backpackIndex
    -- if self:ShowBags() then
        -- backpackIndex = keyRingIndex + NUM_BAG_SLOTS + 1
    -- else
        -- backpackIndex = keyRingIndex + 1
    -- end

    -- if index == keyRingIndex then
        -- return _G[AddonName .. 'KeyRingButton']
    -- elseif index == backpackIndex then
        -- return MainMenuBarBackpackButton
    -- elseif index > keyRingIndex and index < backpackIndex then
        -- return _G[('CharacterBag%dSlot'):format(NUM_BAG_SLOTS - (index - keyRingIndex))]
    -- end
-- end

-- function Template:NumButtons()
    -- local count = 1

    -- if self:ShowKeyRing() then
        -- count = count + 1
    -- end

    -- if self:ShowBags() then
        -- count = count + NUM_BAG_SLOTS
    -- end

    -- return count
-- end

-- local L 
-- local showStates = {}
-- local function addStates(categoryName, stateType)
	-- L = L or LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
	-- local states =
		-- Addon.BarStates:map(
		-- function(s)
			-- return s.type == stateType
		-- end
	-- )

	-- if #states == 0 then
		-- return
	-- end
	
	-- for _, state in ipairs(states) do
		-- local id = state.id
		-- local name = state.text
		-- if type(name) == 'function' then
			-- name = name()
		-- elseif not name then
			-- name = L['State_' .. id:upper()]
		-- end			
		-- tinsert(showStates,  {value = id, text = name})
	-- end
-- end

-- local function addShowStatePanel(menu)
	-- L = L or LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
	-- local panel = menu:NewPanel("Show States")

	-- addStates( UnitClass('player'), 'class')
	-- addStates( L.Modifiers, 'modifier')
	-- addStates( L.Targeting, 'target')
	-- addStates( "Combat", 'combat')

	-- panel:NewDropdown {
		-- name = "State",
		-- items = showStates,
		-- get = function()	
			-- return panel.owner:GetDisplayStateID()
		-- end,
		-- set = function(_, value)
			-- panel.owner:SetDisplayStateID(value)
			-- panel.showStatesEditBox.editBox:OnShow()
		-- end
	-- }

	-- panel:NewDropdown {
		-- name = "Display",
		-- items = {
			-- {value = "disable", text = _G.DISABLE},
			-- {value = "Hide", text = _G.HIDE},
			-- {value = "Show", text = _G.SHOW},
		-- },
		-- get = function()				
			-- return panel.owner:GetDisplayStateValue()
		-- end,
		-- set = function(_, value)
			-- panel.owner:SetDisplayStateValue(value)
			-- panel.showStatesEditBox.editBox:OnShow()
		-- end
	-- }

	-- panel.showStatesEditBox = panel:NewTextInput{
		-- name = L.ShowStates,
		-- multiline = true,
		-- width = 268,
		-- height = 64,
		-- get = function() return panel.owner:GetShowStates() end,
		-- set = function(_, value) panel.owner:SetShowStates(value) end
	-- }

	-- return panel
-- end


-- function Template:OnCreateMenu(menu)
    -- local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    -- local layoutPanel = menu:NewPanel(L.Layout)

    -- layoutPanel:NewCheckButton {
        -- name = L.BagBarShowBags,
        -- get = function()
            -- return layoutPanel.owner:ShowBags()
        -- end,
        -- set = function(_, enable)
            -- return layoutPanel.owner:SetShowBags(enable)
        -- end
    -- }

    -- if Addon:IsBuild('Classic') then
        -- layoutPanel:NewCheckButton {
            -- name = L.BagBarShowKeyRing,
            -- get = function()
                -- return layoutPanel.owner:ShowKeyRing()
            -- end,
            -- set = function(_, enable)
                -- return layoutPanel.owner:SetShowKeyRing(enable)
            -- end
        -- }
    -- end

    -- layoutPanel:AddLayoutOptions()

	-- addShowStatePanel(menu)
    -- menu:AddAdvancedPanel()
    -- menu:AddFadingPanel()
-- end


-- --------------------------------------------------------------------------------
-- --	module
-- --------------------------------------------------------------------------------

-- local Module = Addon:NewModule('Template')

-- function Module:OnInitialize()
    -- for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
        -- self:RegisterButton(('CharacterBag%dSlot'):format(slot))
    -- end

    -- if Addon:IsBuild('Classic') then
        -- -- force hide the old keyring button
        -- KeyRingButton:Hide()

        -- hooksecurefunc(
            -- 'MainMenuBar_UpdateKeyRing',
            -- function()
                -- KeyRingButton:Hide()
            -- end
        -- )

        -- -- setup the dominos specific one
        -- local keyring = CreateFrame('CheckButton', AddonName .. 'KeyRingButton', UIParent, 'ItemButtonTemplate')
        -- keyring:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        -- keyring:SetID(KEYRING_CONTAINER)

        -- keyring:SetScript(
            -- 'OnClick',
            -- function(_, button)
                -- if CursorHasItem() then
                    -- PutKeyInKeyRing()
                -- else
                    -- ToggleBag(KEYRING_CONTAINER)
                -- end
            -- end
        -- )

        -- keyring:SetScript(
            -- 'OnReceiveDrag',
            -- function(_)
                -- if CursorHasItem() then
                    -- PutKeyInKeyRing()
                -- end
            -- end
        -- )

        -- keyring:SetScript(
            -- 'OnEnter',
            -- function(self)
                -- GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

                -- local color = HIGHLIGHT_FONT_COLOR
                -- GameTooltip:SetText(KEYRING, color.r, color.g, color.b)
                -- GameTooltip:AddLine()
            -- end
        -- )

        -- keyring:SetScript(
            -- 'OnLeave',
            -- function()
                -- GameTooltip:Hide()
            -- end
        -- )

        -- keyring.icon:SetTexture([[Interface\Icons\INV_Misc_Bag_16]])

        -- self:RegisterButton(keyring:GetName())

        -- MainMenuBarBackpackButton:HookScript(
            -- 'OnClick',
            -- function(_, button)
                -- if IsControlKeyDown() then
                    -- ToggleBag(KEYRING_CONTAINER)
                -- end
            -- end
        -- )
    -- end

    -- self:RegisterButton('MainMenuBarBackpackButton')
-- end

-- function Module:OnEnable()
    -- for _, button in pairs(BagButtons) do
        -- Addon:GetModule('ButtonThemer'):Register(
            -- button,
            -- 'Bag Bar',
            -- {
                -- Icon = button.icon
            -- }
        -- )
    -- end
-- end

-- function Module:Load()
    -- self.frame = Template:New()
-- end

-- function Module:Unload()
    -- if self.frame then
        -- self.frame:Free()
        -- self.frame = nil
    -- end
-- end

-- local function resize(o, size)
    -- o:SetSize(size, size)
-- end

-- function Module:RegisterButton(name)
    -- local button = _G[name]
    -- if not button then
        -- return
    -- end

    -- button:Hide()

    -- if Addon:IsBuild('Retail') then
        -- resize(button, 36)
        -- resize(button.IconBorder, 37)
        -- resize(button.IconOverlay, 37)
        -- resize(_G[button:GetName() .. 'NormalTexture'], 64)
    -- end

    -- tinsert(BagButtons, button)
-- end
