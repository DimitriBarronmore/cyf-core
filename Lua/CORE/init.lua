--[[
	
	This file automatically initializes all major CORE libraries.
	Feel free to add and remove stuff if you must, 
	but remember that most modules depend on others to work.

--]]


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

-- just about everything relies on this in one way or another
require (current_folder .. "Setup/changed_functions")


-- Events

require(current_folder .. "Events")

-- Initialize events in the current environment
require(current_folder .. "Setup/initialize_events")

-- Overwrite

require(current_folder .. "Overwrite")
-- Pre-wrap various objects
require(current_folder .. "Setup/prewrap_userdata")

-- script-specific libraries, just in case
local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only

	Update:CreateGroup("ADDITIONAL_UPDATES","last")

	-- Inheritance
	DefenseStarting = CreateEvent()
	require ("CORE/Inheritance")

	-- Events
	AddToSandbox("CreateEvent")
	AddToSandbox("break_event")

	-- Overwrite
	AddToSandbox("WrapUserdata")
	AddToSandbox("GetIsWrapped")

	-- States
	EncounterStarting:CreateGroup("CORE_Setup", "first")
	EncounterStarting:Add(function() 
		require "CORE/States" 
	end, "CORE_Setup", "import states")

	-- Monster Script Improvements
	EncounterStarting:Add(function()
		for _, v in pairs(enemies) do
			v.Call("EncounterStarting")
		end
	end, "CORE_Setup", "Monster EncounterStarting")

	local function update_monsters()
		for _, v in pairs(enemies) do
			v.Call("Update")
		end
	end

	EncounterStarting:Add(function()
		Update:Add(update_monsters, "ADDITIONAL_UPDATES", "update() monsters")
	end, "CORE_Setup", "setup monster update")


end

-- Safety Environment!

local safe_env = {}
local to_protect = {
	EncounterStarting = true,
	EnemyDialogueStarting = true,
	EnemyDialogueEnding = true,
	DefenseEnding = true,
	HandleSpare = true,
	HandleItem = true,
	EnteringState = true,
	Update = true,
	BeforeDeath = true,
	OnHit = true,
	HandleAttack = true,
	OnDeath = true,
	OnSpare = true,
	OnTextAdvance = true,
	BeforeDamageCalculation = true,
	BeforeDamageValues = true,
	HandleCustomCommand = true,
	EndingWave = true,
	DefenseStarting = true
}

setmetatable(safe_env, {
	__index = _ENV, 
	__newindex = function(t,k,v)
		if to_protect[k] and _ENV[k] then
			_ENV[k].method = v
		else
			_ENV[k] = v
		end
	end,
	__pairs = function(t)
			local function iter(t, k)
				local v
				k,v = next(t, k)
				if v ~= nil then return k,v end
			end
			return iter, _ENV, nil
		end,
	__ipairs = function(t)
		local function iter(t, i)
			i = i + 1
			local v = t[i]
			if v ~= nil then return i,v end
		end
		return iter, _ENV, 0
	end })

return safe_env