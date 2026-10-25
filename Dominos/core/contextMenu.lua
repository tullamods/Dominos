-- A context menu described as plain data: an ordered list of panels. Each panel
-- is { id, name?, controls, locale? }, and its name is its id unless it says
-- otherwise. Its controls are a list (or a function of the owner that returns
-- one) of registry keys, inline controls and headers. Names are locale keys, so
-- declaring one needs nothing from the config addon.
--
-- A context menu is immutable. Extend returns a new one.

local _, Addon = ...

local ContextMenu = {}
ContextMenu.__index = ContextMenu

-- checks return an error message, or nil. the public functions raise it once, at
-- the caller, so the error points at the file that declared the menu

local function controlError(panelId, control)
    if type(control) == 'string' then
        return
    end

    if type(control) ~= 'table' or type(control.type) ~= 'string' then
        return ('panel %q has a control that is not a registry key or a table with a type'):format(panelId)
    end

    if not control.name then
        return ('panel %q has a %q control without a name'):format(panelId, control.type)
    end

    if control.type ~= 'header' and not (control.get and control.set) then
        return ('panel %q control %q needs get and set'):format(panelId, tostring(control.name))
    end
end

local function controlsError(panelId, controls)
    if type(controls) == 'function' then
        return
    end

    if type(controls) ~= 'table' then
        return ('panel %q needs controls as a list or a function'):format(panelId)
    end

    for _, control in ipairs(controls) do
        local err = controlError(panelId, control)

        if err then
            return err
        end
    end
end

local function panelError(def)
    if type(def.id) ~= 'string' then
        return 'a panel needs a string id'
    end

    return controlsError(def.id, def.controls)
end

local function indexOf(panels, id)
    for i, panel in ipairs(panels) do
        if panel.id == id then
            return i
        end
    end
end

-- the panel owns its controls list, so inserts never reach the menu it came from
local function newPanel(def)
    local controls = def.controls

    return {
        id = def.id,
        name = def.name or def.id,
        locale = def.locale,
        controls = type(controls) == 'table' and CopyTable(controls, true) or controls
    }
end

local function applyAddPanel(panels, op)
    local def = { id = op.addPanel, name = op.name, controls = op.controls, locale = op.locale }
    local err = panelError(def)

    if err then
        return err
    end

    if indexOf(panels, def.id) then
        return ('panel %q already exists'):format(def.id)
    end

    local after = indexOf(panels, op.after)

    if not after then
        return ('cannot add panel %q after %q, which does not exist'):format(def.id, tostring(op.after))
    end

    table.insert(panels, after + 1, newPanel(def))
end

local function applyInsert(panels, op)
    local index = indexOf(panels, op.insert)

    if not index then
        return ('cannot insert into panel %q, which does not exist'):format(tostring(op.insert))
    end

    local panel = panels[index]

    if type(panel.controls) ~= 'table' then
        return ('cannot insert into panel %q, whose controls are a function'):format(op.insert)
    end

    local before = op.before and tIndexOf(panel.controls, op.before)

    if op.before and not before then
        return ('cannot insert before control %q in panel %q, which does not have it'):format(tostring(op.before), op.insert)
    end

    if not before and op.at ~= 'start' and op.at ~= 'end' then
        return ('insert into panel %q needs at = "start" or "end", or before = a control'):format(op.insert)
    end

    if type(op.controls) ~= 'table' then
        return ('insert into panel %q needs a list of controls'):format(op.insert)
    end

    local err = controlsError(op.insert, op.controls)

    if err then
        return err
    end

    local merged = CopyTable(panel.controls, true)
    local first = before or (op.at == 'start' and 1 or #merged + 1)

    for i, control in ipairs(CopyTable(op.controls, true)) do
        table.insert(merged, first + i - 1, control)
    end

    panel.controls = merged
end

--- @param ops table[] each is { addPanel = id, after = id, name, controls, locale? }
---     or { insert = panelId, at = 'start' | 'end', or before = registry key, controls }
function ContextMenu:Extend(ops)
    local panels = {}

    for i, panel in ipairs(self) do
        panels[i] = newPanel(panel)
    end

    for _, op in ipairs(ops) do
        local err

        if op.addPanel then
            err = applyAddPanel(panels, op)
        elseif op.insert then
            err = applyInsert(panels, op)
        else
            err = 'an Extend operation needs addPanel or insert'
        end

        if err then
            error('Context menu: ' .. err, 2)
        end
    end

    return setmetatable(panels, ContextMenu)
end

--- @param defs { id: string, name: string?, controls: table|function, locale: string? }[]
setmetatable(ContextMenu, {
    __call = function(_, defs)
        local panels = {}

        for i, def in ipairs(defs) do
            local err = panelError(def)

            if not err and indexOf(panels, def.id) then
                err = ('duplicate panel %q'):format(def.id)
            end

            if err then
                error('Context menu: ' .. err, 2)
            end

            panels[i] = newPanel(def)
        end

        return setmetatable(panels, ContextMenu)
    end
})

Addon.ContextMenu = ContextMenu
