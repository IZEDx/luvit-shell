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