--[[
Name: LibDataBroker-1.0
Revision: $Revision$
Author: Elkano (elkano@gmx.de)
Website: http://
Documentation: http://www.wowace.com/wiki/LibDataBroker-1.0
SVN: http://svn.wowace.com/wowace/trunk/LibDataBroker-1.0/
Description: A central registry for addons looking for something to display their data.
Dependencies: LibStub, CallbackHandler-1.0
]]

local MAJOR, MINOR = "LibDataBroker-1.0", "$Revision$"
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local _G = getfenv(0)
local setmetatable = _G.setmetatable

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")

lib.callbacks			= lib.callbacks			or CallbackHandler:New(lib)

lib.attributestorage	= lib.attributestorage	or {}
lib.namestorage			= lib.namestorage		or {}
lib.proxystorage		= lib.proxystorage		or {}

local attributestorage	= lib.attributestorage
local namestorage		= lib.namestorage
local proxystorage		= lib.proxystorage

local domt
domt = {
	__metatable =		"access denied",
	__newindex =		function(self, key, value)
							if not attributestorage[self] then attributestorage[self] = {} end
							if attributestorage[self][key] == value then return end
							attributestorage[self][key] = value
							local name = namestorage[self]
							if name then
								lib.callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value)
							end
						end,
	__index =			function(self, key)
							return attributestorage[self] and attributestorage[self][key] or nil
						end,
}

function lib:NewDataObject()
	local dataobject = setmetatable({}, domt)
	return dataobject
end

function lib:RegisterDataObject(dataobjectname, dataobject)
	if not proxystorage[dataobjectname] then
		proxystorage[dataobjectname] = dataobject
		namestorage[dataobject] = dataobjectname
		lib.callbacks:Fire("LibDataBroker_DataobjectRegistered", dataobjectname, dataobject)
		return true
	end
	return false
end

function lib:DataObjectIterator()
	return pairs(proxystorage)
end

function lib:GetDataObjectByName(dataobjectname)
	return proxystorage[dataobjectname]
end

function lib:GetNameByDataObject(dataobject)
	return namestorage[dataobject]
end
