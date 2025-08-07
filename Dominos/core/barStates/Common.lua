-- states that appear in all game versions
local _, Addon = ...

local config = {}

config.modifier = {
    { 'selfcast', macro = '[mod:SELFCAST]', label = AUTO_SELF_CAST_KEY_TEXT },
    { 'ctrlAltShift', macro = '[mod:alt,mod:ctrl,mod:shift]', label = strjoin('+', CTRL_KEY_TEXT, ALT_KEY_TEXT, SHIFT_KEY_TEXT) },
    { 'ctrlAlt', macro = '[mod:alt,mod:ctrl]', label = strjoin('+', CTRL_KEY_TEXT, ALT_KEY_TEXT) },
    { 'altShift', macro = '[mod:alt,mod:shift]', label = strjoin('+', ALT_KEY_TEXT, SHIFT_KEY_TEXT) },
    { 'ctrlShift', macro = '[mod:ctrl,mod:shift]', label = strjoin('+', CTRL_KEY_TEXT, SHIFT_KEY_TEXT) },
    { 'alt', macro = '[mod:alt]', label = ALT_KEY_TEXT },
    { 'ctrl', macro = '[mod:ctrl]', label = CTRL_KEY_TEXT },
    { 'shift', macro = '[mod:shift]', label = SHIFT_KEY_TEXT },
    { 'meta', macro = '[mod:meta]', label = META_KEY_TEXT },
}

config.page = {}
for i = 2, NUM_ACTIONBAR_PAGES do
    config.page[#config.page+1] = {
        id = ('page%d'):format(i),
        macro = ('[bar:%d]'):format(i),
        label = _G[('BINDING_NAME_ACTIONPAGE%d'):format(i)]
    }
end

config.race = {
    NightElf = {
        { 'shadowmeld', macro = '[stealth]', label = 20580 },
    }
}

config.target = {
    { 'help', macro = '[help]' },
    { 'harm', macro = '[harm]' },
    { 'notarget', macro = '[noexists]' },
}

Addon.BarStates:Load(config)