local path = (...):gsub("init", "")

--[[ Loading in baseline modules ]]--

-- Batteries
local create_require = require(path .. "scripthack/new_require")
require = create_require(_G)

require(path .. "batteries")

-- Event System
require(path .. "events")
require(path .. "scripthack/create_enc_events")

Update:CreateGroup("CORE", "first")
Update:CreateGroup("ADDITIONAL_UPDATES", "AfterMethod")
EncounterStarting:CreateGroup("CORE", "first")
EnteringState:CreateGroup("CORE", "first")



--[[ Various Script Wrappers ]]--

-- This script is responsible for creating sandboxes for monster scripts, with created events,
-- and opening up the ability to manipulate them on creation.
local mons_wrap = require(path .. "scripthack/enemy_wrapper")

Update:Add("ADDITIONAL_UPDATES", function()
	mons_wrap.run_update()
end)



-- USER SANDBOX MODIFICATION
local sandbox_obj = {}
sandbox_obj.monster_setup = mons_wrap.enemy_sandbox_setup



-- This script is responsible for capping off the Encounter sandbox.
local enc_wrap = require(path .. "scripthack/encounter_wrapper")
local env = enc_wrap.env

-- ENSURE THAT ALL ADDED FUNCTIONS ARE PRESENT
env.rawtype = rawtype
env.CreateEvent = CreateEvent
-- env.State = perm_State

-- VALUES TO SET HERE:
	-- "State",
	-- "RandomEncounterText",
	-- "CreateProjectile",
	-- "CreateProjectileAbs",
	-- "SetButtonLayer",
	-- "CreateEnemy",
	-- "Flee",
	-- "Wave",
EncounterStarting:Add("CORE", function()
	enc_wrap.post_setup()
	env.CreateEnemy = mons_wrap.CreateEnemy

	-- Custom States
	local new_es = require(path .. "states")
	env.GetCurrentState = GetCurrentState
	env.CreateState = CreateState
	env.GetRealCurrentState = GetRealCurrentState
	env.State = State
	-- rawset(env, "EnteringState", new_es)
end)


-- User must insure this is set in the new file.
return enc_wrap.env

