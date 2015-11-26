exports.name = "ls"

exports.description = "lists all files and folders of the current directory"

exports.onExec = function(client, args)
  fs.readdir(client.path, function(err, files)
    if err or not files then
      client:cout(tostring(err))
      return
    end

    local line = ""
    local c = 0
    local _c = 0
    for k,v in pairs(files) do
      fs.stat(client.path .. v, function(sterr, stats)
        c = c + 1
        _c = _c + 1
        if sterr then return end
        if stats.type ~= "file" then
          v = v .. "/"
        end
        line = line .. v .. ", "
        if c >= 5 then
          c = 0
          client:cout(line)
          line = ""
        end
        if _c >= #files then
          client:cout(line:sub(1,#line - 2))
        end
      end)
    end
  end)
end
