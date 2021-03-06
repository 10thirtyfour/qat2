"use strict"

module.exports = ->
  {Q,_,winston} = runner = @
  {exec, spawn} = require 'child_process'
  # killSeleniumProcess = require './utils/killSeleniumProcess';
  ex = require('child_process').exec;
  extend = (obj) ->
    _.assign(obj,
      logPrefix: -> @name.cyan + ":"
      logMeta: ->
        _.assign {name: @name}, @data
      trace: (args...) -> @logger.trace @logPrefix(), args...
      info: (args...) -> @logger.info @logPrefix(), args...
      pass: (args...) -> @logger.pass args..., @logMeta()
      fail: (args...) -> @logger.fail args..., @logMeta())
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
    for n, v of transports when not plugin.disable[n]
      switch n
        when "file" then logger.add winston.transports.File, v
        when "console" then logger.add winston.transports.Console, v
        when "couchdb" then logger.add require("winston-couchdb").Couchdb, v
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
      {failOnly} = descr
      descr.promise = ->
        @data.timeid = runner.sysinfo.starttimeid
        @info "starting"
        @started=(new Date()).getTime()
        context = this

        Q.fcall( ()-> basePromise.call(context) )
        .finally( -> context.data.duration=(new Date()).getTime() - context.started)
        .then(
          (t) =>
            if failOnly
              @info t
            else
              @pass t
            t
          (f) =>
            f1 = f.toString()
            if f1.indexOf("ECONNREFUSED")==-1 and
               f1.indexOf("browserName")==-1 and
               f1.indexOf("maximize")==-1 and
               f1.indexOf("WARNING")==-1 and
               f1.indexOf("Failed to connect to")==-1 and
               f1.indexOf("No such driver")==-1 and
               !(f1.indexOf("StartApplication")!=-1 and runner.opts.browserList.safari) and
               !(f1.indexOf("Not JSON response")!=-1 and runner.opts.browserList.ie) and
               !(f1.indexOf("getBoundingClientRect")!=-1 and !(runner.tests.async.disabled))
              @fail f
            else
              @info '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>', f1 @info '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>', f1
              # TODO Firefox requires to close current selenium runner
              # log '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>', f1
              # if f1.indexOf("firefox") != -1 then killSeleniumProcess()
              if f1.indexOf("firefox") != -1 then exec("start /MIN c:/qat/firefox.bat")
              if f1.indexOf("edge") !=-1 then exec("start /MIN c:/qat/MicrosoftWebDriver.exe")
              if f1.indexOf("browserName=ie") !=-1  then exec("start /MIN c:/qat/IEDriverServer.exe")
              if f1.indexOf("chrome") !=-1  then exec("start /MIN c:/qat/chromedriver.exe")
              if f1.indexOf("opera") !=-1  then exec("start /MIN c:/qat/operadriver.exe")
            throw f)
  @reg plugin
