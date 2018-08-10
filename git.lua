local awful = require("awful")

local git = {}
local libraries_dir = ""

local spawn_synchronously = function(command)
  local handle = io.popen(command)
  local output = handle:read("*all")
  output = output:gsub("%c$", "")
  handle:close()

  return output
end

function git.clone(library_name, url, callback)
  local command = "git clone "
  url = url or "https://github.com/" .. library_name .. ".git"
  command = command .. url

  local path_to_library = libraries_dir .. library_name .. "/"
  command = command .. " " .. path_to_library
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  spawn_synchronously(command)
end

function git.checkout(library_name, reference, callback)
  local path_to_library = libraries_dir .. library_name .. "/"
  local command = "cd " .. path_to_library .. " && git checkout " .. reference
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  spawn_synchronously(command)
end

function git.pull(library_name, callback)
  local path_to_library = libraries_dir .. library_name .. "/"
  local command = "cd " .. path_to_library .. " && git pull"
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  spawn_synchronously(command)
end

function git.init(options)
  libraries_dir = options.libraries_dir or ""
end

return git
