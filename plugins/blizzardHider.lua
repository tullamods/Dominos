--[[
    This module is responsible for hiding the main menu bar and other components that we don't
    want visible when running Dominos
--]]

local AddonName = ...
local Addon = _G[AddonName]
local BlizzardHider = Addon:NewModule('BlizzardHider')

--[[ Helpers ]]--

local hiddenFrame = Addon:CreateHiddenFrame('Frame', nil, _G['UIParent'], 'SecureFrameTemplate')

local function disableFrame(frameName, unregisterEvents)
    local frame = _G[frameName]

    if not frame then
        Addon:Print('Unknown Frame', frameName)
    end

    frame:SetParent(hiddenFrame)
    frame.ignoreFramePositionManager = true

    if unregisterEvents then
        frame:UnregisterAllEvents()
    end
end

local function disableFrameSlidingAnimation(frameName)
    local animation = (_G[frameName].slideOut:GetAnimations())

    animation:SetOffset(0, 0)
end

--[[ Module Functionality ]]--

function BlizzardHider:OnEnable()
    self:Hide()
end

function BlizzardHider:Hide()
    -- disable, but don't hide the menu bar to work around Blizzard assumptions
    _G['MainMenuBar']:EnableMouse(false)
    _G['MainMenuBar'].ignoreFramePositionManager = true

    -- disable override bar transition animations
    disableFrameSlidingAnimation('MainMenuBar')
    disableFrameSlidingAnimation('OverrideActionBar')

    disableFrame('ArtifactWatchBar')
    disableFrame('HonorWatchBar')
    disableFrame('MultiBarBottomLeft')
    disableFrame('MultiBarBottomRight')
    disableFrame('MultiBarLeft')
    disableFrame('MultiBarRight')
    disableFrame('MainMenuBarArtFrame')
    disableFrame('MainMenuExpBar')
    disableFrame('MainMenuBarMaxLevelBar')
    disableFrame('ReputationWatchBar')
    disableFrame('StanceBarFrame')
    disableFrame('PossessBarFrame')
    disableFrame('PetActionBarFrame')
    disableFrame('MultiCastActionBarFrame')
    disableFrame('MultiBarBottomLeft')
end
