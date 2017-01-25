"use strict"

require "coffee-script"
require("source-map-support").install()

{glob} = runner = require "./runner"

# enable this in config for better error messages
# runner.Q.longStackSupport = true

require("./config").call runner

qrequire = (p) ->
  for i in glob.sync("**/*-index.js", cwd: "lib/#{p}")
    mod = require "./#{p}/#{i}"
    if mod? and mod.call?
      mod.call runner
  return

qrequire "engines"
qrequire "tests"

runner.go().done()
