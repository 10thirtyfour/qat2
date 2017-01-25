"use strict"

module.exports = ()->
  return true
allBelowIsDisabled = ()->
  return if process.platform[0] isnt "w"

  { opts, _, path, Q } = runner = @

  runner.robot = require('robotjs')
  edge = require('edge')
  url = require "url"
  if process.env.hasOwnProperty('ProgramFiles(x86)')
    platform = "win_x64"
  else
    platform =  "win_ia32"
  spawn = require("child_process").spawn
  exec = require("child_process").exec


  opts.assemblyPath?=opts.defaultAssemblyPath[platform]
  refs = [
      "UIAutomationClient.dll",
      "UIAutomationTypes.dll",
      "WindowsBase.dll"].map( (dll)->
        opts.assemblyPath + dll
      )

  getWindowList = (obj)->
    addToCloseList = (w)->
      isUnique = (s)->(typeof s is "string" and !~list.indexOf(s))
      list.push(w) if isUnique(w)
      list.push(w.name) if isUnique(w.name)

    list = []
    if typeof obj is "object" and obj.length>0
      obj.forEach(addToCloseList)
    else
      addToCloseList(obj)
    list


  edgeToPromise = (fun)->
    (obj)->
      def = Q.defer()
      fun( obj, (er,res)->
        if (er) then def.reject(er)
        if (obj.required and !res) then def.reject(obj.requiredMessage)
        def.resolve(res)
      )
      return def.promise

  EdgeCall = edgeToPromise( edge.func(
    source: require("./ui_automation-functions-single").AllInOne,
    references: refs))

  class UIauto
    constructor: ( params={} )->
      @timeout=params.timeout ? 30000
      @promise = Q( {} )
      @progs = []
      @progNames = []
      @


    closeWindow : (obj)->
      @then (p={})->
        param = Object.assign({
          method : "closeWindow"
          names : getWindowList( obj ? p )
        })
        EdgeCall(param)

    transformWindow : (obj)->
      @then (p={})->
        param = Object.assign({
          method: "transformWindow",
          name : p.name ? p[0].name
          },obj )
        EdgeCall( param )

    #getConsoleText : (obj)->
    #  @then (p={})->
    #    param = Object.assign({
    #      method : "getConsoleText"
    #    })
    #    EdgeCall( param)

    getWindows : (obj)->
      @then (p={})->
        param = Object.assign({
          method : "getWindows",
          all : false
        }, obj)
        EdgeCall( param )

    waitWindow : (obj)->
      t = @timeout
      @then (p={})->
        param = Object.assign({
          method   : "waitWindow",
          name     : p.name
          required : true
          requiredMessage : "waitWindow failed"
          timeout  : t
        },obj )
        EdgeCall( param )
        .then( (res)->
          if res is null and param.required
            throw new Error(param.requiredMessage)
          res)

    then : (arg)->
      @promise = Q(@promise).then(arg)
      @

    log : (arg)->
      @then (p)->
        console.log p
        p


    done : (res)->
      @promise=Q(@promise)
        .timeout(@timeout)
        .finally( ( ->
          for prog in @progs
            if typeof prog.kill is "function" then prog.kill('SIGKILL')
          for name in @progNames
            runner.trace "taskkill /F /T /IM #{name}"
            exec "taskkill /F /T /IM #{name}"
            runner.trace "taskkill /F /T /IM #{name}.exe"
            exec "taskkill /F /T /IM #{name}.exe"

          res
        ).bind(@)
      )
      return @promise

    delay : (t)->
      @promise = Q(@promise).delay(t)
      @

    runProgram : (prog)->
      @progNames.push(prog)
      @promise = Q( @promise ).then( (->
        cmd = path.join(runner.environ.LYCIA_DIR,"client","LyciaDesktop.exe")
        lyciaWebUrl = "http://"+opts.appHost+":9090/LyciaWeb/"
        wurl = url.parse(lyciaWebUrl).host
        params = [
          "--server=#{wurl}",
          "--instance=#{opts.qatDefaultInstance}",
          "-c",
          "--command=\"#{prog}\" -d #{opts.common.options.databaseProfile}"]
        @progs.push spawn(cmd,params)
        ).bind(@))
      return @

  runner.uia = ( opts={} )->
    new UIauto( opts )
