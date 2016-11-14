
module.exports = ->
  {Q,utils} = @

  for i in [11..0]
    if i==0
      @reg
        name: "xdep$"+i
    else
      @reg
        name: "xdep$"+i
        after: ["xdep$#{i-1}"]
        silent: (true)
        runAnyway: (true)
        promise: ->
            @runner.logger.trace "xdep$"+i
