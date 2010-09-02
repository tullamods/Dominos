--[[
	Dominos Minimap Button
		Based on the fubar and item rack minimap buttons
--]]

--[[
	Copyright (c) 2008-2009 Jason Greer
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are met:

		* Redistributions of source code must retain the above copyright notice, 
		  this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the 
		  documentation and/or other materials provided with the distribution.
		* Neither the name of the author nor the names of its contributors may 
		  be used to endorse or promote products derived from this software 
		  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
	LIABLE FORANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')

local MinimapButton = CreateFrame('Button', 'DominosMinimapButton', Minimap)
Dominos.Minimap = MinimapButton

function MinimapButton:Load()
	self:SetFrameStrata('MEDIUM')
	self:SetWidth(31); self:SetHeight(31)
	self:SetFrameLevel(8)
	self:RegisterForClicks('anyUp')
	self:RegisterForDrag('LeftButton')
	self:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

	local overlay = self:CreateTexture(nil, 'OVERLAY')
	overlay:SetWidth(53); overlay:SetHeight(53)
	overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
	overlay:SetPoint('TOPLEFT')

	local icon = self:CreateTexture(nil, 'BACKGROUND')
	icon:SetWidth(20); icon:SetHeight(20)
	icon:SetTexture('Interface\\AddOns\\Dominos\\Dominos')
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint('TOPLEFT', 7, -5)
	self.icon = icon

	self:SetScript('OnEnter', self.OnEnter)
	self:SetScript('OnLeave', self.OnLeave)
	self:SetScript('OnClick', self.OnClick)
	self:SetScript('OnDragStart', self.OnDragStart)
	self:SetScript('OnDragStop', self.OnDragStop)
	self:SetScript('OnMouseDown', self.OnMouseDown)
	self:SetScript('OnMouseUp', self.OnMouseUp)
end

function MinimapButton:OnClick(button)
	if button == 'LeftButton' then
		if IsShiftKeyDown() then
			Dominos:ToggleBindingMode()
		else
			Dominos:ToggleLockedFrames()
		end
	elseif button == 'RightButton' then
		Dominos:ShowOptions()
	end
	self:OnEnter()
end

function MinimapButton:OnMouseDown()
	self.icon:SetTexCoord(0, 1, 0, 1)
end

function MinimapButton:OnMouseUp()
	self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end

function MinimapButton:OnEnter()
	if not self.dragging then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetText('Dominos', 1, 1, 1)

		if Dominos:Locked() then
			GameTooltip:AddLine(L.ConfigEnterTip)
		else
			GameTooltip:AddLine(L.ConfigExitTip)
		end

		local KB = LibStub('LibKeyBound-1.0', true)
		if KB then
			if KB:IsShown() then
				GameTooltip:AddLine(L.BindingExitTip)
			else
				GameTooltip:AddLine(L.BindingEnterTip)
			end
		end

		local enabled = select(4, GetAddOnInfo('Dominos_Config'))
		if enabled then
			GameTooltip:AddLine(L.ShowOptionsTip)
		end
		GameTooltip:Show()
	end
end

function MinimapButton:OnLeave()
	GameTooltip:Hide()
end

function MinimapButton:OnDragStart()
	self.dragging = true
	self:LockHighlight()
	self.icon:SetTexCoord(0, 1, 0, 1)
	self:SetScript('OnUpdate', self.OnUpdate)
	GameTooltip:Hide()
end

function MinimapButton:OnDragStop()
	self.dragging = nil
	self:SetScript('OnUpdate', nil)
	self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	self:UnlockHighlight()
end

function MinimapButton:OnUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()

	px, py = px / scale, py / scale

	Dominos:SetMinimapButtonPosition(math.deg(math.atan2(py - my, px - mx)) % 360)
	self:UpdatePosition()
end

--magic fubar code for updating the minimap button's position
--I suck at trig, so I'm not going to bother figuring it out
function MinimapButton:UpdatePosition()
	local angle = math.rad(Dominos:GetMinimapButtonPosition() or random(0, 360))
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local minimapShape = GetMinimapShape and GetMinimapShape() or 'ROUND'

	local round = false
	if minimapShape == 'ROUND' then
		round = true
	elseif minimapShape == 'SQUARE' then
		round = false
	elseif minimapShape == 'CORNER-TOPRIGHT' then
		round = not(cos < 0 or sin < 0)
	elseif minimapShape == 'CORNER-TOPLEFT' then
		round = not(cos > 0 or sin < 0)
	elseif minimapShape == 'CORNER-BOTTOMRIGHT' then
		round = not(cos < 0 or sin > 0)
	elseif minimapShape == 'CORNER-BOTTOMLEFT' then
		round = not(cos > 0 or sin > 0)
	elseif minimapShape == 'SIDE-LEFT' then
		round = cos <= 0
	elseif minimapShape == 'SIDE-RIGHT' then
		round = cos >= 0
	elseif minimapShape == 'SIDE-TOP' then
		round = sin <= 0
	elseif minimapShape == 'SIDE-BOTTOM' then
		round = sin >= 0
	elseif minimapShape == 'TRICORNER-TOPRIGHT' then
		round = not(cos < 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-TOPLEFT' then
		round = not(cos > 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-BOTTOMRIGHT' then
		round = not(cos < 0 and sin < 0)
	elseif minimapShape == 'TRICORNER-BOTTOMLEFT' then
		round = not(cos > 0 and sin < 0)
	end

	local x, y
	if round then
		x = cos*80
		y = sin*80
	else
		x = math.max(-82, math.min(110*cos, 84))
		y = math.max(-86, math.min(110*sin, 82))
	end

	self:SetPoint('CENTER', x, y)
end

MinimapButton:Load()