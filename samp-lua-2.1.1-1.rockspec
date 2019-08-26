package = "samp-lua"
version = "2.1.1-1"
source = {
   url = "git+https://github.com/THE-FYP/SAMP.Lua.git",
   tag = "v2.1.1"
}
description = {
   summary = "A SA-MP API library for MoonLoader",
   detailed = "SAMP.Lua is a lua library for MoonLoader that adds some features to make SA-MP modding simpler.",
   homepage = "https://github.com/THE-FYP/SAMP.Lua",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["samp.events"] = "samp/events.lua",
      ["samp.events.bitstream_io"] = "samp/events/bitstream_io.lua",
      ["samp.events.core"] = "samp/events/core.lua",
      ["samp.events.extra_types"] = "samp/events/extra_types.lua",
      ["samp.events.handlers"] = "samp/events/handlers.lua",
      ["samp.events.utils"] = "samp/events/utils.lua",
      ["samp.raknet"] = "samp/raknet.lua",
      ["samp.synchronization"] = "samp/synchronization.lua"
   }
}
