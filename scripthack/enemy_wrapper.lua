-- ensure core/batteries loads first

local set = function(tab)
	local settab = {}
	for _,v in ipairs(tab) do
		settab[v] = true
	end
	return settab
end

local path = (...):gsub("enemy_wrapper", "")
local create_require = require(path .. "new_require")
local enc_sandbox = require(path .. "encounter_wrapper")

local export = {}

local special_vars = set{
	"comments",
	"commands",
	"randomdialogue",
	"currentdialogue",
	"defensemisstext",
	"noattackmisstext",
	"cancheck",
	"canspare",
	"isactive",
	"sprite",
	"monstersprite",
	"dialogbubble",
	"dialogueprefix",
	"name",
	"hp",
	"maxhp",
	"atk",
	"def",
	"xp",
	"gold",
	"check",
	"unkillable",
	"canmove",
	"posx",
	"posy",
	"font",
	"voice",
}
    
export.sandbox_templ = {
	"_VERSION",
	"_MOONSHARP",
	"ipairs",
	"pairs",
	"next",
	"type",
	"assert",
	"collectgarbage",
	"error",
	"tostring",
	"select",
	"tonumber",
	"print",
	"setmetatable",
	"getmetatable",
	"rawget",
	"rawset",
	"rawequal",
	"rawlen",
	"string",
	-- "package",
	"loadsafe",
	"loadfilesafe",
	"__require_clr_impl",
	"table",
	"unpack",
	"pack",
	"pcall",
	"xpcall",
	"math",
	"coroutine",
	"bit32",
	"dynamic",
	"os",
	"debug",
	"json",
	"SetGlobal",
	"GetGlobal",
	"SetRealGlobal",
	"GetRealGlobal",
	"SetAlMightyGlobal",
	"GetAlMightyGlobal",
	"isCYF",
	"isRetro",
	"safe",
	"windows",
	"UnloadSprite",
	"CYFversion",
	"LTSversion",
	"CreateSprite",
	"CreateLayer",
	"CreateProjectileLayer",
	"SetFrameBasedMovement",
	"SetAction",
	"SetPPCollision",
	"AllowPlayerDef",
	"CreateBar",
	"CreateBarWithSprites",
	"GetCurrentState",
	"BattleDialog",
	"BattleDialogue",
	"CreateState",
	"Player",
	"Arena",
	"DEBUG",
	"EnableDebugger",
	"Audio",
	"NewAudio",
	"Inventory",
	"Input",
	"Misc",
	"Time",
	"Discord",
	"UI",
	"_getv",
	"State",
	-- "CreateText"
	-- custom additions:
	"rawtype",
}

--[[ special: set outside sandbox 
	"_G",
	"load",	
	"loadfile",
	"dofile", 
	"require",

Happens when you select an Act command on this monster. command will be the same as how you defined it in the commands list, except it will be IN ALL CAPS. Intermediate example below, showing how you can use it and spice it up a little.	"Encounter",

--]]
    
local special_funcs = {
	"SetSprite",
	"SetActive",
	"SetDamage",
	"Kill",
	"Spare",
	"Move",
	"MoveTo",
	"BindToArena",
	"SetBubbleOffset",
	"SetDamageUIOffset",
	"SetSliceAnimOffset",
	"Remove",
	-- "CreateText"
}

local script_events = set{
	"HandleAttack",
	"OnDeath",
	"OnSpare",
	"BeforeDamageCalculation",
	"BeforeDamageValues",
	"HandleCustomCommand",
	"OnCreation",
	"Update",
}

--[[ Special: reimplement
	OnHit,
	OnTextAdvance
--]]


local function create_monster_sandbox()
	local sbox = {}
	for _, key in ipairs(export.sandbox_templ) do
		if rawtype(_G[key]) == "table" then
			sbox[key] = table.deepcopy(_G[key])
		else
			sbox[key] = _G[key]
		end
	end

	sbox._G = sbox
	sbox.Encounter = enc_sandbox.env
	sbox.load = function(a, b, c, env)
		if env == nil then
			env = sbox
		end
		return load(a, b, c, env)
	end
	sbox.loadfile = function(a, b, env)
		if env == nil then
			env = sbox
		end
		return loadfile(a, b, env)
	end
	sbox.dofile = function(fname)
		local chunk, err = loadfile(fname, "bt", _ENV)
		if chunk == nil then
            err = err:gsub("^.-%d%):", "")
            error(err)
        end
		local status, err = pcall(chunk)
		if status == false then
			error(err, 0)
		end
		return err
	end
	sbox.require = create_require(sbox)

	return sbox
end

local scripts_registry = {}
local function register_script(script)
	table.insert(scripts_registry, script)
	return #scripts_registry
end

function __REDIRECT_EVENTS(event, script_id, ...)
	local script = scripts_registry[script_id]
	if script[event] then
		script[event](...)
	end
end

local scripts_to_update = {}
function export.run_update()
	for script, _ in pairs(scripts_to_update) do
		script.Update()
	end
end

function export.CreateEnemy(monster_name, x, y)
	local realenim = CreateEnemy("CORE/blank_mons", x, y)
	local newenim = create_monster_sandbox()

	for _, key in ipairs(special_funcs) do
		newenim[key] = function(...)
			realenim.Call(key, {...})
		end
	end

	newenim.Kill = function()
		scripts_to_update[newenim] = nil
		realenim.Call("Kill")
	end

	newenim.Spare = function()
		scripts_to_update[newenim] = nil
		realenim.Call("Spare")
	end

	newenim.SetActive = function(bool)
		if bool == true then
			scripts_to_update[newenim] = true
		else
			scripts_to_update[newenim] = nil
		end
		realenim.Call("SetActive", bool)
	end

	scripts_to_update[newenim] = true

	-- newenim.CreateText = function(a, b, c, d, e)
	-- 	return realenim.Call("CreateText", {a,b,c,d,e})
	-- end

	local id = register_script(newenim)
	-- realenim.Call("__SETUP_EVENTS", id)

	local sbox_events = {}
	local events_id = register_script(sbox_events)

	for key, _ in pairs(script_events) do
		sbox_events[key] = CreateEvent()
		realenim.Call("__DOSTRING",
			([[%s = function(...)
				Encounter.Call("__REDIRECT_EVENTS", {"%s", %s, ...})
			end
			]]):format(key, key, events_id)
		)
	end

	sbox_events.OnDeath.method = function() newenim.Kill() end
	sbox_events.OnSpare.method = function() newenim.Spare() end


	setmetatable(newenim, {
		__index = function(t, k)
			if special_vars[k] then
				return realenim[k]
			elseif script_events[k] then
				return sbox_events[k]
			else
				return rawget(t, k)
			end
		end,
		__newindex = function(t, k, v)
			if type(v) == "function" and (not script_events[k]) then
				realenim.Call("__DOSTRING",
					([[%s = function(...)
						Encounter.Call("__REDIRECT_EVENTS", {"%s", %s, ...})
					end
					]]):format(k, k, id)
				)
				-- rawset(newenim, k, newenim.load(string.dump(v)))
				-- return
			end
			if special_vars[k] then
				realenim[k] = v
			elseif script_events[k] then
				sbox_events[k].method = v
			else
				rawset(t, k, v)
			end
		end
	})

	local chunk, err = loadfile(("Monsters/%s.lua"):format(monster_name), "t", newenim)
	if chunk == nil then
		error(err, 2)
	end
	local status, res = pcall(chunk)
	if status == false then
		error(res, 2)
	end

	realenim.Call("SetSprite", newenim.sprite)
	newenim.OnCreation()

	return newenim
end

-- Automatically set up the dummy monster file for the user.
local filetext = [[
	function __DOSTRING(str)
		load(str)()
	end
		
	sprite = "empty"
	name = "<dummy>"
]]
local has_monsdir = Misc.DirExists("Lua/Monsters/CORE")
if not has_monsdir then
	Misc.CreateDir("Lua/Monsters/CORE")
	local monsfile = Misc.OpenFile("Lua/Monsters/CORE/blank_mons.lua", "w")
	monsfile.Write(filetext, false)
end


return export 
