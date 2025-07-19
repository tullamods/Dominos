-- mists of pandaria specific states
local _, Addon = ...

-- tree form uses a form index that's just 1 + the number of forms you know
local function numFormsPlus1()
    return ('[form:%d]'):format(1 + GetNumShapeshiftForms())
end

Addon.BarStates:LoadClass{
    DRUID = {
        { 'bear', macro = '[bonusbar:3]', label = 5487 },
        { 'prowl', macro = '[bonusbar:1,stealth]', label = 5215 },
        { 'cat', macro = '[bonusbar:1]', label = 768 },
        { 'moonkin', macro = '[bonusbar:4]', label = 24858 },
        { 'tree', macro = numFormsPlus1, label = 33891 },
        { 'travel', form = 783 },
        { 'aquatic', form = 1066 },
        { 'flight', form = {33943, 40120} },
        { 'treant', form = 114282 },
    },
    DEATHKNIGHT = {
        { 'blood', form = 48263 },
        { 'frost', form = 48266 },
        { 'unholy', form = 48265 },
    },
    HUNTER = {
        { 'hawk', form = 13165 },
        { 'cheetah', form = 5118 },
        { 'pack', form = 13159 },
    },
    MONK = {
        { 'ox', form = 115069 },
        { 'tiger', form = 103985 },
        { 'serpent', form = 115070 },
    },
    PALADIN = {
        { 'truth', form = 31801 },
        { 'righteousness', form = 20154 },
        { 'insight', form = 20165 },
    },
    PRIEST = {
        { 'shadowform', macro = '[bonusbar:1]', label = 15473 },
    },
    ROGUE = {
        { 'stealth', macro = '[bonusbar:1]', label = 1784 },
    },
    WARLOCK = {
        { 'metamorphosis', form = 103958 },
    },
    WARRIOR = {
        { 'battle', form = 2457 },
        { 'defensive', form = 71 },
        { 'berserker', form = 2458 },
    },
}