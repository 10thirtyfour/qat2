module.exports = ()->
  return if process.platform[0] isnt "w"

  { opts, _, path, Q } = runner = @

  runner.robot = require('robotjs')
  edge = require('edge')
  url = require "url"
  platform = if process.env.hasOwnProperty('ProgramFiles(x86)') then "win_x64" else "win_ia32"
  spawn = require("child_process").spawn
  exec = require("child_process").exec

  opts.assemblyPath?=opts.defaultAssemblyPath[platform]
  refs = [
      "UIAutomationClient.dll",
      "UIAutomationTypes.dll",
      "WindowsBase.dll"].map( (dll)->
        opts.assemblyPath + dll
      )
  throwWithoutResult = (message)->
    (res)->
      throw new error(message) unless res
      return res

  edgeToPromise = (fun)->
    (obj)->
      def = Q.defer()
      fun( obj, (er,res)->
        if (er) then def.reject(er)
        if (obj.required and !res) then def.reject(obj.requiredMessage)
        def.resolve(res)
      )
      return def.promise


  class UIauto
    constructor: ( params={} )->
      @timeout=params.timeout ? 30000
      @promise = Q( {} )
      @progs = []
      @progNames = []
      @addEdge()
      @

    promisify : (fun, key="")->
      return (obj)->
        t = @timeout
        @promise = Q( @promise ).then( (p)->
          fun( Object.assign( {
            params   : p,
            required : key.startsWith("wait"),
            requiredMessage : "#{key} didn't return a value!",
            timeout  : t
          }, obj) )
        )
        @

    addEdge : ->
      for key,val of require("./ui_automation-functions")
        prom = edgeToPromise( edge.func( source: val, references: refs ))
        @[key] = @promisify(prom, key)


    then : (arg)->
      @promise = Q(@promise).then(arg)
      @

    done : (res)->
      @promise=Q(@promise)
        .timeout(@timeout)
        .finally( ( ->
          for prog in @progs
            if typeof prog.kill is "function" then prog.kill('SIGKILL')
          for name in @progNames
            console.log "taskkill /F /T /IM #{name}"
            exec "taskkill /F /T /IM #{name}"
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
        wurl = url.parse(opts.lyciaWebUrl).host
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
