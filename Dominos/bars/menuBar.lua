--------------------------------------------------------------------------------
-- Menu Bar, by Goranaws
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local MicroButtons = {}
local PetMicroButtonFrame = PetBattleFrame and PetBattleFrame.BottomFrame.MicroButtonFrame

if MicroMenu then
    local function registerButtons(t, ...)
        for i = 1, select('#', ...) do
            local button = select(i, ...)

            -- always reparent the button
            if Addon:IsBuild("retail") then
                button:SetParent(Addon.ShadowUIParent)
            end

            -- ...but only display it on our bar if it was already enabled
            if button:IsShown() then
                t[#t + 1] = button
            end
        end
    end

    registerButtons(MicroButtons, MicroMenu:GetChildren())
else
    for _, buttonName in ipairs{
        "CharacterMicroButton",
        "SpellbookMicroButton",
        "TalentMicroButton",
        "AchievementMicroButton",
        "QuestLogMicroButton",
        "SocialsMicroButton",
        "GuildMicroButton",
        "PVPMicroButton",
        "LFGMicroButton",
        "CollectionsMicroButton",
        "EJMicroButton",
        "WorldMapMicroButton",
        "StoreMicroButton",
        "MainMenuMicroButton",
        "HelpMicroButton"
    } do
        local button = _G[buttonName]

        if button then
            MicroButtons[#MicroButtons + 1] = button
        end
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

if Addon:IsBuild("retail", "tbc") then
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
else
    function MenuBar:Layout()
        for _, button in pairs(MicroButtons) do
            button:Hide()
        end
        self:UpdateActiveButtons()

        if OverrideActionBar and OverrideActionBar:IsVisible() then
            local l, r, t, b = self:GetButtonInsets()

            for i, button in pairs(self.activeButtons) do
                if i > 1 then
                    button:ClearAllPoints()

                    if i == 7 then
                        button:SetPoint('TOPLEFT', self.activeButtons[1], 'BOTTOMLEFT', 0, (t - b) + 3)
                    else
                        button:SetPoint('BOTTOMLEFT', self.activeButtons[i - 1], 'BOTTOMRIGHT', (l - r) - 1, 0)
                    end
                end

                button:Show()
            end
        elseif PetMicroButtonFrame and PetMicroButtonFrame:IsVisible() then
            local l, r, t, b = self:GetButtonInsets()

            for i, button in pairs(self.activeButtons) do
                if i > 1 then
                    button:ClearAllPoints()

                    if i == 7 then
                        button:SetPoint('TOPLEFT', self.activeButtons[1], 'BOTTOMLEFT', 0, (t - b) + 3)
                    else
                        button:SetPoint('BOTTOMLEFT', self.activeButtons[i - 1], 'BOTTOMRIGHT', (l - r) - 1, 0)
                    end
                end

                button:Show()
            end
        else
            for _, button in pairs(self.activeButtons) do
                button:Show()
            end

            MenuBar.proto.Layout(self)
        end
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

    local layout = Addon:Debounce(function()
        local frame = self.frame
        if frame then
            self.frame:Layout()
        end
    end)

    hooksecurefunc("UpdateMicroButtons", layout)

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

    if OverrideActionBar then
        local f = CreateFrame("Frame", nil, OverrideActionBar)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end

    if PetMicroButtonFrame then
        local f = CreateFrame("Frame", nil, PetMicroButtonFrame)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end

    -- a consistent bug in classic era, AchievementFrameAchievements_OnEvent
    -- tries to call a function that does not exist
    if not (Addon:IsBuild('retail') or type(AchievementMicroButton_Update) == 'function') then
        AchievementMicroButton_Update = function() end
    end
end
