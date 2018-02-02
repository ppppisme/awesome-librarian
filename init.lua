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

return {
  __libraries = { },
  verbose = false,

  __notify = function(self, options)
    if (not self.verbose) then return end

    return naughty.notify(options)
  end,

  __spawn_synchronously = function(self, command)
    local handle = io.popen(command)
    local output = handle:read("*all")
    output = output:gsub("%c$", "")
    handle:close()

    return output
  end,

  __dir_is_empty = function(self, dir_path)
    return self:__spawn_synchronously("ls -A " .. dir_path) == ""
  end,

  __remove_file_or_dir = function(self, path)
    os.execute("rm -rf " .. path)
  end,

  __has_item = function(self, table, wanted_item)
    for _, item in pairs(table) do
      if (item == wanted_item) then
        return true
      end
    end

    return false
  end,

  __git = {
    __libraries_path = "",

    clone = function(self, library_name, callback)
      local path_to_library = self.__libraries_path .. library_name .. "/"

      local command ="git clone https://github.com/" .. library_name .. ".git"

      command = command .. " " .. path_to_library
      if (callback) then
        awful.spawn.easy_async_with_shell(command, callback)

        return
      end
      awful.spawn.with_shell(command)
    end,

    checkout = function(self, library_name, reference, callback)
      local path_to_library = self.__libraries_path .. library_name .. "/"

      local command = "cd " .. path_to_library .. " && git checkout " .. reference
      if (callback) then
        awful.spawn.easy_async_with_shell(command, callback)

        return
      end
      awful.spawn.with_shell(command)
    end,

    pull = function(self, library_name, callback)
      local path_to_library = self.__libraries_path .. library_name .. "/"

      local command = "cd " .. path_to_library .. " && git pull"
      if (callback) then
        awful.spawn.easy_async_with_shell(command, callback)

        return
      end
      awful.spawn.with_shell(command)
    end,
  },

  update = function(self, library_name)
    local notification = self:__notify({
        title = "Librarian",
        text = "Updating " .. library_name .. "...",
        timeout = 0,
      })

    self.__git:pull(library_name, function()
      naughty.destroy(notification)
    end)
  end,

  update_all = function(self)
    for _, library_name in pairs(self.__libraries) do
      self:update(library_name)
    end
  end,

  is_installed = function(self, library_name)
    -- @see https://stackoverflow.com/a/40195356
    local exists = function (file)
      local ok, err, code = os.rename(file, file)
      if not ok then
        if code == 13 then return true end
      end
      return ok
    end

    local config_dir = gears.filesystem.get_configuration_dir()

    return exists(config_dir .. "libraries/" .. library_name .. "/init.lua")
  end,

  clean = function(self)
    self:__notify({
        title = "Librarian",
        text = "Removing not used libraries...",
      })

    local libraries_dir = gears.filesystem.get_configuration_dir() .. "libraries/"

    local find_command = "cd " .. libraries_dir .. " && "
    find_command = find_command .. "find -mindepth 2 -maxdepth 2 -type d"

    awful.spawn.easy_async_with_shell(find_command, function(stdout)
      -- Remove preceding './'s
      local dir_list = stdout:gsub("%./", "")

      for dir in dir_list:gmatch("(.-)%c") do
        if (not self:__has_item(self.__libraries, dir)) then
          self.__notify({
              title = "Librarian",
              text = "Removing " .. dir .. "...",
              timeout = 1,
            })
          self:__remove_file_or_dir(libraries_dir .. dir)

          local parent_dir = libraries_dir .. dir:gsub("[^/]+$", "")
          if (self:__dir_is_empty(parent_dir)) then
            self:__remove_file_or_dir(parent_dir)
          end
        end
      end
    end)
  end,

  require = function(self, library_name, options)
    table.insert(self.__libraries, library_name)

    if (not options) then
      options = {
        reference = "master",
      }
    end

    if (not self:is_installed(library_name)) then
      local notification = self.__notify({
          title = "Librarian",
          text = "Installing " .. library_name .. " library. This message will disappear when the process is done.",
          timeout = 0,
        })

      self.__git:clone(library_name, function()
        naughty.destroy(notification)
      end)

      if (options.reference ~= "master") then
        self.__git:checkout(library_name, options.reference)
      end

      return nil
    end

    self.__git:checkout(library_name, options.reference)

    local config_dir = gears.filesystem.get_configuration_dir()
    local author = string.match(library_name, "[^/]+")
    package.path = config_dir .. "libraries/" .. author .. "/?/init.lua;" .. package.path
    package.path = config_dir .. "libraries/" .. author .. "/?.lua;" .. package.path

    return require('libraries/' .. library_name)
  end,

  init = function(self, options)
    self.verbose = options.verbose or false

    local libraries_path = gears.filesystem.get_configuration_dir() .. "libraries/"
    self.__git.__libraries_path = libraries_path
  end,
}
