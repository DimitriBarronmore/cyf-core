--[[ 
	
	CORE Inheritance -- A wave wrapper which sandboxes them inside the Encounter script.
	Made so you can pass values directly to and from the Encounter object.
	Later improved so that the sandbox can be expanded by the user.
	https://github.com/DimitriBarronmore/cyf-core-labs

	© 2021 Dimitri Barronmore
 --]]


-- If this value is true, EndWave() will behave as it normally does.
-- If this value is false, EndWave() will end only the wave it is called in.
if end_waves_simultaneously == nil then
	end_waves_simultaneously = true
end

-- Gotta declare this early for structure reasons
local core_endallwaves

local values_to_copy = {
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
	--"load", --replace all loads?
	--"loadsafe",
	--"loadfile",
	--"loadfilesafe",
	--"dofile",
	"__require_clr_impl",
	--"require",
	"table",
	"unpack",
	"pack",
	--"package",
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
	"safe",
	"windows",
	"CYFversion",
	"CreateSprite",
	"CreateLayer",
	"CreateProjectileLayer",
	"SetFrameBasedMovement",
	"SetAction",
	"SetPPCollision",
	"AllowPlayerDef",
	--"CreateText",
	"GetCurrentState",
	"BattleDialog",
	"BattleDialogue",
	"Encounter",
	"Player",
	"DEBUG",
	"EnableDebugger",
	"Audio",
	"NewAudio",
	"Inventory",
	"Input",
	"Misc",
	"Time",
	"Discord",
	"_getv",
	--"EndWave", --replace this
	"State",
	--"CreateProjectile",
	--"CreateProjectileAbs"
} 

function AddToSandbox(target)
	if not table.findindex(values_to_copy, target) then
		table.insert(values_to_copy, target)
	end
end

function RemoveFromSandbox(target)
	res = table.findindex(values_to_copy, target)
	if res then 
		table.remove(values_to_copy,res)
	end
end

local function createEnv(source)
	source = source or _ENV
	local new_environment = {}
	for i,v in ipairs(values_to_copy) do
		if type(source[v]) == "table" then
			new_environment[v] = table.deepcopy(source[v])
		else
			new_environment[v] = source[v]
		end
	end
	return new_environment
end

local state_waves_loaded = 0
-- 0 : not defending
-- 1 : begin counting up to wave load
-- 2 : load waves
-- 3 : currently defending


-- capture/redirect nextwaves and the wave timer
local active_waves = {}
local waves_to_load = {}
local real_wavetimer
local function captureWaves()
	waves_to_load = nextwaves
	nextwaves = { "blank_wave"}
	real_wavetimer = wavetimer
	wavetimer = math.huge
	state_waves_loaded = 2
end
EnemyDialogueEnding:CreateGroup("INHERITANCE_Post","last")
EnemyDialogueEnding:Add(captureWaves,"INHERITANCE_Post", "captureWaves")


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

-- Partially remaking require for the sandbox to get around the global environment.
local function fake_require(filename, env) 
	if env.package.loaded[filename] then
		return env.package.loaded[filename]
	else
		local val
		if Misc.FileExists("Lua/" .. filename .. ".lua") then
			val = loadfile("Mods/" .. modName .. "/Lua/" .. filename .. ".lua", "t", env)
		elseif Misc.FileExists("Lua/Libraries/" .. filename .. ".lua") then
			val = loadfile("Mods/" .. modName .. "/Lua/Libraries/" .. filename .. ".lua", "t", env)
		else
			-- error("Mods/" .. modName .. "/Lua/" .. filename .. ".lua")
			error("module " .. filename .. " not found", 2)
		end
		local ret = val(filename)
		env.package.loaded[filename] = ret or true
		return ret
	end
end

local function newbullet(abs, env, list, ...)
	local proj = (abs and CreateProjectileAbs) or CreateProjectile
	proj = proj(...)
	proj.SetVar("wave_inheritance_script", env)
	table.insert(list,proj)
	return proj
end

local function defaultonhit(bullet)
	Player.Hurt(3)
end

local function redirect_onhit(bullet)
	wave = bullet.GetVar("wave_inheritance_script")
	if wave then
		wave.OnHit(bullet)
		return break_event
	end
end
OnHit:CreateGroup("INHERITANCE_Pre","first")
OnHit:Add(redirect_onhit, "INHERITANCE_Pre", "redirect_onhit")

local text_directory = {}
local function wave_createtext(wave, ...)
	local _, txt = pcall(CreateText, ...)
	if _ == false then error(txt, 2) end
	text_directory[txt] = wave
	return txt
end

local function redirect_textadvance(text, final)
	if text_directory[text]then
		text_directory[text].OnTextAdvance(text, final)
		if final then text_directory[text] = nil end
		return break_event
	end
end
OnTextAdvance:CreateGroup("INHERITANCE_Pre","first")
OnTextAdvance:Add(redirect_textadvance,
	 "INHERITANCE_Pre", "redirect_textadvance")


local STATE_ENDING = false

local function endwave(wave, realwave, bullets)
	wave.EndingWave()
	table.remove(active_waves, table.findindex(active_waves,wave))

	if end_waves_simultaneously == false then -- staggered ending
		for i,v in ipairs(bullets) do -- clear local bullets
			v.Remove() 
		end
		if #active_waves == 0 and (not STATE_ENDING) then
			core_endallwaves() -- if all false waves have ended, end the real one
		end
	elseif end_waves_simultaneously ~= false and (not STATE_ENDING) then -- simultanious ending
		core_endallwaves()
	end
end

local encounter_blacklist = {}

encounter_blacklist.GetVar = function(name)
	return encounter_blacklist[name]
end

encounter_blacklist.SetVar = function(name, value)
	encounter_blacklist[name] = value
end

encounter_blacklist.Call = function(name, arg)
	if type(_ENV[name]) ~= "function" then
		error("attempt to call a non-function", 2)
	end
	if type(arg) == "table" then
		st, err = pcall(_ENV[name], table.unpack(arg))
		if st == false then error(err, 2) end
	else
		st, err = pcall(_ENV[name], arg)
		if st == false then error(err, 2) end
	end
end

setmetatable(encounter_blacklist, {
	__index = _ENV, 
	__newindex = function(t,k,v) 
		if k == "wavetimer" then
			real_wavetimer = v
		else
			t[k] = v
		end
	end,
	__pairs = function(t)
			local function iter(t, k)
				local v
				k,v = next(t, k)
				if k == "wavetimer" then
					return k, real_wavetimer
				end
				if v ~= nil then
				 return k,v end
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
		end})


local function createwave(wavename, realwave)
	local newwave = createEnv()
	local bulletlist = {}

	local to_protect = {Update = true,
		OnHit = true,
		OnTextAdvance = true, 
		EndingWave = true}
		
	local safety_shell = setmetatable({}, {
		__index = newwave,
		__newindex = function(t,k,v)
			if to_protect[k] then
				newwave[k].method = v
			else
				newwave[k] = v
			end
		end,
		__pairs = function(t)
			local function iter(t, k)
				local v
				k,v = next(t, k)
				if v ~= nil then return k,v end
			end
			return iter, newwave, nil
		end,
		__ipairs = function(t)
			local function iter(t, i)
				i = i + 1
				local v = t[i]
				if v ~= nil then return i,v end
			end
			return iter, newwave, 0
		end})

		-- alter specific values
	newwave.Encounter = encounter_blacklist
	newwave._G = newwave
	newwave._ENV = newwave
	newwave.package = {loaded = {}}
	newwave.wavename = wavename

	newwave.require = function (input)
		return fake_require(input, safety_shell)
	end
	--[[newwave.load = function(ld, source, mode, env, ...)
		source = (type(ld) == "string" and ld) or "=(load)"
		mode = mode or "bt"
		env = env or newwave
		local status, res = pcall(load, ld, source, mode, env, ...)
		if not status then error(res, 2) end
		return res
	end

	newwave.loadfile = function(source, mode, env, ...)
		mode = mode or "bt"
		env = env or newwave
		local status, res = pcall(load, source, mode, env, ...)
		if not status then error(res, 2) end
		return res
	end--]]

	newwave.load = loadsafe
	newwave.loadfile = loadfilesafe

	newwave.dofile = function(filename, ...)
		if Misc.FileExists("Lua/" .. filename) then
			val = loadfile("Mods/" .. modName .. "/Lua/" .. filename, safety_shell)
		elseif Misc.FileExists("Lua/Libraries/" .. filename) then
			val = loadfile("Mods/" .. modName .. "/Lua/Libraries/" .. filename, safety_shell)
		else
			error("file " .. filename .. " not found")
		end
		res = val(...)
		return res
	end

	newwave.EndWave = function()
		endwave(safety_shell, realwave, bulletlist)
	end

	newwave.OnHit = CreateEvent(defaultonhit)
	newwave.Update = CreateEvent()
	newwave.OnTextAdvance = CreateEvent()

	newwave.CreateText = function(...) 
		return wave_createtext(safety_shell, ...)
	end

	newwave.CreateProjectile = function(...)
		return newbullet(false, safety_shell, bulletlist, ...)
	end
	function newwave.CreateProjectileAbs(...)
		return newbullet(true, safety_shell, bulletlist, ...)
	end
	newwave.Arena = realwave["Arena"]
	newwave.EndingWave = CreateEvent()

	return safety_shell

	-- return newwave
end

local real_wave_table
local function core_loadWaves()
	STATE_ENDING = false
	local realwave = Wave[1]
	real_wave_table = Wave
	Wave = {}

	for i,v in ipairs(waves_to_load) do
		local currentwave = createwave(v, realwave)
		if Misc.FileExists("Lua/Waves/" .. v .. ".lua") then
			res = loadfile("Mods/" .. modName .. '/Lua/Waves/' .. v .. '.lua', "t", currentwave)
		else
			error("error in script encounter\n\nThe wave " .. v .. " doesn't exist.",3)
		end
		res()
		table.insert(active_waves, currentwave)
		table.insert(Wave, currentwave)
	end
	waves_to_load = {}
end


local function core_updateWaves()
	if state_waves_loaded == 0 then
		return
	elseif state_waves_loaded == 1 then
		state_waves_loaded = 2
		return
	elseif state_waves_loaded == 2 then
		core_loadWaves()
		DefenseStarting()
		state_waves_loaded = 3
	elseif state_waves_loaded == 3 then

		if Time.wave > real_wavetimer then
			core_endallwaves()
			return
		end

		for i,v in ipairs(active_waves) do
			v.Update()
		end
	end
end

--Update:CreateGroup("INHERITANCE_WAVES","last")
Update:Add(core_updateWaves,"ADDITIONAL_UPDATES", "update inheritance")

function core_endallwaves( )
	STATE_ENDING = true
	for i,v in ipairs(active_waves) do
		--v.EndingWave()
		v.EndWave()
	end
	Wave = real_wave_table
	wavetimer = real_wavetimer
	active_waves = {}
	state_waves_loaded = 0

	Wave[1].Call("EndWave")
end
