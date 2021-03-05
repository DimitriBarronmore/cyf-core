 
--[[
	
	This file automatically initializes all major CORE libraries.
	Feel free to add and remove stuff as well, 
	but remember that certain libraries depend on the functionality of others.

--]]

-- just about everything relies on this in one way or another
require "CORE/Setup/changed_functions"

-- big libraries, in necessary order
require "CORE/Events"
require "CORE/Setup/initialize_events"
require "CORE/Overwrite"

-- script-specific libraries
local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only
	require "CORE/Inheritance"
end

-- smaller libraries
--require "CORE/Types/ordered_dict"