
assert(LibStub, "LibDataBroker-1.1 requires LibStub")
assert(LibStub:GetLibrary("CallbackHandler-1.0", true), "LibDataBroker-1.1 requires CallbackHandler-1.0")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 2)
if not lib then return end
oldminor = oldminor or 0


lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, proxystorage = lib.attributestorage, lib.namestorage, lib.proxystorage

local domt = {
	__metatable = "access denied",
	__newindex = function(self, key, value)
		if not attributestorage[self] then attributestorage[self] = {} end
		if attributestorage[self][key] == value then return end
		attributestorage[self][key] = value
		local name = namestorage[self]
		if not name then return end
		lib.callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value)
		lib.callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value)
		lib.callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value)
		lib.callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value)
	end,
	__index = function(self, key)
		return attributestorage[self] and attributestorage[self][key]
	end,
}

function lib:NewDataObject(name, dataobj)
	if proxystorage[name] then return end

	assert(type(dataobj) == "table" or type(dataobj) == "nil", "Invalid dataobj, must be nil or a table")
	dataobj = setmetatable(dataobj or {}, self.domt)
	proxystorage[name], namestorage[dataobj] = dataobj, name
	lib.callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj)
	return dataobj
end

if oldminor < 1
	function lib:DataObjectIterator()
		return pairs(proxystorage)
	end

	function lib:GetDataObjectByName(dataobjectname)
		return proxystorage[dataobjectname]
	end

	function lib:GetNameByDataObject(dataobject)
		return namestorage[dataobject]
	end
end
