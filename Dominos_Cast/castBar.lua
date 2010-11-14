--[[
	castBar.lua
		A dominos based casting bar
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

local DCB = Dominos:NewModule('CastingBar')
local CastBar, CastingBar

function DCB:Load()
	self.frame = CastBar:New()
end

function DCB:Unload()
	self.frame:Free()
end


--[[ Dominos Frame Object ]]--

CastBar = Dominos:CreateClass('Frame', Dominos.Frame)

function CastBar:New()
	local f = self.super.New(self, 'cast')
	f:SetFrameStrata('HIGH')

	if not f.cast then
		f.cast = CastingBar:New(f)
		f.header:SetParent(nil)
		f.header:ClearAllPoints()
		f:SetWidth(240) 
		f:SetHeight(24)
	end

	f:UpdateText()
	f:Layout()

	return f
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		showText = true,
	}
end

function CastBar:ToggleText(enable)
	self.sets.showText = enable or nil
	self:UpdateText()
end

function CastBar:UpdateText()
	if self.sets.showText then
		self.cast.time:Show()
	else
		self.cast.time:Hide()
	end
	self.cast:AdjustWidth()
end

function CastBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

	local time = panel:NewCheckButton(Dominos_SHOW_TIME)
	time:SetScript('OnClick', function(b) self:ToggleText(b:GetChecked()) end)
	time:SetScript('OnShow', function(b) b:SetChecked(self.sets.showText) end)

	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewScaleSlider()
	panel:NewPaddingSlider()

	self.menu = menu
end

function CastBar:Layout()
	self:SetWidth(max(self.cast:GetWidth() + 4 + self:GetPadding()*2, 8))
	self:SetHeight(max(24 + self:GetPadding()*2, 8))
end


--[[ CastingBar Object ]]--

CastingBar = Dominos:CreateClass('StatusBar')

--omg speed
local BORDER_SCALE = 197/150 --its magic!
local TEXT_PADDING = 18

function CastingBar:New(parent)
	local f = self:Bind(CreateFrame('StatusBar', 'DominosCastingBar', parent, 'DominosCastingBarTemplate'))
	f:SetPoint('CENTER')

	local name = f:GetName()
	local _G = getfenv(0)
	f.time = _G[name .. 'Time']
	f.text = _G[name .. 'Text']
	f.borderTexture = _G[name .. 'Border']
	f.flashTexture = _G[name .. 'Flash']

	f.normalWidth = f:GetWidth()
	f:SetScript('OnUpdate', f.OnUpdate)
	f:SetScript('OnEvent', f.OnEvent)

	return f
end

function CastingBar:OnEvent(event, ...)
	CastingBarFrame_OnEvent(self, event, ...)

	local unit, spell = ...
	if unit == self.unit then
		if event == 'UNIT_SPELLCAST_FAILED' or event == 'UNIT_SPELLCAST_INTERRUPTED' then
			self.failed = true
		elseif event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
			self.failed = nil
		end
		self:UpdateColor(spell)
	end
end

function CastingBar:OnUpdate(elapsed)
	CastingBarFrame_OnUpdate(self, elapsed)

	if self.casting then
		self.time:SetFormattedText('%.1f', self.maxValue - self.value)
		self:AdjustWidth()
	elseif self.channeling then
		self.time:SetFormattedText('%.1f', self.value)
		self:AdjustWidth()
	end
end

function CastingBar:AdjustWidth()
	local textWidth = self.text:GetStringWidth() + TEXT_PADDING
	local timeWidth = (self.time:IsShown() and (self.time:GetStringWidth() + 4) * 2) or 0
	local width = textWidth + timeWidth

	local diff = width - self.normalWidth
	if diff > 0 then
		diff = width - self:GetWidth()
	else
		diff = self.normalWidth - self:GetWidth()
	end

	if diff ~= 0 then
		local newWidth = self:GetWidth() + diff
		self:SetWidth(newWidth)
		self.borderTexture:SetWidth(newWidth * BORDER_SCALE)
		self.flashTexture:SetWidth(newWidth * BORDER_SCALE)

		self:GetParent():Layout()
	end
end

function CastingBar:UpdateColor(spell)
	if self.failed then
		self:SetStatusBarColor(0.86, 0.08, 0.24)
	elseif spell and IsHelpfulSpell(spell) then
		self:SetStatusBarColor(0.31, 0.78, 0.47)
	elseif spell and IsHarmfulSpell(spell) then
		self:SetStatusBarColor(0.63, 0.36, 0.94)
	else
		self:SetStatusBarColor(1, 0.7, 0)
	end
end

--hide the old casting bar
CastingBarFrame:UnregisterAllEvents()
CastingBarFrame:Hide()