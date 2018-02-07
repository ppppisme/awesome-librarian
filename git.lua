local awful = require("awful")

local git = {}
local libraries_path = ""

function git.clone(library_name, callback)
  local path_to_library = libraries_path .. library_name .. "/"

  local command ="git clone https://github.com/" .. library_name .. ".git"

  command = command .. " " .. path_to_library
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  awful.spawn.with_shell(command)
end

function git.checkout(library_name, reference, callback)
  local path_to_library = libraries_path .. library_name .. "/"

  local command = "cd " .. path_to_library .. " && git checkout " .. reference
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  awful.spawn.with_shell(command)
end

function git.pull(library_name, callback)
  local path_to_library = libraries_path .. library_name .. "/"

  local command = "cd " .. path_to_library .. " && git pull"
  if (callback) then
    awful.spawn.easy_async_with_shell(command, callback)

    return
  end
  awful.spawn.with_shell(command)
end

function git.init(options)
  libraries_path = options.libraries_path or ""
end

return git
