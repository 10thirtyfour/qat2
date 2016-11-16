
module.exports = ->
  {Q,utils} = @

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
