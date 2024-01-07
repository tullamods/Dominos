--[[
    Wraps action button click and drag handlers so that we can properly handle
    things like cast on keypress and updating actions after they're shown
--]]

local _, Addon = ...

local Handler = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")

local Handler_ClickBefore = [[
    if button == "HOTKEY" then
        return "LeftButton"
    end

    if down then
        control:CallMethod("SaveActionButtonUseKeyDown")
        return false
    end

    return nil, "RESTORE"
]]

local Handler_ClickAfter = [[
    if message == "RESTORE" then
        control:CallMethod("RestoreActionButtonUseKeyDown")
    end
]]

local Handler_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local Handler_ReceiveDragAfter = [[
    self:CallMethod("UpdateShown")
]]

function Handler:Wrap(target)
    self:WrapScript(target, "OnClick", Handler_ClickBefore, Handler_ClickAfter)
    self:WrapScript(target, "OnReceiveDrag", Handler_ReceiveDragBefore, Handler_ReceiveDragAfter)
end

do
    local useKeyDown
    function Handler:SaveActionButtonUseKeyDown()
        if GetCVarBool("ActionButtonUseKeyDown") then
            SetCVar("ActionButtonUseKeyDown", "0")
            useKeyDown = true
        end
    end

    function Handler:RestoreActionButtonUseKeyDown()
        if useKeyDown then
            SetCVar("ActionButtonUseKeyDown", "1")
            useKeyDown = nil
        end
    end
end

-- export
Addon.ActionButtonScriptHandler = Handler