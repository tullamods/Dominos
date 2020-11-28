local ExtraAbilityContainer = _G.ExtraAbilityContainer
if not ExtraAbilityContainer then
    return
end

local _, Addon = ...
local BAR_ID = 'extra'

local ExtraAbilityBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function ExtraAbilityBar:New()
    local bar = ExtraAbilityBar.proto.New(self, BAR_ID)

    -- drop need for showstates for this case
    if bar:GetShowStates() == '[extrabar]show;hide' then
        bar:SetShowStates(nil)
    end
    
	bar.buttons = ExtraAbilityContainer.frames
	self.sets = Addon:GetFrameSets(BAR_ID) or Addon:SetFrameSets(BAR_ID, bar:GetDefaults())
	hooksecurefunc(ExtraAbilityContainer, "LayoutChildren", function() bar:QueueLayoutUpdate() end)
   -- bar:QueueLayoutUpdate()
    return bar
end

ExtraAbilityBar:Extend(
    'OnAcquire', function(self)
        -- local container = ExtraAbilityContainer

        -- container:ClearAllPoints()
        -- container:SetPoint('CENTER', self)
        -- container:SetParent(self)

        -- self.container = container

        self:QueueLayoutUpdate()
        -- self:UpdateShowBlizzardTexture()
    end
)

function ExtraAbilityBar:ThemeBar(enable)
    if HasExtraActionBar() then
        local button = ExtraActionBarFrame and ExtraActionBarFrame.button
        if button then
            if enable then
                Addon:GetModule('ButtonThemer'):Register(button, 'Extra Bar')
            else
                Addon:GetModule('ButtonThemer'):Unregister(button, 'Extra Bar')
            end
        end
    end

    local zoneAbilities = C_ZoneAbility.GetActiveAbilities()

    if #zoneAbilities > 0 then
        local container = ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer
        for button in container:EnumerateActive() do
            if button then
				button.icon = button.Icon
				
				function button:GetName()
					return "ZoneAbilityFrame"
				end
				
                if enable then
                    Addon:GetModule('ButtonThemer'):Register(
                        button, 'Extra Bar', {Icon = button.Icon}
                    )
                else
                    Addon:GetModule('ButtonThemer'):Unregister(
                        button, 'Extra Bar', {Icon = button.Icon}
                    )
                end
            end
        end
    end
end

function ExtraAbilityBar:GetDefaults()
    return {
		columns = 2,
		spacing = 0,
        point = 'BOTTOM',
        x = 0,
        y = 160,
        showInPetBattleUI = true,
        showInOverrideUI = true
    }
end


function ExtraAbilityBar:QueueLayoutUpdate()
	local numButtons = #ExtraAbilityContainer.frames
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_LEAVE_COMBAT")
		self:SetScript("OnEvent", function()
			self:Layout()
			self:SetScript("OnEvent")
		end)
	else
		self:Layout()
	end
end

-- Frame Overrides
function ExtraAbilityBar:AcquireButton(i)
	return ExtraAbilityContainer.frames[i] and ExtraAbilityContainer.frames[i].frame
end

function ExtraAbilityBar:NumButtons()
    return #ExtraAbilityContainer.frames
end

function ExtraAbilityBar:SetColumns(columns)
    self.sets.columns =  columns or nil
    self:Layout()
end

function ExtraAbilityBar:GetButtonInsets()
    if #self.buttons >= 1 then
        return self.buttons[1].frame:GetHitRectInsets()
    end

    return 0, 0, 0, 0
end

function ExtraAbilityBar:GetButtonSize()
    if #self.buttons >= 1 then
        local w, h = self.buttons[1].frame:GetSize()
        local l, r, t, b = self:GetButtonInsets()

        return w - (l + r), h - (t + b)
    end

    return 0, 0
end
function ExtraAbilityBar:Layout()
	self.buttons = ExtraAbilityContainer.frames
    local numButtons = #self.buttons
    if numButtons < 1 then
        ExtraAbilityBar.proto.Layout(self)
        return
    end

    local cols = max(1, min(self:NumColumns(), numButtons))
    local rows = ceil(numButtons / cols)

    local isLeftToRight = self:GetLeftToRight()
    local isTopToBottom = self:GetTopToBottom()

    -- grab base button sizes
    local l, _, t, _ = self:GetButtonInsets()
    local bW, bH = self:GetButtonSize()
	
	local wOffset = not self:ShowingBlizzardTexture() and 198 or 0
	local hOffset = not self:ShowingBlizzardTexture() and 70 or 0
	
    local pW, pH = self:GetPadding()
    local spacing = self:GetSpacing()

    local buttonWidth = bW + spacing - wOffset
    local buttonHeight = bH + spacing - hOffset

    local xOff = pW - l
    local yOff = pH - t

    for i, button in ipairs(self.buttons) do
        local row = floor((i - 1) / cols)
        if not isTopToBottom then
            row = rows - (row + 1)
        end

        local col = (i - 1) % cols
        if not isLeftToRight then
            col = cols - (col + 1)
        end

        local x = xOff + buttonWidth * col
        local y = yOff + buttonHeight * row

        button.frame:ClearAllPoints()
        button.frame:SetParent(self)
        button.frame:SetPoint('TOPLEFT', x - (wOffset/2), -(y - (hOffset/2)))
    end

    local barWidth = (buttonWidth * cols) + (pW * 2) - spacing
    local barHeight = (buttonHeight * rows) + (pH * 2) - spacing
    self:TrySetSize(barWidth, barHeight)
	self:UpdateShowBlizzardTexture()
end

function ExtraAbilityBar:OnCreateMenu(menu)
    self:AddLayoutPanel(menu)

    menu:AddFadingPanel()
end

function ExtraAbilityBar:AddLayoutPanel(menu)
    local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(l.Layout)


    panel:NewCheckButton {
        name = l.ExtraBarShowBlizzardTexture,
        get = function()
            return panel.owner:ShowingBlizzardTexture()
        end,
        set = function(_, enable)
            panel.owner:ShowBlizzardTexture(enable)
			panel.owner:Layout()
        end
    }

	panel:NewLeftToRightCheckbox()
	panel:NewTopToBottomCheckbox()
    panel:NewColumnsSlider()
    panel:NewSpacingSlider()
    panel.scaleSlider = panel:NewScaleSlider()
    panel.paddingSlider = panel:NewPaddingSlider()
end

function ExtraAbilityBar:ShowBlizzardTexture(show)
    self.sets.hideBlizzardTeture = not show

    self:UpdateShowBlizzardTexture()
end

function ExtraAbilityBar:ShowingBlizzardTexture()
    return not self.sets.hideBlizzardTeture
end

function ExtraAbilityBar:UpdateShowBlizzardTexture()
    if self:ShowingBlizzardTexture() then
        ExtraActionBarFrame.button.style:Show()
        ZoneAbilityFrame.Style:Show()

        self:ThemeBar(false)
    else
        ExtraActionBarFrame.button.style:Hide()
        ZoneAbilityFrame.Style:Hide()

        self:ThemeBar(true)
    end
end

local ExtraAbilityBarModule = Addon:NewModule('ExtraAbilityBar')

function ExtraAbilityBarModule:OnEnable()
    self:ApplyTitanPanelWorkarounds()
end

function ExtraAbilityBarModule:Load()
    if not self.initialized then
        self.initialized = true

        -- disable mouse interactions on the extra action bar
        -- as it can sometimes block the UI from being interactive
        if ExtraActionBarFrame:IsMouseEnabled() then
            ExtraActionBarFrame:EnableMouse(false)
        end

        -- prevent the stock UI from messing with the extra ability bar position
        ExtraAbilityContainer.ignoreFramePositionManager = true

        -- onshow/hide call UpdateManagedFramePositions on the blizzard end so
        -- turn that bit off
        ExtraAbilityContainer:SetScript("OnShow", nil)
        ExtraAbilityContainer:SetScript("OnHide", nil)

        -- watch for new frames to be added to the container as we will want to
        -- possibly theme them later (if they're new buttons)
        hooksecurefunc(
            ExtraAbilityContainer, 'AddFrame', function()
                if self.frame then
                    self.frame:ThemeBar(not self.frame:ShowingBlizzardTexture())
                end
            end
        )

        Addon.BindableButton:AddQuickBindingSupport(_G.ExtraActionButton1)
    end

    self.frame = ExtraAbilityBar:New()
end

function ExtraAbilityBarModule:Unload()
    if self.frame then
        self.frame:Free()
    end
end

-- Titan panel will attempt to take control of the ExtraActionBarFrame and break
-- its position and ability to be usable. This is because Titan Panel doesn't
-- check to see if another addon has taken control of the bar
--
-- To resolve this, we call TitanMovable_AddonAdjust() for the extra ability bar
-- frames to let titan panel know we are handling positions for the extra bar
function ExtraAbilityBarModule:ApplyTitanPanelWorkarounds()
    local adjust = _G.TitanMovable_AddonAdjust
    if not adjust then return end

    adjust('ExtraAbilityContainer', true)
    adjust("ExtraActionBarFrame", true)
    return true
end
