 
--[[
	
	This file automatically initializes all major CORE libraries.
	You don't really need to use it, but you can. You can add and remove stuff as well.

--]]

-- big libraries
require "CORE/Setup/changed_functions"
require "CORE/Events"
require "CORE/Setup/initialize_events"
require "CORE/Overwrite"

-- specific script libraries
local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only
	require "CORE/Inheritance"
end

-- smaller libraries
require "CORE/Types/ordered_dict"