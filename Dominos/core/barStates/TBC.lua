-- burning crusade specific states
local _, Addon = ...

Addon.BarStates:LoadClass{
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
        { 'cheetah', form = 5118 },
        { 'pack', form = 13159 },
        { 'wild', form = 20043 },
    },
    PALADIN = {
        { 'concentration', form = 19746 },
        { 'crusader', form = 32223 },
        { 'devotion', form = 10292 },
        { 'fire', form = 19899 },
        { 'frost', form = 19898 },
        { 'retribution', form = 10301 },
        { 'shadow', form = 19896 },
    },
    PRIEST = {
        { 'shadowform', macro = '[form:1]', label = 15473 },
    },
    ROGUE = {
        { 'stealth', macro = '[bonusbar:1]', label = 1784 },
    },
    WARRIOR = {
        { 'battle', form = 2457 },
        { 'defensive', form = 71 },
        { 'berserker', form = 2458 },
    },
}
