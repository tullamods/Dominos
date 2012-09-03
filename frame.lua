--[[
	frame.lua
		A dominos frame, a generic container object
--]]

local AddonName, Addon = ...

local PerspectiveController
do
	PerspectiveController = CreateFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate'); PerspectiveController:Hide()
	
	local OverrideUIWatcher = CreateFrame('Frame', nil, _G['OverrideActionBar'], 'SecureHandlerShowHideTemplate')
	OverrideUIWatcher:SetFrameRef('PerspectiveController', PerspectiveController)
	OverrideUIWatcher:SetAttribute('_onshow', [[ self:GetFrameRef('PerspectiveController'):SetAttribute('state-overrideui', 'enabled') ]])
	OverrideUIWatcher:SetAttribute('_onhide', [[ self:GetFrameRef('PerspectiveController'):SetAttribute('state-overrideui', 'disabled') ]])
	PerspectiveController:SetAttribute('state-overrideui', OverrideUIWatcher:IsShown())
	
	
	RegisterStateDriver(PerspectiveController, 'petbattleui', '[petbattle]enabled;disabled')
	
	PerspectiveController:Execute([[ myFrames = table.new() ]])
	
	PerspectiveController.Add = function(self, frame)	
		self:SetFrameRef('FrameToRegister', frame)
		self:Execute([[ 
			local frame = self:GetFrameRef('FrameToRegister')
			
			table.insert(myFrames, frame)		
		]])
		frame:SetAttribute('state-overrideui', self:GetAttribute('state-overrideui') == 'enabled')
		frame:SetAttribute('state-petbattleui', self:GetAttribute('state-petbattleui') == 'enabled')
	end
	
	PerspectiveController.Remove = function(self, frame)	
		self:SetFrameRef('FrameToUnregister', frame)
		self:Execute([[ 
			local frameToUnregister = self:GetFrameRef('FrameToUnregister')
			for i = 1, #myFrames do
				local frame = myFrames[i]
				if frame == frameToUnregister then
					table.remove(myFrames, frame)
				end
			end
		]])
	end
	
	PerspectiveController:SetAttribute('_onstate-overrideui', [[	
		local enabled = newstate == 'enabled'
		
		for i = 1, #myFrames do
			myFrames[i]:SetAttribute('state-overrideui', enabled)
		end
	]])
	
	PerspectiveController:SetAttribute('_onstate-petbattleui', [[	
		local enabled = newstate == 'enabled'
		
		for i = 1, #myFrames do
			myFrames[i]:SetAttribute('state-petbattleui', enabled)
		end
	]])
end

local Frame = Dominos:CreateClass('Frame')
Dominos.Frame = Frame

local FadeManager = Dominos.FadeManager
local active = {}
local unused = {}

--constructor
function Frame:New(id, tooltipText, alwaysVisible)
	local id = tonumber(id) or id
	
	local f = self:Restore(id) or self:Create(id, alwaysVisible)
	f:LoadSettings()
	f.buttons = {}
	f:SetTooltipText(tooltipText)
	PerspectiveController:Add(f.header)

	active[id] = f
	return f
end

function Frame:Create(id, alwaysVisible)
	local f = self:Bind(CreateFrame('Frame', format('DominosFrame%s', id), UIParent))
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f.id = id
	
	f.header = CreateFrame('Frame', nil, f, 'SecureHandlerStateTemplate')
	
	if alwaysVisible then
		f.header:SetAttribute('state-showinpetbattleui', true)
		f.header:SetAttribute('state-showinoverrideui', true)
	end
	
	f.header:SetAttribute('_onstate-overrideui', [[
		self:RunAttribute('updateShown')
	]])
	
	f.header:SetAttribute('_onstate-petbattleui', [[
		self:RunAttribute('updateShown')
	]])
	
	f.header:SetAttribute('_onstate-display', [[
		self:RunAttribute('updateShown')
	]])
	
	f.header:SetAttribute('updateShown', [[
		local isOverrideUIShown = self:GetAttribute('state-overrideui') and true or false
		local isPetBattleUIShown = self:GetAttribute('state-petbattleui') and true or false
		
		if isPetBattleUIShown and not self:GetAttribute('state-showinpetbattleui') then
			self:Hide()
			return
		end
		
		if isOverrideUIShown and not self:GetAttribute('state-showinoverrideui') then
			self:Hide()
			return
		end
		
		local displayState = self:GetAttribute('state-display')
		
		if displayState == 'hide' then
			if self:GetAttribute('state-alpha') then
				self:SetAttribute('state-alpha', nil)
			end
			self:Hide()
		else
			local stateAlpha = tonumber(displayState)
			if self:GetAttribute('state-alpha') ~= stateAlpha then
				self:SetAttribute('state-alpha', tonumber(newstate))
			end
			self:Show()
		end
	]])
	
	f.header:SetAttribute('_onstate-alpha', [[ 
		self:CallMethod('Fade') 
	]])
	
	f.header.Fade = function() f:Fade() end
	
	f.header:SetAllPoints(f)

	f.drag = Dominos.DragFrame:New(f)

	return f
end

function Frame:Restore(id)
	local f = unused[id]
	if f then
		unused[id] = nil
		return f
	end
end

--destructor
function Frame:Free()
	active[self.id] = nil

	UnregisterStateDriver(self.header, 'display', 'show')
	Dominos.MouseOverWatcher:Remove(self)
	PerspectiveController:Remove(self.header)

	for i in pairs(self.buttons) do
		self:RemoveButton(i)
	end
	self.buttons = nil
	self.docked = nil

	self:ClearAllPoints()
	self:SetUserPlaced(nil)
	self.drag:Hide()
	self:Hide()

	unused[self.id] = self
end

function Frame:Delete()
	self:Free()
	Dominos:SetFrameSets(self.id, nil)
end

function Frame:LoadSettings(defaults)
	self.sets = Dominos:GetFrameSets(self.id) or Dominos:SetFrameSets(self.id, self:GetDefaults()) --get defaults must be provided by anything implementing the Frame type
	self:Reposition()

	if self.sets.hidden then
		self:HideFrame()
	else
		self:ShowFrame()
	end

	if Dominos:Locked() then
		self:Lock()
	else
		self:Unlock()
	end

	self:UpdateShowStates()
end

--[[ Layout ]]--

--this function is used in a lot of places, but never called in Frame
function Frame:LoadButtons()
	if not self.AddButton then return end
	
	for i = 1, self:NumButtons() do
		self:AddButton(i)
	end
	
	self:UpdateClickThrough()
end

function Frame:RemoveButton(i)
	local b = self.buttons and self.buttons[i]
	if b and b.Free then
		b:Free()
		self.buttons[i] = nil
	end
end

function Frame:UpdateButtonCount(numButtons)
	for i = numButtons + 1, #self.buttons do
		self:RemoveButton(i)
	end

	for i = #self.buttons + 1, numButtons do
		self:AddButton(i)
	end
end

function Frame:SetNumButtons(numButtons)
	self.sets.numButtons = numButtons
	self:UpdateButtonCount(self:NumButtons())
	self:Layout()
end

function Frame:NumButtons()
	return self.sets.numButtons or 0
end

function Frame:SetColumns(columns)
	self.sets.columns = columns ~= self:NumButtons() and columns or nil
	self:Layout()
end

function Frame:NumColumns()
	return self.sets.columns or self:NumButtons()
end

function Frame:SetSpacing(spacing)
	self.sets.spacing = spacing
	self:Layout()
end

function Frame:GetSpacing()
	return self.sets.spacing or 0
end

function Frame:SetPadding(w, h)
	self.sets.padW = w
	self.sets.padH = h or w
	self:Layout()
end

function Frame:GetPadding()
	local w = self.sets.padW or 0
	local h = self.sets.padH or w
	return w, h
end

--the wackiness here is for backward compaitbility reasons, since I did not implement true defaults
function Frame:SetLeftToRight(isLeftToRight)
	local isRightToLeft = not isLeftToRight

	self.sets.isRightToLeft = isRightToLeft and true or nil
	self:Layout()
end

function Frame:GetLeftToRight()
	return not self.sets.isRightToLeft
end

function Frame:SetTopToBottom(isTopToBottom)
	local isBottomToTop = not isTopToBottom

	self.sets.isBottomToTop = isBottomToTop and true or nil
	self:Layout()
end

function Frame:GetTopToBottom()
	return not self.sets.isBottomToTop
end

function Frame:Layout()
	local width, height
	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)
		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()
		local isLeftToRight = self:GetLeftToRight()
		local isTopToBottom = self:GetTopToBottom()

		local b = self.buttons[1]
		local w = b:GetWidth() + spacing
		local h = b:GetHeight() + spacing

		for i,b in pairs(self.buttons) do
			local col
			local row
			if isLeftToRight then
				col = (i-1) % cols
			else
				col = (cols-1) - (i-1) % cols
			end

			if isTopToBottom then
				row = ceil(i / cols) - 1
			else
				row = rows - ceil(i / cols)
			end

			b:ClearAllPoints()
			b:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH))
		end

		width = w*cols - spacing + pW*2
		height = h*ceil(#self.buttons/cols) - spacing + pH*2
	else
		width = 30
		height = 30
	end

	self:SetSize(max(width, 8), max(height, 8))
end


--[[ Scaling ]]--

function Frame:GetScaledCoords(scale)
	local ratio = self:GetFrameScale() / scale
	return (self:GetLeft() or 0) * ratio, (self:GetTop() or 0) * ratio
end

function Frame:SetFrameScale(scale, scaleAnchored)
	local x, y =  self:GetScaledCoords(scale)

	self.sets.scale = scale
	self:Rescale()

	if not self.sets.anchor then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', self:GetParent(), 'BOTTOMLEFT', x, y)
		self:SavePosition()
	end

	if scaleAnchored then
		for _,f in self:GetAll() do
			if f:GetAnchor() == self then
				f:SetFrameScale(scale, true)
			end
		end
	end
end

function Frame:Rescale()
	self:SetScale(self:GetFrameScale())
	self.drag:SetScale(self:GetFrameScale())
end

function Frame:GetFrameScale()
	return self.sets.scale or 1
end


--[[ Opacity ]]--

function Frame:SetFrameAlpha(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
	self:UpdateAlpha()
end

function Frame:GetFrameAlpha()
	return self.sets.alpha or 1
end

--faded opacity (mouse not over the frame)
function Frame:SetFadeMultiplier(alpha)
	local alpha = alpha or 1
	if alpha == 1 then
		self.sets.fadeAlpha = nil
	else
		self.sets.fadeAlpha = alpha
	end
	self:UpdateWatched()
	self:UpdateAlpha()
end

function Frame:GetFadeMultiplier()
	return self.sets.fadeAlpha or 1
end

function Frame:UpdateAlpha()
	self:SetAlpha(self:GetExpectedAlpha())
	if Dominos:IsLinkedOpacityEnabled() then
		self:ForDocked('UpdateAlpha')
	end
end

--returns the opacity value we expect the frame to be at in its current state
function Frame:GetExpectedAlpha()
	--if this is a docked frame and linked opacity is enabled
	--then return the expected opacity of the parent frame
	if Dominos:IsLinkedOpacityEnabled() then
		local anchor = (self:GetAnchor())
		if anchor and anchor:FrameIsShown() then
			return anchor:GetExpectedAlpha()
		end
	end

	--if the frame is moused over, then return the frame's normal opacity
	if self.focused then
		return self:GetFrameAlpha()
	end

	--if there's a statealpha value for the frame, then use it
	local stateAlpha = self.header:GetAttribute('state-alpha')
	if stateAlpha then
		return stateAlpha / 100
	end

	return self:GetFrameAlpha() * self:GetFadeMultiplier()
end


--[[ Mouseover Checking ]]--

local function isChildFocus(...)
	local focus = GetMouseFocus()
	for i = 1, select('#', ...) do
		if focus == select(i, ...) then
			return true
		end
	end
	for i = 1, select('#', ...) do
		local f = select(i, ...)
		if f:IsShown() and isChildFocus(f:GetChildren()) then
			return true
		end
	end
	return false
end

local function isDescendant(frame, ...)
	for i = 1, select('#', ...) do
		local f = select(i, ...)
		if frame == f then
			return true
		end
	end
	for i = 1, select('#', ...) do
		local f = select(i, ...)
		if isDescendant(frame, f:GetChildren()) then
			return true
		end
	end
	return false
end

--returns all frames docked to the given frame
function Frame:IsFocus()
	if self:IsMouseOver(1, -1, -1, 1) then
		return (GetMouseFocus() == WorldFrame) or isChildFocus(self:GetChildren())
	end
	if SpellFlyout and SpellFlyout:IsMouseOver(1, -1, -1, 1) and isDescendant(SpellFlyout:GetParent(), self) then
		return true
	end
	return Dominos:IsLinkedOpacityEnabled() and self:IsDockedFocus()
end

function Frame:IsDockedFocus()
	local docked = self.docked
	if docked then
		for _,f in pairs(docked) do
			if f:IsFocus()  then
				return true
			end
		end
	end
	return false
end


--[[ Fading ]]--

local function fader_Create(parent)
	local fadeGroup = parent:CreateAnimationGroup()
	fadeGroup:SetLooping('NONE')
	fadeGroup:SetScript('OnFinished', function(self) parent:SetAlpha(self.targetAlpha) end)

	local fade = fadeGroup:CreateAnimation('Alpha')
	fade:SetSmoothing('NONE')
	fade:SetOrder(1)

	return function(targetAlpha, duration)
		if fadeGroup:IsPlaying() then
			fadeGroup:Pause()
			parent:SetAlpha(parent:GetAlpha() + (fade:GetChange() * fade:GetProgress()))
		end
		fadeGroup.targetAlpha = targetAlpha
		fade:SetChange(targetAlpha - parent:GetAlpha())
		fade:SetDuration(duration)
		fadeGroup:Play()
	end
end

local Fade = setmetatable({}, {__index = function(t, parent)
	local fade = fader_Create(parent)
	t[parent] = fade
	return fade
end})


--fades the frame from the current opacity setting
--to the expected setting
function Frame:Fade()
	if floor(abs(self:GetExpectedAlpha()*100 - self:GetAlpha()*100)) == 0 then
		return
	end

	if not self:FrameIsShown() then
		return
	end

	Fade[self](self:GetExpectedAlpha(), 0.1)
	if Dominos:IsLinkedOpacityEnabled() then
		self:ForDocked('Fade')
	end
end

--[[ Visibility ]]--

function Frame:ShowFrame()
	self.sets.hidden = nil
	self:Show()
	self.drag:UpdateColor()
	self:UpdateWatched()
	self:UpdateAlpha()

	if Dominos:IsLinkedOpacityEnabled() then
		self:ForDocked('ShowFrame')
	end
end

function Frame:HideFrame()
	self.sets.hidden = true
	self:Hide()
	self.drag:UpdateColor()
	self:UpdateWatched()
	self:UpdateAlpha()

	if Dominos:IsLinkedOpacityEnabled() then
		self:ForDocked('HideFrame')
	end
end

function Frame:ToggleFrame()
	if self:FrameIsShown() then
		self:HideFrame()
	else
		self:ShowFrame()
	end
end

function Frame:FrameIsShown()
	return not self.sets.hidden
end


--[[ Clickthrough ]]--

function Frame:SetClickThrough(enable)
	self.sets.clickThrough = enable and true or false
	self:UpdateClickThrough()
end

function Frame:GetClickThrough()
	return self.sets.clickThrough
end

function Frame:UpdateClickThrough()
	local buttons = self.buttons
	if not buttons then return end

	local clickThrough = self:GetClickThrough()
	for i, button in pairs(self.buttons) do
		if clickThrough then
			button:EnableMouse(false)
		else
			button:EnableMouse(true)
		end
	end
end


--[[ Show states ]]--

function Frame:SetShowStates(states)
	self.sets.showstates = states
	self:UpdateShowStates()
end

function Frame:GetShowStates()
	local states = self.sets.showstates

	--hack to convert [combat] into [combat]show;hide in case a user is using the old style of showstates
	if states then
		if states:sub(#states) == ']' then
			states = states .. 'show;hide'
			self.sets.showstates = states
		end
	end

	return states
end

function Frame:UpdateShowStates()
	local showstates = self:GetShowStates()
	if showstates then
		RegisterStateDriver(self.header, 'display', showstates)
	else
		UnregisterStateDriver(self.header, 'display')
		if self.header:GetAttribute('state-display') then
			self.header:SetAttribute('state-display', nil)
		end
	end
end

--[[ Lock/Unlock ]]--

function Frame:Lock()
	self.drag:Hide()
end

function Frame:Unlock()
	self.drag:Show()
end

--[[ Sticky Bars ]]--

Frame.stickyTolerance = 16

function Frame:StickToEdge()
	local point, x, y = self:GetRelPosition()
	local s = self:GetScale()
	local w = self:GetParent():GetWidth()/s
	local h = self:GetParent():GetHeight()/s
	local rTolerance = self.stickyTolerance/s
	local changed = false

	--sticky edges
	if abs(x) <= rTolerance then
		x = 0
		changed = true
	end

	if abs(y) <= rTolerance then
		y = 0
		changed = true
	end

	-- auto centering
	local cX, cY = self:GetCenter()
	if y == 0 then
		if abs(cX - w/2) <= rTolerance*2 then
			if point == 'TOPLEFT' or point == 'TOPRIGHT' then
				point = 'TOP'
			else
				point = 'BOTTOM'
			end

			x = 0
			changed = true
		end
	elseif x == 0 then
		if abs(cY - h/2) <= rTolerance*2 then
			if point == 'TOPLEFT' or point == 'BOTTOMLEFT' then
				point = 'LEFT'
			else
				point = 'RIGHT'
			end

			y = 0
			changed = true
		end
	end

	--save this junk if we've done something
	if changed then
		self.sets.point = point
		self.sets.x = x
		self.sets.y = y

		self:ClearAllPoints()
		self:SetPoint(point, x, y)
	end
end

function Frame:Stick()
	self:ClearAnchor()

	--only do sticky code if the alt key is not currently down
	if Dominos:Sticky() and not IsAltKeyDown() then
		--try to stick to a bar, then try to stick to a screen edge
		for _, f in self:GetAll() do
			if f ~= self then
				local point = FlyPaper.Stick(self, f, self.stickyTolerance)
				if point then
					self:SetAnchor(f, point)
					break
				end
			end
		end

		if not self.sets.anchor then
			self:StickToEdge()
		end
	end

	self:SavePosition()
	self.drag:UpdateColor()
end

function Frame:Reanchor()
	local f, point = self:GetAnchor()
	if not(f and FlyPaper.StickToPoint(self, f, point)) then
		self:ClearAnchor()
		if not self:Reposition() then
			self:ClearAllPoints()
			self:SetPoint('CENTER')
		end
	else
		self:SetAnchor(f, point)
	end
	self.drag:UpdateColor()
end

function Frame:SetAnchor(anchor, point)
	self:ClearAnchor()

	if anchor.docked then
		local found = false
		for i,f in pairs(anchor.docked) do
			if f == self then
				found = i
				break
			end
		end
		if not found then
			tinsert(anchor.docked, self)
		end
	else
		anchor.docked = {self}
	end

	self.sets.anchor = anchor.id .. point
	self:UpdateWatched()
	self:UpdateAlpha()
end

function Frame:ClearAnchor()
	local anchor, point = self:GetAnchor()
	if anchor and anchor.docked then
		for i,f in pairs(anchor.docked) do
			if f == self then
				tremove(anchor.docked, i)
				break
			end
		end
		if not next(anchor.docked) then
			anchor.docked = nil
		end
	end

	self.sets.anchor = nil
	self:UpdateWatched()
	self:UpdateAlpha()
end

function Frame:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = #anchorString - 1
		return self:Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end

--[[ Positioning ]]--

function Frame:GetRelPosition()
	local parent = self:GetParent()
	local w, h = parent:GetWidth(), parent:GetHeight()
	local x, y = self:GetCenter()
	local s = self:GetScale()
	w = w/s h = h/s

	local dx, dy
	local hHalf = (x > w/2) and 'RIGHT' or 'LEFT'
	if hHalf == 'RIGHT' then
		dx = self:GetRight() - w
	else
		dx = self:GetLeft()
	end

	local vHalf = (y > h/2) and 'TOP' or 'BOTTOM'
	if vHalf == 'TOP' then
		dy = self:GetTop() - h
	else
		dy = self:GetBottom()
	end

	return vHalf..hHalf, dx, dy
end

function Frame:SavePosition()
	local point, x, y = self:GetRelPosition()
	local sets = self.sets

	sets.point = point
	sets.x = x
	sets.y = y
end

--place the frame at it's saved position
function Frame:Reposition()
	self:Rescale()

	local sets = self.sets
	local point, x, y = sets.point, sets.x, sets.y

	if point then
		self:ClearAllPoints()
		self:SetPoint(point, x, y)
		self:SetUserPlaced(true)
		return true
	end
end

function Frame:SetFramePoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
	self:SavePosition()
end

--[[ Menus ]]--

function Frame:CreateMenu()
	self.menu = Dominos:NewMenu(self.id)
	self.menu:AddLayoutPanel()
	self.menu:AddAdvancedPanel()
end

function Frame:ShowMenu()
	local enabled = select(4, GetAddOnInfo('Dominos_Config'))
	if enabled then
		if not self.menu then
			self:CreateMenu()
		end

		local menu = self.menu
		if menu then
			menu:Hide()
			menu:SetOwner(self)
			menu:ShowPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
			menu:Show()
		end
	end
end

--[[ Tooltip Text ]]--

function Frame:SetTooltipText(text)
	self.tooltipText = text
end

function Frame:GetTooltipText()
	return self.tooltipText
end

--[[ Mouseover Watching ]]--

function Frame:UpdateWatched()
	if self:FrameIsShown() and self:GetFadeMultiplier() < 1 and not(Dominos:IsLinkedOpacityEnabled() and self:GetAnchor()) then
		Dominos.MouseOverWatcher:Add(self)
	else
		Dominos.MouseOverWatcher:Remove(self)
	end
end

--[[ Metafunctions ]]--

function Frame:Get(id)
	return active[tonumber(id) or id]
end

function Frame:GetAll()
	return pairs(active)
end

function Frame:ForAll(method, ...)
	for _,f in self:GetAll() do
		local action = f[method]
		if action then
			action(f, ...)
		end
	end
end

function Frame:ForDocked(method, ...)
	if self.docked then
		for _, f in pairs(self.docked) do
			local action = f[method]
			if action then
				action(f, ...)
			end
		end
	end
end

--takes a frameId, and performs the specified action on that frame
--this adds two special IDs, 'all' for all frames and '<number>-<number>' for a range of IDs
function Frame:ForFrame(id, method, ...)
	if id == 'all' then
		self:ForAll(method, ...)
	else
		local startID, endID = tostring(id):match('(%d+)-(%d+)')
		startID = tonumber(startID)
		endID = tonumber(endID)

		if startID and endID then
			if startID > endID then
				local t = startID
				startID = endID
				endID = t
			end

			for i = startID, endID do
				local f = self:Get(i)
				if f then
					local action = f[method]
					if action then
						action(f, ...)
					end
				end
			end
		else
			local f = self:Get(id)
			if f then
				local action = f[method]
				if action then
					action(f, ...)
				end
			end
		end
	end
end