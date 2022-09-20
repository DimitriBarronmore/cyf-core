
-- Based partially on code from Candran
-- Thanks for having an implementation to reference
-- https://github.com/Reuh/candran
local function filepath_search(filepath)
	for path in package.path:gmatch("[^;]+") do
		local fixed_path = path:gsub("%?", (filepath:gsub("%.", "/")))
		-- local file = open(fixed_path)
		-- if file then
		-- 	file:close()
		-- 	return fixed_path
		-- end
		if Misc.FileExists("Lua/" .. fixed_path) then
			return fixed_path
		end
	end
end

local function return_lua_searcher(env)
	local searcher = function(modulepath)
		local filepath = filepath_search(modulepath)
		if filepath then
			return function(reqpath)
				local chunk, err = loadfile(filepath, "t", env)
				if chunk then
					return chunk, reqpath
				else
					error("error loading module '" .. reqpath .. "'\n" .. (err or ""), 0)
				end
			end
		else
			local err = ("\n\tno file '%s.lua' in package.path"):format(modulepath, 2)
			return err
		end
	end
	return searcher
end

local function create_require(env)
	env.package = env.package or {}
	package.searchers = { return_lua_searcher(env) }
	package.preload = {}
	package.path = "?.lua;?/init.lua;Libraries/?.lua;Libraries/?/init.lua"

	local newrequire = function(modname)
		if package.loaded[modname] then
			return package.loaded[modname]
		end

		local loader
		local errors = {}
		if package.preload[modname] then
			loader = package.preload[modname]
		else
			for _,searcher in ipairs(package.searchers) do
				local result = searcher(modname)
				if type(result) == "function" then
					loader = result
					break
				-- 	local module = result(modname)
				-- 	if module ~= nil then
				-- 		package.loaded[modname] = module
				-- 	else
				-- 		if package.loaded[modname] == nil then
				-- 			package.loaded[modname] = true
				-- 		end
				-- 	end
				-- 	return package.loaded[modname]
				else
					table.insert(errors, result)
				end
			end
		end
		if loader == nil then
			error(table.concat(errors))
		else
			-- DEBUG("loader: " .. tostring(loader))
			local status, res = pcall(loader, modname)
			-- error("res " .. res)
			if status == false or type(res) ~= "function" then
				error(res, 2)
				-- error("error loading module '" .. modname .. "'\n" .. res, 2)
			end

			local chunk = res
			status, res = pcall(chunk, modname)
			if status == false then
				-- error("merr" .. res, 2)
				error("error loading module '" .. modname .. "'\n" .. res, 2)
			end

			-- DEBUG("result:" .. tostring(res))
			if res == nil then
				res = true
			end
			package.loaded[modname] = res
			return res
		end
	end
	return newrequire
end

return create_require