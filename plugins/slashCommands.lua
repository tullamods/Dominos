--[[
    Slash command module for Dominos
--]]
local AddonName = ...
local Addon = _G[AddonName]
local SlashCommands = Addon:NewModule('SlashCommands', 'AceConsole-3.0')

local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local function printCommand(cmd, desc)
    print((' - |cFF33FF99%s|r: %s'):format(cmd, desc))
end

function SlashCommands:OnEnable()
    self:RegisterChatCommand('dominos', 'OnCmd')
    self:RegisterChatCommand('dom', 'OnCmd')
end
local args = {}
local splitting
local function getArgs(msg) --Breaks the msg up into a table.
	wipe(args)
	splitting = nil
	while string.find(msg, ' ') do
		splitting = string.split(' ', msg) or msg
		msg = string.gsub(msg, splitting..' ', "")
		tinsert(args, splitting)
	end
	if msg and not string.find(msg, ' ') then
		tinsert(args, msg)
	end
	return args or msg
end

function SlashCommands:OnCmd(msg)
   local args  = getArgs(msg)
   local cmd1, cmd2 = args[1], args[2] 
   if cmd1 == 'config' or cmd1 == 'lock' then
        Addon:ToggleLockedFrames()
    elseif cmd1 == 'bind' then
        Addon:ToggleBindingMode()
        --frame functions
    elseif cmd1 == 'scale' then
        Addon:ScaleFrames(cmd2)
	elseif cmd1 == 'setalpha' then
        Addon:SetOpacityForFrames(cmd2)
	elseif cmd1 == 'fade' then
        Addon:SetFadeForFrames(cmd2)
	elseif cmd1 == 'setcols' then
        Addon:SetColumnsForFrames(cmd2)
	elseif cmd1 == 'pad' then
        Addon:SetPaddingForFrames(cmd2)
	elseif cmd1 == 'space' then
        Addon:SetSpacingForFrame(cmd2)
	elseif cmd1 == 'show' then
        Addon:ShowFrames(cmd2)
	elseif cmd1 == 'hide' then
        Addon:HideFrames(cmd2)
	elseif cmd1 == 'toggle' then
        Addon:ToggleFrames(cmd2)
	--actionbar functions
	elseif cmd1 == 'numbars' then
        Addon:SetNumBars(tonumber(cmd2))
	elseif cmd1 == 'numbuttons' then
        Addon:SetNumButtons(tonumber(cmd2))
	--profile functions
	elseif cmd1 == 'save' then
		local profileName = string.join(' ', cmd2)
        Addon:SaveProfile(profileName)
	elseif cmd1 == 'set' then
		local profileName = string.join(' ', cmd2)
        Addon:SetProfile(profileName)
	elseif cmd1 == 'copy' then
		local profileName = string.join(' ', cmd2)
        Addon:CopyProfile(profileName)
	elseif cmd1 == 'delete' then
		local profileName = string.join(' ', cmd2)
        Addon:DeleteProfile(profileName)
	elseif cmd1 == 'reset' then
        Addon:ResetProfile()
	elseif cmd1 == 'list' then
        Addon:ListProfiles()
	elseif cmd1 == 'version' then
        Addon:PrintVersion()
	elseif cmd1 == 'help' or cmd1 == '?' then
        self:PrintHelp()
    --debug methods
	elseif cmd1 == 'statedump' then
        Addon.OverrideController:DumpStates()
	elseif cmd1 == 'configstatus' then
    	self:PrintConfigModeStatus()
    --default case, show the options menu if present, otherwise display list of commands
	else
		if not Addon:ShowOptions() then
            self:PrintHelp()
		end
	end
end

function SlashCommands:PrintConfigModeStatus()
    local status = Addon:IsConfigAddonEnabled() and 'ENABLED' or 'DISABLED'

    Addon:Printf('Config Mode Status: %s', status)
end

function SlashCommands:PrintHelp(cmd)
    Addon:Print('Commands (/dom, /dominos)')

    printCommand('config', L.ConfigDesc)
    printCommand('scale <frameList> <scale>', L.SetScaleDesc)
    printCommand('setalpha <frameList> <opacity>', L.SetAlphaDesc)
    printCommand('fade <frameList> <opacity>', L.SetFadeDesc)
    printCommand('setcols <frameList> <columns>', L.SetColsDesc)
    printCommand('pad <frameList> <padding>', L.SetPadDesc)
    printCommand('space <frameList> <spacing>', L.SetSpacingDesc)
    printCommand('show <frameList>', L.ShowFramesDesc)
    printCommand('hide <frameList>', L.HideFramesDesc)
    printCommand('toggle <frameList>', L.ToggleFramesDesc)
    printCommand('save <profile>', L.SaveDesc)
    printCommand('set <profile>', L.SetDesc)
    printCommand('copy <profile>', L.CopyDesc)
    printCommand('delete <profile>', L.DeleteDesc)
    printCommand('reset', L.ResetDesc)
    printCommand('list', L.ListDesc)
    printCommand('version', L.PrintVersionDesc)
end
