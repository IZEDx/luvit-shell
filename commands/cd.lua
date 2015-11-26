exports.name = "cd"

exports.description = "navigates to the defined folder, use .. to go back a folder"

exports.onExec = function(client, path)
	path = util.generatePath(client.path, path)
	if not fs.existsSync(path) then
		client:cout("directory not found")
		return
	end

	fs.stat(path, function(err, stats)
		if err then
			client:cout(err)
		end
		if stats.type == "file" then
			client:cout("target is no directoy")
			return
		end
		if path:sub(#path, #path) ~= shell.delimiter then
			path = path .. shell.delimiter
		end
		client.path = path

		client:indicator(client.username .. "@" .. config.ws.host .. ": " .. client.path .. " $")
	end)
end
