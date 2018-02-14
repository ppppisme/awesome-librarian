--  _ _ _                    _
-- | (_) |__  _ __ __ _ _ __(_) __ _ _ __
-- | | | '_ \| '__/ _` | '__| |/ _` | '_ \
-- | | | |_) | | | (_| | |  | | (_| | | | |
-- |_|_|_.__/|_|  \__,_|_|  |_|\__,_|_| |_|
--
--
-- Copyright (C) 2018 pppp
--
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
-- more details.
--
-- You should have received a copy of the GNU General Public License along with
-- this program.  If not, see <https://www.gnu.org/licenses/>.
--

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local git = require("librarian.git")

local librarian = {}

local libraries = {}
local libraries_dir = ""
local verbose = false;

local notify = function(options)
  if (not verbose) then return end

  return naughty.notify(options)
end

-- @see https://stackoverflow.com/a/40195356
local exists = function (file)
  local ok, _, code = os.rename(file, file)
  if not ok then
    if code == 13 then return true end
  end
  return ok
end

local spawn_synchronously = function(command)
  local handle = io.popen(command)
  local output = handle:read("*all")
  output = output:gsub("%c$", "")
  handle:close()

  return output
end

local dir_is_empty = function(dir_path)
  return spawn_synchronously("ls -A " .. dir_path) == ""
end

local remove_file_or_dir = function(path)
  os.execute("rm -rf " .. path)
end

local has_item = function(table, wanted_item)
  for _, item in pairs(table) do
    if (item == wanted_item) then
      return true
    end
  end

  return false
end

local add_to_package_path = function(library_name)
  local config_dir = gears.filesystem.get_configuration_dir()
  local author = string.match(library_name, "[^/]+")
  package.path = config_dir .. libraries_dir .. author .. "/?/init.lua;" .. package.path
  package.path = config_dir .. libraries_dir .. author .. "/?.lua;" .. package.path
end

local function install_async(library_name, options, callback)
  local notification = notify({
      title = "Librarian",
      text = "Installing " .. library_name .. " library...",
      timeout = 0,
    })

  git.clone(library_name, function()
    naughty.replace_text(notification, "Librarian", library_name .. " is installed.")
    naughty.reset_timeout(notification, 5)
    git.checkout(library_name, options.reference or "master")
    if (callback ~= "async") then
      callback()
    end
  end)
end

local function install(library_name, options)
  local notification = notify({
      title = "Librarian",
      text = "Installing " .. library_name .. " library...",
      timeout = 0,
    })

  git.clone(library_name)
  git.checkout(library_name, options.reference or "master")

  naughty.replace_text(notification, "Librarian", library_name .. " is installed.")
  naughty.reset_timeout(notification, 5)
end

function librarian.update(library_name)
  local notification = notify({
      title = "Librarian",
      text = "Updating " .. library_name .. "...",
      timeout = 0,
    })

  git.pull(library_name, function(stdout)
    local message = library_name .. " was updated."
    if (stdout:gsub("%c", "") == "Already up to date.") then
      message = library_name .. " is up to date."
    end
    naughty.replace_text(notification, "Librarian", message)
    naughty.reset_timeout(notification, 5)
  end)
end

function librarian.update_all()
  for _, library_name in pairs(libraries) do
    librarian.update(library_name)
  end
end

function librarian.is_installed(library_name)
  local config_dir = gears.filesystem.get_configuration_dir()

  return exists(config_dir .. libraries_dir .. library_name .. "/init.lua")
end

function librarian.clean()
  notify({
      title = "Librarian",
      text = "Removing not used libraries...",
    })

  local libraries_path = gears.filesystem.get_configuration_dir() .. libraries_dir

  local find_command = "cd " .. libraries_path .. " && "
  find_command = find_command .. "find -mindepth 2 -maxdepth 2 -type d"

  awful.spawn.easy_async_with_shell(find_command, function(stdout)
    -- Remove preceding './'s
    local dir_list = stdout:gsub("%./", "")

    for dir in dir_list:gmatch("(.-)%c") do
      if (not has_item(libraries, dir)) then
        notify({
            title = "Librarian",
            text = "Removing " .. dir .. "...",
            timeout = 1,
          })
        remove_file_or_dir(libraries_path .. dir)

        local parent_dir = libraries_path .. dir:gsub("[^/]+$", "")
        if (dir_is_empty(parent_dir)) then
          remove_file_or_dir(parent_dir)
        end
      end
    end
  end)
end

function librarian.require_async(library_name, options, callback)
  table.insert(libraries, library_name)
  options = options or {}
  callback = callback or "async"

  if (not librarian.is_installed(library_name)) then
    install_async(library_name, options, function()
      local library = require(libraries_dir .. library_name)
      if (callback ~= "async") then
        callback(library)
      end
    end)

    return nil
  end

  git.checkout(library_name, options.reference or "master", function()
    local library = require(libraries_dir .. library_name)
    callback(library)
  end)
end

function librarian.require(library_name, options)
  table.insert(libraries, library_name)
  options = options or {}

  if (not librarian.is_installed(library_name)) then
    install(library_name, options)
  end

  git.checkout(library_name, options.reference or "master")
  add_to_package_path(library_name)

  return require(libraries_dir .. library_name)
end

function librarian.init(options)
  verbose = options.verbose or false
  libraries_dir = options.libraries_dir or "libraries/"

  local libraries_path = gears.filesystem.get_configuration_dir() .. libraries_dir .. "/"
  if (not exists(libraries_path)) then
    os.execute("mkdir -p " .. libraries_path)
  end
  git.init({libraries_path = libraries_path})
end

return librarian
