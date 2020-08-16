-- this is a workaround for Blizzard not supporting custom buttons doing cast
-- on keypress without registering for MouseButtonDown
local _, Addon = ...

local CastOnKeyPressHandler = Addon:CreateHiddenFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate')

CastOnKeyPressHandler:SetAttribute('IgnoreMouseClicks', true)
CastOnKeyPressHandler:SetAttribute('CastOnKeyPress', GetCVarBool('ActionButtonUseKeyDown'))

CastOnKeyPressHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        self:SetAttribute('CastOnKeyPress', GetCVarBool('ActionButtonUseKeyDown'))
    elseif event == "CVAR_UPDATE" and ...  == ACTION_BUTTON_USE_KEY_DOWN then
        if not InCombatLockdown() then
            self:SetAttribute('CastOnKeyPress', GetCVarBool('ActionButtonUseKeyDown'))
        end
    end
end)

CastOnKeyPressHandler:RegisterEvent("CVAR_UPDATE")
CastOnKeyPressHandler:RegisterEvent("PLAYER_REGEN_ENABLED")

function CastOnKeyPressHandler:Register(button)
    -- add LeftButtonDown to the clicks we watch
    button:RegisterForClicks('AnyUp', 'LeftButtonDown')

    -- filter out click events that aren't either on up, or a keypress on down
    -- (when cast on keypress is enabled)
	self:WrapScript(button, 'OnClick', [[
        -- only left clicks are considered for cast on keypress
        if button ~= "LeftButton" then return end

        -- a key down event
        if down then
            -- cast on keypress is off, ignore
            if not control:GetAttribute("CastOnKeyPress") then
                return false
            end

            -- down click, and possibly a mouse click, ignore if we want to
            if self:IsUnderMouse() and control:GetAttribute('IgnoreMouseClicks') then
                return false
            end
        -- key up events
        else
            -- this would be a
            if control:GetAttribute("CastOnKeyPress") and not (self:IsUnderMouse() or control:GetAttribute('IgnoreMouseClicks')) then
                return false
            end
        end
    ]])
end

Addon.CastOnKeyPressHandler = CastOnKeyPressHandler