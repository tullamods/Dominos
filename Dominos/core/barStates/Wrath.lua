-- wotlk specific states
local _, Addon = ...

Addon.BarStates:LoadClass{
    DEATHKNIGHT = {
        { 'blood', form = 48266 },
        { 'frost', form = 48263 },
        { 'unholy', form = 48265 },
    },
    DRUID = {
        { 'bear', macro = '[bonusbar:3]', label = 5487 },
        { 'prowl', macro = '[bonusbar:1,stealth]', label = 5215 },
        { 'cat', macro = '[bonusbar:1]', label = 768 },
        { 'moonkin', form = 24858 },
        { 'tree', form = 33891 },
        { 'travel', form = 783 },
        { 'aquatic', form = 1066 },
        { 'flight', form = {33943, 40120} },
    },
    HUNTER = {
        { 'hawk', form = 13165 },
        { 'dragonhawk', form = 61846 },
        { 'viper', form = 34074 },
        { 'monkey', form = 13163 },
        { 'cheetah', form = 5118 },
        { 'pack', form = 13159 },
        { 'wild', form = 20043 },
    },
    PALADIN = {
        { 'concentration', form = 19746 },
        { 'crusader', form = 32223 },
        { 'devotion', form = 27149 },
        { 'fire', form = 27153 },
        { 'frost', form = 27152 },
        { 'retribution', form = 27150 },
        { 'shadow', form = 27151 },
        { 'righteousness', form = 21084 },
        { 'command', form = 20375 },
    },
    PRIEST = {
        { 'shadowform', macro = '[form:1]', label = 15473 },
    },
    ROGUE = {
        { 'shadowdance', macro = '[bonusbar:2]', label = 51713 },
        { 'stealth', macro = '[bonusbar:1]', label = 1784 },
    },
    WARLOCK = {
        { 'metamorphosis', macro = '[form:1]', label = 47241 },
    },
    WARRIOR = {
        { 'battle', form = 2457 },
        { 'defensive', form = 71 },
        { 'berserker', form = 2458 },
    },
}