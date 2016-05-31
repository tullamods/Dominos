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
	if class == 'WARRIOR' then
		BarStates:add{
			type = 'class',
			id = 'battle',
			value = '[form:1]',
			text = function()
				local talentID = select(2, GetTalentRowSelectionInfo(7)) 

				--handle display of gladiator vs battle stance
				if talentID == 21206 then
					return select(2, GetTalentInfoByID(talentID))
				end

				return GetSpellInfo(2457)
			end
		}

		addState('class', 'defensive', '[form:2]', GetSpellInfo(71))
	elseif class == 'DRUID' then
		addState('class', 'moonkin', '[bonusbar:4]', GetSpellInfo(24858))
		addState('class', 'bear', '[bonusbar:3]', GetSpellInfo(5487))
		addState('class', 'tree', function() return format('[form:%d]', GetNumShapeshiftForms() + 1) end, GetSpellInfo(33891))
		addState('class', 'prowl', '[bonusbar:1,stealth]', GetSpellInfo(5215))
		addState('class', 'cat', '[bonusbar:1]', GetSpellInfo(768))
	elseif class == 'PRIEST' then
		addState('class', 'shadow', '[bonusbar:1]', GetSpellInfo(15473))
	elseif class == 'ROGUE' then
		addState('class', 'shadowdance', '[form:2]', GetSpellInfo(185313) .. '/' .. GetSpellInfo(1856))
		addState('class', 'stealth', '[bonusbar:1]', GetSpellInfo(1784))
	elseif class == 'WARLOCK' then
		addState('class', 'meta', '[form:1]', GetSpellInfo(103958))
	elseif class == 'MONK' then
		BarStates:add{
			type = 'class',
			id = 'tiger',
			value = '[bonusbar:1]',
			text = function()
				--handle display of tiger vs crane stance
				if GetSpecialization() == 2 then
					return GetSpellInfo(154436) --Stance of the Spirited Crane
				end

				return GetSpellInfo(103985)
			end
		}

		addState('class', 'ox', '[bonusbar:2]', GetSpellInfo(115069))
		addState('class', 'serpent', '[bonusbar:3]', GetSpellInfo(115070))
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
			Dominos.ActionBar:ForAll('UpdateStateDriver')
		end
	end)
	f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
end
