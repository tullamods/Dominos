-- the war within specific states
local _, Addon = ...

Addon.BarStates:LoadClass{
    ALL = {
        { 'dragonriding', macro = '[bonusbar:5]', label = GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE }
    },
    DRUID = {
        { 'bear', macro = '[bonusbar:3]', label = 5487 },
        { 'prowl', macro = '[bonusbar:1,stealth]', label = 5215 },
        { 'cat', macro = '[bonusbar:1]', label = 768 },
        { 'moonkin', macro = '[bonusbar:4]', label = 24858 },
        { 'tree', form = 114282 },
        { 'travel', form = 783 },
        { 'stag', form = 210053 },
    },
    EVOKER = {
        { 'soar', macro = '[bonusbar:1]', label = 369536 },
    },
    PALADIN = {
        { 'concentration', form = 317920 },
        { 'crusader', form = 32223 },
        { 'devotion', form = 465 },
        { 'retribution', form = 183435 },
        { 'shield', equipped = {Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield} },
    },
    PRIEST = {
        { 'shadowform', form = 232698 },
    },
    ROGUE = {
        { 'shadowdance', macro = '[bonusbar:1,form:2]', label = 185313 },
        { 'stealth', macro = '[bonusbar:1]', label = 1784 },
    },
    WARRIOR = {
        { 'battle', form = 386164 },
        { 'defensive', form = 386208 },
        { 'shield', equipped = {Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield} }
    }
}