-- The context menu of a bar. Each bar has its own, made the first time it is
-- opened, so several can be open at once and a menu always edits the same bar.
-- A menu is only the frame around its panel's controls. The controls come from
-- the pool when a panel is shown, and go back when the panel is left or the
-- menu is hidden, so closed menus cost little.

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local ConfigLocale = Addon:GetLocale()

local CONTENT_WIDTH, CONTENT_HEIGHT = 280, 410
local SECTION_PADDING = 8

local menus = {} -- bar -> its menu
local open = {} -- the menus being shown

local Manager = {}
Addon.ContextMenus = Manager

local MenuMixin = {}

MenuMixin.minimumWidth = 320
MenuMixin.topPadding = 30
MenuMixin.bottomPadding = 12
MenuMixin.leftPadding = 12
MenuMixin.rightPadding = 12
MenuMixin.spacing = 0

local function isDescendantOf(region, ancestor)
    while region do
        if region == ancestor then
            return true
        end

        region = region:GetParent()
    end

    return false
end

local function lookup(locale, text)
    local value = locale and rawget(locale, text)

    if value == true then
        return text
    end

    return value
end

--------------------------------------------------------------------------------
-- What controls call to read and write the bar
--------------------------------------------------------------------------------

-- a method name is called on the bar, a function with the bar, and anything
-- else is the value
function MenuMixin:Resolve(value)
    local owner = self.owner

    if type(value) == 'string' then
        local method = owner[value]

        if type(method) ~= 'function' then
            error(('Context menu refers to %q, which %s does not have'):format(value, tostring(owner.id or owner)), 2)
        end

        return method(owner)
    elseif type(value) == 'function' then
        return value(owner)
    end

    return value
end

function MenuMixin:GetValue(def)
    return self:Resolve(def.get)
end

function MenuMixin:SetValue(def, value)
    local owner = self.owner
    local set = def.set

    if type(set) == 'string' then
        local method = owner[set]

        if type(method) ~= 'function' then
            error(('Context menu refers to %q, which %s does not have'):format(set, tostring(owner.id or owner)), 2)
        end

        method(owner, value)
    else
        set(owner, value)
    end

    -- other controls, and other bars' menus, may depend on this
    Manager:MarkDirty()
end

-- text is a key of the control's locale, then of the config locale. anything
-- else (a game string, a name already translated) is shown as it is
function MenuMixin:Localize(text, locale)
    if type(text) ~= 'string' then
        return text
    end

    if locale then
        local L = LibStub('AceLocale-3.0'):GetLocale(locale, true)
        local value = lookup(L, text)

        if value then
            return value
        end
    end

    return lookup(ConfigLocale, text) or text
end

--------------------------------------------------------------------------------
-- Showing a panel
--------------------------------------------------------------------------------

-- text inputs apply their value when they lose focus. do that before the
-- controls are given up
function MenuMixin:CommitEdits()
    local focus = GetCurrentKeyBoardFocus()

    if focus and isDescendantOf(focus, self) then
        focus:ClearFocus()
    end
end

-- scrolls the panel just far enough to show a control
function MenuMixin:ScrollIntoView(control)
    local scroll = self.Settings
    local top, bottom = scroll:GetTop(), scroll:GetBottom()
    local controlTop, controlBottom = control:GetTop(), control:GetBottom()

    -- nothing to go by until the layout has run
    if not (top and bottom and controlTop and controlBottom) then
        return
    end

    local offset = scroll:GetVerticalScroll()

    if controlTop > top then
        scroll:SetVerticalScroll(math.max(0, offset - (controlTop - top)))
    elseif controlBottom < bottom then
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScrollRange(), offset + (bottom - controlBottom)))
    end
end

-- tab goes to the next control on this panel that takes typing, shift tab to the
-- one before it, and either wraps around
function MenuMixin:FocusNextEditBox(current, backwards)
    local typing = {}
    local index

    for _, control in ipairs(self.controls) do
        if Addon:GetControlEditBox(control) then
            typing[#typing + 1] = control

            if control == current then
                index = #typing
            end
        end
    end

    if index and #typing > 1 then
        local nextControl = typing[(index - 1 + (backwards and -1 or 1)) % #typing + 1]

        self:ScrollIntoView(nextControl)
        Addon:GetControlEditBox(nextControl):SetFocus()
    end
end

function MenuMixin:ReleaseControls()
    local controls = self.controls

    for i = #controls, 1, -1 do
        Addon:ReleaseControl(controls[i])
        controls[i] = nil
    end
end

function MenuMixin:GetPanel(id)
    for _, panel in ipairs(self.contextMenu) do
        if panel.id == id then
            return panel
        end
    end
end

function MenuMixin:BuildPanel(id)
    self:CommitEdits()
    self:ReleaseControls()

    local panel = self:GetPanel(id)

    if panel then
        for index, def in ipairs(Addon:GetPanelControls(panel, self)) do
            local control = Addon:AcquireControl(def, self.Content, self)

            control.layoutIndex = index

            -- space out sections, but not above the first control
            if def.type == 'header' and index > 1 then
                control.topPadding = SECTION_PADDING
            end

            self.controls[index] = control
        end
    end

    self.Content:MarkDirty()
    self.Settings:SetContent(self.Content)
end

function MenuMixin:RefreshControls()
    for _, control in ipairs(self.controls) do
        Addon:RefreshControl(control)
    end
end

function MenuMixin:Rebuild()
    local id = self.Selector.currentPanelID

    if id then
        self:BuildPanel(id)
    end
end

-- a change to the bar can make controls available or not, such as columns
-- once a bar has more than one button. true if the panel shown no longer has
-- the controls it should
function MenuMixin:NeedsRebuild()
    local panel = self:GetPanel(self.Selector.currentPanelID)

    if not panel then
        return false
    end

    local defs = Addon:GetPanelControls(panel, self)
    local controls = self.controls

    if #defs ~= #controls then
        return true
    end

    for index, def in ipairs(defs) do
        if controls[index].def.name ~= def.name then
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- The frame
--------------------------------------------------------------------------------

function MenuMixin:Anchor()
    local frame = self.owner
    local ratio = UIParent:GetScale() / frame:GetEffectiveScale()
    local x = frame:GetLeft() / ratio
    local y = frame:GetTop() / ratio

    self:ClearAllPoints()
    self:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', x, y)
end

-- always starts on the first panel
function MenuMixin:Open()
    self:Hide()
    self.TitleBar:Setup(self.owner:GetDisplayName())
    self:Anchor()

    self.Selector.currentPanelID = nil
    self:Show()
    self:Raise()
    self.Selector:Select(self.contextMenu[1].id)
end

function MenuMixin:OnShowMenu()
    open[self] = true

    if self.owner.OnMenuShown then
        self.owner:OnMenuShown()
    end
end

function MenuMixin:OnHideMenu()
    self:CommitEdits()
    self:ReleaseControls()

    open[self] = nil

    if self.owner.OnMenuHidden then
        self.owner:OnMenuHidden()
    end
end

function MenuMixin:Initialize(owner)
    self.owner = owner
    self.contextMenu = owner.contextMenu
    self.controls = {}

    self:EnableKeyboard(false)
    self:EnableMouse(true)
    self:SetClampedToScreen(true)
    self:SetFrameStrata('DIALOG')
    self:SetMovable(true)
    self:SetToplevel(true)

    self.TitleBar = CreateFrame('Frame', nil, self, 'DialogHeaderTemplate, TitleDragAreaTemplate')
    self.TitleBar.ignoreInLayout = true

    self.Border = CreateFrame('Frame', nil, self, 'DialogBorderTranslucentTemplate')
    self.Border:SetFrameLevel(self.TitleBar:GetFrameLevel() + 1)
    self.Border.ignoreInLayout = true

    self.CloseButton = CreateFrame('Button', nil, self, 'UIPanelCloseButton')

    local closeOffset = Addon:IsGameType('vanilla') and 8 or 2
    self.CloseButton:SetPoint('TOPRIGHT', closeOffset, closeOffset)

    self.CloseButton:SetFrameLevel(self.TitleBar:GetFrameLevel() + 10)
    self.CloseButton.ignoreInLayout = true

    local selector = Addon:CreatePanelSelector(self)
    selector.OnSelect = function(_, id) self:BuildPanel(id) end
    selector:SetFixedHeight(CONTENT_HEIGHT)
    selector.layoutIndex = 1
    self.Selector = selector

    for _, panel in ipairs(self.contextMenu) do
        selector:AddPanel(panel.id, self:Localize(panel.name, panel.locale))
    end

    local settings = Addon:CreateScrollableContainer(self)
    settings:SetFixedSize(CONTENT_WIDTH, CONTENT_HEIGHT)
    settings.layoutIndex = 2
    self.Settings = settings

    local content = CreateFrame('Frame', nil, settings, 'VerticalLayoutFrame')
    content.spacing = 8
    content.topPadding = 8
    content.bottomPadding = 4
    content.leftPadding = 4
    content.rightPadding = 4
    content.fixedWidth = settings.fixedWidth
    self.Content = content

    -- hidden before the scripts exist, so the bar isn't told it was hidden
    self:Hide()
    self:HookScript('OnShow', self.OnShowMenu)
    self:HookScript('OnHide', self.OnHideMenu)

    self:MarkDirty()
end

local function createMenu(owner)
    local menu = CreateFrame('Frame', nil, UIParent, 'HorizontalLayoutFrame')

    Mixin(menu, MenuMixin)
    menu:Initialize(owner)

    return menu
end

--------------------------------------------------------------------------------
-- All the menus
--------------------------------------------------------------------------------

function Manager:Open(owner)
    assert(owner.contextMenu, ('%s has no context menu'):format(tostring(owner.id or owner)))

    local menu = menus[owner]

    if not menu then
        menu = createMenu(owner)
        menus[owner] = menu
    end

    menu:Open()
end

-- every shown menu is read again on the next frame, so that a change made in
-- one is shown in the rest
local refresher = CreateFrame('Frame')

refresher:Hide()
refresher:SetScript('OnUpdate', function(self)
    self:Hide()

    for menu in pairs(open) do
        menu:RefreshControls()

        if menu:NeedsRebuild() then
            -- rebuilding gives up the control being dragged or typed in, so
            -- wait until the user is done with it
            local focus = GetCurrentKeyBoardFocus()

            if IsMouseButtonDown('LeftButton') or (focus and isDescendantOf(focus, menu)) then
                self:Show()
            else
                menu:Rebuild()
            end
        end
    end
end)

function Manager:MarkDirty()
    refresher:Show()
end

function Manager:CloseAll()
    for menu in pairs(open) do
        menu:Hide()
    end
end

-- bars are reused by id, so a freed bar still looks fine. ask what is active
function Manager:CloseFreed()
    for menu in pairs(open) do
        local owner = menu.owner

        if ParentAddon.Frame:Get(owner.id) ~= owner then
            menu:Hide()
        end
    end
end

function Manager:ACTIONBAR_COUNT_UPDATED()
    -- the bars are freed by another handler of this event, and handlers run in
    -- no set order. so look on the next frame
    C_Timer.After(0, function()
        self:CloseFreed()

        -- the lists of some panels depend on how many bars there are
        for menu in pairs(open) do
            menu:Rebuild()
        end
    end)
end

function Manager:LAYOUT_UNLOADING()
    self:CloseAll()
end

ParentAddon.RegisterCallback(Manager, 'ACTIONBAR_COUNT_UPDATED')
ParentAddon.RegisterCallback(Manager, 'LAYOUT_UNLOADING')
