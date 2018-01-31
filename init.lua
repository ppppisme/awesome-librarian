local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

return {
  __libraries = { },

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

  __download = function(self, library_name, notification)
    local config_dir = gears.filesystem.get_configuration_dir()
    local command ="git clone https://github.com/" .. library_name .. ".git"
    command = command .. " " .. config_dir .. "libraries/" .. library_name .. "/"

    awful.spawn.easy_async(command, function(stdout, stderr, reason, exit_code)
      if (exit_code ~= 0) then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Librarian",
            text = stderr,
          })
      end

      if (notification == nil) then
        return
      end

      naughty.destroy(notification)
    end)
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
    naughty.notify({
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
          naughty.notify({
              title = "Librarian",
              text = "Removing " .. dir .. "...",
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

  require = function(self, library_name)
    table.insert(self.__libraries, library_name)

    if (not self:is_installed(library_name)) then
      local notification = naughty.notify({
          title = "Librarian",
          text = "Installing " .. library_name .. " library. This message will disappear when the process is done.",
          timeout = 0,
        })
      self:__download(library_name, notification)

      return nil
    end

    local config_dir = gears.filesystem.get_configuration_dir()
    local author = string.match(library_name, "[^/]+")
    package.path = config_dir .. "libraries/" .. author .. "/?/init.lua;" .. package.path
    package.path = config_dir .. "libraries/" .. author .. "/?.lua;" .. package.path

    return require('libraries/' .. library_name)
  end,
}
