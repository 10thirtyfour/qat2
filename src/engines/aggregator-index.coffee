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
              _store = (null)
              _reduce = (null)
          callback null, (true)
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
    deff = Q.defer()
    p = deff.promise.timeout(10000)
    if runner.logger.transports.couchdb?
      db = require('nano')('http://'+runner.logger.transports.couchdb.host+':5984/qat_log')
      db.view 'suits','all', { key : runner.sysinfo.starttimeid }, (err, suits)->
        if((err) || (suits.rows.length!=1)) 
          console.log "!!! Cant get suite or key is not unique !!!"
          deff.resolve("err")
          return
        suite=suits.rows[0]
        suite.value.params.status   = "complete"
        suite.value.params.result   = plugin.queries.common._store
        suite.value.params.duration = Math.round((new Date() - new Date(runner.sysinfo.starttimeid)) / 1000)
        db.insert suite.value, suite._id, (err, msg)->
          runner.spammer "report", key:runner.sysinfo.starttimeid  
          if err then deff.resolve("error") else deff.resolve("ok")
    else
      deff.resolve("no couchdb")
 
    console.log archy mkTree()
    
    context=@
    return p.then( ()-> donePromise.call context)
  @reg plugin
