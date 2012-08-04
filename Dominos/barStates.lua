--[[
	barStates.lua
		A thingy for mapping stateIds to macro states
--]]

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
Dominos.BarStates = BarStates


local getFormIndex = function(spellName)
	for i = 1, GetNumShapeshiftForms() do
		local _, name = GetShapeshiftFormInfo(i)
		if name == spellName then
			return i
		end
	end
	return nil
end

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

--possession
addState('possess', 'possess', '[possessbar]')

--paging
for i = 2, 6 do
	addState('page', 'page' .. i, string.format('[bar:%d]', i), _G['BINDING_NAME_ACTIONPAGE' .. i])
end

--class
do
	local class = select(2, UnitClass('player'))
	if class == 'WARRIOR' then		
		addState('class', 'battle', '[bonusbar:1]', GetSpellInfo(2457))
		addState('class', 'defensive', '[bonusbar:2]', GetSpellInfo(71))
		addState('class', 'berserker', '[bonusbar:3]', GetSpellInfo(2458))
	elseif class == 'DRUID' then
		addState('class', 'moonkin', '[bonusbar:4]', GetSpellInfo(24858))
		addState('class', 'bear', '[bonusbar:3]', GetSpellInfo(5487))
		addState('class', 'tree', function()
			local index = getFormIndex(GetSpellInfo(33891))
			if index then
				return ('[form:%d]'):format(index)
			end
			return nil
		end, GetSpellInfo(33891))
		addState('class', 'prowl', '[bonusbar:1,stealth]', GetSpellInfo(5215))
		addState('class', 'cat', '[bonusbar:1]', GetSpellInfo(768))
	elseif class == 'PRIEST' then
		addState('class', 'shadow', '[bonusbar:1]', GetSpellInfo(15473))
	elseif class == 'ROGUE' then
		addState('class', 'vanish', '[bonusbar:1,form:3]', GetSpellInfo(1856))
		addState('class', 'shadowdance', '[bonusbar:2]', GetSpellInfo(51713))
		addState('class', 'stealth', '[bonusbar:1]', GetSpellInfo(1784))
	elseif class == 'WARLOCK' then
		addState('class', 'meta', '[form:2]', GetSpellInfo(47241))
	elseif class == 'MONK' then
		addState('class', 'tiger', '[bonusbar:1]', GetSpellInfo(103985))
		addState('class', 'ox', '[bonusbar:2]', GetSpellInfo(115069))
		addState('class', 'serpent', '[bonusbar:3]', GetSpellInfo(115070))		
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
			Dominos.ActionBar:ForAll('UpdateStateDriver')
		end
	end)
	f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
end