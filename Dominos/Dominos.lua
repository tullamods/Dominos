--[[
	Dominos.lua
		Driver for Dominos Frames
--]]

local AddonName, Addon = ...

Dominos = LibStub('AceAddon-3.0'):NewAddon(AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local CURRENT_VERSION = GetAddOnMetadata(AddonName, 'Version')
local CONFIG_ADDON_NAME = AddonName .. '_Config'


--[[ Startup ]]--

function Dominos:OnInitialize()
	--register database events
	self.db = LibStub('AceDB-3.0'):New('DominosDB', self:GetDefaults(), UnitClass('player'))
	self.db.RegisterCallback(self, 'OnNewProfile')
	self.db.RegisterCallback(self, 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied')
	self.db.RegisterCallback(self, 'OnProfileReset')
	self.db.RegisterCallback(self, 'OnProfileDeleted')

	--version update
	if DominosVersion then
		if DominosVersion ~= CURRENT_VERSION then
			self:UpdateSettings(DominosVersion:match('(%w+)%.(%w+)%.(%w+)'))
			self:UpdateVersion()
		end
	--new user
	else
		DominosVersion = CURRENT_VERSION
	end

	--slash command support
	self:RegisterSlashCommands()

	--create a loader for the options menu
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Dominos_Config')
	end)

	--keybound support
	local kb = LibStub('LibKeyBound-1.0')
	kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
	kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
end

function Dominos:OnEnable()
	self:HideBlizzard()
	self:CreateDataBrokerPlugin()
	self:Load()

	self.MultiActionBarGridFixer:SetShowGrid(self:ShowGrid())
end

function Dominos:CreateDataBrokerPlugin()
	local dataObject = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(AddonName, {
		type = 'launcher',

		icon = [[Interface\Addons\Dominos\Dominos]],

		OnClick = function(_, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Dominos:ToggleBindingMode()
				else
					Dominos:ToggleLockedFrames()
				end
			elseif button == 'RightButton' then
				Dominos:ShowOptions()
			end
		end,

		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine(AddonName)

			if Dominos:Locked() then
				tooltip:AddLine(L.ConfigEnterTip)
			else
				tooltip:AddLine(L.ConfigExitTip)
			end

			local KB = LibStub('LibKeyBound-1.0', true)
			if KB then
				if KB:IsShown() then
					tooltip:AddLine(L.BindingExitTip)
				else
					tooltip:AddLine(L.BindingEnterTip)
				end
			end

			if self:IsConfigAddonEnabled() then
				tooltip:AddLine(L.ShowOptionsTip)
			end
		end,
	})

	LibStub('LibDBIcon-1.0'):Register(AddonName, dataObject, self.db.profile.minimap)
end

--[[ Version Updating ]]--

function Dominos:GetDefaults()
	return {
		profile = {
			possessBar = 1,

			sticky = true,
			linkedOpacity = false,
			showMacroText = true,
			showBindingText = true,
			showTooltips = true,
			showTooltipsCombat = true,
			useVehicleUI = true,

			minimap = {
				hide = false,
			},

			ab = {
				count = 10,
				showgrid = true,
			},

			frames = {}
		}
	}
end

function Dominos:UpdateSettings(major, minor, bugfix)
	--inject new roll bar defaults
	if major == '5' and minor == '0' and bugfix < '14' then
		for profile, sets in pairs(self.db.sv.profiles) do
			if sets.frames then
				local rollBarFrameSets = sets.frames['roll']
				if rollBarFrameSets then
					rollBarFrameSets.showInPetBattleUI = true
					rollBarFrameSets.showInOverrideUI = true
				end
			end
		end
	end
end

function Dominos:UpdateVersion()
	DominosVersion = CURRENT_VERSION

	self:Print(string.format(L.Updated, DominosVersion))
end


--Load is called  when the addon is first enabled, and also whenever a profile is loaded
function Dominos:Load()
	for i, module in self:IterateModules() do
		if module.Load then
			module:Load()
		end
	end

	self.Frame:ForAll('Reanchor')
	self:UpdateMinimapButton()
end

--unload is called when we're switching profiles
function Dominos:Unload()
	--unload any module stuff
	for i, module in self:IterateModules() do
		if module.Unload then
			module:Unload()
		end
	end
end


--[[ Blizzard Stuff Hiding ]]--

--shamelessly pulled from Bartender4
function Dominos:HideBlizzard()
	local uiHider = CreateFrame('Frame', nil, _G['UIParent'], 'SecureFrameTemplate'); uiHider:Hide()
	self.uiHider = uiHider

	local disableFrame = function(frameName, unregisterEvents)
		local frame = _G[frameName]
		if not frame then
			self:Print('Unknown Frame', frameName)
		end

		frame:SetParent(uiHider)
		frame.ignoreFramePositionManager = true

		if unregisterEvents then
			frame:UnregisterAllEvents()
		end
	end

	--[[ disable, but don't hide the menu bar ]]--

	_G['MainMenuBar']:EnableMouse(false)
	_G['MainMenuBar'].ignoreFramePositionManager = true

	disableFrame('MultiBarBottomLeft')
	disableFrame('MultiBarBottomRight')
	disableFrame('MultiBarLeft')
	disableFrame('MultiBarRight')
	disableFrame('MainMenuBarArtFrame')
	disableFrame('MainMenuExpBar')
	disableFrame('MainMenuBarMaxLevelBar')
	disableFrame('ReputationWatchBar')
	disableFrame('StanceBarFrame')
	disableFrame('PossessBarFrame')
	disableFrame('PetActionBarFrame')
	disableFrame('MultiCastActionBarFrame')


	--[[ disable override bar transition animations ]]--

	do
		local animations = {_G['MainMenuBar'].slideOut:GetAnimations()}
		animations[1]:SetOffset(0, 0)

		animations = {_G['OverrideActionBar'].slideOut:GetAnimations()}
		animations[1]:SetOffset(0, 0)
	end

	self:UpdateUseOverrideUI()
end

function Dominos:SetUseOverrideUI(enable)
	self.db.profile.useOverrideUI = enable and true or false
	self:UpdateUseOverrideUI()
end

function Dominos:UsingOverrideUI()
	return self.db.profile.useOverrideUI
end

function Dominos:UpdateUseOverrideUI()
	local usingOverrideUI = self:UsingOverrideUI()

	self.OverrideController:SetAttribute('state-useoverrideui', usingOverrideUI)

	local oab = _G['OverrideActionBar']
	oab:ClearAllPoints()
	if usingOverrideUI then
		oab:SetPoint('BOTTOM')
	else
		oab:SetPoint('LEFT', oab:GetParent(), 'RIGHT', 100, 0)
	end
end


--[[ Keybound Events ]]--

function Dominos:LIBKEYBOUND_ENABLED()
	for _,frame in self.Frame:GetAll() do
		if frame.KEYBOUND_ENABLED then
			frame:KEYBOUND_ENABLED()
		end
	end
end

function Dominos:LIBKEYBOUND_DISABLED()
	for _,frame in self.Frame:GetAll() do
		if frame.KEYBOUND_DISABLED then
			frame:KEYBOUND_DISABLED()
		end
	end
end


--[[ Profile Functions ]]--

function Dominos:SaveProfile(name)
	local toCopy = self.db:GetCurrentProfile()
	if name and name ~= toCopy then
		self:Unload()
		self.db:SetProfile(name)
		self.db:CopyProfile(toCopy)
		self.isNewProfile = nil
		self:Load()
	end
end

function Dominos:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:Unload()
		self.db:SetProfile(profile)
		self.isNewProfile = nil
		self:Load()
	else
		self:Print(format(L.InvalidProfile, name or 'null'))
	end
end

function Dominos:DeleteProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.db:DeleteProfile(profile)
	else
		self:Print(L.CantDeleteCurrentProfile)
	end
end

function Dominos:CopyProfile(name)
	if name and name ~= self.db:GetCurrentProfile() then
		self:Unload()
		self.db:CopyProfile(name)
		self.isNewProfile = nil
		self:Load()
	end
end

function Dominos:ResetProfile()
	self:Unload()
	self.db:ResetProfile()
	self.isNewProfile = true
	self:Load()
end

function Dominos:ListProfiles()
	self:Print(L.AvailableProfiles)

	local current = self.db:GetCurrentProfile()
	for _,k in ipairs(self.db:GetProfiles()) do
		if k == current then
			print(' - ' .. k, 1, 1, 0)
		else
			print(' - ' .. k)
		end
	end
end

function Dominos:MatchProfile(name)
	local name = name:lower()
	local nameRealm = name .. ' - ' .. GetRealmName():lower()
	local match

	for i, k in ipairs(self.db:GetProfiles()) do
		local key = k:lower()
		if key == name then
			return k
		elseif key == nameRealm then
			match = k
		end
	end
	return match
end


--[[ Profile Events ]]--

function Dominos:OnNewProfile(msg, db, name)
	self.isNewProfile = true
	self:Print(format(L.ProfileCreated, name))
end

function Dominos:OnProfileDeleted(msg, db, name)
	self:Print(format(L.ProfileDeleted, name))
end

function Dominos:OnProfileChanged(msg, db, name)
	self:Print(format(L.ProfileLoaded, name))
end

function Dominos:OnProfileCopied(msg, db, name)
	self:Print(format(L.ProfileCopied, name))
end

function Dominos:OnProfileReset(msg, db)
	self:Print(format(L.ProfileReset, db:GetCurrentProfile()))
end


--[[ Settings...Setting ]]--

function Dominos:SetFrameSets(id, sets)
	local id = tonumber(id) or id
	self.db.profile.frames[id] = sets

	return self.db.profile.frames[id]
end

function Dominos:GetFrameSets(id)
	return self.db.profile.frames[tonumber(id) or id]
end


--[[ Options Menu Display ]]--

function Dominos:ShowOptions()
	if InCombatLockdown() then
		return
	end

	if LoadAddOn('Dominos_Config') then
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(self.Options)
		return true
	end
	return false
end

function Dominos:NewMenu(id)
	if not self.Menu then
		LoadAddOn('Dominos_Config')
	end

	return self.Menu and self.Menu:New(id)
end


--[[ Slash Commands ]]--

function Dominos:RegisterSlashCommands()
	self:RegisterChatCommand('dominos', 'OnCmd')
	self:RegisterChatCommand('dom', 'OnCmd')
end

function Dominos:OnCmd(args)
	local cmd = string.split(' ', args):lower() or args:lower()

	--frame functions
	if cmd == 'config' or cmd == 'lock' then
		self:ToggleLockedFrames()
	elseif cmd == 'scale' then
		self:ScaleFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setalpha' then
		self:SetOpacityForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'fade' then
		self:SetFadeForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setcols' then
		self:SetColumnsForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'pad' then
		self:SetPaddingForFrames(select(2, string.split(' ', args)))
	elseif cmd == 'space' then
		self:SetSpacingForFrame(select(2, string.split(' ', args)))
	elseif cmd == 'show' then
		self:ShowFrames(select(2, string.split(' ', args)))
	elseif cmd == 'hide' then
		self:HideFrames(select(2, string.split(' ', args)))
	elseif cmd == 'toggle' then
		self:ToggleFrames(select(2, string.split(' ', args)))
	--actionbar functions
	elseif cmd == 'numbars' then
		self:SetNumBars(tonumber(select(2, string.split(' ', args))))
	elseif cmd == 'numbuttons' then
		self:SetNumButtons(tonumber(select(2, string.split(' ', args))))
	--profile functions
	elseif cmd == 'save' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SaveProfile(profileName)
	elseif cmd == 'set' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SetProfile(profileName)
	elseif cmd == 'copy' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:CopyProfile(profileName)
	elseif cmd == 'delete' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:DeleteProfile(profileName)
	elseif cmd == 'reset' then
		self:ResetProfile()
	elseif cmd == 'list' then
		self:ListProfiles()
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'help' or cmd == '?' then
		self:PrintHelp()
	elseif cmd == 'statedump' then
		self.OverrideController:DumpStates()
	elseif cmd == 'configstatus' then
		local status = self:IsConfigAddonEnabled() and 'ENABLED' or 'DISABLED'
		print(('Config Mode Status: %s'):format(status))
	--options stuff
	else
		if not self:ShowOptions() then
			self:PrintHelp()
		end
	end
end

do
	local function PrintCmd(cmd, desc)
		print(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	function Dominos:PrintHelp(cmd)
		self:Print('Commands (/dom, /dominos)')

		PrintCmd('config', L.ConfigDesc)
		PrintCmd('scale <frameList> <scale>', L.SetScaleDesc)
		PrintCmd('setalpha <frameList> <opacity>', L.SetAlphaDesc)
		PrintCmd('fade <frameList> <opacity>', L.SetFadeDesc)
		PrintCmd('setcols <frameList> <columns>', L.SetColsDesc)
		PrintCmd('pad <frameList> <padding>', L.SetPadDesc)
		PrintCmd('space <frameList> <spacing>', L.SetSpacingDesc)
		PrintCmd('show <frameList>', L.ShowFramesDesc)
		PrintCmd('hide <frameList>', L.HideFramesDesc)
		PrintCmd('toggle <frameList>', L.ToggleFramesDesc)
		PrintCmd('save <profile>', L.SaveDesc)
		PrintCmd('set <profile>', L.SetDesc)
		PrintCmd('copy <profile>', L.CopyDesc)
		PrintCmd('delete <profile>', L.DeleteDesc)
		PrintCmd('reset', L.ResetDesc)
		PrintCmd('list', L.ListDesc)
		PrintCmd('version', L.PrintVersionDesc)
	end
end

--version info
function Dominos:PrintVersion()
	self:Print(DominosVersion)
end

function Dominos:IsConfigAddonEnabled()
	return GetAddOnEnableState(UnitName('player'), AddonName .. '_Config') >= 1
end


--[[ Configuration Functions ]]--

--moving
Dominos.locked = true

function Dominos:SetLock(enable)
	if InCombatLockdown() and (not enable) then
		return
	end

	self.locked = enable or false

	if self:Locked() then
		self:GetModule('ConfigOverlay'):Hide()
	else
		LibStub('LibKeyBound-1.0'):Deactivate()
		self:GetModule('ConfigOverlay'):Show()
	end
end

function Dominos:Locked()
	return self.locked
end

function Dominos:ToggleLockedFrames()
	self:SetLock(not self:Locked())
end

function Dominos:ToggleBindingMode()
	self:SetLock(true)
	LibStub('LibKeyBound-1.0'):Toggle()
end

--scale
function Dominos:ScaleFrames(...)
	local numArgs = select('#', ...)
	local scale = tonumber(select(numArgs, ...))

	if scale and scale > 0 and scale <= 10 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
		end
	end
end

--opacity
function Dominos:SetOpacityForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
		end
	end
end

--faded opacity
function Dominos:SetFadeForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFadeMultiplier', alpha)
		end
	end
end

--columns
function Dominos:SetColumnsForFrames(...)
	local numArgs = select('#', ...)
	local cols = tonumber(select(numArgs, ...))

	if cols then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetColumns', cols)
		end
	end
end

--spacing
function Dominos:SetSpacingForFrame(...)
	local numArgs = select('#', ...)
	local spacing = tonumber(select(numArgs, ...))

	if spacing then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetSpacing', spacing)
		end
	end
end

--padding
function Dominos:SetPaddingForFrames(...)
	local numArgs = select('#', ...)
	local pW, pH = select(numArgs - 1, ...)

	if tonumber(pW) and tonumber(pH) then
		for i = 1, numArgs - 2 do
			self.Frame:ForFrame(select(i, ...), 'SetPadding', tonumber(pW), tonumber(pH))
		end
	end
end

--visibility
function Dominos:ShowFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'ShowFrame')
	end
end

function Dominos:HideFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'HideFrame')
	end
end

function Dominos:ToggleFrames(...)
	for i = 1, select('#', ...) do
		self.Frame:ForFrame(select(i, ...), 'ToggleFrame')
	end
end

--clickthrough
function Dominos:SetClickThroughForFrames(...)
	local numArgs = select('#', ...)
	local enable = select(numArgs - 1, ...)

	for i = 1, numArgs - 2 do
		self.Frame:ForFrame(select(i, ...), 'SetClickThrough', tonumber(enable) == 1)
	end
end

--empty button display
function Dominos:ToggleGrid()
	self:SetShowGrid(not self:ShowGrid())
end

function Dominos:SetShowGrid(enable)
	self.db.profile.showgrid = enable or false
	self.ActionBar:ForAll('UpdateGrid')
	self.MultiActionBarGridFixer:SetShowGrid(enable)
end

function Dominos:ShowGrid()
	return self.db.profile.showgrid
end

--right click selfcast
function Dominos:SetRightClickUnit(unit)
	self.db.profile.ab.rightClickUnit = unit
	self.ActionBar:ForAll('UpdateRightClickUnit')
end

function Dominos:GetRightClickUnit()
	return self.db.profile.ab.rightClickUnit
end

--binding text
function Dominos:SetShowBindingText(enable)
	self.db.profile.showBindingText = enable or false

	for _,f in self.Frame:GetAll() do
		if f.buttons then
			for _,b in pairs(f.buttons) do
				if b.UpdateHotkey then
					b:UpdateHotkey()
				end
			end
		end
	end
end

function Dominos:ShowBindingText()
	return self.db.profile.showBindingText
end

--macro text
function Dominos:SetShowMacroText(enable)
	self.db.profile.showMacroText = enable or false

	for _,f in self.Frame:GetAll() do
		if f.buttons then
			for _,b in pairs(f.buttons) do
				if b.UpdateMacro then
					b:UpdateMacro()
				end
			end
		end
	end
end

function Dominos:ShowMacroText()
	return self.db.profile.showMacroText
end

--possess bar settings
function Dominos:SetOverrideBar(id)
	local prevBar = self:GetOverrideBar()
	self.db.profile.possessBar = id
	local newBar = self:GetOverrideBar()

	prevBar:UpdateOverrideBar()
	newBar:UpdateOverrideBar()
end

function Dominos:GetOverrideBar()
	return self.Frame:Get(self.db.profile.possessBar)
end

--action bar numbers
function Dominos:SetNumBars(count)
	count = max(min(count, 120), 1) --sometimes, I do entertaininig things

	if count ~= self:NumBars() then
		self.ActionBar:ForAll('Delete')
		self.db.profile.ab.count = count

		for i = 1, self:NumBars() do
			self.ActionBar:New(i)
		end
	end
end

function Dominos:SetNumButtons(count)
	self:SetNumBars(120 / count)
end

function Dominos:NumBars()
	return self.db.profile.ab.count
end


--tooltips
function Dominos:ShowTooltips()
	return self.db.profile.showTooltips
end

function Dominos:SetShowTooltips(enable)
	self.db.profile.showTooltips = enable or false
	self:GetModule('Tooltips'):SetShowTooltips(enable)
end

function Dominos:SetShowCombatTooltips(enable)
	self.db.profile.showTooltipsCombat = enable or false
	self:GetModule('Tooltips'):SetShowTooltipsInCombat(enable)
end

function Dominos:ShowCombatTooltips()
	return self.db.profile.showTooltipsCombat
end


--minimap button
function Dominos:SetShowMinimap(enable)
	self.db.profile.minimap.hide = not enable
	self:UpdateMinimapButton()
end

function Dominos:ShowingMinimap()
	return not self.db.profile.minimap.hide
end

function Dominos:UpdateMinimapButton()
	if self:ShowingMinimap() then
		LibStub('LibDBIcon-1.0'):Show('Dominos')
	else
		LibStub('LibDBIcon-1.0'):Hide('Dominos')
	end
end

function Dominos:SetMinimapButtonPosition(angle)
	self.db.profile.minimapPos = angle
end

function Dominos:GetMinimapButtonPosition(angle)
	return self.db.profile.minimapPos
end

--sticky bars
function Dominos:SetSticky(enable)
	self.db.profile.sticky = enable or false
	if not enable then
		self.Frame:ForAll('Stick')
		self.Frame:ForAll('Reposition')
	end
end

function Dominos:Sticky()
	return self.db.profile.sticky
end

--linked opacity
function Dominos:SetLinkedOpacity(enable)
	self.db.profile.linkedOpacity = enable or false
	self.Frame:ForAll('UpdateWatched')
	self.Frame:ForAll('UpdateAlpha')
end

function Dominos:IsLinkedOpacityEnabled()
	return self.db.profile.linkedOpacity
end

--[[ Masque Support ]]--

function Dominos:Masque(group, button, buttonData)
	local Masque = LibStub('Masque', true)
	if Masque then
		Masque:Group('Dominos', group):AddButton(button, buttonData)
		return true
	end
end

function Dominos:RemoveMasque(group, button)
	local Masque = LibStub('Masque', true)
	if Masque then
		Masque:Group('Dominos', group):RemoveButton(button)
		return true
	end
end


--[[ Utility Functions ]]--

--utility function: create a widget class
function Dominos:CreateClass(type, parentClass)
	local class = CreateFrame(type)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	function class:Bind(o)
		return setmetatable(o, self.mt)
	end

	return class
end
