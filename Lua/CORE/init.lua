--[[
	
	This file automatically initializes all major CORE libraries.
	Feel free to add and remove stuff as well, 
	but remember that certain libraries depend on the functionality of others.

--]]

-- A convenience flag to demonstrate that CORE is loaded.
CORE_LOADED = true
CORE_VERSION = "prerelease"

local current_folder = (...):gsub('%init$', '')

-- Excellent mod path/name finder snippet adapted shamelessly from here:
-- https://github.com/AllyTally/meow-2/blob/main/Lua/Libraries/Overworld.lua
-- Because the one at https://github.com/AllyTally/cyf-snippets literally doesn't work
local modPath, modName
do
	output = Misc.OpenFile("","w").filePath
        output = output:gsub("/", "\\")
        modPath = output
        modName = output:sub(0, output:find("\\[^\\]*$") - 1):sub(output:sub(0, output:find("\\[^\\]*$") - 1):find("\\[^\\]*$") + 1, output:len())
end

-- We're introducing new loading modes now. Very important.
local loading_mode = _coremode or "dump"
local core
if loading_mode == "packaged" then
	core = {}
end



-- just about everything relies on this in one way or another
require (current_folder .. "Setup/changed_functions")


-- Events

local events = require(current_folder .. "Events")

if loading_mode == "packaged" then
	core.events = events

elseif loading_mode == "modules" then
	_ENV.events = events

elseif loading_mode == "dump" then
	_ENV.CreateEvent = events.CreateEvent
	_ENV.break_event = events.break_event

end

-- Initialize events in the current environment
local initevents = loadfile("Mods/" .. modName .. "/Lua/" .. current_folder .. "Setup/initialize_events.lua", "t", _ENV)
initevents(events.CreateEvent)


-- Overwrite

local wrapudata = require(current_folder .. "Overwrite")

if loading_mode == "packaged" then
	core.overwrite = {}
	core.overwrite.WrapUserdata = wrapudata

elseif loading_mode == "modules" then
	_ENV.overwrite = {}
	_ENV.overwrite.WrapUserdata = wrapudata

elseif loading_mode == "dump" then
	_ENV.WrapUserdata = wrapudata

end

-- script-specific libraries, just in case
local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only

	-- these need to be updated somewhat
	require ("CORE/Inheritance")
	--require ("CORE/Setup/initialize_wave_sandbox")

end

-- smaller libraries
--require "CORE/Types/ordered_dict"


return core