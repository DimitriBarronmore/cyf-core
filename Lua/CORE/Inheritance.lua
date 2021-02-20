
--[[ 
	
	CORE Inheritance -- A wave wrapper which sandboxes them inside the Encounter script.
	Made so you can pass values directly to and from the Encounter object.
	Designed for use in Create Your Frisk by https://github.com/DimitriBarronmore

	Copyright © 2020 Dimitri Barronmore
	Released under a Creative Commons Attribution 4.0 International license.
	https://creativecommons.org/licenses/by/4.0/
 --]]

-- A convenience value for library makers.
-- You can use this to test whether this file has been loaded or not.
CORE_Inheritance = true 

-- If this value is true, EndWave() will behave as it normally does.
-- If this value is false, EndWave() will end only the wave it is called in.
end_waves_simultaniously = true


-- Big ol' sandbox so nothing gets through. Probably not that secure.
wave_sandbox = {
_VERSION = _VERSION,
_MOONSHARP = _MOONSHARP,
ipairs = ipairs,
pairs = pairs,
next = next,
type = type,
assert = assert,
collectgarbage = collectgarbage,
error = error,
tostring = tostring,
select = select,
tonumber = tonumber,
print = print,
setmetatable = setmetatable,
getmetatable = getmetatable,
rawget = rawget,
rawset = rawset,
rawequal = rawequal,
rawlen = rawlen,
string = string,
package = package,
load = load,
loadsafe = loadsafe,
loadfile = loadfile,
loadfilesafe = loadfilesafe,
dofile = dofile,
__require_clr_impl = __require_clr_impl,
require = require,
table = table,
unpack = unpack,
pack = pack,
pcall = pcall,
xpcall = xpcall,
math = math,
coroutine = coroutine,
bit32 = bit32,
dynamic = dynamic,
os = os,
debug = debug,
json = json,
SetGlobal = SetGlobal,
GetGlobal = GetGlobal,
SetRealGlobal = SetRealGlobal,
GetRealGlobal = GetRealGlobal,
SetAlMightyGlobal = SetAlMightyGlobal,
GetAlMightyGlobal = GetAlMightyGlobal,
isCYF = isCYF,
safe = safe,
windows = windows,
CYFversion = CYFversion,
CreateSprite = CreateSprite,
CreateLayer = CreateLayer,
CreateProjectileLayer = CreateProjectileLayer,
SetFrameBasedMovement = SetFrameBasedMovement,
SetAction = SetAction,
SetPPCollision = SetPPCollision,
AllowPlayerDef = AllowPlayerDef,
CreateText = CreateText,
GetCurrentState = GetCurrentState,
BattleDialog = BattleDialog,
BattleDialogue = BattleDialogue,
Encounter = Encounter,
Player = Player,
DEBUG = DEBUG,
EnableDebugger = EnableDebugger,
Audio = Audio,
NewAudio = NewAudio,
Inventory = Inventory,
Input = Input,
Misc = Misc,
Time = Time,
Discord = Discord,
_getv = _getv,
EndWave = EndWave, --replace this
State = State,
CreateProjectile = CreateProjectile,
CreateProjectileAbs = CreateProjectileAbs
}



-- A simple compatibility function.
function Call(func, args)
	_G[func](args)
end

-- some necessary values
local loaded_waves = {}
local nextwaves_buffer = {}
local wavemetatable = {__index = wave_sandbox}


-- Unfortunately, this is necessary as load() is currently broken in CYF.
function loadFileCYF(filename, env, errlevel)
	local errlevel = errlevel or 2
	local env = env or _ENV
	local status, res = pcall(Misc.OpenFile,filename)
	if not status then error("file " .. filename .. " was not found",errlevel) end
	local lines = res.ReadLines()

	local compiledlines = table.concat(lines,"\n")
	local chunk = load(compiledlines, filename, "bt", env)
	return chunk
end

-- Partially remaking require for the sandbox to get around the global environment.
local function fake_require(filename, env) 
	if env.package.loaded[filename] then
		return env.package.loaded[filename]
	else
		chunk = loadFileCYF("Lua/" .. filename .. ".lua", env,4)
		env.package.loaded[filename] = chunk
		return chunk
	end
end

-- empty nextwaves into a safe place and put in the loader
local function BufferWaves()
	nextwaves_buffer = nextwaves
	nextwaves = {'wave_loader'}
end
EnemyDialogueEnding:Add(BufferWaves,"AfterMethod")


-- This is the big one. Constructs the sandboxes.
local function loadWave(waveName)

	local wave_capsule = {} -- an outer table to encapsulate everything
	local wave_environment = {} -- the environment the wave runs in

	local local_bullets = {} -- for later removal

	-- replace package.loaded for the false require.
	-- I would love to use the orignal table, but that doesn't really work.
	-- or at least, I'm not smart enough to make it work.
	wave_environment.package = setmetatable({},{__index=package})
	wave_environment.package.loaded = {} 

	-- a unique key to distinguish this sandbox in the table of loaded waves
	function wave_capsule.key() end 

	function wave_environment.EndWave()
		wave_environment.EndingWave()

		if end_waves_simultaniously == false then -- staggered ending
			for k,v in pairs(local_bullets) do -- clear local bullets
				k.Remove() 
			end
			loaded_waves[wave_capsule.key] = nil -- remove capsule from list of active waves
			wave_capsule = nil -- clean up the object
			local count = 0
			for k in pairs(loaded_waves) do
				count = count + 1
			end
			if count == 0 then
				Wave[1].Call('EndWave') -- if all false waves have ended, end the real one
			end
		else -- simultanious ending
			Wave[1].Call('EndWave') 
		end
	end

	-- save created bullets in a local table
	-- also mark bullets with the environment they came from
	function wave_environment.CreateProjectile(...)
		local proj = CreateProjectile(...)
		proj.SetVar("wave_inheritance_script", wave_environment)
		local_bullets[proj] = true
		return proj
	end
	function wave_environment.CreateProjectileAbs(...)
		local proj = CreateProjectileAbs(...)
		proj.SetVar("wave_inheritance_script", wave_environment)
		local_bullets[proj] = true
		return proj
	end

	function wave_environment.OnHit(bullet) -- default OnHit
    	Player.Hurt(3)
	end

	function wave_environment.EndingWave() end -- just in case

	function wave_environment.require(filename) -- the other half of the fake require
		wave_environment.__wave_inheret_temp_chunk = fake_require(filename,wave_environment)
		local chunk = load("__wave_inheret_temp_chunk()","require","bt",wave_environment)
		--wave_environment.__wave_inheret_temp_chunk = nil
		return chunk()
	end

	wave_environment.Encounter = _G -- the "Encounter script object"
	wave_environment._G = wave_environment -- of course
	wave_environment.wavename = waveName

	wave_environment.Arena = Wave[1].GetVar('Arena') -- pass a reference to the real arena

	setmetatable(wave_environment, wavemetatable) -- close the sandbox lid
	
	-- finally, run the actual wave code, making sure to check that the file exists.
	stat, res = pcall(loadFileCYF,'Lua/Waves/' .. waveName .. '.lua', wave_environment)
	if not stat then error("error in script encounter\n\nThe wave " .. waveName .. " doesn't exist.",3) end
	res()

	wave_capsule.env = wave_environment -- encapsulate the sandbox for safekeeping
	loaded_waves[wave_capsule.key] = wave_capsule -- mark this capsule as active

end

function Load_Waves() -- called in wave blank a frame after it loads
	for i,v in ipairs(nextwaves_buffer) do
		loadWave(v)
	end
end

-- if the bullet is tied to a script, run onhit from that script and break
-- make sure this always (hopefully) runs first
OnHit:CreateGroup("CORE_Inheritance", "first")
OnHit:Add(function(bullet)
	if bullet.GetVar('wave_inheritance_script') then
		bullet.GetVar('wave_inheritance_script').OnHit(bullet)
		return break_event
	end
end, "CORE_Inheritance")

-- end waves one by one when the time comes
function End_Loaded_Waves()
	for i,v in pairs(loaded_waves) do
		pcall(v.env.EndingWave)
		v.env.EndWave()
	end
	loaded_waves = {}
end

-- update every wave in random order
local function UpdateWaves()
	if GetCurrentState() ~= "PAUSE" then
		for i,v in pairs(loaded_waves) do
			v.env.Update()
		end
	end
end
Update:Add(UpdateWaves,"AfterMethod")

