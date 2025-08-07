-- vanilla specific states
local _, Addon = ...

Addon.BarStates:LoadClass{
    DRUID = {
        { 'bear', macro = '[bonusbar:3]', label = 5487 },
        { 'prowl', macro = '[bonusbar:1,stealth]', label = 5215 },
        { 'cat', macro = '[bonusbar:1]', label = 768 },
        { 'moonkin', form = 24858 },
        { 'travel', form = 783 },
        { 'aquatic', form = 1066 },
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