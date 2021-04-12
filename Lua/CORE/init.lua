local current_folder = (...):gsub('%init$', '')
--[[
	
	This file automatically initializes all major CORE libraries.
	Feel free to add and remove stuff as well, 
	but remember that certain libraries depend on the functionality of others.

--]]

-- just about everything relies on this in one way or another
require (current_folder .. "Setup/changed_functions")

-- big libraries, in necessary order
require (current_folder .. "Events")
require (current_folder .. "Setup/initialize_events")
require (current_folder .. "Overwrite")

-- script-specific libraries, just in case
local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only
	require (current_folder .."Inheritance")
	require (current_folder .. "Setup/initialize_wave_sandbox")

end

-- smaller libraries
--require "CORE/Types/ordered_dict"