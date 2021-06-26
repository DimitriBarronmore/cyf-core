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

-- Module table.
local inheritance = {}

local sandbox = {}

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
	"CreateText",
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
	"CreateProjectile",
	"CreateProjectileAbs"
} 

function inheritance.AddToSandbox(target)
	if not table.findindex(values_to_copy, target) then
		table.insert(values_to_copy, target)
	end
end

function inheritance.RemoveFromSandbox(target)
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

-- capture/redirect nextwaves
local active_waves = {}
local waves_to_load = {}
local function captureWaves()
	waves_to_load = nextwaves
	nextwaves = {'wave_loader'}
end
EnemyDialogueEnding:CreateGroup("CORE_Post","last")
EnemyDialogueEnding:Add(captureWaves,"CORE_Post", "captureWaves")


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
			error("Mods/" .. modName .. "/Lua/" .. filename .. ".lua")
			--error("module " .. filename .. " not found", 2)
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
OnHit:CreateGroup("CORE_Pre","first")
OnHit:Add(redirect_onhit, "CORE_Pre", "redirect_onhit")

local function endwave(wave, realwave, bullets)
	wave.EndingWave()
	table.remove(active_waves, table.findindex(active_waves,wave))

	if end_waves_simultaneously == false then -- staggered ending
		for i,v in ipairs(bullets) do -- clear local bullets
			v.Remove() 
		end
		if #active_waves == 0 then
			realwave.Call('EndWave') -- if all false waves have ended, end the real one
		end
	else -- simultanious ending
		realwave.Call('EndWave')
	end
end

local function createwave(wavename, realwave)
	local newwave = createEnv()
	local bulletlist = {}
		-- alter specific values
	newwave.Encounter = _ENV
	newwave._G = newwave
	newwave._ENV = newwave
	newwave.package = {loaded = {}}
	newwave.wavename = wavename

	newwave.require = function (input)
		return fake_require(input, newwave)
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
			val = loadfile("Mods/" .. modName .. "/Lua/" .. filename, env)
		elseif Misc.FileExists("Lua/Libraries/" .. filename) then
			val = loadfile("Mods/" .. modName .. "/Lua/Libraries/" .. filename, env)
		else
			error("file " .. filename .. " not found")
		end
		res = val(...)
		return res
	end

	newwave.EndWave = function()
		endwave(newwave, realwave, bulletlist)
	end

	newwave.OnHit = CreateEvent(defaultonhit)
	newwave.Update = CreateEvent()


	newwave.CreateProjectile = function(...)
		return newbullet(false, newwave, bulletlist, ...)
	end
	function newwave.CreateProjectileAbs(...)
		return newbullet(true, newwave, bulletlist, ...)
	end
	newwave.Arena = realwave["Arena"]
	newwave.EndingWave = function() end

	return newwave
end

function core_loadWaves()
	local realwave = Wave[1]
	for i,v in ipairs(waves_to_load) do
		local currentwave = createwave(v, realwave)
		if Misc.FileExists("Lua/Waves/" .. v .. ".lua") then
			res = loadfile("Mods/" .. modName .. '/Lua/Waves/' .. v .. '.lua', "t", currentwave)
		else
			error("error in script encounter\n\nThe wave " .. v .. " doesn't exist.",3)
		end
		res()
		table.insert(active_waves, currentwave)
	end
	waves_to_load = {}
end

function core_updateWaves()
	for i,v in ipairs(active_waves) do
		v.Update()
	end
end

function core_endallwaves( )
	for i,v in ipairs(active_waves) do
		v.EndingWave()
		v.EndWave()
	end
	active_waves = {}
end


return sandbox