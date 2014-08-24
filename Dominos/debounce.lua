local Dominos = Dominos
local unpack = unpack
local select = select
local Timer_After = _G['C_Timer'].After

function Dominos:Debounce(func, wait, isImmediate)
	local args = nil
	local argCount = 0
	local isRunning = false

	local ready = function ()
		if not isImmediate then
			if argCount > 1 then
				func(unpack(args, 1, argCount))
			elseif argCount > 0 then
				func(args)
			else
				func()
			end
		end	

    	isRunning = false 		
	end

	return function(...)		
	    local callNow = isImmediate and not isRunning

	    if not isRunning then
	    	isRunning = true
	    	Timer_After(wait, ready)
	    end

    	if callNow then
    		func(...)
    	else
	    	-- a minor optimization to make sure that we don't create
	    	-- a billion tables if the user is never passing more than one argument to the function
	    	argCount = select('#', ...)
	    	if argCount > 1 then
	    		args = { ... }
	    	else
	    		args = ...
	    	end
	    end
	end
end