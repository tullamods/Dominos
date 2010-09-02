--[[
	bindableButton.lua
		An abstract button class used to allow keybound to work transparently on both the stock blizzard bindings, and click bindings
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

local BindableButton = Dominos:CreateClass('CheckButton')
Dominos.BindableButton = BindableButton

local KeyBound = LibStub('LibKeyBound-1.0')
local _G = _G

--there's a nice assumption here: all hotkey text will use the same naming convention
--the call here is wacky because this functionality is actually called for the blizzard buttons _before_ I'm able to bind the action button methods to them
function BindableButton:UpdateHotkey(buttonType)
	local key = BindableButton.GetHotkey(self, buttonType)
	if key ~= ''  and Dominos:ShowBindingText() then
		_G[self:GetName()..'HotKey']:SetText(key)
		_G[self:GetName()..'HotKey']:Show()
	else
		_G[self:GetName()..'HotKey']:SetText('') --blank out non blank text, such as RANGE_INDICATOR
		_G[self:GetName()..'HotKey']:Hide()
	end
end

--returns what hotkey to display for the button
function BindableButton:GetHotkey(buttonType)
	local key = BindableButton.GetBlizzBindings(self, buttonType) or BindableButton.GetClickBindings(self)
	return key and KeyBound:ToShortKey(key) or ''
end

--returns all blizzard bindings assigned to the button
function BindableButton:GetBlizzBindings(buttonType)
	local buttonType = buttonType or self.buttonType
	if buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		return GetBindingKey(buttonType .. id)
	end
end

--returns all click bindings assigned to the button
function BindableButton:GetClickBindings()
	return GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
end

--returns a comma separated list of all bindings for the given action button
--used for keybound support
local function getKeyStrings(...)
	local keys
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if keys then
			keys = keys .. ", " .. GetBindingText(key, "KEY_")
		else
			keys = GetBindingText(key, "KEY_")
		end
	end
	return keys
end

function BindableButton:GetBindings()
	local blizzKeys = getKeyStrings(self:GetBlizzBindings())
	local clickKeys = getKeyStrings(self:GetClickBindings())

	if blizzKeys then
		if clickKeys then
			return blizzKeys .. ', ' .. clickKeys
		end
		return blizzKeys
	else
		return clickKeys
	end
end

--set bindings (more keybound support)
function BindableButton:SetKey(key)
	if self.buttonType then
		local id = self:GetAttribute('bindingid') or self:GetID()
		SetBinding(key, self.buttonType .. id)
	else
		SetBindingClick(key, self:GetName(), 'LeftButton')
	end
end

--clears all bindings from the button (keybound support again)
local function ClearBindings(...)
	for i = 1, select('#', ...) do
		SetBinding(select(i, ...), nil)
	end
end

function BindableButton:ClearBindings()
	ClearBindings(self:GetBlizzBindings())
	ClearBindings(self:GetClickBindings())
end