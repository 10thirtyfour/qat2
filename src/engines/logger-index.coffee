module.exports = ->
  {Q,_,winston} = runner = @
  extend = (obj) ->
    _.assign(obj,
      logPrefix: -> @name.cyan + ":"
      logMeta: ->
        _.assign {name: @name}, @data
      trace: (args...) -> @logger.trace @logPrefix(), args...
      info: (args...) -> @logger.info @logPrefix(), args...
      pass: (args...) -> @logger.pass @logPrefix(), args..., @logMeta()
      fail: (args...) -> @logger.fail @logPrefix(), args..., @logMeta())
  plugin =
    setup: true
    name: "logger"
    # CONFOPT:
    disable:
      couchdb: true
      #logio: true
    # CONFOPT:
    transports:
      file:
        filename: "qat.log"
        level: "trace"
        handleExceptions: true
        timestamp: true
      console:
        level: "info"
        handleExceptions: true
        colorize: true
      logio:
        level: "pass"
        handleExceptions: true
        colorize: true
      couchdb:
        host: "localhost"
        port: 5984
        db: "qat_log"
        level: "pass"
    levels:
        trace: 0
        info: 1
        pass: 2
        fail: 3
    colors:
      trace: "white"
      info: "yellow"
      pass: "green"
      fail: "red"
    promise: ->
      Q {}
  init = (obj) =>
    {transports,levels,colors} = plugin
    runner.logger = logger = logger = new winston.Logger
      exitOnError: false
    for n, v of transports # unless plugin.disable[n]
      switch n
        when "file" then logger.add winston.transports.File, v
        when "console" then logger.add winston.transports.Console, v
        when "couchdb"
          logger.add require("winston-couchdb").Couchdb, v
        else continue      
    logger.setLevels levels
    winston.addColors colors
    obj.logger = logger
    extend obj
  #TODO: options are not inited here, do something better
  _.merge plugin, runner.opts.logger
  init runner, plugin.conf
  runner.forEachTest (descr) =>
    descr.logger = @logger
    extend descr
    basePromise = descr.promise
    if basePromise? and not descr.setup and not descr.silent
      descr.promise = ->
        @info "starting"
        basePromise.call(this).then(
          (t) =>
            @pass t
            t
          (f) =>
            @fail f
            throw f)
  @reg plugin
