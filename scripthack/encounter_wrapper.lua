local set = function(tab)
	local settab = {}
	for _,v in ipairs(tab) do
		settab[v] = true
	end
	return settab
end

-- local path = (...):gsub("encounter_wrapper", "")
-- local create_require = require(path .. "new_require")


local initial_sandbox = {
	"_G",
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
	"package",
	"load",
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
	"CreateText",
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
	"encountertext",
	"nextwaves",
	"wavetimer",
	"arenasize",
	"enemies",
	"enemypositions",
	-- custom additions
	"rawtype"
}

local post_encstarting = {
	"State",
	"RandomEncounterText",
	"CreateProjectile",
	"CreateProjectileAbs",
	"SetButtonLayer",
	"CreateEnemy",
	"Flee",
	-- "Wave",
}

local special_variables = set{
	"music",
	"encountertext",--
	"nextwaves",--
	"wavetimer",--
	"arenasize",--
	"enemies",--
	"enemypositions",--
	"autolinebreak",
	"playerskipdocommand",
	"unescape",
	"flee",
	"fleesuccess",
	"fleetexts",
	"revive",
	"deathtext",
	"deathmusic",
	-- "Wave",
	"noscalerotationbug",
}

local event_names = set{
	"EncounterStarting",
	"EnemyDialogueStarting",
	"EnemyDialogueEnding",
	"DefenseEnding",
	"HandleSpare",
	"HandleFlee",
	"HandleItem",
	"EnteringState",
	"Update",
	"BeforeDeath",
	"OnHit",
	"OnTextAdvance",
}

local sandbox_env = {}


for _,key in ipairs(initial_sandbox) do
	sandbox_env[key] = _G[key]
end

-- for key, _ in pairs(event_names) do
-- 	local ev = CreateEvent()
-- 	_G[key] = ev
-- end

-- OnHit.method = function()
-- 	Player.Hurt(3)
-- end

local function post_setup()
	for _, key in ipairs(post_encstarting) do
		rawset(sandbox_env, key, _G[key])
	end
end


setmetatable(sandbox_env, {
	__index = function(t,k)
		if special_variables[k] or event_names[k] then
			return _G[k]
		else
			return rawget(t, k)
		end
	end,
	__newindex = function(t,k,v)
		if special_variables[k] then
			_G[k] = v
		elseif event_names[k] then
			_G[k].method = v
		else
			rawset(t, k, v)
		end
	end
})



return { env = sandbox_env, post_setup = post_setup }