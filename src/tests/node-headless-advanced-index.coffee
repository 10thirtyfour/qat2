"use strict"

cfeval = require("coffee-script").eval
vm = require "vm"

module.exports = ->

  {path,Q,fs,_,yp,utils} = runner = @

  @runner.tests.globLoader.disable.file.pattern?=[]
  for dbp of @opts.dbprofiles when dbp isnt @opts.common.options.databaseProfile
    @runner.tests.globLoader.disable.file.pattern.push "**/*-#{dbp}-db-qfgl-test.coffee"

  @reg
    name: "advancedLoader"
    before: ["globLoader"]
    setup: true
    promise: ->
      yp.frun =>
        @runner.tests.globLoader.regGlob
          name: "node$headless-advanced"
          pattern: ["**/*-test.coffee"]
          parseFile: (fn) ->
            yp.frun ->
              contextParams =
                fileName: fn
                testName : runner.toolfuns.filenameToTestname(fn)
                relativeName: path.relative(runner.tests.globLoader.root, fn)
                runner: runner
              for n,f of runner.extfuns
                do (n,f) =>
                  contextParams[n] = (params...) ->
                    f.apply contextParams,params
              try
                cfeval fs.readFileSync(fn,encoding:"utf8"),sandbox: contextParams
              catch errorMessage
                runner.info "Headless-advanced. Eval failed for #{fn}. Message : #{errorMessage}"
              true
        true
