"use strict"

module.exports = ->
  {Q,_,prettyjson} = runner = @
  @reg
    name: "async"
    setup: true
    maxThreads: 2
    # TODO: tests with shared state should run in sequence, for this
    #       we need to update the graph and rebuild the graph to make
    #       such cases to run in sequence
    disabled: true
    promise: ->
      cur = 0
      queue = []
      checkQ = =>
        {maxThreads} = @
        av = maxThreads - cur
        @trace "queue: #{queue.length}, working now:#{cur}, available:#{av}"
        nxt = for i in queue.splice 0, av
            i().finally( ->
              cur--
              checkQ())
        cur+= nxt.length
        if runner.stopOnError
          Q.all(nxt)
        else
          Q.all(for i in nxt
            i.catch (e) ->
              runner.info "error", prettyjson e
              Q {})
      @trace "replacing scheduler"
      #TODO: use base scheduler
      runner.schedule = (actions) =>
        queue.push actions...
        checkQ()
        Q {}
      Q {}
