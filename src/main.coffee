###
# #%L
# QUERIX
# %%
# Copyright (C) 2015 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel : +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
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

