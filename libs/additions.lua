exports.name = "additions"
exports.author = "Niklas Kühtmann"

fs.rmsubdir = function(path, cb)
	fs.readdir(path, function(err, files)
		if err or (not files) then
			cb(err)
		else
			for k,v in pairs(files) do
				local stats = fs.statSync(path .. "/" .. tostring(v))
				if stats.is_file then
					local ret = fs.unlinkSync(path .. "/" .. tostring(v))
					if ret then
						cb(ret)
						return
					end
				elseif stats then
					local ret = fs.rmsubdir(path .. "/" .. tostring(v))
					if ret then
						cb(ret)
						return
					end
				end
			end
			fs.rmdir(path, cb)
		end
	end)
end

table.find = function(t, v)
	for k,v1 in pairs(t) do
		if v1 == v then
			return k
		end
	end
	return nil
end

table.reverse = function( tab )
	local size = #tab
	local newTable = {}

	for i,v in ipairs ( tab ) do
		newTable[size-i] = v
	end

	return newTable
end

table.invert = function( tab )
	local newTable = {}

	for k,v in pairs ( tab ) do
		newTable[v] = k
	end

	return newTable
end

table.foreach = function(t, f)
	local ret = {}
	for k,v in pairs(t) do
		table.insert(ret, f(k,v))
	end
	return unpack(ret)
end



string.split = function(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end

	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end