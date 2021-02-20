
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



-- A compatibility function.
function Call(func, args)
	_G[func](args)
end

-- some necessary values
local loaded_waves = {}
local nextwaves_buffer = {}
local wavemetatable = {__index = wave_sandbox}


-- Unfortunately, this is necessary as load() is broken in CYF.
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


local function fake_require(filename, env)
	if env.package.loaded[filename] then
		return env.package.loaded[filename]
	else
		chunk = loadFileCYF("Lua/" .. filename .. ".lua", env,4)
		env.package.loaded[filename] = chunk
		return chunk
	end
end


local function BufferWaves()
	nextwaves_buffer = nextwaves
	nextwaves = {'wave_loader'}
end
EnemyDialogueEnding = CreateEvent()
EnemyDialogueEnding:Add(BufferWaves,"AfterMethod")

end_waves_simultaniously = true

local function loadWave(waveName)

	local wave_capsule = {}
	local wave_environment = {}

	local local_bullets = {}

	wave_environment.package = setmetatable({},{__index=package})
	wave_environment.package.loaded = {}

	function wave_capsule.key() end

	function wave_environment.EndWave()
		if end_waves_simultaniously == false then
			for k,v in pairs(local_bullets) do
				k.Remove()
			end
			loaded_waves[wave_capsule.key] = nil
			wave_capsule = nil
			local count = 0
			for k in pairs(loaded_waves) do
				count = count + 1
			end
			if count == 0 then
				Wave[1].Call('EndWave')
			end
		else
			Wave[1].Call('EndWave')
		end
	end

	function wave_environment.CreateProjectile(...)
		local proj = CreateProjectile(...)
		proj.SetVar("wave_inheritance_script", wave_environment)
		local_bullets[proj] = true
		--DEBUG("proj created")
		return proj
	end
	function wave_environment.CreateProjectileAbs(...)
		local proj = CreateProjectileAbs(...)
		proj.SetVar("wave_inheritance_script", wave_environment)
		local_bullets[proj] = true
		--DEBUG("proj created")
		return proj
	end

	function wave_environment.OnHit(bullet)
    	Player.Hurt(3)
	end

	function wave_environment.EndingWave() end

	function wave_environment.require(filename) 
		wave_environment.__wave_inheret_temp_chunk = fake_require(filename,wave_environment)
		local chunk = load("__wave_inheret_temp_chunk()","require","bt",wave_environment)
		return chunk()
	end


	wave_environment.Encounter = _G
	wave_environment._G = wave_environment
	wave_environment.wavename = waveName

	wave_environment.Arena = Wave[1].GetVar('Arena')

	--[[function wave_environment.require(file)
		DEBUG("hiii" .. Time.time)
		runFileCYF('Lua/' .. file .. '.lua', wave_environment )
	end--]]

	setmetatable(wave_environment, wavemetatable)
	
	stat, res = pcall(loadFileCYF,'Lua/Waves/' .. waveName .. '.lua', wave_environment)
	if not stat then error("error in script encounter\n\nThe wave " .. waveName .. " doesn't exist.",3) end
	res()

	wave_capsule.env = wave_environment
	loaded_waves[wave_capsule.key] = wave_capsule

end

function Load_Waves() -- called in wave blank a frame after it loads
	for i,v in ipairs(nextwaves_buffer) do
		loadWave(v)
	end
end

OnHit:Add(function(bullet)
	if bullet.GetVar('wave_inheritance_script') then
		bullet.GetVar('wave_inheritance_script').OnHit(bullet)
		return "break_event"
	end
end, "BeforeMethod")

function OnHit.method()
	Player.Hurt(2)
end

function End_Loaded_Waves()
	for i,v in pairs(loaded_waves) do
		pcall(v.env.EndingWave)
		v.env.EndWave()
	end
	loaded_waves = {}
end

local function UpdateWaves()
	if GetCurrentState() ~= "PAUSE" then
		for i,v in pairs(loaded_waves) do
			v.env.Update()
		end
	end
end
--Update = CreateEvent()
Update:Add(UpdateWaves,"AfterMethod")

