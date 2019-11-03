# Librarian

## Description

Librarian is a simple yet capable library manager for Awesome WM. It's purpose
is to ease and automate installation of AwesomeWM plugins, especially those
which are not distributed as luarocks package.

## Features:

*  Automatic library download and installation with one line of code
*  Support for various sources of libraries like git repositories and etc.
*  Supports async download if you are using proper library handler

## Installation

1. Move to the Awesome configuration directory

```shellscript
cd ~/.config/awesome
```

1. Download latest version of librarian:

```shellscript
wget https://github.com/scisssssssors/awesome-librarian/archive/master.zip
```

1. Unzip downloaded archive:

```shellscript
unzip master.zip
```

1. And then rename unzipped directory to librarian:

```shellscript
mv awesome-librarian-master librarian
```

1. Last step is to let rc.lua know about librarian by requiring it:

```lua
local librarian = require("librarian")
local gears = require("gears")

-- libraries_dir points to a directory which will store all downloaded libraries
-- if it doesn't exist then librarian will create it
librarian.init({
    libraries_dir = gears.filesystem.get_configuration_dir() .. "/libraries/",
})
```

## Usage

To require a library use this line:

```lua
-- assuming that you have required librarian before this snippet

local tyrannical = librarian.require("Elv13/tyrannical")
```

Tyrannical variable will contain table that would be returned by ordinary
`require`. What really happens is librarian downloads the library, registers it
in package.path and only then it returns required table.

By default, an assumption is made that required library is hosted on Github,
otherwise you can specify url via `url` item in `options` object passed as a
second argument:

```lua
local tyrannical = librarian.require("Elv13/tyrannical", {
    url = "https://whatever.address/is/to/git/repository",
})
```

In case you use asynchronous library handler, you can run code after library is
initialized:

```lua
local tyrannical = librarian.require("Elv13/tyrannical", {
    do_after = function (tyrannical)
        tyrannical.properties.maximized = {
            test = false,
        }
    end,
})
```

It is also possible to require specific version of library by providing
`reference` key:

```
local tyrannical = librarian.require("Elv13/tyrannical", {
    reference = "next", -- you can use both branch name or commit hash
})
```

## Alternatives:

*  git submodules system
*  luarocks packages which are automatically available in Awesome since v4.3
