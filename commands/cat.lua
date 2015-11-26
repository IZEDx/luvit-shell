exports.name = "cat"

exports.description = "outputs the content of a file to the console"

exports.onExec = function(client, path)
	path = util.generatePath(client.path, path)
	if not fs.existsSync(path) then
		client:cout("file not found")
		return
	end

	fs.stat(path, function(err, stats)
		if err then
			client:cout(err)
		end
		if stats.type ~= "file" then
			client:cout("target is no file")
			return
		end

		fs.readFile(path, function(err, data)
			if err then 
				client:cout(err) 
			else 
				client:cout(data) 
			end
		end)
	end)
end
