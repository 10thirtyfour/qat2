archy = require "archy"

module.exports = ->
  {Q,_,prettyjson,utils,winston} = runner = @
  util = require "util"
  sum = (vals) ->
    vals.reduce(
      (l,r) -> l + r
      0)
  _store = null
  _reduce = null
  _maxLevel = null
  emit = (k,v) ->
    if _.isArray k
      cur = _store
      upd = ->
        if cur._?
          cur._ = _reduce [k], [cur._,v]
        else
          cur._ = v
      upd()
      for i,x in utils.mkArray k
        if x >= _maxLevel
          if cur[i]
            cur[i] = _reduce [k], [cur[i],v]
          else
            cur[i] = v
          break
        cur = cur[i] ?= { }
        upd()
  plugin =
    setup: true
    name: "aggregator"
    after: ["logger"] # that's not needed though (logger is inited before `go`)
    queries:
      common:
        map: ({params:p}) ->
          kind = p.kind ? "nokind"
          emit([p.level,kind,p.name], 1) if p? and p.name and p.level
    promise: ->
      class Transport 
        constructor: (@opts) ->
          @name = "aggregator"
      util.inherits Transport, winston.Transport
      runner.logger.add Transport, {}
      Transport::log = (level, msg, meta, callback) ->
          if level is "pass" or level is "fail"
            params = _.assign {}, meta,
              timestamp: new Date
              level: level
              message: msg
            msg = params: params
            for i,v of plugin.queries
              return if v.disabled
              _store = v._store ?= {}
              _reduce = v.reduce ?= (keys,vals) -> sum vals
              _maxLevel = v.levels ? 1
              v.map msg
              _store = null
              _reduce = null
          callback null, true
      Q {}
  labelToColor = (lab) ->
    switch lab
      when "pass" then lab.green
      when "fail" then lab.red
      else lab
  mkTree = ->
    go = (obj) ->
        for i, v of obj when i isnt "_"
          if v._?
            label: "#{labelToColor i}:#{v._}"
            nodes: go(v)
          else
            "#{labelToColor i}:#{v}"
    tree = {}
    for name, {_store} of plugin.queries
      tree.label = name
      tree.nodes = go _store
    tree
  donePromise = runner.tests.done.promise
  runner.tests.done.promise = ->
    console.log archy mkTree()
    runner.spammer "sendReport", key:runner.sysinfo.starttimeid
    donePromise.call @
  @reg plugin
