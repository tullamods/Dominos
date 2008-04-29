dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../LibDataBroker-1.0/LibDataBroker-1.0.lua")

local LDB = LibStub("LibDataBroker-1.0")

local callback_result
function callback_test(...)
	callback_result = {...}
end

local function dataobject_registered(callback, doname)
	LDB.RegisterCallback("test", "LibDataBroker_AttributeChanged_"..doname, callback_test)
end

LDB.RegisterCallback("test", "LibDataBroker_DataobjectRegistered", callback_test)
LDB.RegisterCallback("test2", "LibDataBroker_DataobjectRegistered", dataobject_registered)

-- creating new dataobject
local dataobject = LDB:NewDataObject()
assert(type(dataobject) == "table")

-- unset attributes return nil
assert(dataobject["test"] == nil)

-- set attributes return value
dataobject["test"] = 123
assert(dataobject["test"] == 123)

-- registering fires callback
callback_result = nil
LDB:RegisterDataObject("testdo", dataobject)
assert(callback_result[1] == "LibDataBroker_DataobjectRegistered" and callback_result[2] == "testdo" and callback_result[3] == dataobject)

-- changing attribute of registered dataobject fires callback
callback_result = nil
dataobject["test"] = 456
assert(callback_result[1] == "LibDataBroker_AttributeChanged_testdo" and callback_result[2] == "testdo" and callback_result[3] == "test" and callback_result[4] == 456)
assert(dataobject["test"] == 456)

-- functions as attributes
callback_result = nil
local testfunc_result = nil
dataobject.testfunc = function(self, ...) return {LDB:GetNameByDataObject(self), ...} end
assert(callback_result[1] == "LibDataBroker_AttributeChanged_testdo" and callback_result[2] == "testdo" and callback_result[3] == "testfunc" and type(callback_result[4]) == "function")

testfunc_result = dataobject:testfunc("testdata")
assert(testfunc_result[1] == "testdo" and testfunc_result[2] == "testdata")

-- data objects are independant
local dataobject2 = LDB:NewDataObject()
assert(type(dataobject2) == "table" and dataobject2 ~= dataobject)
callback_result = nil
LDB:RegisterDataObject("testdo2", dataobject2)
assert(callback_result[1] == "LibDataBroker_DataobjectRegistered" and callback_result[2] == "testdo2" and callback_result[3] == dataobject2)
callback_result = nil
dataobject2["test"] = "abc"
assert(callback_result[1] == "LibDataBroker_AttributeChanged_testdo2" and callback_result[2] == "testdo2" and callback_result[3] == "test" and callback_result[4] == "abc")
assert(dataobject2["test"] == "abc")
assert(dataobject["test"] == 456)

-- LDB:GetDataObjectByName
assert(LDB:GetDataObjectByName("testdo") == dataobject)
assert(LDB:GetDataObjectByName("testdo2") == dataobject2)

-- LDB:GetNameByDataObject
assert(LDB:GetNameByDataObject(dataobject) == "testdo")
assert(LDB:GetNameByDataObject(dataobject2) == "testdo2")

-- LDB::DataObjectIterator
for k, v in LDB:DataObjectIterator() do
	assert(LDB:GetDataObjectByName(k) == v)
end

print("OK")