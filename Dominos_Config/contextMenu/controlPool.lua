-- Widgets for the controls of a context menu, reused instead of recreated.
-- Frames are never garbage collected, so a menu takes widgets from here when
-- it shows a panel and gives them back when the panel goes away.
--
-- A control type is registered once with the functions that make and manage its
-- widget. Each takes the widget as its first argument:
--
--   Create(parent)  makes a widget. install scripts here, once, and have them
--                   read widget.def and widget.menu when they run. never
--                   HookScript after this, since hooks can't be removed
--   Bind(widget)    show widget.def: label, limits, tooltip, current value.
--                   widget.def and widget.menu are already set
--   Refresh(widget) read the value again, touching the frame only if it changed
--   Release(widget) optional. forget anything Bind or the user left behind
--   GetEditBox(widget) optional. the edit box of a control that has one, so that
--                   the menu can tab between them
--
-- A definition can also have enabled, resolved like available. while it's false
-- the control stays where it is, dimmed and unclickable, so turning one setting
-- off doesn't make others jump around. the pool does this, not the type
--
-- widget.menu is whatever the control should call to read and write the bar it
-- is showing: menu:GetValue(def), menu:SetValue(def, value),
-- menu:Resolve(value) for limits and item lists, and menu:Localize(text, locale)

local _, Addon = ...

local controlTypes = {}
local freeWidgets = {}

local DISABLED_ALPHA = 0.5

-- a cover over the widget takes its clicks, wheel, and hover while it's off
local function updateEnabled(widget)
    local enabled = widget.def.enabled
    enabled = enabled == nil or not not widget.menu:Resolve(enabled)

    local cover = widget.DisabledCover

    if not (enabled or cover) then
        cover = CreateFrame('Frame', nil, widget)
        cover:SetAllPoints()
        cover:EnableMouse(true)
        cover:EnableMouseWheel(true)
        widget.DisabledCover = cover
    end

    if cover then
        -- over the widget's own children, whatever level they're at
        cover:SetFrameLevel(widget:GetFrameLevel() + 20)
        cover:SetShown(not enabled)
    end

    widget:SetAlpha(enabled and 1 or DISABLED_ALPHA)
end

function Addon:RegisterControlType(name, controlType)
    assert(not controlTypes[name], ('Control type %q is already registered'):format(name))
    assert(controlType.Create, ('Control type %q needs Create'):format(name))
    assert(controlType.Bind, ('Control type %q needs Bind'):format(name))
    assert(controlType.Refresh, ('Control type %q needs Refresh'):format(name))

    controlTypes[name] = controlType
    freeWidgets[name] = {}
end

function Addon:GetControlType(name)
    return controlTypes[name]
end

--- @param def table a control definition
--- @param parent table the frame to show the widget in
--- @param menu table what the widget reads and writes through
function Addon:AcquireControl(def, parent, menu)
    local name = def.type
    local controlType = controlTypes[name]
    assert(controlType, ('Unknown control type %q'):format(tostring(name)))

    local free = freeWidgets[name]
    local widget = table.remove(free)

    if widget then
        widget.inPool = nil
        widget:SetParent(parent)
    else
        widget = controlType.Create(parent)
        widget.controlType = name
    end

    -- a reused widget keeps the level it had under its old parent
    widget:SetFrameLevel(parent:GetFrameLevel() + 1)

    widget.def = def
    widget.menu = menu

    local ok, err = pcall(controlType.Bind, widget)

    if not ok then
        Addon:ReleaseControl(widget)
        error(err, 0)
    end

    updateEnabled(widget)

    widget:Show()

    return widget
end

function Addon:ReleaseControl(widget)
    assert(widget.controlType, 'Not a control widget')
    assert(not widget.inPool, 'Control widget was already released')

    local release = controlTypes[widget.controlType].Release
    if release then
        release(widget)
    end

    widget.def = nil
    widget.menu = nil
    widget.layoutIndex = nil
    widget.inPool = true

    if widget.DisabledCover then
        widget.DisabledCover:Hide()
    end

    widget:SetAlpha(1)

    widget:Hide()
    widget:ClearAllPoints()
    widget:SetParent(nil)

    table.insert(freeWidgets[widget.controlType], widget)
end

-- the edit box of a widget in use, if its type has one
function Addon:GetControlEditBox(widget)
    local getEditBox = controlTypes[widget.controlType].GetEditBox

    return getEditBox and getEditBox(widget)
end

-- re-read the value shown by a widget that is in use
function Addon:RefreshControl(widget)
    controlTypes[widget.controlType].Refresh(widget)
    updateEnabled(widget)
end

-- the tooltip of a control: its name, then the tooltip text, if it has any
-- instruction is an optional how to use line, like right click to reset
function Addon:ShowControlTooltip(control, instruction)
    local def = control.def

    if def and (def.tooltip or instruction) then
        local menu = control.menu

        GameTooltip:SetOwner(control, 'ANCHOR_RIGHT')
        GameTooltip_SetTitle(GameTooltip, menu:Localize(def.name, def.locale))

        if def.tooltip then
            GameTooltip_AddNormalLine(GameTooltip, menu:Localize(def.tooltip, def.locale))
        end

        if instruction then
            GameTooltip_AddInstructionLine(GameTooltip, instruction)
        end

        GameTooltip:Show()
    end
end

function Addon:HideControlTooltip(control)
    if GameTooltip:IsOwned(control) then
        GameTooltip:Hide()
    end
end
