exports.name = "help"

exports.description = "returns a list of all commands / gives detailed information about a command"

exports.onExec = function(client, v1)
  if v1 and shell.commands[v1] then
    client:cout("help (".. v1 .. "): " .. shell.commands[v1].description)
    return
  end

  local line = ""
  local c = 0
  for k,v in pairs(shell.commands) do
    c = c + 1
    line = line .. v.name .. ", "
    if c >= 5 then
      c = 0
      client:cout(line)
      line = ""
    end
  end
  if c > 0 then
    client:cout(line:sub(1,#line - 2))
  end
end
