--------------------------------------------------------------------------------
-- Menu Bar, by Goranaws
-- A movable bar for the micro menu buttons
-- Things get a bit trickier with this one, as the buttons shift around when
-- entering a pet battle, or using the override UI
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local MicroButtons = { }
local PetMicroButtonFrame

if Addon:IsBuild('retail') then
    local function registerButtons(...)
        for i = 1, select('#', ...) do
            local button = select(i, ...)

            if button:IsShown() then
                MicroButtons[#MicroButtons+1] = button
            end
        end
    end

    registerButtons(MicroMenu:GetChildren())

    PetMicroButtonFrame = PetBattleFrame.BottomFrame.MicroButtonFrame
else
    for _, name in ipairs(MICRO_BUTTONS) do
        local button = _G[name]
        if button then
            MicroButtons[#MicroButtons + 1] = button
        end
    end

    PetMicroButtonFrame = false
end

local MICRO_BUTTON_NAMES = {
    ['CharacterMicroButton'] = CHARACTER_BUTTON,
    ['SpellbookMicroButton'] = SPELLBOOK_ABILITIES_BUTTON,
    ['TalentMicroButton'] = TALENTS_BUTTON,
    ['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
    ['QuestLogMicroButton'] = QUESTLOG_BUTTON,
    ['GuildMicroButton'] = LOOKINGFORGUILD,
    ['LFDMicroButton'] = DUNGEONS_BUTTON,
    ['LFGMicroButton'] = LFG_BUTTON,
    ['EJMicroButton'] = ENCOUNTER_JOURNAL,
    ['MainMenuMicroButton'] = MAINMENU_BUTTON,
    ['StoreMicroButton'] = BLIZZARD_STORE,
    ['CollectionsMicroButton'] = COLLECTIONS,
    ['HelpMicroButton'] = HELP_BUTTON,
    ['SocialsMicroButton'] = SOCIAL_BUTTON,
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
    self.activeButtons = { }
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

function MenuBar:NumButtons()
    return #self.activeButtons
end

function MenuBar:UpdateActiveButtons()
    wipe(self.activeButtons)

    for _, button in ipairs(MicroButtons) do
        if not self:IsMenuButtonDisabled(button) then
            self.activeButtons[#self.activeButtons+1] = button
        end
    end
end

function MenuBar:ReloadButtons()
    self:UpdateActiveButtons()

    MenuBar.proto.ReloadButtons(self)
end

function MenuBar:DisableMenuButton(button, disabled)
    local disabledButtons = self.sets.disabled or {}

    disabledButtons[button:GetName()] = disabled and true
    self.sets.disabled = disabledButtons

    self:ReloadButtons()
end

function MenuBar:IsMenuButtonDisabled(button)
    local disabledButtons = self.sets.disabled

    if disabledButtons then
        return disabledButtons[button:GetName()]
    end

    return false
end

if Addon:IsBuild("retail") then
    function MenuBar:Layout()
        for _, button in pairs(MicroButtons) do
            button:Hide()
        end

        if OverrideActionBar and OverrideActionBar:IsVisible() then
            local l, r, t, b = self:GetButtonInsets()

            for i, button in ipairs(MicroButtons) do
                button:ClearAllPoints()
                button:SetParent(OverrideActionBar)

                if i == 1 then
                    local x, y = OverrideActionBar:GetMicroButtonAnchor()

                    x = x - 12
                    y = y + button:GetHeight()

                    button:SetPoint('BOTTOMLEFT', x, y)
                elseif i == 7 then
                    button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, (t - b) - 3)
                else
                    button:SetPoint('BOTTOMLEFT', MicroButtons[i - 1], 'BOTTOMRIGHT', (l - r) + 6, 0)
                end

                button:Show()
            end
        elseif PetMicroButtonFrame and PetMicroButtonFrame:IsVisible() then
            local l, r, t, b = self:GetButtonInsets()

            for i, button in ipairs(MicroButtons) do
                button:ClearAllPoints()
                button:SetParent(PetMicroButtonFrame)

                if i == 1 then
                    button:SetPoint('BOTTOMLEFT', -9, button:GetHeight())
                elseif i == 7 then
                    button:SetPoint('TOPLEFT', MicroButtons[1], 'BOTTOMLEFT', 0, (t - b) - 3)
                else
                    button:SetPoint('BOTTOMLEFT', MicroButtons[i - 1], 'BOTTOMRIGHT', (l - r) + 8, 0)
                end

                button:Show()
            end
        else
            for _, button in pairs(self.buttons) do
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
                        button:SetPoint('TOPLEFT', self.activeButtons[1], 'BOTTOMLEFT', 0, (b - t) + 3)
                    else
                        button:SetPoint('BOTTOMLEFT', self.activeButtons[i - 1], 'BOTTOMRIGHT', (l - r) - 1, 0)
                    end
                end

                button:Show()
            end
        else
            for _, button in pairs(self.buttons) do
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

local function MenuButtonCheckbox_Create(panel, button, name)
    if not button then
        return
    end

    return panel:NewCheckButton {
        name = name or button:GetName(),

        get = function()
            return not panel.owner:IsMenuButtonDisabled(button)
        end,

        set = function(_, enable)
            panel.owner:DisableMenuButton(button, not enable)
        end
    }
end

local function Menu_AddDisableMenuButtonsPanel(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(L.Buttons)
    local width, height = 0, 0
    local prev = nil

    for _, microButton in ipairs(MicroButtons) do
        local button = MenuButtonCheckbox_Create(panel, microButton, MICRO_BUTTON_NAMES[microButton:GetName()])

        if button then
            if prev then
                button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -2)
            else
                button:SetPoint('TOPLEFT', 0, -2)
            end

            local bWidth, bHeight = button:GetEffectiveSize()

            width = math.max(width, bWidth)
            height = height + (bHeight + 2)

            prev = button
        end
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

function MenuBarModule:OnInitialize()
    -- the performance bar actually appears under the game menu button if you
    -- move it somewhere else
    local perf = MainMenuMicroButton and MainMenuMicroButton.MainMenuBarPerformanceBar
    if perf then
        perf:ClearAllPoints()
        perf:SetPoint('BOTTOM', 0, 0)
    end

    local function layout()
        local frame = self.frame
        if frame then
            self.frame:Layout()
        end
    end

    hooksecurefunc("UpdateMicroButtons", layout)

    if OverrideActionBar then
        local f = CreateFrame('Frame', nil, OverrideActionBar)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end

    if PetMicroButtonFrame then
        local f = CreateFrame('Frame', nil, PetMicroButtonFrame)
        f:SetScript("OnShow", layout)
        f:SetScript("OnHide", layout)
    end
end

function MenuBarModule:Load()
    self.frame = MenuBar:New()
end

function MenuBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end
