--[[
	barStates.lua
		A thingy for mapping stateIds to macro states
--]]

local AddonName, Addon = ...
local states = {}

local getStateIterator = function(type, i)
	for j = i + 1, #states do
		local state = states[j]
		if state and ((not type) or state.type == type) then
			return j, state
		end
	end
end

local BarStates = {
	add = function(self, state, index)
		if index then
			return table.insert(states, index, state)
		end
		return table.insert(states, state)
	end,

	getAll = function(self, type)
		return getStateIterator, type, 0
	end,

	get = function(self, id)
		for i, v in pairs(states) do
			if v.id == id then
				return v
			end
		end
	end,

	map = function(self, f)
		local results = {}
		for k, v in ipairs(states) do
			if f(v) then
				table.insert(results, v)
			end
		end
		return results
	end,
}
Addon.BarStates = BarStates

local addState = function(stateType, stateId, stateValue, stateText)
	return BarStates:add{
		type = stateType,
		id = stateId,
		value = stateValue,
		text = stateText
	}
end

--keybindings
addState('modifier', 'selfcast', '[mod:SELFCAST]', AUTO_SELF_CAST_KEY_TEXT)
addState('modifier', 'ctrlAltShift', '[mod:alt,mod:ctrl,mod:shift]')
addState('modifier', 'ctrlAlt', '[mod:alt,mod:ctrl]')
addState('modifier', 'altShift', '[mod:alt,mod:shift]')
addState('modifier', 'ctrlShift', '[mod:ctrl,mod:shift]')
addState('modifier', 'alt', '[mod:alt]', ALT_KEY)
addState('modifier', 'ctrl', '[mod:ctrl]', CTRL_KEY)
addState('modifier', 'shift', '[mod:shift]', SHIFT_KEY)

--paging
for i = 2, 6 do
	addState('page', 'page' .. i, string.format('[bar:%d]', i), _G['BINDING_NAME_ACTIONPAGE' .. i])
end

--class
do
	local class = select(2, UnitClass('player'))

	if class == 'DRUID' then
		addState('class', 'moonkin', '[bonusbar:4]', GetSpellInfo(24858))
		addState('class', 'bear', '[bonusbar:3]', GetSpellInfo(5487))
		addState('class', 'tree', function() return format('[form:%d]', GetNumShapeshiftForms() + 1) end, GetSpellInfo(33891))
		addState('class', 'prowl', '[bonusbar:1,stealth]', GetSpellInfo(5215))
		addState('class', 'cat', '[bonusbar:1]', GetSpellInfo(768))
	elseif class == 'ROGUE' then
		addState('class', 'shadowdance', '[form:2]', GetSpellInfo(185313))
		addState('class', 'stealth', '[bonusbar:1]', GetSpellInfo(1784))
	end

	local race = select(2, UnitRace('player'))
	if race == 'NightElf' then
		addState('class', 'shadowmeld', '[stealth]', GetSpellInfo(58984))
	end
end

--target reaction
addState('target', 'help', '[help]')
addState('target', 'harm', '[harm]')
addState('target', 'notarget', '[noexists]')


--automatic updating for UPDATE_SHAPESHIFT_FORMS
do
	local f = CreateFrame('Frame'); f:Hide()
	f:SetScript('OnEvent', function()
		if not InCombatLockdown() then
			Addon.ActionBar:ForAll('UpdateStateDriver')
		end
	end)
	f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
end









--sloppy testing. 






local Unitconditionals = { --these really only work if using @"unit"
	"combat",
	"nocombat",
	"dead",
	"nodead",
	"exists",
	"noexists",
	"harm",
	"noharm",
	"help",
	"nohelp",
	"party",
	"noparty",
	"raid",
	"noraid",
	"unithasvehicleui",
	"nounithasvehiclui",
}


local macroStates = {
	["@"] = {
		"player",
		"target",
		"targettarget",
		"pet",
		"pettarget",
		"focus",
		"focustarget",
		"mouseover",
		"mousetarget",
		["raid"] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30}, --who really needs this?
		"boss1",
		"boss2",
		"boss3",
		"boss4",
	},
	modifier = {
		"shift",
		"shiftctrl",
		"shiftalt",
		"shiftctrlalt",
		"ctrl",
		"ctrlalt",
		"alt",
		"any",
	},
	actionbar = {
		1,
		2,
		3,
		4,
		5,
		6,
	},
	"overridebar",
	"vehicleui",
	"extrabar",
	"possesbar",
	"shapeshift",

	form = {0,1,2,3,4, "any"},
	noform = {0,1,2,3,4, "any"},
	stance = {0,1,2,3,4, "any"},
	nostance = {0,1,2,3,4, "any"},
	group = {"party","raid"},
	
-- only make available if first arg is @unit	
	"combat",
	"nocombat",
	"dead",
	"nodead",
	"exists",
	"noexists",
	"harm",
	"noharm",
	"help",
	"nohelp",
	"party",
	"noparty",
	"raid",
	"noraid",
	"unithasvehicleui",
	"nounithasvehiclui",
--	
	
	"cursor",
	"flyable",
	"flying",
	"indoors",
	"outdoors",
	"mounted",
	"nomounted",
	"petbattle",
	"nopetbattle",
	"resting",
	"noresting",
	"stealth",
	"nostealth",
	"swimming",
	"noswimming",
}

local editBox = CreateFrame("EditBox", "MacroEditor", UIParent, "InputBoxTemplate")
editBox:SetPoint("Center", 0,0)
editBox:SetSize(200, 50)
editBox:SetAutoFocus(false)


local function SetText(info)
	local a,b,c,d,e
	if type(info) == "table" then
		a,b,c,d,e = unpack(info)
	else
		a = info
	end

	if b == "any" then
		b = nil
	end
	if a == "@" then
		if c then
			return a ..b.. c
		else
			return a..b
		end
	elseif a == "actionbar" then
		if b then
			return a..":"..b
		else
			return a
		end
	elseif a == "modifier" then
		if b then
			return a..":"..b
		else
			return a
		end
	elseif a == "form" or  a == "stance" or  a == "noform" or  a == "nostance" then
		if b then
			return a..":"..b
		else
			return a
		end
	elseif a == "group" then
		if b then
			return a..":"..b
		else
			return a
		end
	else
		return a
	end
end

editBox.Button = CreateFrame("Button", editBox:GetName().."Button", editBox, "UIMenuButtonStretchTemplate")
editBox.Button:SetPoint("Left", editBox, "Right")
editBox.Button:SetSize(25, 25)
editBox.Button:SetText("+")

local function UpdateText(editBox, text)
	local edit = editBox:GetText()
	
	if edit and edit~="" then
		text = edit..","..text
	end
	
	editBox:SetText(text)

	L_CloseDropDownMenus()
end

function editBox:initialize(level, information, x,y,z)
	local info = L_UIDropDownMenu_CreateInfo()
	local _table
	local title
	
	
	if information then
		_table = information.info
	else
		_table = macroStates --for top level
	end
	
	for index, value in pairs(_table) do
		wipe(info)
		
		if level == 1 then
			local title
			if type(value) == "table" then
				local passOn = {}
				title = index
				passOn.info = value
				passOn.args = {index}
				info.hasArrow = true
				info.menuList = passOn
			else
				title = value
				function info.func()
					UpdateText(editBox, SetText(value))
				end
			end

			info.text = title
			info.arg1 = title
			info.notcheckable = true
			L_UIDropDownMenu_AddButton(info)
		else
			local title
			if type(value) == "table" then
				local passOn = {}
				title = index
				passOn.info = value
				passOn.args = CopyTable(information.args) or {}
				tinsert(passOn.args, index)
				
				info.menuList = passOn
				info.hasArrow = true
			else
				title = value
				function info.func()
					tinsert(information.args, value)
					UpdateText(editBox, SetText(information.args))
				end
			end
			info.text = title
			info.arg1 = title
			L_UIDropDownMenu_AddButton(info,level)
		end
	end
end

editBox:SetScript("OnMouseDown", function(self)
	--Display dropdown with state options
	editBox.relativeTo = editBox
	L_UIDropDownMenu_SetAnchor(editBox, 0, 0, "TopLeft", editBox, "BottomLeft")
	L_ToggleDropDownMenu(1, nil, editBox)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end)

editBox:SetScript("OnEditFocusLost", function(self) 
	L_CloseDropDownMenus()
end)

editBox:SetScript("OnEnterPressed", function(self)
	self:ClearFocus()
	L_CloseDropDownMenus()
end)
editBox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus()
end)

editBox.Button:SetScript("OnClick", function()

	local text = editBox:GetText()
	addState('target', text,	'['.. text ..']',			text)

	DominosDB.customStates = DominosDB.cutomStates or {}
	DominosDB.customStates[text] = '['.. text ..']'
	
	
	editBox:ClearFocus()
end)

hooksecurefunc(Dominos, "OnInitialize",function()
	DominosDB.customStates = DominosDB.customStates or {}
	for text, state in pairs(DominosDB.customStates) do
		addState('target', text,	state,			text)
	end
end)


--current design allows for custom typed macros, and provides quick suggestions.

--todos:
	--simplify
	--add ability to delete unwanted states
	--integrate properly
	--prevent states from having duplicate conditionals
	--**save states in a table, for cleaner reconstruction and manipulation/deletion**
		--Example {@target, harm, combat} --gets constructed using a pairs() setup
		-- this might allow me to remove possible conditionals in the dropdown if they don't work for the "@unit"
		--could also help prevent duplicates
	--rewrite the "macroStates" table, to work with previous todo.
