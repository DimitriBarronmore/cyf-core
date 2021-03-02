--[[ 
	
	CORE Events -- Listener-based events built off a doubly-linked list.
	A cleaner version of the concept put forth in Monster Events. 
	Designed for use in Create Your Frisk by https://github.com/DimitriBarronmore

	Copyright © 2020 Dimitri Barronmore, Some Rights Reserved
	Released under a Creative Commons Attribution 4.0 International license.
	https://creativecommons.org/licenses/by/4.0/
 --]]

-- A convenience value for library makers.
-- You can use this to test whether this file has been loaded or not.
CORE_Events = true 


--[[ Linked list functions. 
	 This code was heavily referenced from a luapower library, alhough my version is significantly lazier.
	 https://luapower.com/linkedlist

	 I don't recommend using these directly unless you've looked very 
	 close at how the lists work in the context of the Event object.

	 Currently there's no way to remove an item from the list, or to traverse the list backwards. 
	 If this comment still exists, I never felt the need to add one. Them's the brakes. 
—-]]

local LList = {}

function LList:insertFirst(t)
	if self.first then
		self.first._prev, t._next = t, self.first
		self.first = t
	else
		self.first, self.last = t, t
	end
end

function LList:insertLast(t)
	if self.last then
		self.last._next, t._prev = t, self.last
		self.last = t
	else
		self.last, self.first = t, t
	end
end

function LList:insertAfter(t, pivot)
	if self.last == pivot then
		pivot._next, self.last = t, t
		t._prev = pivot
	else
		t._next, t._prev = pivot._next, pivot
		pivot._next, pivot._next._prev = t, t
	end

end

function LList:insertBefore(t, pivot)
	if self.first == pivot then
		pivot._prev, self.first = t, t
		t._next = pivot
	else
		t._next, t._prev = pivot, pivot._prev
		pivot._prev, pivot._prev._next = t, t
	end	
end

-- :items() is an iterator function, next is the function that does the iterating. 
-- Don't ask me how this works or why they're named like that. 

function LList:next(last)
	if last then
		return last._next
	else
		return self.first
	end
end

function LList:items()
	return self.next, self
end


--[[ Here lies the functions that the end user needs to become familiar with. 
	 These invoke the linked list, with a couple of extra goodies to get all the functionality moving smoothly.
  ]]

local EventFunctions = {}


--[[ Setting the stack level to 3 makes the error appear on the line that tries to add the set.
	 Hardcoding like this probably isn't great, but it should work fine. 
	 Nothing else should call these functions anyways, they're local for a reason. ]]

local function check_if_in_list(set, name)
	if set[name] then 
		error('This event already has a set named "' .. name .. '"', 3) 
	end
end
local function check_if_not_in_list(set, name)
	if not set[name] then 
		error("This event does not have a set named \"" .. name .. "\"", 3) 
	end
end

-- Add a new group to the linked list, complete with .methods field.
-- Places it into the .list table for easy access and debugging.
function EventFunctions:CreateGroup(name, position, before)
	-- Check for errors and set default values.
	local err = ""
	if not name then err = err .. "You must specify a name for the new group.\n" end
	if not position then err = err .. "You must specify a position for the new group." end
	if err ~= "" then error(err,2) end

	before = before or false
	check_if_in_list(self.list, name)
	check_if_not_in_list(self.list, position)
	-- Initiate table and place it in the list.
	local newset = {methods = {}}
	self.list[name] = newset
	-- Insert the new table.
	if before == true then
		self.list:insertBefore(newset, self.list[position])
	else
		self.list:insertAfter(newset,self.list[position])
	end
end

-- Place a function into the waiting list, with optional name for debugging purposes.
-- Doesn't error if you put in something other than a function, but it WILL crash anyways.
-- Defaults to BeforeMethod, for no particular reason.
function EventFunctions:Add(func, chosen_set, name)
	--error checking
	if func == self.method then
		error("cannot add .method function to its own event", 2)
	end
	if self.dictionary[func] then
		error('given function has already been added to this event as <' .. self.dictionary[func][2].name .. '>: "'  .. self.dictionary[func][1] .. '"', 2)
	end
	if not func then error("must pass in a function", 2) end
	local temp_mt = getmetatable(func)
	if not (type(func) == "function") then
		if not (temp_mt and temp_mt.__call) then
		error("cannot add <" .. type(func) .."> to execution group"
			.. ".\nRequested object must be a function or a callable table.",2)
		end
	end
	--Make sure people don't mess with the "Method" set.
	if chosen_set == "Method" then error('The Method set is reserved for this event\'s ".method" function.', 2) end
	--Set up defaults.
	chosen_set = chosen_set or "BeforeMethod"
	name = name or "<" .. ( table.findindex(_ENV,func) or tostring(func)) .. ">"
	--Make sure the chosen set actually exists.
	local set = self.list[chosen_set]
	if not set then error('This event has no set "' .. chosen_set .. '"', 2) end
	--Add the function to the set.
	self.dictionary[func] = {name, set}
	table.insert(set.methods, func)
end


-- Remove a function from the waiting list. Requires a pointer to the function object.
function EventFunctions:Remove(func)
	-- protect Method
	if func == self.method then
		error("The .method function cannot be removed.", 2)
	end
	-- Check if the function has been added previously.
	if not self.dictionary[func] then
		error("The given function is not registered to the event.", 2)
	end
	--Remove the function, if it's previously been added.
	set = self.dictionary[func][2]
	local res = table.findindex(set.methods, func)
	table.remove(set.methods, res)
	self.dictionary[func] = nil
end

-- Prevent a group of functions from running with the event.
-- All this does is place a boolean in the set. 
function EventFunctions:DisableGroup(chosen_set)
	--Check if set exists
	check_if_not_in_list(self.list, chosen_set)
	local set = self.list[chosen_set]
	if not set.is_disabled then
		set.is_disabled = true
	end
end

-- Allow a group of functions disabled with the previous function to run again.
function EventFunctions:EnableGroup(chosen_set)
	--Check if set exists
	check_if_not_in_list(self.list, chosen_set)
	local set = self.list[chosen_set]
	if set.is_disabled then
		set.is_disabled = nil
	end
end


-- A nice unique key to break with.
function break_event() end

-- Iterates through every group of functions, calling each function with the given arguments.
-- Will not execute a group with the value .is_disabled
-- Order of execution within a group is undefined
function EventFunctions:Call(...)
	local end_result
	local temp_result
	local broken = false
	for set in self.list() do
		if not set.is_disabled then
			for i,func in ipairs(set.methods) do
				temp_result, broken = func(...)
				if (temp_result == break_event) or (broken == break_event) then
					broken = true
					if broken == break_event then end_result = temp_result end
					goto continue
				end
			end
			if set == self.list.Method then
				end_result = temp_result
			end
		end
	end
	::continue::
	return end_result, broken
end

-- Step through the list without calling any functions, printing given names.
function EventFunctions:Debug()
	final = ""
	for set in self.list() do
		final = final .. (set.name .. ": " .. (set.is_disabled and "[disabled]" or "[enabled]") .. "\n")
		for i, func in ipairs(set.methods) do
			local name
			final = final .. ("   > " .. i .. " - " .. self.dictionary[func][1] .. "\n")
		end
	end
	return final
end

-- Here we finally create and return individual Event objects.

function CreateEvent(func)
	local temp_mt = getmetatable(func)
	if func then
		if not (type(func) == "function") then
			if not (temp_mt and temp_mt.__call) then
			error("Attempted to make event with reference of type <" .. type(func)
				.. ">.\nRequested object must be a function or a callable table.",2)
		end end
	end

	--Initialize List
	local Event = {}
	--Set the metatable for the Event object.
	setmetatable(Event, { __index = EventFunctions, 
						  __type = "event",
						  __call = function(tab, ...)
						  	  return tab:Call(...)
						  end
						} )
	--Initialize the default series of sets.
	Event.dictionary = {}
	Event.list = setmetatable({}, {__index = LList, 
								   __call = function(tab)
								      return tab:items()
								   end
							 	  } )
	Event.list.BeforeMethod = {name = "BeforeMethod", methods = {}}
	Event.list.AfterMethod = {name = "AfterMethod", methods = {}}
	Event.list:insertFirst(Event.list.BeforeMethod)
	Event.list:insertLast(Event.list.AfterMethod)

	--Set up the method itself
	Event.method = func or function() end
	local callmethod = function(...) return Event.method(...) end -- so the method can be changed later
	Event.list.Method = { name = "Method", methods = {callmethod}}
	Event.dictionary[callmethod] = {".method", Event.list.Method}
	Event.list:insertAfter(Event.list.Method, Event.list.BeforeMethod)

	return Event
end