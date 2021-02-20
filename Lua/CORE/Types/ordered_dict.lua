--[[
	
	Integer Dictionaries -- A slightly cursed custom type. 
	Allows for arbitrary key extraction like a set, but also stores ordered indexes.
	I don't know who will ever need it, including myself, but I'm including it here regardless.

	Released under a Creative Commons Attribution 4.0 International license.
	https://creativecommons.org/licenses/by/4.0/
	
	If you see this, I need to rewrite this library from the ground-up.
	Or at least document it better.

--]]


iDict = {}

iDict.mt = {
	__call = function(self, input)
		return self.new(input)
	end
	}

iDict.assignMT = {
	__index = iDict,
	__type = "iDict"
} 


function iDict.assignMT.__pairs(tbl)
  -- Iterator function
  local function stateless_iter(tbl, i)
    -- Implement your own index, value selection logic
    i = i + 1
    local v = tbl[i]
    if v then return i, v.key, v.value end
  end

  -- return iterator function, table, and starting point
  return stateless_iter, tbl, 0
end

setmetatable( iDict, iDict.mt )

function iDict.new(input)
	local output = {}
	for i,v in ipairs(input) do
		output[v[1]] = {["value"] = v[2], ["index"] = i }
		output[i] = {["value"] = v[2], ["key"] = v[1] }
		setmetatable( output, iDict.assignMT )
	end
	return output
end

function iDict.get(self, value)
	if self[value] then
		return self[value].value
	else
		return nil
	end
end

function iDict.set(self, key, value)
	if self[key] then
		if type( key ) == "number" then
			linktype = "key"
		else
			linktype = "index"
		end

		if value == nil then
			local deleting
			if linktype == "index" then
				deleting = self[key].index
			else
				deleting = key
			end
			self:scrollDown(deleting)
		else
			self[key].value = value
			self[self[key][linktype]].value = value
		end
	else
		self:_insert({key, value})
	end
end

function iDict.insert(self, key, value, index)
	if self[key] then return end
	local index = index or nil

	if index then
		self:scrollUp(index)
	else
		index = #self+1
	end
	self[index] = {["value"] = value, ["key"] = key }
	self[key] = {["value"] = value, ["index"] = i }
end

function iDict.scrollDown(self, index)
	self[self[index].key] = nil
	for i = index, #self-1, 1 do
		self[i] = self[i+1]
		self[self[i].key].index = i+1
	end
	self[#self] = nil
end

function iDict.scrollUp(self, index)
	for i = #self, index, -1 do
		self[i+1] = self[i]
		self[self[i].key].index = i+1
	end
end

-- fruits = iDict{{"a", "apple"}, {"b", "banana"}, {"c", "cantaloupe"}}