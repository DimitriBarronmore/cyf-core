--[[

	CORE Overwrite -- A lightweight and modular userdata wrapper.
	Inspired from a library by and written with minor help from Eir#8327
	https://github.com/DimitriBarronmore/cyf-core-labs

	© 2021 Dimitri Barronmore
--]]


-- Define a metatable to mimick the properties of userdata.
local function err_compare(lhs, rhs)
	error("attempt to compare " .. type(lhs) .. " with " .. type(rhs), 2)
end

local function err_arithmetic()
	error("attempt to perform arithmetic on a userdata value", 2)
end

local userdata_metatable = {
	__type = "userdata",
	
	__call = function()
		error("attempt to call a userdata value", 2)
	end,
	__len = function()
		error("attempt to get length of a userdata value", 2)
	end,
	__pairs = function()
		error("bad argument #1 to 'next' (table expected, got userdata)", 2)
	end,
	__ipairs = function(_, k)
		error("bad argument #1 to '!!next_i!!' (table expected, got userdata)", 2)
	end,

	__eq = function(lhs, rhs)
		return (pcall(function() return lhs.userdata end) and lhs.userdata or lhs) == (pcall(function() return rhs.userdata end) and rhs.userdata or rhs)
	end,

	__lt = err_compare,
	__le = err_compare,

	__add = err_arithmetic,
	__sub = err_arithmetic, 
	__mul = err_arithmetic,
	__div = err_arithmetic,
	__mod = err_arithmetic,
	__pow = err_arithmetic }


local function accesserr() error("attempted to assign to a readonly value", 3) end

local special_set_bullets = {
	x = function(t,v) t.userdata.x = v end, 
	y = function(t,v) t.userdata.y = v end, 
	absx = function(t,v) t.userdata.absx = v end, 
	absy = function(t,v) t.userdata.absy = v end, 
	ppcollision = function(t,v) t.userdata.ppcollision = v end,  --b
	ppchanged = function(t,v) t.userdata.ppchanged = v end,  --b
	isactive = accesserr, --readonly
	layer = function(t,v) t.userdata.layer = v end,
	isPersistent = function(t,v) t.userdata.isPersistent = v end --b
}

local special_set_sprites = {
	spritename = function(t,v) t.userdata.spritename = v end, 
	x = function(t,v) t.userdata.x = v end, 
	y = function(t,v) t.userdata.y = v end, 
	absx = function(t,v) t.userdata.absx = v end, 
	absy = function(t,v) t.userdata.absy = v end, 
	xscale = function(t,v) t.userdata.xscale = v end,  
	yscale = function(t,v) t.userdata.yscale = v end,  
	isactive = accesserr, --readonly
	width = accesserr, --readonly
	height = accesserr, --readonly
	xpivot = function(t,v) t.userdata.xpivot = v end,  
	ypivot = function(t,v) t.userdata.ypivot = v end,  
	animcomplete = accesserr, --readonly
	currentframe = function(t,v) t.userdata.currentframe = v end,  
	currenttime = function(t,v) t.userdata.currenttime = v end,  
	animationspeed = function(t,v) t.userdata.animationspeed = v end,  
	animationpaused = function(t,v) t.userdata.animationpaused = v end,  
	loopmode = function(t,v) t.userdata.loopmode = v end,  
	color = function(t,v) t.userdata.color = v end,  
	color32 = function(t,v) t.userdata.color32 = v end,  
	alpha = function(t,v) t.userdata.alpha = v end,  
	alpha32 = function(t,v) t.userdata.alpha32 = v end,  
	rotation = function(t,v) t.userdata.rotation = v end,  
	layer = function(t,v) t.userdata.layer = v end,  
	shader = function(t,v) t.userdata.shader = v end
}

local special_get_bullets = {
	x = function(t) return t.userdata.x end, 
	y = function(t) return t.userdata.y end, 
	absx = function(t) return t.userdata.absx end, 
	absy = function(t) return t.userdata.absy end, 
	ppcollision = function(t) return t.userdata.ppcollision end,  --b
	ppchanged = function(t) return t.userdata.ppchanged end,  --b
	xscale = function(t) return t.userdata.xscale end,
	isactive = function(t) return t.userdata.isactive end,  --readonly
	layer = function(t) return t.userdata.layer end,
	isPersistent = function(t) return t.userdata.isPersistent end 
}

local special_get_sprites = {
	spritename = function(t) return t.userdata.spritename end, 
	x = function(t) return t.userdata.x end, 
	y = function(t) return t.userdata.y end, 
	absx = function(t) return t.userdata.absx end, 
	absy = function(t) return t.userdata.absy end, 
	xscale = function(t) return t.userdata.xscale end, 
	yscale = function(t) return t.userdata.yscale end,
	isactive = function(t) return t.userdata.isactive end,  --readonly
	width = function(t) return t.userdata.width end,   --readonly 
	height = function(t) return t.userdata.height end,  --readonly 
	xpivot = function(t) return t.userdata.xpivot end, 
	ypivot = function(t) return t.userdata.ypivot end, 
	animcomplete = function(t) return t.userdata.animcomplete end,  --readonly 
	currentframe = function(t) return t.userdata.currentframe end, 
	currenttime = function(t) return t.userdata.currenttime end, 
	animationspeed = function(t) return t.userdata.animationspeed end, 
	animationpaused = function(t) return t.userdata.animationpaused end, 
	loopmode = function(t) return t.userdata.loopmode end, 
	color = function(t) return t.userdata.color end, 
	color32 = function(t) return t.userdata.color32 end, 
	alpha = function(t) return t.userdata.alpha end,  
	alpha32 = function(t) return t.userdata.alpha32 end,  
	rotation = function(t) return t.userdata.rotation end,  
	layer = function(t) return t.userdata.layer end
}

local function setupAudio(input)
	input.Play =  input.userdata.Play
	input.Stop = input.userdata.Stop
	input.Pause = input.userdata.Pause
	input.Unpause = input.userdata.Unpause
	input.Volume = input.userdata.Volume
	input.Pitch = input.userdata.Pitch
	input.LoadFile = input.userdata.LoadFile
	input.PlaySound = input.userdata.PlaySound
	input.StopAll = input.userdata.StopAll
	input.PauseAll = input.userdata.PauseAll
	input.UnpauseAll = input.userdata.UnpauseAll
	input.SetSoundDictionary = input.userdata.SetSoundDictionary
	input.GetSoundDictionary = input.userdata.GetSoundDictionary
	input._get.playtime = function(t) return t.userdata.playtime end
	input._set.playtime = function(t,v) t.userdata.playtime = v end
	input._get.totaltime = function(t) return t.userdata.totaltime end
	input._set.totaltime = accesserr
end
local function setupBullet(input)
	input.Move =  input.userdata.Move   --static, b, s
	input.MoveTo =  input.userdata.MoveTo  --static, b, s
	input.MoveToAbs =  input.userdata.MoveToAbs  --static, b, s
	input.SendToTop =  input.userdata.SendToTop  --static
	input.SendToBottom =  input.userdata.SendToBottom  --static
	input.Remove =  input.userdata.Remove  --static 
	input.SetVar =  input.userdata.SetVar  --static
	input.GetVar =  input.userdata.GetVar  --static

	for k,v in pairs(special_set_bullets) do
		input._set[k] = v
	end
	for k,v in pairs(special_get_bullets) do
		input._get[k] = v
	end
	input.ResetCollisionSystem =  input.userdata.ResetCollisionSystem  --static, b
	input.isColliding =  input.userdata.isColliding  --static, b
	input.isPersistent =  input.userdata.isPersistent  --b
	input.sprite =  input.userdata.sprite
end
local function setupSprite(input)
	--shared
	input.Move =  input.userdata.Move   --static, b, s
	input.MoveTo =  input.userdata.MoveTo  --static, b, s
	input.MoveToAbs =  input.userdata.MoveToAbs  --static, b, s
	input.SendToTop =  input.userdata.SendToTop  --static
	input.SendToBottom =  input.userdata.SendToBottom  --static
	input.Remove =  input.userdata.Remove  --static 
	input.SetVar =  input.userdata.SetVar  --static
	input.GetVar =  input.userdata.GetVar  --static

	for k,v in pairs(special_set_sprites) do
		input._set[k] = v
	end
	for k,v in pairs(special_get_sprites) do
		input._get[k] = v
	end
	input.Set =  input.userdata.Set  --static 
	input.SetParent =  input.userdata.SetParent  --static 
	input.Mask =  input.userdata.Mask  --static 
	input.shader =  input.userdata.shader  
	input.SetPivot =  input.userdata.SetPivot  --static 
	input.SetAnchor =  input.userdata.SetAnchor  --static 
	input.Scale =  input.userdata.Scale  --static 
	input.SetAnimation =  input.userdata.SetAnimation  --static 
	input.StopAnimation =  input.userdata.StopAnimation  --static
	input.MoveBelow =  input.userdata.MoveBelow  --static
	input.Dust =  input.userdata.Dust 
end

local listener_newindex = function(t,k,v)
	if t._set[k] == nil then t.userdata[k] = v return end
	local keytype = type(t._set[k])
	
	if keytype == "function" then
		t._set[k](t, v)
	else 
		error("this wrapped userdata has a ._set field, " .. k .. ", which is not a function",2)
	end
end

local listener_index = function(t,k) 
	if t._get[k] == nil then return t.userdata[k] end
	local keytype = type(t._get[k])
	
	if keytype == "function" then
		return t._get[k](t)
	else
		return t._get[k]
	end
end

-- Take a userdata object as input and spit out a replica.
-- Requires my custom __type metamethod to output as type <userdata>.
-- Values can be added/replaced using rawset() or Userdata.SetRaw()
-- The original object is stored at the field ["userdata"]
-- ._get and ._set are used like metamethods to perform actions or
--    redirect values when a variable is accessed
-- This causes odd behavior in sprites, bullets, and the audio object
-- All fresh references will end up going through Get/SetVar or Get/SetSoundDictionary

function GetIsWrapped(udata)
	res, err = pcall(function() return udata.userdata end)
	--DEBUG(err)
	return res
end

function WrapUserdata(usrdata)
	if type(usrdata) ~= "userdata" then
		error("tried to wrap object of type " .. type(usrdata),2)
	end

	local new_object = {}
	new_object.userdata = usrdata
	new_object._get = {}
	new_object._set = {}

	local __tostring = tostring(new_object.userdata)
	
	local userdata_mt = {
		__index = listener_index,
		__newindex = listener_newindex,
		__tostring = function() return __tostring end,
		}
	for k,v in pairs(userdata_metatable) do
		userdata_mt[k] = v
	end

	-- Convenience functions. 
	-- You don't really need these, but if you want them, they're there.
	function new_object.SetRaw(var, value)
		rawset(new_object, var, value)
	end
	function new_object.GetRaw(var)
		rawget(new_object, var)
	end

	if __tostring == "LuaSpriteController" then
		setupSprite(new_object)
	elseif __tostring == "ProjectileController" then
		setupBullet(new_object)
	elseif __tostring == "MusicManager" then
		setupAudio(new_object)
	end

	setmetatable(new_object, userdata_mt)
	return new_object
end