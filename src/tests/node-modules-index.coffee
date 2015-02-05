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
module.exports = ->
  {Q,utils} = @
  @reg
    name: "node-modules-search"
    before: "globLoader"
    setup: true
    disabled: true
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$modules"
        pattern: ["**/*-index.+(js|coffee)"]
        parseFile: (fn) ->
          Q(require fn)
      Q({})
