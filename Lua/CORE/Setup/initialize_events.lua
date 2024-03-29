-- Detect what script the file is currently being run in and initialize game events accordingly.

local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter Script Events

	EncounterStarting = CreateEvent()

	EnemyDialogueStarting = CreateEvent()

	EnemyDialogueEnding = CreateEvent()

	DefenseEnding = CreateEvent()

	HandleSpare = CreateEvent()

	HandleItem = CreateEvent()

	EnteringState = CreateEvent()

	--Update = CreateEvent()

	BeforeDeath = CreateEvent()

elseif mons then -- Monster Script Events

	EncounterStarting = CreateEvent()

	HandleAttack = CreateEvent()

	OnDeath = CreateEvent(function() Kill() end)

	OnSpare = CreateEvent(function() Spare() end)

	BeforeDamageCalculation = CreateEvent()

	BeforeDamageValues = CreateEvent()

	HandleCustomCommand = CreateEvent()
    
elseif wave then -- Wave Script Events

	EndingWave = CreateEvent()
    
end

-- All-Script Events

Update = CreateEvent()

OnHit = CreateEvent(function() Player.Hurt(3) end )

OnTextAdvance = CreateEvent()

