
module.exports = ->
  {Q,utils} = @

  @reg
    name: "read$environ"
    setup: true
    before: ["globLoader"]
    data:
      kind: "setup"
    promise: @toolfuns.getEnviron

  @reg
    name: "node-modules-search"
    after: ["advancedLoader","tlogLoader"]
    before: "globLoader"
    setup: true
    disabled: true
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$modules"
        pattern: ["**/*-index.+(js|coffee)"]
        parseFile: (fn) ->
          Q(require fn)
    @reg
      name: "xdep"
      silent : (true)
      runAnyway: (true)
      before : ["done"]
      promise: ->
        @runner.logger.trace "xdep"
      Q({})
