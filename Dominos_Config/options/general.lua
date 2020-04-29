-- general options for Dominos

local AddonName, Addon = ...
local ParentAddonName, ParentAddon = GetAddOnDependencies(AddonName)
local ParentAddon = _G[ParentAddonName]
local L = LibStub('AceLocale-3.0'):GetLocale(ParentAddonName .. '-Config')

local function call_method(obj, method, ...)
    local func = obj[method]

    if type(func) ~= "function" then
        error("%s:%s is not a function", obj.GetName and obj:GetName() or obj, method, 2)
    end

    return func(obj, ...)
end

local function h(text)
    return { type = "header",  name =  text }
end

local function p(props)
    if type(props) == "string" then
        return {
            type = "description",
            name = props
        }
    end

    return {
        type = "description",
        name = props[1] or props.value,
        fontSize = props.size
    }
end

local function group(props)
    local options = {
        type = "group",
        name = props.name,
        inline = props.inline,
        args = {}
    }

    local args = options.args

    for i = 1, #props do
        local prop = props[i]

        if type(prop) == "function" then
            prop = prop()   
        end

        prop.order = i
        args[prop.name] =  prop
    end        

    return options
end

local function button(props)
    return {
        type = "execute",
        name = props.name,
        desc = props.desc,
        func = props.func,
        width = props.width or 1.75,
    }
end

local function checkbox(props)
    local options = {
        type = "toggle",
        name = props.name,    
        desc = props.desc,
        disabled = props.disabled,
        width = props.width or 1.5,
    }

    local prop = props.prop
    if type(prop) == "string" then
        options.get = function() 
            return call_method(ParentAddon, prop)
        end

        options.set = function(_, enable) return 
            call_method(ParentAddon, "Set" .. prop, enable) 
        end
    else
        options.get = props.get
        options.set = props.set
    end        

    return options
end

local function dropdown(props)
    return {
        type = "select",
        name = props.name,    
        desc = props.desc,
        values = props.values,
        disabled = props.disabled,
        get = props.get,
        set = props.set,
        width = props.width
    }
end

local function radio_group(props)
    return {
        type = "select",
        style = "radio",
        name = props.name,    
        values = props.values,
        disabled = props.disabled,
        get = props.get,
        set = props.set,
        width = props.width
    }
end

Addon:AddAceConfigOptionsPanel("general",  group {
    name = L.General,

    button {
        name = L.EnterConfigMode,

        func = function()
            ParentAddon:ToggleLockedFrames()
            HideUIPanel(InterfaceOptionsFrame)                    
        end
    },

    button {
        name = L.EnterBindingMode,

        func = function()
            ParentAddon:ToggleLockedFrames()
            HideUIPanel(InterfaceOptionsFrame)                    
        end
    },

    checkbox {
		name = L.ShowMinimapButton,
		get = function() return ParentAddon:ShowingMinimap() end,
        set = function(_, enable) ParentAddon:SetShowMinimap(enable) end,
        width = "full"
    },
    
    checkbox {
		name = L.StickyBars,
        prop = "Sticky",
        width = "full"
    },

    checkbox {
		name = L.LinkedOpacity,
		get = function() return ParentAddon:IsLinkedOpacityEnabled() end,
        set = function(_, enable) ParentAddon:SetLinkedOpacity(enable) end,
        width = "full"
    },

    h "Action Buttons - Behavior",    

    checkbox {
        name = L.LockActionButtons,
        get = function() return LOCK_ACTIONBAR == "1" end,
        set = function() InterfaceOptionsActionBarsPanelLockActionBars:Click() end,
        width = "full"
    },

    dropdown {
        name = L.RightClickUnit,

        values = {
            player = L.RCUPlayer,
            focus = L.RCUFocus,
            targettarget = L.RCUToT,
            none = "None"
        },

        width = 1.5,

        get = function()
            return ParentAddon:GetRightClickUnit() or "none"
        end,

        set = function(_, value)
            if value == "none" then
                ParentAddon:SetRightClickUnit(nil)
            else
                ParentAddon:SetRightClickUnit(value)
            end
        end
    },

    dropdown {
        name = L.ShowTooltips,

        width = 1.5,

        values = {
            always = ALWAYS,
            never = NEVER,
            ooc = "Out of Combat"
        },

        get = function()
            if ParentAddon:ShowTooltips() then
                if ParentAddon:ShowCombatTooltips() then
                    return "always"
                end

                return "ooc"
            end

            return "never"
        end,

        set = function(_, value)
            if value == "always" then
                ParentAddon:SetShowTooltips(true)
                ParentAddon:SetShowCombatTooltips(true)
            elseif value == "ooc" then
                ParentAddon:SetShowTooltips(true)
                ParentAddon:SetShowCombatTooltips(false)                
            elseif value == "never" then
                ParentAddon:SetShowTooltips(false)
                ParentAddon:SetShowCombatTooltips(false)
            else
                error(("%s - Unknown tooltip option %q"):format(ParentAddonName, value))
            end
        end
    },    

    h "Action Buttons - Look & Feel",    

    checkbox {
        name = L.ShowEmptyButtons,
        prop = "ShowGrid",
    },

    checkbox {
        name = L.ShowBindingText,
        prop = "ShowBindingText",
    },
    
    checkbox {
        name = L.ShowMacroText,
        prop = "ShowMacroText",
    },

    checkbox {
        name = L.ShowCountText,
        prop = "ShowCounts",
    },

    checkbox {
        name = L.ShowEquippedItemBorders,
        prop = "ShowEquippedItemBorders",
    },

    checkbox {
        name = L.ThemeActionButtons,
        desc = "Applies some custom style adjustments to action buttons when enabled, and leave them untouched when not",
        prop = "ThemeButtons",
        width = "full"
    },   

    h "Override UI Behavior",    

    checkbox {
        name = L.ShowOverrideUI,
        desc = "Display the Blizzard override UI when entering a vehicle, and other situations.",
        disabled = ParentAddon:IsBuild("classic"),
        get = function() return ParentAddon:UsingOverrideUI() end,
        set = function(_, enable) ParentAddon:SetUseOverrideUI(enable) end,
        width = "full"
    },   

    dropdown {
        name = L.PossessBar,
        desc = "What action bar to display actions on when possessing an enemy, and other situations",

        values = function()
            local items = {}

            for i = 1, ParentAddon:NumBars() do
                tinsert(items, ('Action Bar %d'):format(i))
            end

            return items                
        end,

        get = function()
            local bar = ParentAddon:GetOverrideBar()
            
            if bar then
                return bar.id
            end

            return 1
        end,

        set = function(_, value)
            ParentAddon:SetOverrideBar(value)
        end
    }    
})