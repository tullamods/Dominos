--------------------------------------------------------------------------------
-- Menu Bar, by Goranaws
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local PetMicroButtonFrame = PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame

local MicroButtons = {}
for _, buttonInfo in ipairs(MicroMenu:GenerateButtonInfos()) do
    local skip
    if buttonInfo.gameRule then
        skip = C_GameRules.IsGameRuleActive(buttonInfo.gameRule)
    elseif buttonInfo.callback then
        skip = buttonInfo.callback()
    else
        skip = false
    end

    -- drop layout index to fix issues with UpdateHelpTicketButtonAnchor calls
    local button = buttonInfo.button
    if button.layoutIndex ~= nil then
        button.layoutIndex = nil
    end

    -- two hacks:
    -- use button:IsShown to better handle some of the conditional buttons
    -- allow the talent button to show up even if you don't yet have talents
    if not skip and (button:IsShown() or button == TalentMicroButton) then
        MicroButtons[#MicroButtons + 1] = button
    end
end

local MICRO_BUTTON_NAMES = {
    ['ProfessionMicroButton'] = PROFESSIONS_BUTTON,
    ['PlayerSpellsMicroButton'] = PLAYERSPELLS_BUTTON,
    ['HousingMicroButton'] = HOUSING_MICRO_BUTTON,
    ['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
    ['CharacterMicroButton'] = CHARACTER_BUTTON,
    ['CollectionsMicroButton'] = COLLECTIONS,
    ['EJMicroButton'] = ENCOUNTER_JOURNAL,
    ['GuildMicroButton'] = LOOKINGFORGUILD,
    ['HelpMicroButton'] = HELP_BUTTON,
    ['LFDMicroButton'] = DUNGEONS_BUTTON,
    ['LFGMicroButton'] = LFG_BUTTON,
    ['MainMenuMicroButton'] = MAINMENU_BUTTON,
    ['PVPMicroButton'] = PLAYER_V_PLAYER,
    ['QuestLogMicroButton'] = QUESTLOG_BUTTON,
    ['SocialsMicroButton'] = SOCIAL_BUTTON,
    ['SpellbookMicroButton'] = SPELLBOOK_ABILITIES_BUTTON,
    ['StoreMicroButton'] = BLIZZARD_STORE,
    ['TalentMicroButton'] = TALENTS_BUTTON,
    ['WorldMapMicroButton'] = WORLDMAP_BUTTON
}

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

function MenuBar:GetDefaults()
    if Addon:IsBuild("retail") then
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

-- 3.4.1 swaps the last two return values of get hit rect insts
-- so just hardcode for now
if (select(4, GetBuildInfo()) == 30401) then
    function MenuBar:GetButtonInsets()
        return 0, 0, 18, 0
    end
end

function MenuBar:NumButtons()
    return #self.activeButtons
end

function MenuBar:UpdateActiveButtons()
    wipe(self.activeButtons)

    for _, button in ipairs(MicroButtons) do
        if self:IsMenuButtonEnabled(button) then
            self.activeButtons[#self.activeButtons + 1] = button
        end
    end
end

function MenuBar:ReloadButtons()
    self:UpdateActiveButtons()

    MenuBar.proto.ReloadButtons(self)
end

function MenuBar:SetEnableMenuButton(button, enabled)
    enabled = enabled and true

    if enabled then
        local disabled = self.sets.disabled

        if disabled then
            disabled[button:GetName()] = false
        end
    else
        local disabled = self.sets.disabled

        if not disabled then
            disabled = {}
            self.sets.disabled = disabled
        end

        disabled[button:GetName()] = true
    end

    self:ReloadButtons()
end

function MenuBar:IsMenuButtonEnabled(button)
    local buttonName = button and button:GetName()
    if not buttonName then
        return false
    end

    local disabledButtons = self.sets.disabled
    if disabledButtons and disabledButtons[buttonName] then
        return false
    end

    if buttonName == "StoreMicroButton" then
        return C_StorePublic.IsEnabled()
    elseif buttonName == "GuildMicroButton" and not Addon:IsBuild("retail") then
        return not C_CVar.GetCVarBool("useClassicGuildUI")
    elseif buttonName == "SocialsMicroButton" and not Addon:IsBuild("retail") then
        return C_CVar.GetCVarBool("useClassicGuildUI")
    elseif buttonName == "HelpMicroButton" then
        return not Addon:IsBuild("mists")
    else
        return true
    end
end

function MenuBar:Layout()
    for _, button in pairs(MicroButtons) do
        button:Hide()
    end

    if OverrideActionBar and OverrideActionBar:IsVisible() then
        for i, button in ipairs(MicroButtons) do
            button:ClearAllPoints()
            button:SetParent(OverrideActionBar)
            button:SetScale(0.8)

            if i == 1 then
                local x, y = OverrideActionBar:GetMicroButtonAnchor()
                button:SetPoint('BOTTOMLEFT', x + button:GetWidth(), y + button:GetHeight())
            elseif i == 7 then
                button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, 0)
            else
                button:SetPoint('BOTTOMLEFT', MicroButtons[i - 1], 'BOTTOMRIGHT', 0, 0)
            end

            button:Show()
        end
    elseif PetMicroButtonFrame and PetMicroButtonFrame:IsVisible() then
        for i, button in ipairs(MicroButtons) do
            button:ClearAllPoints()
            button:SetParent(PetMicroButtonFrame)
            button:SetScale(1)

            if i == 1 then
                button:SetPoint('TOPLEFT', -17, 9)
            elseif i == 7 then
                button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, 6)
            else
                button:SetPoint('TOPLEFT', MicroButtons[i - 1], 'TOPRIGHT', -5, 0)
            end

            button:Show()
        end
    else
        for _, button in pairs(self.buttons) do
            button:SetScale(1)
            button:Show()
        end

        MenuBar.proto.Layout(self)
    end
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

    for _, button in ipairs(MicroButtons) do
        local toggle = panel:NewCheckButton({
            name = MICRO_BUTTON_NAMES[button:GetName()] or button:GetName(),

            get = function()
                return panel.owner:IsMenuButtonEnabled(button)
            end,

            set = function(_, enable)
                panel.owner:SetEnableMenuButton(button, enable)
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

local MenuBarModule = Addon:NewModule('MenuBar')

function MenuBarModule:Load()
    self.frame = MenuBar:New()
end

function MenuBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
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

    -- layout the frame again after an UpdateMicroButtons call, as Blizzard
    -- repositions the buttons at that point
    hooksecurefunc("UpdateMicroButtons", function()
        local f = self.frame
        if f then
            f:Layout()
        end
    end)

    -- ensure that the micro menu remains banished
    -- otherwise, it'll try laying itself out again and trigger an error
    if MicroMenu then
        MicroMenu:SetParent(Addon.ShadowUIParent)

        hooksecurefunc(MicroMenu, "SetParent", function(menu, parent)
            if parent == MicroMenuContainer then
                menu:SetParent(Addon.ShadowUIParent)
            end
        end)

        local function repositionHelpdeskTicketButton()
            if HelpOpenWebTicketButton then
                HelpOpenWebTicketButton:ClearAllPoints()
                HelpOpenWebTicketButton:SetPoint("CENTER", CharacterMicroButton, "CENTER", 0, 20)
            end
        end

        hooksecurefunc(MicroMenu, "UpdateHelpTicketButtonAnchor", repositionHelpdeskTicketButton)
        repositionHelpdeskTicketButton()
    end

    -- banish the micro menu container
    if MicroMenuContainer then
        MicroMenuContainer:SetParent(Addon.ShadowUIParent)
    end

    -- a consistent bug in classic era, AchievementFrameAchievements_OnEvent
    -- tries to call a function that does not exist
    if not (Addon:IsBuild('retail') or type(AchievementMicroButton_Update) == 'function') then
        AchievementMicroButton_Update = function() end
    end
end
