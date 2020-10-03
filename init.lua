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
local utils = require("librarian.utils")

local librarian = {}

local libraries = {}
local libraries_dir = ""

local library_managers = {
  require("librarian.git")
}

local notifier = {}

local function determine_library_manager(library)
  return require("librarian.git")
end

local add_to_package_path = function (library_name)
  local author = string.match(library_name, "[^/]+")

  package.path = libraries_dir .. author .. "/?/init.lua;" .. package.path
  package.path = libraries_dir .. author .. "/?.lua;" .. package.path
end

function librarian.update(library_name)
  local handler = determine_library_manager(library_name)

  handler.pull(library_name)
end

function librarian.update_all()
  for library_name, _ in pairs(libraries) do
    librarian.update(library_name)
  end
end

function librarian.is_installed(library_name)
  return utils.file_exists(libraries_dir .. library_name .. "/init.lua")
end

function librarian.remove_unused()
  notifier.notify({
    title = "Librarian",
    text = "Removing not used libraries...",
  })

  local find_command = "cd " .. libraries_dir .. " && "
  find_command = find_command .. "find -mindepth 2 -maxdepth 2 -type d"

  awful.spawn.easy_async_with_shell(find_command, function(stdout)
    -- Remove preceding './'s
    local dir_list = stdout:gsub("%./", "")

    for dir in dir_list:gmatch("(.-)%c") do
      if (not utils.has_key(libraries, dir)) then
        notifier.notify({
          title = "Librarian",
          text = "Removing " .. dir .. "...",
          timeout = 1,
        })

        utils.remove_file_or_dir(libraries_dir .. dir)

        local parent_dir = libraries_dir .. dir:gsub("[^/]+$", "")

        if (utils.dir_is_empty(parent_dir)) then
          utils.remove_file_or_dir(parent_dir)
        end
      end
    end
  end)
end

local function install(library_name, options)
  local handler = determine_library_manager(library_name)
  handler.clone(library_name, options.url)
end

function librarian.require(library_name, options)
  options = options or {}
  options.name = library_name

  libraries[library_name] = options

  if (not librarian.is_installed(library_name)) then
    install(library_name, options)
  end

  local handler = determine_library_manager(library_name)
  handler.checkout(library_name, options.reference or "master")
  add_to_package_path(library_name)

  local library = require(library_name)
  -- Do not continue if handler returns false.

  local do_after_callback = options["do_after"]
  if (do_after_callback) then
    do_after_callback(library)
  end

  return library
end

function librarian.init(_libraries_dir, options)
  libraries_dir = _libraries_dir

  if (not utils.file_exists(libraries_dir)) then
    os.execute("mkdir -p " .. libraries_dir)
  end

  package.path = libraries_dir .. "/?/init.lua;" .. package.path
  notifier = options.notifier or require('naughty')

  if (options.library_managers) then
    for _, item in pairs(options.library_managers) do
      table.insert(library_managers, item)
    end
  end

  -- TODO: do not init all managers, only needed ones.
  for _, item in pairs(library_managers) do
    item.init({libraries_dir = libraries_dir})
  end
end

return librarian
