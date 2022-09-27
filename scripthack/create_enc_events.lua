local event_names = {
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

for _, key in ipairs(event_names) do
	local ev = CreateEvent()
	_G[key] = ev
end

OnHit.method = function()
	Player.Hurt(3)
end