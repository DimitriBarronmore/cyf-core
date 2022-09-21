local path = (...):gsub("init", "")

-- Batteries
local create_require = require(path .. "scripthack/new_require")
require = create_require(_G)

require(path .. "batteries")

local enc_wrap = require(path .. "scripthack/encounter_wrapper")
local new_encounter_env = enc_wrap.env


-- INITIAL LIBRARY SETUP
function EncounterStarting()
	enc_wrap.post_setup()
	new_encounter_env.EncounterStarting()

end

-- -- STEP BY STEP SETUP
function Update()

	new_encounter_env.Update()
end


-- User must insure this is set in the new file.
return new_encounter_env

