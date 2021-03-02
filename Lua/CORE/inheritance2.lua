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
"load", --replace all loads?
"loadsafe",
"loadfile",
"loadfilesafe",
"dofile",
"__require_clr_impl",
"require",
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
"EndWave", --replace this
"State",
"CreateProjectile",
"CreateProjectileAbs"
} 

function sandbox.add(target)
	if not table.findindex(values_to_copy, target) then
		table.insert(values_to_copy, target)
	end
end

function sandbox.remove(target)
	res = table.findindex(values_to_copy, target)
	if res then 
		table.remove(values_to_copy,res)
	end
end

function sandbox.createEnv(source)
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

return sandbox