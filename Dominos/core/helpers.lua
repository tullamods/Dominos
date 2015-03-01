-- functions I call at least three times

local AddonName = ...
local Addon = _G[AddonName]

-- create a frame, and then hide it
function Addon:CreateHiddenFrame(...)
    local frame = CreateFrame(...)

    frame:Hide()

    return frame
end

-- A utility function for extending blizzard widget types (Frames, Buttons, etc)
function Addon:CreateClass(frameType, prototype)
    local class = self:CreateHiddenFrame(frameType)
    local class_mt = { __index = class }

    class.Bind = function(self, obj)
        return setmetatable(obj, class_mt)
    end

    if prototype then
        class.proto = prototype

        return setmetatable(class, {__index = prototype})
    end

    return class
end
