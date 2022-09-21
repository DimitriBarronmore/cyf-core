
rawtype = type
function type(obj)
	local obj_mt = getmetatable( obj ) or nil
	if not obj_mt then return rawtype(obj) end
	
	if rawtype(obj_mt.__type) == "function" then
		return obj_mt.__type(t)
	end

	if obj_mt.__type == nil then
		return rawtype(obj)
	end

	return obj_mt.__type
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
    k = (rawtype(k) == 'table') and table.deepcopy(k, seen) or k
    v = (rawtype(v) == 'table') and table.deepcopy(v, seen) or v
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