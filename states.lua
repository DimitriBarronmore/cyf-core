--[[ 
	CORE States -- Object-Driven Finite State Machine
	Created as a complete replacement for CYF's EnteringState function.
	https://github.com/DimitriBarronmore/cyf-core-labs

	© 2021 Dimitri Barronmore
--]]

local states_list = { }

local current_state = GetCurrentState()
local last_state_entered = current_state

local valid_game_states = { ACTIONSELECT = true, ATTACKING = true, DEFENDING = true,
							ENEMYSELECT = true, ACTMENU = true, ITEMMENU = true,
							MERCYMENU = true, ENEMYDIALOGUE = true, DIALOGRESULT = true,
							DONE = true, NONE = true, PAUSE = true }

CreateState = function( name, state )
	-- default
	-- DEBUG("CREATING STATE " .. name)
	if state == nil then state = "NONE" end
	
	-- error checking
	-- if not valid_game_states[state] then
	-- 	error("the game state \"" .. tostring(state) .. "\" does not exist.", 2)
	-- end
	if not type(name) == "string" then
		error("state name must be a string", 2)
	end

	-- build state table
	local newstate = { }
	newstate.update = CreateEvent( )
	newstate.onEnter = CreateEvent( )
	newstate.onExit = CreateEvent( )
	newstate._state = state
	newstate.__type = "state"

	-- register in list
	states_list[ name:upper() ] = newstate
	setmetatable(newstate, newstate)

	return newstate
end

for name in pairs(valid_game_states) do
	CreateState(name, name)
	--st.onEnter = function() DEBUG("ENTERING " .. name) end
	--st.onExit = function() DEBUG("EXITING " .. name) end
end

local function GetStateObject(name)
	return states_list[name:upper()]
end

local last_paused

GetRealCurrentState = GetCurrentState

function GetCurrentState()
	if states_list[current_state]._state == "PAUSE" then
		return last_paused
	else
		return current_state
	end
end


local last_name, next_name


local change_state = State

local nested = 0
local nestedmax = 0
local last_last
local first_run = true
local function new_state( nextstate, no_transition )
	-- DEBUG("run " .. nextstate)
	-- uppercase
	nextstate = nextstate:upper()
	next_name, last_name = nextstate, current_state

	-- error checking
	if not type(nextstate == "string") then
		error("state name must be a string", 2)
	elseif not states_list[nextstate] then
		error("attempt to enter state which does not exist", 2)
	end

	nested = nested + 1
	nestedmax = nested

	-- state change logic
	local last, next = states_list[current_state], states_list[nextstate]

	-- new_es_callback(nextstate, current_state)
	if nestedmax > nested then goto EARLY_EXIT end

	--DEBUG(tostring(last_last) .. " " .. tostring(last))
	if next._state == "PAUSE" then 
		last_paused = current_state 
		Update:DisableGroup("ADDITIONAL_UPDATES")
	else
		Update:EnableGroup("ADDITIONAL_UPDATES")
	end

	if last_last == last or next._state == "PAUSE" then goto ENTER end

	last_last = last

	--DEBUG("exit " .. nextstate .. " " .. (table.findindex(states_list, last) or "nil"))
	if first_run == true then
		first_run = false
	else
		last.onExit( nextstate )
	end

	if last._state == "PAUSE" then
		states_list[last_paused].onExit( nextstate )
	end

	if nestedmax > nested then goto EARLY_EXIT end

	::ENTER::

	last_last = false

	--DEBUG("enter " .. nextstate)
	next.onEnter( current_state )

	if nestedmax > nested then goto EARLY_EXIT end

	--if exec_counter > current_exec_counter then goto EARLY_EXIT end

	--DEBUG("change " .. nextstate)

	if nested == nestedmax then
		--DEBUG('change state to ' .. nextstate)
		if no_transition ~= "skip_transition" then
			change_state( next._state )
		end
		current_state = nextstate
	end

	::EARLY_EXIT::

	nested = nested - 1

	--print("h")

end

State = setmetatable({},{
	__call = function(t,arg) return new_state(arg) end,
	__index = function(t,k) return GetStateObject(k) end,
	__newindex = function() error("The State table is read-only.", 2) end
})


local new_entering_state = function (new, old, ignore_this)
	if ignore_this then return end

	local natural = (nested > 0 and "unnatural") or "natural"
	--DEBUG(nested)

	-- DEBUG(natural .. " STATE CHANGE ".. old .. " > " .. new)
	if natural == "natural" then 
		State(new, "skip_transition")
		-- new_es_callback(new, old)
	else
		-- DEBUG("real states: " .. last_name .. " > " .. next_name)
		EnteringState(next_name, last_name, true)
		return break_event
	end

end

EnteringState:Add(new_entering_state, "CORE", "pass correct arguments to enteringstate")

local function update_current_state()
	states_list[current_state].update()
end

-- Update:CreateGroup("STATES_UPDATE", "last")
Update:Add(update_current_state, "ADDITIONAL_UPDATES", "update() current state")

-- return new_es_callback