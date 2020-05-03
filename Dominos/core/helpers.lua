-- functions I call at least three(ish) times

local AddonName, Addon = ...

-- create a frame, and then hide it
function Addon:CreateHiddenFrame(...)
    local frame = CreateFrame(...)

    frame:Hide()

    return frame
end

-- A utility function for extending blizzard widget types (Frames, Buttons, etc)
function Addon:CreateClass(frameType, prototype)
    local class = self:CreateHiddenFrame(frameType)
    local class_mt = {__index = class}

    class.Bind = function(_, obj)
        return setmetatable(obj, class_mt)
    end

    if prototype then
        class.proto = prototype

        return setmetatable(class, {__index = prototype})
    end

    return class
end

-- returns a function that generates unique names for frames
-- in the format <AddonName>_<Prefix>[1, 2, ...]
function Addon:CreateNameGenerator(prefix)
    local id = 0
    return function()
        id = id + 1
        return ("%s_%s_%d"):format(AddonName, prefix, id)
    end
end

-- A functional way to fade a frame from one opacity to another without constantly
-- creating new animation groups for the frame
do
    local Fade = setmetatable({}, {
        __call = function(self, frame, toAlpha, delay, duration)
            return self[frame](toAlpha, delay, duration)
        end,

        __index = function(self, frame)
            local animationGroup = frame:CreateAnimationGroup()
            animationGroup:SetLooping("NONE")
            animationGroup:SetToFinalAlpha(true)

            local fadeAnimation = animationGroup:CreateAnimation("Alpha")
            fadeAnimation:SetSmoothing("IN_OUT")
            fadeAnimation:SetOrder(0)

            local function func(toAlpha, delay, duration)
                fadeAnimation:SetFromAlpha(frame:GetAlpha())
                fadeAnimation:SetToAlpha(toAlpha)
                fadeAnimation:SetStartDelay(delay)
                fadeAnimation:SetDuration(duration)

                animationGroup:Restart()
            end

            self[frame] = func
            return func
        end
    })

    function Addon:Fade(frame, toAlpha, delay, duration)
        Fade(frame, toAlpha, delay, duration)
    end
end

-- somewhere between a debounce and a throttle
function Addon:Defer(func, delay, arg1)
    delay = delay or 0

    local waiting = false

    local function callback()
        func(arg1)

        waiting = false
    end

    return function()
        if not waiting then
            waiting = true

            C_Timer.After(delay or 0, callback)
        end
    end
end
