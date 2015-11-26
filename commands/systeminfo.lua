exports.name = "systeminfo"

exports.description = "shows system information"

exports.onExec = function(client, args)
  for k,v in pairs(ffi) do
    client:cout(tostring(k) .. "   " .. tostring(v))
  end
end
