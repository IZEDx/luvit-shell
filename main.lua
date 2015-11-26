_G.fs = require('fs')
_G.http = require('http')
_G.timer = require('timer')
_G.os = require('os')
_G.uv = require('uv')
_G.table = require('table')
_G.string = require('string')
_G.ffi = require('ffi')

_G.luvsocks = require('luvsocks')

_G.sleep = uv.sleep
os.homedir = uv.os_homedir


require('additions')
_G.util = require('util')


_G.config = require('./config.lua')

--process.new = uv.Process.initialize

_G.isWin = ffi.os:lower():find("win") 

_G.shell = {} -- global variable holder
shell.commands = {}
shell.rootPath = isWin and "C:\\" or "/"
shell.delimiter = isWin and "\\" or "/"


-- print(require('los').type())


------------- Load commands
do
	for k,v in pairs(config.commands) do
		local stats = fs.statSync("./commands/" .. tostring(v) .. ".lua")
		if stats.type == "file" then
			local cmd = require("./commands/" .. tostring(v) .. ".lua")
			if cmd.name then
				shell.commands[cmd.name] = cmd
			end
		end
	end
end


------------------ error handler
process:on('error', function(v)
	print(v)
end)


--------------- Initialize http server
local HTTPServer = util.HTTPServer(config.http.port, function(req,ret,res)
	local url = util.parseURL(req.url)

	local html = util.makeHTMLTemplate("./template.html", {
		TITLE = "shell@" .. config.ws.host .. "(" .. ffi.os .. ffi.arch .. ")",
		WSHOST = req.socket:address().ip == "127.0.0.1" and "127.0.0.1" or config.ws.host,
		WSPORT = config.ws.port
	})
	ret(html)
end)

_G.Server = luvsocks.new():listen(config.ws.port)

Server:on("connect", function(client)
	print("New client connected from:", client.ip, "UID:", client.uid)

	client.queue = {}

	client.cout = function(client, msg)
		table.insert(client.queue, msg)
	end

	client.interval = timer.setInterval(10, function()
		for k,msg in pairs(client.queue) do
			client:send("cout", msg)
			client.queue[k] = nil
			break
		end
	end)

	client.indicator = function(client, i)
		client.indic = i
		client:send("indicator", {indicator = i})
	end

	client.path = shell.rootPath
	client:indicator("login as:")

	client.onUsername = function(client, data)
		if not config.users[data] then
			client:cout("-zhell " .. data .. ": username not found")
			print(client.ip .. " attempted to login using " .. data)
			return
		end
		client.username = data
		client.authenticated = false
		client:cout([[Using username "]] .. client.username .. [[".]])
		print(client.ip .. " attempts to login using " .. client.username)
		client:indicator(client.username .. "@" .. config.ws.host .. "'s password:")
	end

	client.onPassword = function(client, data)
		if not client.username or client.authenticated then return end
		if data == config.users[client.username] then
			client.authenticated = true
			client:cout("shell 1.0-stable #1 SMP " .. os.date() .. " " .. ffi.os .. ffi.arch)
			client:cout(" ")
			client:cout("The commands in this shell are free for use and may affect")
			client:cout("the system they're ran on in a negative way. This should not")
			client:cout("be used by an individual with no preceeding knowledge of this")
			client:cout("particular product or the system it's run on.")
			client:cout(" ")
			client:cout("This shell comes with ABSOLUTELY NO WARRANTY, to the extent")
			client:cout("permitted by applicable law.")
			client:cout("All copyright goes to IZED, b42.in, big thanks to luvit!")
			client:indicator(client.username .. "@" .. config.ws.host .. ": " .. client.path .. " $")
			print(client.ip .. " successfully logged in using " .. client.username)
		else
			client:cout("-shell " .. data .. ": invalid password")
			print(client.ip .. " failed logging into " .. client.username)
		end
	end


	client:on("input", function(data)
		if type(data) ~= "string" then return end
		if not client.username then
			client:onUsername(data)
			return
		elseif not client.authenticated then
			client:onPassword(data)
			return
		end

		local cmd, args = util.parseArgs(data)

		if not cmd then return end
		print(client.username .. "[" .. client.ip .. "]", "entered command", data)

		local c = shell.commands[cmd]
		if not c then
			client:cout("-shell " .. cmd .. ": command not found, try \"help\"")
			return
		end

		c.onExec(client, unpack(args))
	end)
end)