
module.exports = ->
  {Q,utils} = @

  return true
  @reg
    name: "xdep"
    #silent : (true)
    runAnyway: (true)
    before : ["done"]
    promise: ->
      @runner.logger.trace "xdep"

  return true

  for i in [11..0]
    if i==0
      @reg
        name: "xdep$"+i
        silent : (true)
        runAnyway: (true)
        promise: ->
          @runner.logger.trace "xdep$"+i
    else
      @reg
        name: "xdep$"+i
        after: ["xdep$#{i-1}"]
        silent : (true)
        runAnyway: (true)
        promise: ->
          @runner.logger.trace "xdep$"+i
