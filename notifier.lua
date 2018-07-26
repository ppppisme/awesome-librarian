local naughty = require("naughty")

return {
  notify = function(options)
    return naughty.notify(options)
  end,

  replace_text = naughty.replace_text,

  reset_timeout = naughty.reset_timeout,
}
