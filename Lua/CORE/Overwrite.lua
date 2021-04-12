--[[

	CORE Overwrite -- A lightweight and modular userdata wrapper for Lua. 
	Inpspired from a library by and written with minor help from Eir#8327 (formerly known by WD20019)
	Designed for use in Create Your Frisk by https://github.com/DimitriBarronmore
	
	Copyright © 2020 Dimitri Barronmore¸Some Rights Reserved
	Released under a Creative Commons Attribution 4.0 International license.
	https://creativecommons.org/licenses/by/4.0/

--]]


-- A convenience value for library makers.
-- You can use this to test whether this file has been loaded or not.
CORE_Overwrite = true 


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


-- Take a userdata object as input and spit out a replica.
-- Requires my custom __type metamethod to output as type <userdata>.
-- Values can be added/replaced using rawset() or Userdata.SetRaw()
-- The original object is stored at the field ["userdata"]

function WrapUserdata(usrdata)
	if type(usrdata) ~= "userdata" then
		error("tried to wrap object of type " .. type(usrdata),2)
	end

	local new_object = {}
	new_object.userdata = usrdata

	local __tostring = tostring(new_object.userdata)
	
	local userdata_mt = {
		__index = new_object.userdata,
		__newindex = new_object.userdata,
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

	setmetatable(new_object, userdata_mt)

	return new_object
end


-- Take an optional object/table and return a replica/blank table with _get and _set fields.
-- This allows you to give an object special behavior when certain fields are used.
-- Intended to be used in combination with wrapUserdata(), but can be used on anything.
-- The base object is stored at the field _self to allow for possible recursive wrapping.

-- This necessarily breaks userdata objects with special behaviour for square-bracket indexing.
-- That includes a number of CYF objects, such as bullets, sprites, and the audio library.
-- This is because all indexes passed to the original object are done using "table.index" notation.
-- Plan accordingly when creating libraries.

local listener_index = function(t,k)  -- I honestly wish this wasn't so complicated.
	if t._get[k] then

		-- Run and return functions, or simply return other values.
		if (type(t._get[k]) == "function") then
			return t._get[k](t)
		else
			return t._get[k]
		end
	else
		-- Use environment schenanigans to get the original dot-syntax value of the desired key.
		chunk = load("return t._self." .. k, "wrapper", "bt", {t = t, k = k})
		local _, ret = pcall(chunk)
		if not _ then error(ret, 2) end
		return ret
	end
end

local listener_newindex = function(t,k,v)
	if t._set[k] then

		if type(t._set[k]) == "function" then
			t._set[k](t, v)
		else 
			error("fields in ._set must be functions",2)
		end
	else
		-- Use environment schenanigans as above to set values in the original object.
		chunk = load("t._self." .. k .. " = v", "wrapper", "bt", {t = t, k = k, v = v})
		local _, ret = pcall(chunk)
		if not _ then error(ret, 2) end
		return ret
	end
end

local listener_eq = function(lhs, rhs)
	return (pcall(function() return lhs._self end) and lhs._self or lhs) == (pcall(function() return rhs._self end) and rhs._self or rhs)
end

function IndexListener(input)
	if not (type(input) == "table" or type(input) == "userdata") then 
		error("tried to wrap object of type " .. type(input),2)
	end

	local new_table = {}
	new_table._self = input or {}
	new_table._get = {}
	new_table._set = {}

	local mt = {
		__index = listener_index,
		__newindex = listener_newindex,
		__eq = listener_eq,
		__type = type(input)
	}

	-- If the original object has a metatable, copy remaining fields in for utility reasons.
	old_mt = getmetatable( input )
	if old_mt then
		for k,v in pairs(old_mt) do
			if not mt[k] then mt[k] = v end
		end
	end

	setmetatable(new_table, mt)
	return new_table
end
