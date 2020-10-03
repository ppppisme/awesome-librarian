local utils = {}

function utils.spawn_synchronously(command)
  local handle = io.popen(command)
  local output = handle:read("*all"):gsub("%c$", "")
  handle:close()

  return output
end

function utils.remove_file_or_dir(path)
  os.execute("rm -rf " .. path)
end

function utils.dir_is_empty(path)
  return utils.spawn_synchronously("ls -A " .. path) == ""
end

function utils.has_key(table, wanted_key)
  for key, _ in pairs(table) do
    if (key == wanted_key) then
      return true
    end
  end

  return false
end


-- https://stackoverflow.com/a/40195356
function utils.file_exists(file)
  local ok, _, code = os.rename(file, file)
  if not ok then
    if code == 13 then return true end
  end
  return ok
end

return utils
