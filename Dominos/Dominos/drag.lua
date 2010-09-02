--[[
	drag.lua
		A Dominos frame component that controls frame movement
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

local Drag = Dominos:CreateClass('Button')
Dominos.DragFrame = Drag

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')


function Drag:New(owner)
	local f = self:Bind(CreateFrame('Button', nil, UIParent))
	f.owner = owner

	f:EnableMouseWheel(true)
	f:SetClampedToScreen(true)
	f:SetFrameStrata(owner:GetFrameStrata())
	f:SetAllPoints(owner)
	f:SetFrameLevel(owner:GetFrameLevel() + 5)

	local bg = f:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture(1, 1, 1, 0.4)
	bg:SetAllPoints(f)
	f:SetNormalTexture(bg)

	local t = f:CreateTexture(nil, 'BACKGROUND')
	t:SetTexture(0.2, 0.3, 0.4, 0.5)
	t:SetAllPoints(f)
	f:SetHighlightTexture(t)

	f:SetNormalFontObject('GameFontNormalLarge')
	f:SetText(owner.id)

	f:RegisterForClicks('AnyUp')
	f:RegisterForDrag('LeftButton')
	f:SetScript('OnMouseDown', self.StartMoving)
	f:SetScript('OnMouseUp', self.StopMoving)
	f:SetScript('OnMouseWheel', self.OnMouseWheel)
	f:SetScript('OnClick', self.OnClick)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)
	f:Hide()

	return f
end


function Drag:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
	GameTooltip:SetText(format('Bar: %s', self:GetText():gsub('^%l', string.upper)), 1, 1, 1)
	
	local tooltipText = self.owner:GetTooltipText()
	if tooltipText then
		GameTooltip:AddLine(tooltipText .. '\n', nil, nil, nil, nil, 1)
	end

	if self.owner.ShowMenu then
		GameTooltip:AddLine(L.ShowConfig)
	end

	if self.owner:IsShown() then
		GameTooltip:AddLine(L.HideBar)
	else
		GameTooltip:AddLine(L.ShowBar)
	end

	GameTooltip:AddLine(format(L.SetAlpha, ceil(self.owner:GetFrameAlpha()*100)))
	GameTooltip:Show()
end

function Drag:OnLeave()
	GameTooltip:Hide()
end

function Drag:StartMoving(button)
	if button == 'LeftButton' then
		self.isMoving = true
		self.owner:StartMoving()

		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
end

function Drag:StopMoving()
	if self.isMoving then
		self.isMoving = nil
		self.owner:StopMovingOrSizing()
		self.owner:Stick()
		self:OnEnter()
	end
end

function Drag:OnMouseWheel(arg1)
	local newAlpha = min(max(self.owner:GetAlpha() + (arg1 * 0.1), 0), 1)
	if newAlpha ~= self.owner:GetAlpha() then
		self.owner:SetFrameAlpha(newAlpha)
		self:OnEnter()
	end
end

function Drag:OnClick(button)
	if button == 'RightButton' then
		if IsShiftKeyDown() then
			self.owner:ToggleFrame()
		else
			self.owner:ShowMenu()
		end
	elseif button == 'MiddleButton' then
		self.owner:ToggleFrame()
	end
	self:OnEnter()
end

--updates the drag button color of a given bar if its attached to another bar
function Drag:UpdateColor()
	if self.owner:IsShown() then
		if self.owner:GetAnchor() then
			self:GetNormalTexture():SetTexture(0, 0.2, 0.2, 0.4)
		else
			self:GetNormalTexture():SetTexture(0, 0.5, 0.7, 0.4)
		end
	else
		if self.owner:GetAnchor() then
			self:GetNormalTexture():SetTexture(0.1, 0.1, 0.1, 0.4)
		else
			self:GetNormalTexture():SetTexture(0.5, 0.5, 0.5, 0.4)
		end
	end
end