local _, Addon = ...

local ButtonFlash = {}

local function createAnimation(button)
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetFrameStrata('TOOLTIP')

    local texture = frame:CreateTexture()
    texture:SetTexture([[Interface\Cooldown\star4]])
    texture:SetAlpha(0)
    texture:SetAllPoints(frame)
    texture:SetBlendMode('ADD')
    texture:SetDrawLayer('OVERLAY', 7)

    local animation = texture:CreateAnimationGroup()

    local alpha = animation:CreateAnimation('Alpha')
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0)
    alpha:SetOrder(1)

    local scale1 = animation:CreateAnimation('Scale')
    scale1:SetScale(1.5, 1.5)
    scale1:SetDuration(0)
    scale1:SetOrder(1)

    local scale2 = animation:CreateAnimation('Scale')
    scale2:SetScale(0, 0)
    scale2:SetDuration(0.3)
    scale2:SetOrder(2)

    local rotation = animation:CreateAnimation('Rotation')
    rotation:SetDegrees(90)
    rotation:SetDuration(0.3)
    rotation:SetOrder(2)

    frame.texture = texture
    frame.animation = animation
    frame:Hide()

    return frame
end

function ButtonFlash:Add(button)
    if button.buttonFlash then
        return
    end

    button.buttonFlash = createAnimation(button)

    if button.SetButtonStateBase then
        hooksecurefunc(button, 'SetButtonStateBase', function(self, state)
            if state == 'PUSHED' then
                ButtonFlash:Play(self)
            end
        end)
    end
end

function ButtonFlash:SetEnabled(button, enabled)
    local frame = button.buttonFlash
    if not frame then
        return
    end

    frame.enabled = enabled and true or nil
    if not frame.enabled then
        frame.animation:Stop()
        frame.texture:SetAlpha(0)
        frame:Hide()
    end
end

function ButtonFlash:Play(button)
    local frame = button.buttonFlash
    if not frame or not frame.enabled or not button:IsVisible() then
        return
    end

    frame:ClearAllPoints()
    frame:SetAllPoints(button)
    frame:SetFrameLevel(button:GetFrameLevel() + 10)
    frame:Show()
    frame.texture:SetAlpha(0)
    frame.animation:Stop()
    frame.animation:Play()
end

Addon.ButtonFlash = ButtonFlash
