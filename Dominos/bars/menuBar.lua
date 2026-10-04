--------------------------------------------------------------------------------
-- Menu Bar, by Goranaws
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local MicroButtons = {}

-- generate containers for all of the micro buttons
do
    local displayNames = setmetatable(
        {
            ['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
            ['CharacterMicroButton'] = CHARACTER_BUTTON,
            ['CollectionsMicroButton'] = COLLECTIONS,
            ['EJMicroButton'] = ENCOUNTER_JOURNAL,
            ['GuildMicroButton'] = LOOKINGFORGUILD,
            ['HelpMicroButton'] = HELP_BUTTON,
            ['HousingMicroButton'] = HOUSING_MICRO_BUTTON,
            ['LegacyMicroButton'] = LEGACY_BUTTON,
            ['LFDMicroButton'] = DUNGEONS_BUTTON,
            ['LFGMicroButton'] = LFG_BUTTON,
            ['MainMenuMicroButton'] = MAINMENU_BUTTON,
            ['PlayerSpellsMicroButton'] = PLAYERSPELLS_BUTTON,
            ['ProfessionMicroButton'] = PROFESSIONS_BUTTON,
            ['PVPMicroButton'] = PLAYER_V_PLAYER,
            ['QuestLogMicroButton'] = QUESTLOG_BUTTON,
            ['SocialsMicroButton'] = SOCIAL_BUTTON,
            ['SpellbookMicroButton'] = SPELLBOOK_ABILITIES_BUTTON,
            ['StoreMicroButton'] = BLIZZARD_STORE,
            ['TalentMicroButton'] = TALENTS_BUTTON,
            ['WorldMapMicroButton'] = WORLDMAP_BUTTON
        },
        {
            __index = function (t, k)
                Addon:Printf("Error: Missing display name for MicroButton %q", k)
                return k
            end
        }
    )

    local function attach(container)
        local button = container.button

        if button:GetParent() ~= container then
            button:SetParent(container)
            button:ClearAllPoints()
            button:SetPoint('CENTER', container)
            button:SetShown(true)
        end
    end

    local function detach(container)
        local button = container.button

        if button:GetParent() ~= MicroMenu then
            button:SetParent(MicroMenu)
        end
    end

    local function shouldShow(container)
        local buttonInfo = container.buttonInfo

        if buttonInfo.gameRule and C_GameRules.IsGameRuleActive(buttonInfo.gameRule) then
            return false
        end

        if buttonInfo.callback and buttonInfo.callback() then
            return false
        end

        local buttonName = buttonInfo.button:GetName()
        if buttonName == "StoreMicroButton" then
            return C_StorePublic.IsEnabled()
        elseif buttonName == "GuildMicroButton" then
            return not C_CVar.GetCVarBool("useClassicGuildUI")
        elseif buttonName == "SocialsMicroButton" then
            return C_CVar.GetCVarBool("useClassicGuildUI")
        elseif buttonName == "HelpMicroButton" then
            return not C_StorePublic.IsEnabled()
        else
            return true
        end
    end

    for _, buttonInfo in ipairs(MicroMenu:GenerateButtonInfos()) do
        local button = buttonInfo.button
        if button then
            local container = CreateFrame('Frame', ('%s%sContainer'):format(AddonName, button:GetName()),
                Addon.ShadowUIParent)

            container.button = button
            container.buttonInfo = buttonInfo
            container.displayName = displayNames[button:GetName()]
            container.AttachButton = attach
            container.DetachButton = detach
            container.ShouldShow = shouldShow
            container:SetSize(button:GetSize())

            MicroButtons[#MicroButtons + 1] = container
        end
    end
end

--------------------------------------------------------------------------------
-- bar
--------------------------------------------------------------------------------

local MenuBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function MenuBar:New()
    return MenuBar.proto.New(self, 'menu')
end

function MenuBar:GetDisplayName()
    return L.MenuBarDisplayName
end

MenuBar:Extend('OnCreate', function(self)
    self.activeButtons = {}
end)

MenuBar:Extend('OnAttachButton', function(_, button)
    button:SetShown(true)
    button:AttachButton()
end)

MenuBar:Extend('OnDetachButton', function(_, button)
    button:SetShown(false)
    button:DetachButton()
end)

function MenuBar:GetDefaults()
    if Addon:IsGameType("standard") then
        return {
            displayLayer = 'LOW',
            point = 'BOTTOMRIGHT',
            x = 0,
            y = 48
        }
    else
        return {
            displayLayer = 'LOW',
            point = 'BOTTOMRIGHT',
            x = 0,
            y = 0
        }
    end
end

function MenuBar:AcquireButton(index)
    return self.activeButtons[index]
end

function MenuBar:NumButtons()
    return #self.activeButtons
end

function MenuBar:ReloadButtons()
    wipe(self.activeButtons)

    for _, container in ipairs(MicroButtons) do
        if self:IsMenuButtonEnabled(container) then
            self.activeButtons[#self.activeButtons + 1] = container
        end
    end

    MenuBar.proto.ReloadButtons(self)
end

function MenuBar:SetEnableMenuButton(container, enabled)
    local key = container.button:GetName()
    
    enabled = enabled and true

    if enabled then
        local disabled = self.sets.disabled

        if disabled then
            disabled[key] = false
        end
    else
        local disabled = self.sets.disabled

        if not disabled then
            disabled = {}
            self.sets.disabled = disabled
        end

        disabled[key] = true
    end

    self:ReloadButtons()
end

function MenuBar:IsMenuButtonEnabled(container)
    local key = container.button:GetName()
    local disabledButtons = self.sets.disabled
    if disabledButtons and disabledButtons[key] then
        return false
    end

    return container:ShouldShow()
end

-- exports
Addon.MenuBar = MenuBar

--------------------------------------------------------------------------------
-- context menu
--------------------------------------------------------------------------------

local function Menu_AddDisableMenuButtonsPanel(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(L.Buttons)
    local width, height = 0, 0
    local prev = nil

    for _, container in ipairs(MicroButtons) do
        local toggle = panel:NewCheckButton({
            name = container.displayName,

            get = function()
                return panel.owner:IsMenuButtonEnabled(container)
            end,

            set = function(_, enable)
                panel.owner:SetEnableMenuButton(container, enable)
            end
        })

        if prev then
            toggle:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -2)
        else
            toggle:SetPoint('TOPLEFT', 0, -2)
        end

        local bWidth, bHeight = toggle:GetEffectiveSize()

        width = math.max(width, bWidth)
        height = height + (bHeight + 2)

        prev = toggle
    end

    panel.width = width
    panel.height = height

    return panel
end

function MenuBar:OnCreateMenu(menu)
    menu:AddLayoutPanel()
    Menu_AddDisableMenuButtonsPanel(menu)
    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

local MenuBarModule = Addon:NewModule('MenuBar', 'AceEvent-3.0')

function MenuBarModule:Load()
    self.bar = MenuBar:New()
end

function MenuBarModule:Unload()
    if self.bar then
        self.bar:Free()
        self.bar = nil
    end
end

function MenuBarModule:AttachButtons()
    for _, container in ipairs(MicroButtons) do
        container:AttachButton()
    end
end

function MenuBarModule:DetachButtons()
    for _, container in ipairs(MicroButtons) do
        container:DetachButton()
    end
end

function MenuBarModule:OnFirstLoad()
    -- the performance bar actually appears under the game menu button if you
    -- move it somewhere else
    local perf = MainMenuMicroButton and MainMenuMicroButton.MainMenuBarPerformanceBar
    if perf then
        perf:ClearAllPoints()
        perf:SetPoint('BOTTOM', 0, 0)
    end

    -- banish the micro menu container so that it does not show up in edit mode
    if MicroMenuContainer then
        MicroMenuContainer:SetParent(Addon.ShadowUIParent)
    end

    -- attach buttons if the MicroMenu isn't currently part of the override/petbattle ui
    if MicroMenu:GetParent() == MicroMenuContainer or (MicroMenu:GetParent() == OverrideActionBar and Addon:UsingOverrideUI()) then
        self:AttachButtons()
    end

    -- watch for MicroMenu parent changes and attach/detach buttons as needed
    hooksecurefunc(MicroMenu, 'SetParent', function(_, parent)
        if parent == OverrideActionBar and Addon:UsingOverrideUI() then
            self:DetachButtons()
        elseif PetBattleFrame and parent == PetBattleFrame.BottomFrame.MicroButtonFrame and C_PetBattles.IsInBattle() then
            self:DetachButtons()
        else
            self:AttachButtons()
        end
    end)

    -- the pet battle frame doesn't reparent the MicroMenu when exiting, so
    -- so reattach based on the event
    if PetBattleFrame then
        self:RegisterEvent('PET_BATTLE_CLOSE', 'AttachButtons')
    end

    if MicroMenu:GetParent() == MicroMenuContainer then
        self:AttachButtons()
    end

    if MicroMenu.UpdateHelpTicketButtonAnchor then
        local function repositionHelpdeskTicketButton()
            local bar = self.bar
            if not bar then
                return
            end

            if HelpOpenWebTicketButton then
                HelpOpenWebTicketButton:ClearAllPoints()
                HelpOpenWebTicketButton:SetPoint("CENTER", CharacterMicroButton, "CENTER", 0, 20)
            end
        end

        hooksecurefunc(MicroMenu, "UpdateHelpTicketButtonAnchor", repositionHelpdeskTicketButton)
        repositionHelpdeskTicketButton()
    end

    -- a consistent bug in classic era, AchievementFrameAchievements_OnEvent
    -- tries to call a function that does not exist
    if Addon:IsGameType('cata') and AchievementMicroButton_Update == nil then
        AchievementMicroButton_Update = function() end
    end
end