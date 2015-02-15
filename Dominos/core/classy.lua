-- classy
-- A utility function for extending blizzard widget types (Frames, Buttons, etc)

function Dominos:CreateClass(frameType, prototype)
    local class = CreateFrame(frameType)
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
