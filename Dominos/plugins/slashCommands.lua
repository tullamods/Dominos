-- slash commands

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local SlashCommands = Addon:NewModule('SlashCommands', 'AceConsole-3.0')

local function printCommand(cmd, desc)
    print((' - |cFF33FF99%s|r: %s'):format(cmd, desc))
end

-- "8x12", "8 x 12" or "8 12": returns the bar count and length
local function parseBarSize(text)
    text = text or ''

    local count, length = text:match('^%s*(%d+)%s*[xX%*]%s*(%d+)%s*$')
    if not count then
        count, length = text:match('^%s*(%d+)%s+(%d+)%s*$')
    end

    return tonumber(count), tonumber(length)
end

function SlashCommands:OnEnable()
    self:RegisterChatCommand('dominos', 'OnCmd')
    self:RegisterChatCommand('dom', 'OnCmd')
end

function SlashCommands:OnCmd(args)
    local cmd = string.split(' ', args):lower() or args:lower()

    if cmd == 'config' or cmd == 'lock' then
        Addon:ToggleLockedFrames()
    elseif cmd == 'bind' then
        Addon:ToggleBindingMode()
    elseif cmd == 'actions' then
        Addon:ToggleActionBook()
    elseif cmd == 'scale' then
        Addon:ScaleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setalpha' then
        Addon:SetOpacityForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'fade' then
        Addon:SetFadeForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'setcols' then
        Addon:SetColumnsForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'pad' then
        Addon:SetPaddingForFrames(select(2, string.split(' ', args)))
    elseif cmd == 'space' then
        Addon:SetSpacingForFrame(select(2, string.split(' ', args)))
    elseif cmd == 'show' then
        Addon:ShowFrames(select(2, string.split(' ', args)))
    elseif cmd == 'hide' then
        Addon:HideFrames(select(2, string.split(' ', args)))
    elseif cmd == 'toggle' then
        Addon:ToggleFrames(select(2, string.split(' ', args)))
    elseif cmd == 'abs' then
        local count, length = parseBarSize(args:match('^%S+%s+(.*)$'))

        if count then
            Addon:SetActionBarSize(count, length)

            if count > Addon:NumBars() then
                Addon:Printf(L.NumBarsLimited, Addon:NumBars(), Addon:GetActionBarLength())
            end
        else
            printCommand('abs <bars>x<buttons>', L.ActionBarsDesc)
        end
    elseif cmd == 'save' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:SaveProfile(profileName)
    elseif cmd == 'set' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:SetProfile(profileName)
    elseif cmd == 'copy' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:CopyProfile(profileName)
    elseif cmd == 'delete' then
        local profileName = string.join(' ', select(2, string.split(' ', args)))
        Addon:DeleteProfile(profileName)
    elseif cmd == 'reset' then
        Addon:ResetProfile()
    elseif cmd == 'list' then
        Addon:ListProfiles()
    elseif cmd == 'version' then
        Addon:PrintVersion()
    elseif cmd == 'help' or cmd == '?' then
        self:PrintHelp()
    else
        if not Addon:ShowOptionsFrame() then
            self:PrintHelp()
        end
    end
end

function SlashCommands:PrintHelp(cmd)
    Addon:Print('Commands (/dom, /dominos)')

    printCommand('config', L.ConfigDesc)
    printCommand('actions', L.ActionsDesc)
    printCommand('scale <frameList> <scale>', L.SetScaleDesc)
    printCommand('setalpha <frameList> <opacity>', L.SetAlphaDesc)
    printCommand('fade <frameList> <opacity>', L.SetFadeDesc)
    printCommand('setcols <frameList> <columns>', L.SetColsDesc)
    printCommand('pad <frameList> <padding>', L.SetPadDesc)
    printCommand('space <frameList> <spacing>', L.SetSpacingDesc)
    printCommand('show <frameList>', L.ShowFramesDesc)
    printCommand('hide <frameList>', L.HideFramesDesc)
    printCommand('toggle <frameList>', L.ToggleFramesDesc)
    printCommand('abs <bars>x<buttons>', L.ActionBarsDesc)
    printCommand('save <profile>', L.SaveDesc)
    printCommand('set <profile>', L.SetDesc)
    printCommand('copy <profile>', L.CopyDesc)
    printCommand('delete <profile>', L.DeleteDesc)
    printCommand('reset', L.ResetDesc)
    printCommand('list', L.ListDesc)
    printCommand('version', L.PrintVersionDesc)
end
