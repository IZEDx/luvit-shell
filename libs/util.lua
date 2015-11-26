exports.name = "utils"
exports.author = "Niklas Kühtmann"


exports.debugTable = function(tbl, lvl, func)
	if type(tbl) ~= "table" then
		tbl = {}
	end
	func = func or print
	lvl = lvl or 0
	for k,v in pairs(tbl) do
		local space = ""
		for i = 1, lvl do
			space = space .. "  "
		end
		func(space .. tostring(k) .. ":   " .. tostring(v))
		if type(v) == "table" then
			exports.debugTable(v, lvl + 1, func)
		end
	end
end

exports.makeHTMLTemplate = function(file, options)
	if fs.existsSync(file) then
		local data = fs.readFileSync(file)
		if data then
			data = tostring(data)
			for k,v in pairs(options) do
				data = data:gsub("##"..k.."##", v)
			end
			return data
		end
	end
end

exports.cleanPath = function(_path)
	_path = _path:gsub("/", shell.delimiter)
	_path = _path:gsub("\\", shell.delimiter)

	local path = ""
	for i = 1, #_path do
		local c = _path:sub(i,i)
		path = path..c
		if c == shell.delimiter and _path:sub(i+1,i+1) == shell.delimiter then
			path = path..(isWin and "/" or "\\")
		end
	end


	local parts = path:split(shell.delimiter)
	local cleanParts = {}
	local c = 0
	local d = (isWin and path:sub(1, #shell.rootPath) == shell.rootPath) and 0 or 1
	for k,v in pairs(parts) do
		if v == (isWin and "/" or "\\") then
			c = c + 1
			table.insert(cleanParts, "")
		elseif v == ".." then
			if d > 1 then
				cleanParts[c] = nil
			end
		elseif v ~= "." then
			c = c + 1
			d = d + 1
			table.insert(cleanParts, v)
		end
	end
	local cleanPath = path:sub(1,1) == shell.delimiter and shell.delimiter or ""
	for k,v in pairs(cleanParts) do
		cleanPath = cleanPath .. v .. (k == #cleanParts and "" or shell.delimiter)
	end

	if path:sub(#path, #path) == shell.delimiter and cleanPath:sub(#cleanPath, #cleanPath) ~= shell.delimiter then
		cleanPath = cleanPath .. shell.delimiter
	end
	return cleanPath
end

exports.generatePath = function(old, new)
	new = new:gsub("/", shell.delimiter)
	new = new:gsub("\\", shell.delimiter)

	if new:sub(1, #shell.rootPath) == shell.rootPath then
		return exports.cleanPath(new)
	else
		if new:sub(1,1) == shell.delimiter then
			new = new:sub(2)
		end
		return exports.cleanPath(old .. (old:sub(#old, #old) == shell.delimiter and "" or shell.delimiter) .. new)
	end

end

exports.parseArgs = function(input)
	local args = {}
	local buffer = ""
	local bstring = false

	for i = 0, #input do
		local c = input:sub(i,i)
		if c == "\"" then
			if bstring then
				table.insert(args, buffer)
				buffer = ""
				bstring = false
			else
				bstring = true
			end
		elseif c == " " then
			if bstring then
				buffer = buffer .. " "
			elseif buffer ~= "" then
				table.insert(args, buffer)
				buffer = ""
			end
		else
			buffer = buffer .. c
		end
	end
	table.insert(args, buffer)

	local cmd = args[1] or ""
	local _args = {}
	for k,v in ipairs(args) do
		if k > 1 then
			_args[k-1] = v
		end
	end

	return cmd, _args
end

exports.parseURL = function(url)
	local _url = string.split(url, "?")
	local path = _url[1] or url
	local ending = string.split(path, ".")
	ending = ending[#ending]
	local _get = string.split(_url[2] or "", "&")
	local get = {}
	for k,v in pairs(_get) do
		local arg = string.split(v, "=")
		if arg[1] and arg[2] then
			get[arg[1]] = arg[2]
		end
	end
	return {path = path, get = get, ending = ending}
end

exports.HTTPServer = function(port, cb)
	local server = {}

	server.dataTypes = {}

	server.server = http.createServer(function (req, res)

		res:on("error", function(err)
			print("Error while sending a response: " .. tostring(err))
		end)

		local function out(out, _ctype, code)
			local body = out
			local ctype = _ctype or "text/html"

			if not body then
				body = code or 404
				code = code or 404
				ctype= "text/html"
			else
				code = 200
			end

			res:writeHead(code, {["Content-Type"] = ctype,["Content-Length"] = #body})
			res:finish(body)
		end


		local url = exports.parseURL(req.url)
		print("Request for:", req.url, "by:",  req.socket:address().ip)


		if server.dataTypes[url.ending] then

			local custom = server.dataTypes[url.ending]

			if type(custom) == "function" then
				custom(url, out)
			else
				if fs.existsSync("." .. url.path) then
					out(fs.readFileSync("." .. url.path), custom)
				else
					out()
				end
			end

			else

			if cb then
				cb(req, out, res)
			else
				out(nil, nil, 500)
			end

		end

	end):listen(port)

	server.addDataType = function(self, ending, custom)
		self.dataTypes[ending] = custom
	end

	print("Started HTTP Server on port", port)

	return server
end