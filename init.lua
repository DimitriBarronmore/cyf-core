local path = (...):gsub("init", "")

--[[ Loading in baseline modules ]]--

-- Batteries
local create_require = require(path .. "scripthack/new_require")
require = create_require(_G)

require(path .. "batteries")

-- Event System
require(path .. "events")
require(path .. "scripthack/create_enc_events")


--[[ Various Script Wrappers ]]--

-- This script is responsible for creating events for each of the encounter script events, 
-- and then building the protected sandbox for them.
local enc_wrap = require(path .. "scripthack/encounter_wrapper")

-- This script is responsible for creating sandboxes for monster scripts, with created events,
-- and opening up the ability to manipulate them on creation.
local mons_wrap = require(path .. "scripthack/enemy_wrapper")


-- INITIAL LIBRARY SETUP
EncounterStarting:CreateGroup("CORE", "first")
EncounterStarting:Add("CORE", function()
	enc_wrap.post_setup()

end)

-- UPDATES
Update:CreateGroup("CORE", "first")
Update:Add("CORE", function()
	mons_wrap.run_update()
end)

-- USER SANDBOX MODIFICATION
Sandbox = {}
Sandbox.monster_setup = mons_wrap.enemy_sandbox_setup


-- User must insure this is set in the new file.
return enc_wrap.env

