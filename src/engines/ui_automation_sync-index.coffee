module.exports = ()->
  return if process.platform[0] isnt "w"

  { yp, opts, _, path, Q } = runner = @

  url = require "url"

  edge = require('edge')

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

  killProg = (prog)->
    if typeof prog.child.kill is "function" then prog.child.kill('SIGKILL')
    n = path.basename(prog.name,",exe")+".exe"
    exec "taskkill /F /T /IM #{n}"
    exec "taskkill /F /T /IM qrun.exe"

    #exec "taskkill /F /T /IM #{name}.exe"

    #console.log n
    #exec "C:\\Windows\\System32\\wbem\\WMIC.exe PROCESS WHERE NAME=\"#{n}\" DELETE"

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

  class DesktopWindow
    constructor: ( params )->
      @set(params)

    set : (params)->
      unless params then return null
      @name = params.name
      @automationId = params.automationId
      @processId = params.processId
      @window =if params.window  then Object.assign({},params.window ) else null
      @browser=if params.browser then Object.assign({},params.browser) else null
      @

    move : (x,y)->
      @set yp EdgeCall({
        method:"transformWindow"
        processId:@processId
        name:@name
        move:[x,y]
      })

    resize : (w,h)->
      @set yp EdgeCall({
        method:"transformWindow"
        processId:@processId
        name:@name
        resize: if typeof w is "string" then w else [w,h]
      })

    close : ()->
      yp EdgeCall({
        method:"closeWindow"
        names : [@name]
      })


  DesktopFunctions =
    waitWindow : (obj)->
      new DesktopWindow yp EdgeCall( Object.assign({
        method:"waitWindow"
        required : true
        requiredMessage : "wainWindow failed"
        timeout : opts.common.timeouts.run
      }, obj))


    getWindows : (obj)->
      (yp EdgeCall(Object.assign({
        method:"getWindows"
        all:false
      },obj))
        .map((w)-> new DesktopWindow(w)))

    closeWindow : (obj)->
      yp EdgeCall(Object.assign({
        method:"closeWindow"
        names : getWindowList( obj )
      },obj))


    delay : (ms)->
      yp Q(true).delay(ms)

    runProgram : (name)->
      @progs?=[]
      LDcmd = path.join(runner.environ.LYCIA_DIR,"client","LyciaDesktop.exe")
      webUrl = url.parse(opts.lyciaWebUrl).host
      params = [
        "--server=#{webUrl}",
        "--instance=#{opts.qatDefaultInstance}",
        "-c",
        "--command=\"#{name}\" -d #{opts.common.options.databaseProfile}"]
      @progs.push( name : name, child : spawn(LDcmd,params))

    getConsoleText : ()->
      yp EdgeCall(method:"getConsoleText")
    robot : require('robotjs')

  @reg
    name : "ld"
    setup : true
    before : "globLoader"
    enable : true
    promise : ->
      plugin = @
      runner.regLD = (info)->
        d = Object.assign( { kind : "win.desktop" }, info.data )
        @reg
          name : info.name
          data : d
          promise : ->
            testContext = Object.assign({ errorMessage:""},DesktopFunctions )
            (yp.frun ->
              res = info.syn.call testContext
              if testContext.errorMessage and testContext.errorMessage.length
                throw new Error(testContext.errorMessage)
              res)
            .timeout( opts.common.timeouts.run )
            .finally( -> testContext.progs.forEach( killProg ) )

      true
