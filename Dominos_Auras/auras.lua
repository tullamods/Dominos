local addonName, Addon = ...
Addon.masque = LibStub('Masque', true)
Addon.parent = GetAddOnDependencies(addonName)

local function SkinAura(aura, kind)
	local group = Addon.masque and Addon.masque:Group(Addon.parent, kind)
	if group then
		group:AddButton(aura, {Icon = aura.icon, Cooldown = aura.cooldown})
	end
end

local duration = 1.5
local function GetAlpha(seconds, low, high)
	return math.floor(low + ((math.abs(((seconds - (duration/2))/1) * 100)*(high - low))/100)) / 100
end

local elapsed
local pulsing = {HELPFUL = {}, HARMFUL = {},}
local isPulsing
local pulseTotal = 0

local Pulsing = {}

local function PulseIcons(filter)
	if not filter then return end
	elapsed = elapsed or GetTime()
	if #pulsing[filter] > 0 and not Pulsing[filter] then --don't pulse if function is already being run.
		Pulsing[filter] = true
		local seconds = GetTime() - elapsed		
		if seconds > duration then
			elapsed, Pulsing[filter]  = nil, nil
			return PulseIcons()
		end
		local alpha = GetAlpha(seconds, 30, 100)
		local swipe = GetAlpha(seconds, 20, 50)
		for i, aura in pairs(pulsing[filter]) do
			aura:SetAlpha(alpha)
			aura.cooldown:SetSwipeColor(1,1,1,swipe)--swipeAlpha)
		end
		Pulsing[filter] = nil
	end		
end

Addon.PulseIcons = PulseIcons

local function StartPulse(aura, filter)
	if not tContains(pulsing[filter], aura) then
		tinsert(pulsing[filter], aura)
	end
end

local function EndPulse(aura, filter)
	if tContains(pulsing[filter], aura) then
		tDeleteItem(pulsing[filter], aura)
		aura:SetAlpha(1)
		aura.cooldown:SetSwipeColor(1,1,1,.5)
	end
end

local GetRelPos = function(self)
	local width, height = GetScreenWidth()/self:GetScale(), GetScreenHeight()/self:GetScale();
	local x, y = self:GetCenter()
	local xOffset, yOffset
	local Hori = (x > width/2) and 'RIGHT' or 'LEFT'
	if Hori == 'RIGHT' then
		xOffset = self:GetRight() - width
	else
		xOffset = self:GetLeft()
	end
	local Vert = (y > height/2) and 'TOP' or 'BOTTOM'
	if Vert == 'TOP' then
		yOffset = self:GetTop() - height
	else
		yOffset = self:GetBottom()
	end
	return Vert, Hori, xOffset, yOffset
end

local function SelectProperSide(self)
	local width = GetScreenWidth()
	
	local Vert, Hori, xOffset, yOffset = GetRelPos(self)
	local vert , hori
	
	if Vert == "TOP" then
		vert = "BOTTOM"
	elseif Vert == "BOTTOM" then
		vert = "TOP"
	end		
	
	if Hori == "LEFT" then
		hori = "RIGHT"
	elseif Hori == "RIGHT" then
		hori = "LEFT"
	end
	
	return Vert..Hori, vert..hori
end

local WarnTime = BUFF_DURATION_WARNING_TIME




DominosAuraMixin = {} --must be in the global space, so it can be mixed in

function DominosAuraMixin:OnLoad()
	local filter = self:GetParent():GetParent():GetFilter()
	
	self:RegisterForClicks("AnyUp");
	
	SkinAura(self,  "Aura "..filter)
	self.cooldown:SetHideCountdownNumbers(true)
		
	if Addon["onAuraLoad".. filter] then
		Addon["onAuraLoad".. filter](self)
	end
end

function DominosAuraMixin:OnHide()
	--reset appearance: prevent previous content from displaying
	self.icon:SetTexture("");
	self.cooldown:SetCooldown(0, 0)
	self.cooldown:Hide()
	self.count:SetText("");
	self.name, self.Icon, self.QTY, self.debuffType, self.dura, self.expTime = nil, nil, nil, nil, nil, nil
end

function DominosAuraMixin:OnMouseUp(button)
	--allows a Shift-Left click to send the
	--name of a buff to the chat window edit box.
	--Useful for mount collecting! See someone on 
	--a mount you want? shift-left click the buff icon
	--for easy copy and paste outside of WoW!
	if button == "LeftButton" and IsShiftKeyDown() then
		if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
			local name = UnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self:GetParent():GetAttribute("filter"));
			local _, _, _, _, _, _, spellId = GetSpellInfo(name);
			if spellId then
				ChatEdit_InsertLink(GetSpellLink(spellId))
			else
				ChatEdit_InsertLink(name);
			end
		end
	end
end

function DominosAuraMixin:OnEnter()
	GameTooltip:SetOwner(self,"ANCHOR_BOTTOMLEFT")
	GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2)
	if ( GameTooltip:IsOwned(self) ) then
		if self:GetParent():GetAttribute("filter") =="HELPFUL" then
			GameTooltip:SetUnitAura(self:GetParent():GetAttribute("unit"), self:GetID())
		else
			GameTooltip:SetUnitDebuff(self:GetParent():GetAttribute("unit"), self:GetID())
		end
	end
	
	--Always show the tooltip towards to screen center.
	GameTooltip:ClearAllPoints()
	local p1, p2 = SelectProperSide(self)
	GameTooltip:SetPoint(p1, self, p2)
end

function DominosAuraMixin:OnLeave()
	GameTooltip:Hide()
end

function DominosAuraMixin:OnUpdate(elapsed)
	if self:IsShown() then
		local name, icon, count, debuffType, dura, expTime, _, _, _, _, _, _, _, _, timeMod = UnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self:GetAttribute("filter"))
		if name then
			local dura = (dura and dura > 0) and dura or 0
			local expTime = (expTime and expTime > 0) and expTime or 0
			local remaining = (dura and expTime) and expTime - elapsed or 0

			self.cooldown:SetCooldown(expTime - dura, dura or 0)	

			--because i can.
			local _ = (((remaining > 0) and (remaining <= 10)) and StartPulse or EndPulse)(self, self:GetParent():GetParent():GetFilter()) --apparently, functions can b expressed this way.
			local _ = (icon ~= self.Icon) and self.icon:SetTexture(icon)
			local _ = (count ~= self.QTY) and self.count:SetText(count > 1 and count or "")

			if (dura ~= self.dura) or (expTime ~= self.expTime) then
				if (dura > 0 or expTime > 0) then
					self.cooldown:Show()
				else
					self.cooldown:Hide()
				end
			end
			
			if not _G["OmniCC"] then
				local fontColor, text = NORMAL_FONT_COLOR
				if remaining > 0 then -- Update our timeLeft
					text = max( ((timeMod>0) and (remaining/timeMod) or remaining) + 1, 0 )
					fontColor = (remaining < WarnTime) and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
				end
				local _ = text and self.cooldown.text:SetFormattedText(SecondsToTimeAbbrev(text));
				self.cooldown.text:SetVertexColor(fontColor.r, fontColor.g, fontColor.b);
			end
			
			self.name, self.Icon, self.QTY, self.debuffType, self.dura, self.expTime = name, icon, count, debuffType, dura, expTime
		end
	else
		EndPulse(self, self:GetParent():GetParent():GetFilter())
	end
end
