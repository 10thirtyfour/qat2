module.exports = ->
  {Q,utils} = @
  @reg
    name: "node-modules-search"
    before: "globLoader"
    setup: true
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$modules"
        pattern: ["**/*-index.+(js|coffee)"]
        parseFile: (fn) ->
          Q(require fn)
      Q({})
