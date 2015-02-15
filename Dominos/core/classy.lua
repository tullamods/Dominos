-- classy.lua
-- A utility function for extending blizzard widget types (Frames, Buttons, etc)

local function object_Bind(self, obj)
    return setmetatable(obj, self.mt)
end

function Dominos:CreateClass(frameType, prototype)
    local obj = CreateFrame(frameType)

    obj.Bind = object_Bind

    obj.mt = {__index = obj}

    if prototype then
        obj = setmetatable(obj, {__index = prototype})
        obj.super = prototype
    end

    return obj
end
