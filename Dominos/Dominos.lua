-- Dominos.lua - The main driver for Dominos
local AddonName, AddonTable = ...
local Addon = LibStub('AceAddon-3.0'):NewAddon(AddonTable, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local KeyBound = LibStub('LibKeyBound-1.0')

local ADDON_VERSION = C_AddOns.GetAddOnMetadata(AddonName, 'Version')
local CONFIG_ADDON_NAME = AddonName .. '_Config'
local DB_SCHEMA_VERSION = 2
local BINDINGS_VERSION = 3

-- setup custom callbacks
Addon.callbacks = LibStub('CallbackHandler-1.0'):New(Addon)

-- how many action buttons we support, and what button to map keybinding presses
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    Addon.ACTION_BUTTON_COUNT = 14 * NUM_ACTIONBAR_BUTTONS
else
    Addon.ACTION_BUTTON_COUNT = 10 * NUM_ACTIONBAR_BUTTONS
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function Addon:OnInitialize()
    -- setup db
    self:CreateDatabase()
    self:UpgradeDatabase()

    -- register keybound callbacks
    KeyBound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
    KeyBound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
end

function Addon:OnEnable()
    self:MigrateBindings()
    self:Load()

    -- watch for binding updates, updating all bars on the last one that happens
    -- in rapid sequence
    self.UpdateHotkeys = self:Debounce(function()
        if not InCombatLockdown() then
            self.Frame:ForEach('ForButtons', 'UpdateOverrideBindings')
        end

        self.Frame:ForEach('ForButtons', 'UpdateHotkeys')
    end, 0.01)

    self:RegisterEvent('UPDATE_BINDINGS')
    self:RegisterEvent("GAME_PAD_ACTIVE_CHANGED", "UPDATE_BINDINGS")
end

-- configuration events
function Addon:OnUpgradeDatabase(oldVersion, newVersion)
    if oldVersion and oldVersion < 2 then
        for _, profile in pairs(self.db.profiles) do
            local mainBar = profile.frames and profile.frames[1]

            if mainBar then
                for _, pages in pairs(mainBar.pages) do

                    if pages.dragonriding == nil then
                        pages.dragonriding = 10
                    end
                end
            end
        end
    end
end

function Addon:OnUpgradeAddon(oldVersion, newVersion)
    self:Printf(L.Updated, ADDON_VERSION, self:GetWowBuild())
end

-- binding events
function Addon:UPDATE_BINDINGS()
    self:UpdateHotkeys()
end

function Addon:LIBKEYBOUND_ENABLED()
    self.Frame:ForEach('KEYBOUND_ENABLED')
end

function Addon:LIBKEYBOUND_DISABLED()
    self.Frame:ForEach('KEYBOUND_DISABLED')
end

-- profile events
function Addon:OnNewProfile(msg, db, name)
    self:Printf(L.ProfileCreated, name)
end

function Addon:OnProfileDeleted(msg, db, name)
    self:Printf(L.ProfileDeleted, name)
end

function Addon:OnProfileChanged(msg, db, name)
    self:Printf(L.ProfileLoaded, name)
    self:Load()
end

function Addon:OnProfileCopied(msg, db, name)
    self:Printf(L.ProfileCopied, name)
    self:Reload()
end

function Addon:OnProfileReset(msg, db)
    self:Printf(L.ProfileReset, db:GetCurrentProfile())
    self:Reload()
end

function Addon:OnProfileShutdown(msg, db, name)
    self:Unload()
end

--------------------------------------------------------------------------------
-- Layout Lifecycle
--------------------------------------------------------------------------------

local initializedModules = {}

-- Load is called when the addon is first enabled, and also whenever a profile
-- is loaded
function Addon:Load()
    self.callbacks:Fire('LAYOUT_LOADING')

    local function module_load(module, id)
        if not self.db.profile.modules[id] then
            return
        end

        -- try calling OnFirstLoad if we've not loaded this module first
        if not initializedModules[module] then
            local f = module.OnFirstLoad
            if type(f) == 'function' then
                f(module)
            end

            initializedModules[module] = true
        end

        local f = module.Load
        if type(f) == 'function' then
            f(module)
        end
    end

    for id, module in self:IterateModules() do
        local success, msg = pcall(module_load, module, id)
        if not success then
            self:Printf('Failed to load %s\n%s', module:GetName(), msg)
        end
    end

    self.Frame:ForEach('RestoreAnchor')
    self:GetModule('ButtonThemer'):Reskin()

    self.callbacks:Fire('LAYOUT_LOADED')
end

-- unload is called when we're switching profiles
function Addon:Unload()
    self.callbacks:Fire('LAYOUT_UNLOADING')

    local function module_unload(module, id)
        if not self.db.profile.modules[id] then
            return
        end

        local f = module.Unload
        if type(f) == 'function' then
            f(module)
        end
    end

    -- unload any module stuff
    for id, module in self:IterateModules() do
        local success, msg = pcall(module_unload, module, id)
        if not success then
            self:Printf('Failed to unload %s\n%s', module:GetName(), msg)
        end
    end

    self.callbacks:Fire('LAYOUT_UNLOADED')
end

function Addon:Reload()
    self:Unload()
    self:Load()
end

--------------------------------------------------------------------------------
-- Database Setup
--------------------------------------------------------------------------------

-- db actions
function Addon:CreateDatabase()
    local dbName = AddonName .. 'DB'
    local dbDefaults = self:GetDatabaseDefaults()
    local defaultProfileName = UnitClass('player')
    local db = LibStub('AceDB-3.0'):New(dbName, dbDefaults, defaultProfileName)

    local LibDualSpec = LibStub('LibDualSpec-1.0', true)

    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(db, dbName)
    end

    db.RegisterCallback(self, 'OnNewProfile')
    db.RegisterCallback(self, 'OnProfileChanged')
    db.RegisterCallback(self, 'OnProfileCopied')
    db.RegisterCallback(self, 'OnProfileDeleted')
    db.RegisterCallback(self, 'OnProfileReset')
    db.RegisterCallback(self, 'OnProfileShutdown')

    self.db = db
end

function Addon:GetDatabaseDefaults()
    return {
        profile = {
            possessBar = self:IsBuild('retail', 'wrath') and 1 or "pet",
            -- if true, applies a default dominos skin to buttons
            -- when masque is not enabled
            applyButtonTheme = true,
            sticky = true,
            linkedOpacity = false,
            showMacroText = true,
            showBindingText = true,
            showCounts = true,
            showEquippedItemBorders = true,
            showTooltips = true,
            showTooltipsCombat = true,
            showSpellGlows = true,
            showSpellAnimations = true,
            useOverrideUI = self:IsBuild('retail', 'wrath'),

            ab = {
                count = self.ACTION_BUTTON_COUNT / NUM_ACTIONBAR_BUTTONS,
                rightClickUnit = "player"
            },

            actionColors = {
                ['**'] = {
                    r = 1,
                    g = 1,
                    b = 1,
                    a = 1,
                    desaturate = false,
                    enabled = true
                },

                oor = {
                    r = 1,
                    g = 0.5,
                    b = 0.5,
                    enabled = false
                },

                oom = {
                    r = 0.5,
                    g = 0.5,
                    b = 1
                },

                unusable = {
                    r = 0.4,
                    g = 0.4,
                    b = 0.4
                },
            },

            alignmentGrid = {
                enabled = not self:IsBuild("retail"),
                size = 32
            },

            hotkeyColors = {
                ['**'] = {
                    r = 1,
                    g = 1,
                    b = 1,
                    a = 1,
                    enabled = true
                },

                oor = {
                    r = 1,
                    g = 0.12549,
                    b = 0.12549
                }
            },

            frames = {
            },

            minimap = {
                hide = false
            },

            -- what modules are enabled
            -- module[id] = enabled
            modules = { ['**'] = true }
        }
    }
end

function Addon:UpgradeDatabase()
    local configVerison = self.db.global.configVersion
    if configVerison ~= DB_SCHEMA_VERSION then
        self:OnUpgradeDatabase(configVerison, DB_SCHEMA_VERSION)
        self.db.global.configVersion = DB_SCHEMA_VERSION
    end

    local addonVersion = self.db.global.addonVersion
    if addonVersion ~= ADDON_VERSION then
        self:OnUpgradeAddon(addonVersion, ADDON_VERSION)
        self.db.global.addonVersion = ADDON_VERSION
    end
end

-- migrate legacy bindings from LeftButton to HOTKEY
function Addon:MigrateBindings()
    local bindingSet = GetCurrentBindingSet()
    local dbIndex = bindingSet == 2 and "char" or "global"

    if self.db[dbIndex].bindingsVersion == BINDINGS_VERSION then return end

    --- @param command string the command to bind keys to
    --- @param ... string all the keys to remap
    --- @return boolean
    local function setBindings(command, ...)
        local saved = false

        for i = 1, select("#", ...) do
            if SetBinding(select(i, ...), command) then
                saved = true
            end
        end

        return saved
    end

    local legacy = 'CLICK ' .. AddonName .. 'ActionButton%d:LeftButton'
    local modern = 'CLICK ' .. AddonName .. 'ActionButton%d:HOTKEY'
    local migrated = false

    for i = 1, Addon.ACTION_BUTTON_COUNT do
        if setBindings(modern:format(i), GetBindingKey(legacy:format(i))) then
            migrated = true
        end
    end

    if migrated then
        SaveBindings(bindingSet)
    end

    self.db[dbIndex].bindingsVersion = BINDINGS_VERSION
end

--------------------------------------------------------------------------------
-- Profiles
--------------------------------------------------------------------------------

-- profile actions
function Addon:SaveProfile(name)
    local toCopy = self.db:GetCurrentProfile()
    if name and name ~= toCopy then
        self.db:SetProfile(name)
        self.db:CopyProfile(toCopy)
    end
end

function Addon:SetProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self.db:SetProfile(profile)
    else
        self:Printf(L.InvalidProfile, name or 'null')
    end
end

function Addon:DeleteProfile(name)
    local profile = self:MatchProfile(name)
    if profile and profile ~= self.db:GetCurrentProfile() then
        self.db:DeleteProfile(profile)
    else
        self:Print(L.CantDeleteCurrentProfile)
    end
end

function Addon:CopyProfile(name)
    if name and name ~= self.db:GetCurrentProfile() then
        self.db:CopyProfile(name)
    end
end

function Addon:ResetProfile()
    self.db:ResetProfile()
end

function Addon:ListProfiles()
    self:Print(L.AvailableProfiles)

    local current = self.db:GetCurrentProfile()
    for _, k in ipairs(self.db:GetProfiles()) do
        if k == current then
            print(' - ' .. k, 1, 1, 0)
        else
            print(' - ' .. k)
        end
    end
end

function Addon:MatchProfile(name)
    name = name:lower()

    local nameRealm = name .. ' - ' .. GetRealmName():lower()
    local match

    for _, k in ipairs(self.db:GetProfiles()) do
        local key = k:lower()
        if key == name then
            return k
        elseif key == nameRealm then
            match = k
        end
    end

    return match
end

--------------------------------------------------------------------------------
-- Configuration UI
--------------------------------------------------------------------------------

function Addon:ShowOptionsFrame()
    if not self:IsConfigAddonEnabled() then
        return false
    end

    if self:LoadConfigAddon() then
        local dialog = LibStub('AceConfigDialog-3.0')

        dialog:Open(AddonName)
        dialog:SelectGroup(AddonName, "general")

        return true
    end

    return false
end

function Addon:NewMenu()
    if self:IsConfigAddonEnabled() and self:LoadConfigAddon() then
        return self.Options.Menu:New()
    end
end

function Addon:IsConfigAddonEnabled()
    local player = UnitName('player')

    if type(GetAddOnEnableState) == "function" then
        return GetAddOnEnableState(player, CONFIG_ADDON_NAME) > 0
    end

    return C_AddOns.GetAddOnEnableState(CONFIG_ADDON_NAME, player) > 0
end

function Addon:LoadConfigAddon()
    if not (C_AddOns.IsAddOnLoaded or IsAddOnLoaded)(CONFIG_ADDON_NAME) then
        return (C_AddOns.LoadAddOn or LoadAddOn)(CONFIG_ADDON_NAME)
    end

    return true
end

--------------------------------------------------------------------------------
-- Configuration API
--------------------------------------------------------------------------------

-- frame settings

function Addon:SetFrameSets(id, sets)
    id = tonumber(id) or id

    self.db.profile.frames[id] = sets

    return self.db.profile.frames[id]
end

function Addon:GetFrameSets(id)
    return self.db.profile.frames[tonumber(id) or id]
end

-- configuration mode
Addon.locked = true

function Addon:SetLock(locked)
    if InCombatLockdown() and (not locked) then
        return
    end

    if locked and (not self:Locked()) then
        self.locked = true
        self.callbacks:Fire('CONFIG_MODE_DISABLED')
    elseif (not locked) and self:Locked() then
        self.locked = false
        self:LoadConfigAddon()
        self.callbacks:Fire('CONFIG_MODE_ENABLED')
    end
end

function Addon:Locked()
    return self.locked
end

function Addon:ToggleLockedFrames()
    self:SetLock(not self:Locked())
end

-- binding mode
function Addon:SetBindingMode(enable)
    if enable and (not self:IsBindingModeEnabled()) then
        self:SetLock(true)
        KeyBound:Activate()
    elseif (not enable) and self:IsBindingModeEnabled() then
        KeyBound:Deactivate()
    end
end

function Addon:IsBindingModeEnabled()
    return KeyBound:IsShown()
end

function Addon:ToggleBindingMode()
    self:SetBindingMode(not self:IsBindingModeEnabled())
end

-- scale
function Addon:ScaleFrames(...)
    local numArgs = select('#', ...)
    local scale = tonumber(select(numArgs, ...))

    if scale and scale > 0 and scale <= 10 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
        end
    end
end

-- opacity
function Addon:SetOpacityForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))

    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
        end
    end
end

-- faded opacity
function Addon:SetFadeForFrames(...)
    local numArgs = select('#', ...)
    local alpha = tonumber(select(numArgs, ...))

    if alpha and alpha >= 0 and alpha <= 1 then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetFadeMultiplier', alpha)
        end
    end
end

-- columns
function Addon:SetColumnsForFrames(...)
    local numArgs = select('#', ...)
    local cols = tonumber(select(numArgs, ...))

    if cols then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetColumns', cols)
        end
    end
end

-- spacing
function Addon:SetSpacingForFrame(...)
    local numArgs = select('#', ...)
    local spacing = tonumber(select(numArgs, ...))

    if spacing then
        for i = 1, numArgs - 1 do
            self.Frame:ForFrame(select(i, ...), 'SetSpacing', spacing)
        end
    end
end

-- padding
function Addon:SetPaddingForFrames(...)
    local numArgs = select('#', ...)
    local pW, pH = select(numArgs - 1, ...)

    if tonumber(pW) and tonumber(pH) then
        for i = 1, numArgs - 2 do
            self.Frame:ForFrame(select(i, ...), 'SetPadding', tonumber(pW), tonumber(pH))
        end
    end
end

-- visibility
function Addon:ShowFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'ShowFrame')
    end
end

function Addon:HideFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'HideFrame')
    end
end

function Addon:ToggleFrames(...)
    for i = 1, select('#', ...) do
        self.Frame:ForFrame(select(i, ...), 'ToggleFrame')
    end
end

-- clickthrough
function Addon:SetClickThroughForFrames(...)
    local numArgs = select('#', ...)
    local enable = select(numArgs - 1, ...)

    for i = 1, numArgs - 2 do
        self.Frame:ForFrame(select(i, ...), 'SetClickThrough', tonumber(enable) == 1)
    end
end

-- empty button display
function Addon:SetShowGrid(enable)
    self.db.profile.showgrid = enable and true
    self.callbacks:Fire("SHOW_EMPTY_BUTTONS_CHANGED", self:ShowGrid())
end

function Addon:ShowGrid()
    return self.db.profile.showgrid and true
end

-- right click selfcast
function Addon:SetRightClickUnit(unit)
    self.db.profile.ab.rightClickUnit = unit
    self.Frame:ForEach('SetRightClickUnit', unit)
end

function Addon:GetRightClickUnit()
    return self.db.profile.ab.rightClickUnit
end

-- binding text
function Addon:SetShowBindingText(enable)
    self.db.profile.showBindingText = enable and true
    self.Frame:ForEach('ForButtons', 'UpdateHotkeys')
end

function Addon:ShowBindingText()
    return self.db.profile.showBindingText
end

-- macro text
function Addon:SetShowMacroText(enable)
    self.db.profile.showMacroText = enable and true
    self.Frame:ForEach('ForButtons', 'SetShowMacroText', enable)
end

function Addon:ShowMacroText()
    return self.db.profile.showMacroText
end

-- equipped item borders
function Addon:SetShowEquippedItemBorders(enable)
    self.db.profile.showEquippedItemBorders = enable and true
    self.Frame:ForEach('ForButtons', 'SetShowEquippedItemBorders', enable)
end

function Addon:ShowEquippedItemBorders()
    return self.db.profile.showEquippedItemBorders
end

-- spell overlay glows
function Addon:SetShowSpellGlows(enable)
    self.db.profile.showSpellGlows = enable and true
    self.callbacks:Fire("SHOW_SPELL_GLOWS_CHANGED", self:ShowingSpellGlows())
end

function Addon:ShowingSpellGlows()
    return self.db.profile.showSpellGlows
end

-- spell animations
function Addon:SetShowSpellAnimations(enable)
    self.db.profile.showSpellAnimations = enable and true
    self.callbacks:Fire("SHOW_SPELL_ANIMATIONS_CHANGED", self:ShowingSpellAnimations())
end

function Addon:ShowingSpellAnimations()
    return self.db.profile.showSpellAnimations
end

-- override ui
function Addon:SetUseOverrideUI(enable)
    self.db.profile.useOverrideUI = enable and true
    self.callbacks:Fire("USE_OVERRRIDE_UI_CHANGED", self:UsingOverrideUI())
end

function Addon:UsingOverrideUI()
    return self.db.profile.useOverrideUI and self:IsBuild('retail', 'wrath')
end

-- override action bar selection
function Addon:SetOverrideBar(id)
    local prevBar = self:GetOverrideBar()

    self.db.profile.possessBar = id
    local newBar = self:GetOverrideBar()

    prevBar:UpdateOverrideBar()
    newBar:UpdateOverrideBar()

    self.callbacks:Fire('OVERRIDE_BAR_UPDATED', newBar)
end

function Addon:GetOverrideBar()
    return self.Frame:Get(self.db.profile.possessBar)
end

-- action bar counts
function Addon:SetNumBars(count)
    count = Clamp(count, 1, self.ACTION_BUTTON_COUNT)

    if count ~= self:NumBars() then
        self.db.profile.ab.count = count
        self.callbacks:Fire('ACTIONBAR_COUNT_UPDATED', count)
    end
end

function Addon:SetNumButtons(count)
    self:SetNumBars(self.ACTION_BUTTON_COUNT / count)
end

function Addon:NumBars()
    return self.db.profile.ab.count
end

-- tooltips
function Addon:ShowTooltips()
    return self.db.profile.showTooltips
end

function Addon:SetShowTooltips(enable)
    self.db.profile.showTooltips = enable and true
    self:GetModule('Tooltips'):SetShowTooltips(enable)
end

function Addon:SetShowCombatTooltips(enable)
    self.db.profile.showTooltipsCombat = enable and true
    self:GetModule('Tooltips'):SetShowTooltipsInCombat(enable)
end

function Addon:ShowCombatTooltips()
    return self.db.profile.showTooltipsCombat
end

-- minimap button
function Addon:SetShowMinimap(enable)
    self.db.profile.minimap.hide = not enable
    self:GetModule('Launcher'):Update()
end

function Addon:ShowingMinimap()
    return not self.db.profile.minimap.hide
end

-- sticky bars
function Addon:SetSticky(enable)
    self.db.profile.sticky = enable and true

    if not enable then
        self.Frame:ForEach('Stick')
        self.Frame:ForEach('Reposition')
    end
end

function Addon:Sticky()
    return self.db.profile.sticky
end

-- linked opacity
function Addon:SetLinkedOpacity(enable)
    self.db.profile.linkedOpacity = enable and true

    self.Frame:ForEach('UpdateWatched')
    self.Frame:ForEach('UpdateAlpha')
end

function Addon:IsLinkedOpacityEnabled()
    return self.db.profile.linkedOpacity
end

-- button theming toggle
function Addon:ThemeButtons()
    return self.db.profile.applyButtonTheme
end

function Addon:SetThemeButtons(enable)
    self.db.profile.applyButtonTheme = enable and true
    self:GetModule('ButtonThemer'):Reskin()
end

-- show counts toggle
function Addon:ShowCounts()
    return self.db.profile.showCounts
end

function Addon:SetShowCounts(enable)
    self.db.profile.showCounts = enable and true
    self.Frame:ForEach('ForButtons', 'SetShowCountText', enable)
end

-- alignment grid
function Addon:SetAlignmentGridEnabled(enable)
    self.db.profile.alignmentGrid.enabled = enable
    self.callbacks:Fire('ALIGNMENT_GRID_ENABLED', self:GetAlignmentGridEnabled())
end

function Addon:GetAlignmentGridEnabled()
    return self.db.profile.alignmentGrid.enabled and true
end

function Addon:SetAlignmentGridSize(size)
    self.db.profile.alignmentGrid.size = tonumber(size)
    self.callbacks:Fire('ALIGNMENT_GRID_SIZE_CHANGED', self:GetAlignmentGridSize())
end

function Addon:GetAlignmentGridSize()
    return self.db.profile.alignmentGrid.size
end

function Addon:GetAlignmentGridScale()
    -- due to changes in Dominos_Config\overlay\ui.lua to
    -- function "DrawGrid", grid now displays with perfectly square subdivisions.
    local gridScale = GetScreenHeight() / (Addon:GetAlignmentGridSize() * 2)
    return gridScale, gridScale
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

-- display the current addon build being used
function Addon:PrintVersion()
    self:Printf('%s-%s', ADDON_VERSION, self:GetWowBuild())
end

-- get the current World of Warcraft build being used
function Addon:GetWowBuild()
    local project = WOW_PROJECT_ID

    if project == WOW_PROJECT_MAINLINE then
        return 'retail'
    end

    if project == WOW_PROJECT_CLASSIC then
        return 'classic'
    end

    local exLevel = LE_EXPANSION_LEVEL_CURRENT

    if exLevel == LE_EXPANSION_WRATH_OF_THE_LICH_KING or exLevel == LE_EXPANSION_NORTHREND then
        return 'wrath'
    end

    if exLevel == LE_EXPANSION_BURNING_CRUSADE then
        return 'bcc'
    end

    if exLevel == LE_EXPANSION_CLASSIC then
        return 'classic'
    end

    return 'unknown'
end

-- check if we're running the addon on one of a given set of wow versions
function Addon:IsBuild(...)
    local build = self:GetWowBuild()

    for i = 1, select('#', ...) do
        if build == select(i, ...):lower() then
            return true
        end
    end

    return false
end

function Addon.OnLaunch(_, button)
    if button == 'LeftButton' then
        if IsShiftKeyDown() then
            Addon:ToggleBindingMode()
        else
            Addon:ToggleLockedFrames()
        end
    elseif button == 'RightButton' then
        Addon:ShowOptionsFrame()
    end
end

if type(C_AddOns) == "table" then
    _G[AddonName .. '_Launch'] = Addon.OnLaunch
end

-- exports
-- luacheck: push ignore 122
_G[AddonName] = Addon
-- luacheck: pop
