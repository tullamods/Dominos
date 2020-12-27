local addonName, addonTable = ...
DominosAuras = _G.LibStub("AceAddon-3.0"):NewAddon(addonTable, addonName)

function DominosAuras:OnInitialize()
	self.masque = LibStub('Masque', true)
end

function DominosAuras:SkinAura(aura, kind)
	local group = self.masque and self.masque:Group("Dominos", kind)
	if group then
		group:AddButton(aura, {Icon = aura.icon, Cooldown = aura.cooldown})
	end
end

local duration = 1.5
local function GetAlpha(seconds, low, high)
	return math.floor(low + ((math.abs(((seconds - (duration/2))/1) * 100)*(high - low))/100)) / 100
end

local elapsed
local pulsing = {}
local isPulsing
local pulseTotal = 0
function DominosAuras:PulseIcons()
	elapsed = elapsed or GetTime()
	if #pulsing > 0 and not Pulsing then --don't pulse if function is already being run.
		Pulsing = true
		local seconds = GetTime() - elapsed		
		if seconds > duration then
			elapsed,Pulsing  = nil, nil
			return DominosAuras:PulseIcons()
		end
		local alpha = GetAlpha(seconds, 30, 100)
		local swipe = GetAlpha(seconds, 20, 50)
		for i, aura in pairs(pulsing) do
			aura:SetAlpha(alpha)
			aura.cooldown:SetSwipeColor(1,1,1,swipe)--swipeAlpha)
			Pulsing = nil
		end
		Pulsing = nil
	end		
end

local function StartPulse(aura)
	if not tContains(pulsing, aura) then
		tinsert(pulsing, aura)
	end
end

local function EndPulse(aura)
	if tContains(pulsing, aura) then
		tDeleteItem(pulsing, aura)
		aura:SetAlpha(1)
		aura.cooldown:SetSwipeColor(1,1,1,.5)
	end
end

local mixin = {}
DominosAurasMixin = mixin --must be in the global space, so it can be mixed in

function mixin:OnLoad()
	self:RegisterForClicks("AnyUp");
	DominosAuras:SkinAura(self,  "Aura "..self:GetParent():GetAttribute("filter"))
	self.cooldown:SetHideCountdownNumbers(true)
end

function mixin:OnHide()
	--reset appearance: prevent previous content from displaying
	self.icon:SetTexture("");
	self.cooldown:SetCooldown(0, 0)
	self.cooldown:Hide()
	self.count:SetText("");
	self.name, self.Icon, self.QTY, self.debuffType, self.dura, self.expirationTime = nil, nil, nil, nil, nil, nil
end

function mixin:OnMouseUp()
	--allows a Shift-Left click to send the
	--name of a buff to the chat window edit box.
	--Useful for mount collecting! See someone on 
	--a mount you want? shift-left click the buff icon, 
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

function mixin:OnEnter()
	GameTooltip:SetOwner(self,"ANCHOR_BOTTOMLEFT")
	GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2)
	if ( GameTooltip:IsOwned(self) ) then
		if self:GetParent():GetAttribute("filter") =="HELPFUL" then
			GameTooltip:SetUnitAura(self:GetParent():GetAttribute("unit"), self:GetID())
		else
			GameTooltip:SetUnitDebuff(self:GetParent():GetAttribute("unit"), self:GetID())
		end
	end
end

function mixin:OnLeave()
	GameTooltip:Hide()
end

function mixin:OnUpdate(elapsed)
	if self:IsShown() then
		local name, icon, count, debuffType, dura, expirationTime, _, _, _, _, _, _, _, _, timeMod = UnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self:GetAttribute("filter"))
		if name then
			if (name ~= self.name) or (icon ~= self.Icon) or (count ~= self.QTY) or (debuffType ~= self.debuffType) or (dura ~= self.dura) or (expirationTime ~= self.expirationTime) then
				self.icon:SetTexture(icon);
				if (dura or expirationTime) and ((dura>0) or (expirationTime>0)) then
					self.cooldown:SetCooldown(expirationTime - dura, dura);
				else
					self.cooldown:SetCooldown(0, 0)
					self.cooldown:Hide()
				end

				if not _G["OmniCC"] then
					-- Update our timeLeft
					local timeLeft = expirationTime - elapsed
					if ( timeMod > 0 ) then
						timeLeft = timeLeft / timeMod;
					end
					timeLeft = max( timeLeft + 1, 0 );

					self.cooldown.text:SetFormattedText(SecondsToTimeAbbrev(timeLeft));
					if ( timeLeft < BUFF_DURATION_WARNING_TIME ) then
						self.cooldown.text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					else
						self.cooldown.text:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
					end
					
					local font = self.cooldown.text:GetFont()
					self.cooldown.text:SetWordWrap(false)					
				end
				if not (count>1)then count="" end
				self.count:SetText(count);
			end
			local t = expirationTime - elapsed
			
			if (t > 0) and (t <= 10) then --pulse
				StartPulse(self)
			else
				EndPulse(self)
			end
			self.name, self.Icon, self.QTY, self.debuffType, self.dura, self.expirationTime = name, icon, count, debuffType, dura, expirationTime
		end
	else
		EndPulse(self)
	end
end

local header  = {}
DominosAurasHeaderMixin = header --must be in the global space, so it can be mixed in

function header:OnLoad()
	self:GetParent():RegisterEvent("UNIT_AURA");
	self:GetParent():RegisterEvent("UNIT_TARGET");
	self:GetParent():RegisterEvent("GROUP_ROSTER_UPDATE");
	self:GetParent():RegisterEvent("PLAYER_ENTERING_WORLD");
	self:GetParent():RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	self:GetParent():RegisterUnitEvent("UNIT_AURA", "player", "vehicle");
	
	RegisterUnitWatch(self)
	self:GetParent().headerAura = self
end

function header:Update()
	if not self:GetParent().sets then return end --safety precaution
	local _time = GetTime()
	for i = 1, self:GetParent().sets.columns * self:GetParent().sets.rows do
		local aura = self:GetAttribute("child" .. i)
		if aura then
			aura:OnUpdate(_time)
		end
	end
	DominosAuras:PulseIcons()
end
