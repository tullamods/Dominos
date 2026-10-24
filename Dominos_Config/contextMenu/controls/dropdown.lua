-- a labeled drop down list. the font and texture controls are drop downs whose
-- items come from LibSharedMedia

local _, Addon = ...

local function itemValue(item)
    if type(item) == 'table' then
        return item.value
    end

    return item
end

local function itemLabel(control, item)
    local text = item

    if type(item) == 'table' then
        text = item.text

        if text == nil then
            text = item.value
        end
    end

    -- a function gets the value, so that one list can be shown different ways
    if type(text) == 'function' then
        text = text(itemValue(item))
    end

    return control.menu:Localize(text, control.def.locale)
end

--- @param name string the control type
--- @param source { items: function, getValue: function?, initItem: function? }
---     items(control) returns the list. getValue(control) returns the selected
---     value, and defaults to asking the bar. initItem(button, value) styles a
---     menu entry
local function registerDropdown(name, source)
    local function getValue(control)
        if source.getValue then
            return source.getValue(control)
        end

        return control.menu:GetValue(control.def)
    end

    local function refresh(control)
        local value = getValue(control)

        -- regenerating the menu is what re-reads the selected value
        if not control.synced or control.value ~= value then
            control.synced = true
            control.value = value
            control.Dropdown:GenerateMenu()
        end
    end

    local function create(parent)
        local control = CreateFrame('Button', nil, parent, 'ResizeLayoutFrame')

        control.leftPadding = 2
        control.rightPadding = 2
        control.topPadding = 2
        control.bottomPadding = 2
        control.expand = true

        local dropdown = CreateFrame('DropdownButton', nil, control, 'WowStyle1DropdownTemplate')
        dropdown.expand = true
        control.Dropdown = dropdown

        local label = control:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
        label:SetPoint('LEFT')
        label:SetJustifyH('LEFT')
        label:SetJustifyV('MIDDLE')
        label:SetText('X')
        label:SetSize(120, label:GetStringHeight())
        control.Label = label

        dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
        dropdown:SetPoint('RIGHT')

        control:SetFixedHeight(max(dropdown:GetHeight() or -math.huge, label:GetStringHeight()))
        control:MarkDirty()

        control:SetScript('OnEnter', function()
            if control.def then
                refresh(control)
            end

            Addon:ShowControlTooltip(control)
        end)
        
        control:SetScript('OnLeave', function()
            Addon:HideControlTooltip(control)
        end)

        return control
    end

    local function generateMenu(control)
        return function(_, rootDescription)
            rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)

            local items = source.items(control) or {}

            control.items = items

            for i, item in ipairs(items) do
                local radio = rootDescription:CreateRadio(
                    itemLabel(control, item),
                    function(index) return itemValue(control.items[index]) == getValue(control) end,
                    function(index)
                        local value = itemValue(control.items[index])

                        control.value = value
                        control.menu:SetValue(control.def, value)
                    end,
                    i
                )

                if source.initItem then
                    local value = itemValue(item)

                    radio:AddInitializer(function(button)
                        source.initItem(button, value)
                    end)
                end
            end
        end
    end

    local function bind(control)
        local def = control.def

        control.Label:SetText(control.menu:Localize(def.name, def.locale))
        control.synced = false

        -- the menu is set up once, here, since setting it up reads the value
        if not control.Dropdown:GetMenuDescription() then
            control.Dropdown:SetupMenu(generateMenu(control))
            control.synced = true
            control.value = getValue(control)
        elseif control:IsShown() then
            refresh(control)
        else
            -- the dropdown regenerates its menu when it is shown
            control.synced = true
            control.value = getValue(control)
        end
    end

    local function release(control)
        if control.Dropdown.CloseMenu then
            control.Dropdown:CloseMenu()
        end

        Addon:HideControlTooltip(control)

        control.synced = false
        control.value = nil
        control.items = nil
    end

    Addon:RegisterControlType(name, {
        Create = create,
        Bind = bind,
        Refresh = refresh,
        Release = release
    })
end

registerDropdown('dropdown', {
    items = function(control)
        return control.menu:Resolve(control.def.items)
    end
})

-- media settings may be missing or refer to media that isn't registered (ex,
-- old lowercase defaults). LibSharedMedia falls back to its default in that
-- case, so show that as the selected value
local function validMedia(mediaType)
    return function(control)
        local LSM = LibStub('LibSharedMedia-3.0')
        local value = control.menu:GetValue(control.def)

        if value and LSM:IsValid(mediaType, value) then
            return value
        end

        return LSM:GetDefault(mediaType)
    end
end

registerDropdown('texture', {
    items = function()
        return LibStub('LibSharedMedia-3.0'):List('statusbar')
    end,
    getValue = validMedia('statusbar')
})

registerDropdown('font', {
    items = function()
        return Addon.Fonts:GetAll()
    end,
    getValue = validMedia('font'),
    -- preview each font in the menu using the font itself
    initItem = function(button, fontID)
        local font = Addon.Fonts:GetFontObject(fontID)

        if font then
            button.fontString:SetFontObject(font)
            button.fontString:SetText(fontID)
        end
    end
})
