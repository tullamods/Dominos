-- Works out which controls a panel of a context menu shows for its bar:
-- registry keys become definitions, controls take their panel's locale, and
-- anything not available is left out

local _, Addon = ...

local function available(menu, def)
    return def.available == nil or menu:Resolve(def.available)
end

-- a control with no locale of its own uses its panel's. definitions are shared,
-- so they are copied rather than changed
local function withLocale(def, locale)
    if locale and not def.locale then
        def = CopyTable(def, true)
        def.locale = locale
    end

    return def
end

--- @param panel table a panel of a context menu
--- @param menu table has Resolve(value), which asks the bar
--- @return table[] definitions, in order
function Addon:GetPanelControls(panel, menu)
    local controls = panel.controls

    if type(controls) == 'function' then
        controls = controls(menu.owner)
    end

    local result = {}
    local header

    -- a header starts a section. it is shown with the first control that is
    -- available in it, and if the header is not available neither is the section
    local skipping = false

    for _, control in ipairs(controls) do
        local def = control

        if type(control) == 'string' then
            def = Addon.Controls[control]
            assert(def, ('Panel %q refers to the unknown control %q'):format(panel.id, control))
        end

        def = withLocale(def, panel.locale)

        if def.type == 'header' then
            skipping = not available(menu, def)
            header = not skipping and def or nil
        elseif not skipping and available(menu, def) then
            if header then
                result[#result + 1] = header
                header = nil
            end

            result[#result + 1] = def
        end
    end

    return result
end
