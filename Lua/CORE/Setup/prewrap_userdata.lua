
Player = WrapUserdata( Player )
Audio = WrapUserdata( Audio )
NewAudio = WrapUserdata( NewAudio )
Input = WrapUserdata( Input )
Time = WrapUserdata( Time )
Inventory = WrapUserdata( Inventory )
Misc = WrapUserdata( Misc )
Discord = WrapUserdata( Discord )

-- Sadly, pre-wrapping the Arena is simply impractical. 
-- That's fine, we have another library for that.

-- A series of values to determine pre-wrapping for created objects.

if autowrapbullets == nil then autowrapbullets = false end

if autowrapsprites == nil then autowrapsprites = false end

if autowraptext == nil then autowraptext = false end

if autowrapfiles == nil then autowrapfiles = false end



local _CreateProjectile = CreateProjectile
local newCreateProjectile = function(...)
	local _, proj = pcall(_CreateProjectile, ...)
	if _ == false then error(proj, 2) end
	if autowrapbullets then 
		proj = WrapUserdata(proj)
	end
	return proj 
end

local _CreateProjectileAbs = CreateProjectileAbs
local newCreateProjectileAbs = function(...)
	local _, proj = pcall(_CreateProjectileAbs, ...)
	if _ == false then error(proj, 2) end
	if autowrapbullets then 
		proj = WrapUserdata(proj)
	end
	return proj 
end

CreateProjectile = newCreateProjectile
CreateProjectileAbs = newCreateProjectileAbs

local enc = SetButtonLayer
local mons = Kill
local wave = EndWave

if (not (mons or wave)) or enc then -- Encounter-only
	local initbullets = function()
		_CreateProjectile = CreateProjectile
		_CreateProjectileAbs = CreateProjectileAbs
		CreateProjectile = newCreateProjectile
		CreateProjectileAbs = newCreateProjectileAbs
	end

	EncounterStarting:CreateGroup("CORE_Pre", "first")
	EncounterStarting:Add(initbullets, "CORE_Pre", "ensure bullet prewrap")
end

local _CreateSprite = CreateSprite
CreateSprite = function(...)
	local _, spr = pcall(_CreateSprite, ...)
	if _ == false then error(spr, 2) end
	if autowrapsprites then 
		spr = WrapUserdata(spr)
	end
	return spr
end

local _CreateText = CreateText
CreateText = function(...)
	local _, txt = pcall(_CreateText, ...)
	if _ == false then error(txt, 2) end
	if autowraptext then 
		txt = WrapUserdata(txt)
	end
	return txt
end

local _OpenFile = Misc.OpenFile
local newOpenFile = function(...)
	local _, file = pcall(_OpenFile, ...)
	if _ == false then error(file, 2) end
	if autowrapfiles then 
		file = WrapUserdata(file)
	end
	return file
end

Misc.SetRaw("OpenFile", newOpenFile)--]]