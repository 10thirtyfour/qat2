cfeval = require("coffee-script").eval
vm = require "vm"

module.exports = ->
  
  {path,Q,fs,_,yp,utils} = runner = @

  @reg
    name: "node-headless-advanced-index"
    before: "globLoader"
    setup: true
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$headless-advanced"
        pattern: ["**/*-test.coffee"]
        parseFile: (fn) ->
          yp.frun( =>
            contextParams = 
              fileName: fn
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
            return ->
              nop=0
            )
      Q({})
