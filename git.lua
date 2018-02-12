local awful = require("awful")

local git = {}
local libraries_path = ""

local spawn_synchronously = function(command)
  local handle = io.popen(command)
  local output = handle:read("*all")
  output = output:gsub("%c$", "")
  handle:close()

  return output
end

function git.clone(library_name, callback)
  local command ="git clone https://github.com/" .. library_name .. ".git"
  local path_to_library = libraries_path .. library_name .. "/"
  command = command .. " " .. path_to_library
  if (callback) then
    if (callback == "async") then
      awful.spawn.with_shell(command)
    else
      awful.spawn.easy_async_with_shell(command, callback)
    end

    return
  end
  spawn_synchronously(command)
end

function git.checkout(library_name, reference, callback)
  local path_to_library = libraries_path .. library_name .. "/"
  local command = "cd " .. path_to_library .. " && git checkout " .. reference
  if (callback) then
    if (callback == "async") then
      awful.spawn.with_shell(command)
    else
      awful.spawn.easy_async_with_shell(command, callback)
    end

    return
  end
  spawn_synchronously(command)
end

function git.pull(library_name, callback)
  local path_to_library = libraries_path .. library_name .. "/"
  local command = "cd " .. path_to_library .. " && git pull"
  if (callback) then
    if (callback == "async") then
      awful.spawn.with_shell(command)
    else
      awful.spawn.easy_async_with_shell(command, callback)
    end

    return
  end
  spawn_synchronously(command)
end

function git.init(options)
  libraries_path = options.libraries_path or ""
end

return git
