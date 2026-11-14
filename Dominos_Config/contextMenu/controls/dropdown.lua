-- a labeled drop down list. the border, font, and texture controls are drop downs whose
-- items come from LibSharedMedia. their def.default is the text of an entry
-- that goes first and stands for no media, which the bar reads as false

local AddonName, Addon = ...
local LSM = LibStub('LibSharedMedia-3.0')

-- font objects for previewing fonts in the menu, made as they are needed
local fontObjects = setmetatable({}, {
    __index = function(t, k)
        local fontPath = LSM:Fetch('font', k, false)

        if fontPath then
            local font = CreateFont(('%sFonts%s'):format(AddonName, k))

            -- shared media can list fonts this client doesn't have, and
            -- SetFont errors on those
            local ok, loaded = pcall(font.SetFont, font, fontPath, 12, 'OUTLINE')

            if ok and loaded ~= false then
                t[k] = font

                return font
            end

            t[k] = false
        end
    end
})

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

-- the WithCheck variants put a check box (def.check get/set) before the label,
-- like sliderWithCheck. the list is dimmed while it's off, and keeps its value
local function updateEnabled(control)
    control.Dropdown:SetEnabled(control.checked)
    control.Dropdown:SetAlpha(control.checked and 1 or 0.5)
end

--- registers name and name .. 'WithCheck'
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
        if control.CheckButton then
            Addon:RefreshControlCheck(control)
        end

        local value = getValue(control)

        -- regenerating the menu is what re-reads the selected value
        if not control.synced or control.value ~= value then
            control.synced = true
            control.value = value
            control.Dropdown:GenerateMenu()
        end
    end

    local function create(parent, withCheck)
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

        local height = math.max(dropdown:GetHeight(), label:GetStringHeight())

        -- same 120 to the list as the plain one, so the lists line up
        if withCheck then
            local checkbox = Addon:AddControlCheck(control, label, updateEnabled)
            -- the padding indents the whole control, so pull the check box back
            -- out to line up with plain check rows. the label gets the width
            -- back so the lists still line up
            checkbox:SetPoint('LEFT', -control.leftPadding, 0)
            label:SetWidth(120 - checkbox:GetWidth() - 3 + control.leftPadding)
            height = math.max(height, checkbox:GetHeight())
        end

        dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
        dropdown:SetPoint('RIGHT')

        control:SetFixedHeight(height)
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
        local function isSelected(index)
            return itemValue(control.items[index]) == getValue(control)
        end

        local function setSelected(index)
            local value = itemValue(control.items[index])

            control.value = value
            control.menu:SetValue(control.def, value)
        end

        return function(_, rootDescription)
            rootDescription:SetGridMode(MenuConstants.VerticalGridDirection)

            local items = source.items(control) or {}

            control.items = items

            for i, item in ipairs(items) do
                local radio = rootDescription:CreateRadio(
                    itemLabel(control, item), isSelected, setSelected, i
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
        control.checked = nil

        if control.CheckButton then
            Addon:RefreshControlCheck(control)
        end

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

        if control.CheckButton then
            control.CheckButton:UnlockHighlight()
        end

        control.synced = false
        control.checked = nil
        control.value = nil
        control.items = nil
    end

    local function createPlain(parent)
        return create(parent, false)
    end

    local function createWithCheck(parent)
        return create(parent, true)
    end

    Addon:RegisterControlType(name, {
        Create = createPlain,
        Bind = bind,
        Refresh = refresh,
        Release = release
    })

    Addon:RegisterControlType(name .. 'WithCheck', {
        Create = createWithCheck,
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

-- shared media comes sorted by byte, which puts lowercase names after
-- uppercase ones, so sort again ignoring case
local function mediaItems(mediaType)
    return function(control)
        local names = CopyTable(LSM:List(mediaType))

        table.sort(names, function(a, b)
            return a:lower() < b:lower()
        end)

        if control.def.default then
            table.insert(names, 1, { value = false, text = control.def.default })
        end

        return names
    end
end

-- media settings may be missing or refer to media that isn't registered (ex,
-- old lowercase defaults). show the default entry for those when there is one,
-- and LibSharedMedia's own default when there isn't
local function validMedia(mediaType)
    return function(control)
        local value = control.menu:GetValue(control.def)

        if value and LSM:IsValid(mediaType, value) then
            return value
        end

        if control.def.default then
            return false
        end

        return LSM:GetDefault(mediaType)
    end
end

registerDropdown('texture', {
    items = mediaItems('statusbar'),
    getValue = validMedia('statusbar')
})

registerDropdown('border', {
    items = mediaItems('border'),
    getValue = validMedia('border')
})

registerDropdown('font', {
    items = mediaItems('font'),
    getValue = validMedia('font'),
    -- preview each font in the menu using the font itself
    initItem = function(button, fontID)
        local font = fontID and fontObjects[fontID]

        if font then
            button.fontString:SetFontObject(font)
            button.fontString:SetText(fontID)
        end
    end
})
