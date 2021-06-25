--[[
		This is where any single functions that I'm making 
		small changes to live. These changes aren't large enough
		to be a full file, so they go here instead.
--]]

local old_type = type
function type(obj)
	local obj_mt = getmetatable( obj ) or nil
	if not obj_mt then return old_type(obj) end
	
	if old_type(obj_mt.__type) == "function" then
		return obj_mt.__type(t)
	end

	return obj_mt.__type or old_type(obj)
end

--[[
	This function comes directly from a stackoverflow answer by islet8.
	https://stackoverflow.com/a/16077650
--]]
function table.deepcopy(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no = {}
  seen[o] = no
  setmetatable(no, table.deepcopy(getmetatable(o), seen))

  for k, v in next, o, nil do
    k = (type(k) == 'table') and deepcopy(k, seen) or k
    v = (type(v) == 'table') and deepcopy(v, seen) or v
    no[k] = v
  end
  return no
end

function table.findindex(tab, target)
	for i,v in pairs(tab) do
		if v == target then return i end
	end
	return false
end

if json then
	function json.indent(jsonstring)
	    local function formatstring(str, indent)
	        return (string.rep("  ", indent) .. str .. "\n") 
	    end

	    jsonstring = string.gsub(jsonstring,",", ",\n")
	    jsonstring = string.gsub(jsonstring, "[%[]", "[\n")
	    jsonstring = string.gsub(jsonstring, "[%{]", "{\n")
	    jsonstring = string.gsub(jsonstring, "[%]]", "\n]")
	    jsonstring = string.gsub(jsonstring, "[%}]", "\n}")

	    local indent = 0
	    local lineindex = 1
	    local compile = {}
	    for str in string.gmatch(jsonstring, "([^\n]+)") do
	        if string.find(str, "[(%]|%})]") then
	            indent = indent - 1
	        end
	        compile[lineindex] = formatstring(str, indent)
	        lineindex = lineindex + 1
	        if string.find(str, "[(%[|%{)]") then
	            indent = indent + 1
	        end
	    end

	    jsonstring = table.concat(compile)

	    return jsonstring
	end
end