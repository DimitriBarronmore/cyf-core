--[[
		This is where any single functions that I'm making 
		small changes to live. These changes aren't large enough
		to be a full file, so they go here instead.
--]]

local old_type = type
function type(obj)
	local obj_mt = getmetatable( obj ) or nil
	if obj_mt then
		return obj_mt.__type or old_type(obj)
	else
		return old_type(obj)
	end
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