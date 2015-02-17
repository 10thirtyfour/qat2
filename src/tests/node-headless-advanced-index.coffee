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
cfeval = require("coffee-script").eval
vm = require "vm"

module.exports = ->
  
  {path,Q,fs,_,yp,utils} = runner = @

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
            yp.frun =>
              #console.log " COFEEE >> #{fn}"
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
      
