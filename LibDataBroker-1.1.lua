
assert(LibStub, "LibDataBroker-1.1 requires LibStub")
assert(LibStub:GetLibrary("CallbackHandler-1.0", true), "LibDataBroker-1.1 requires CallbackHandler-1.0")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 2)
if not lib then return end
oldminor = oldminor or 0


lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, callbacks = lib.attributestorage, lib.namestorage, lib.callbacks

lib.domt = lib.domt or {
	__metatable = "access denied",
	__newindex = function(self, key, value)
		if not attributestorage[self] then attributestorage[self] = {} end
		if attributestorage[self][key] == value then return end
		attributestorage[self][key] = value
		local name = namestorage[self]
		if not name then return end
		callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value)
		callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value)
	end,
	__index = function(self, key)
		return attributestorage[self] and attributestorage[self][key]
	end,
}

function lib:NewDataObject(name, dataobj)
	if self.proxystorage[name] then return end

	if dataobj then
		assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
		self.attributestorage[dataobj] = {}
		for i,v in pairs(dataobj) do
			self.attributestorage[dataobj][i] = v
			dataobj[i] = nil
		end
	end
	dataobj = setmetatable(dataobj or {}, self.domt)
	self.proxystorage[name], self.namestorage[dataobj] = dataobj, name
	self.callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj)
	return dataobj
end

if oldminor < 1 then
	function lib:DataObjectIterator()
		return pairs(self.proxystorage)
	end

	function lib:GetDataObjectByName(dataobjectname)
		return self.proxystorage[dataobjectname]
	end

	function lib:GetNameByDataObject(dataobject)
		return self.namestorage[dataobject]
	end
end
