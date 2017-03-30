"use strict"

# robot js syntax
# https://github.com/octalmage/robotjs/wiki/Syntax

module.exports = ()->
  return if process.platform[0] isnt "w"

  DesktopDefaults =
    topMenuHeight : 19
    menuHeight : 22

  { yp, opts, _, path, Q } = runner = @

  url = require "url"
  edge = require('edge')
  runner.robot = require('robotjs')

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
    #console.log prog
    if typeof prog.child.kill is "function" then prog.child.kill('SIGKILL')
    n = path.basename(prog.name,",exe")+".exe"
    runner.trace "taskkill /F /T /IM #{n}"
    exec "taskkill /F /T /IM #{n}"
    runner.trace "taskkill /F /T /IM qrun.exe"
    exec "taskkill /F /T /IM qrun.exe"

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

  menuBarToObject = (menuBarArray)->
    return null if menuBarArray is null
    obj = {}
    if menuBarArray and menuBarArray.length
      menuBarArray.forEach (el)->
        obj[el.name]=el
    obj


  class DesktopWindow
    constructor: ( params )->
      @set(params)

    set : (params)->
      unless params then return null
      @name = params.name
      @automationId = params.automationId
      @processId = params.processId
      @isModal=params.isModal
      @visualState=params.visualState
      @menuBar = menuBarToObject(params.menuBar)
      @window =if params.window  then _.assign({},params.window ) else null
      @browser=if params.browser then _.assign({},params.browser) else null
      @


    getMenu : (group="")->
      menuBarToObject yp EdgeCall({
        method:"getMenu"
        name  : @name
        group : group
      })

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

    close : ( obj )->
      yp EdgeCall( _.assign({
        method:"closeWindow"
        names : [@name]
      },obj))

    moveMouse : (x,y)->
      runner.robot.moveMouse(@browser.left+x, @browser.top+y)
      @


    moveMouseSmooth : (x,y)->
      runner.robot.moveMouseSmooth(@browser.left+x, @browser.top+y)
      @

    mouseClick : (button="left", double=false)->
      runner.robot.mouseClick(button, double)
      @

    click : (dx,dy)->
      runner.robot.moveMouse(@browser.left+dx, @browser.top+dy)
      runner.robot.mouseClick("left",false)
      @

    mouseToggle : (down="down", button="left")->
      runner.robot.mouseToggle(down, button)
      @

    getPixel : (dx,dy)->
      @getPixelColor(dx,dy)

    getPixelColor : (dx,dy)->
      runner.robot.getPixelColor(@broser.left + dx, @browser.top + dy)
  # ==========================
  runner.robot.moveTo = (rect)->
    r = if rect.hasOwnProperty("rect") then rect.rect else rect
    tx=r.left + r.width/2
    ty=r.top + r.height/2
    runner.robot.moveMouse( tx, ty )

  DesktopFunctions =
    waitWindow : (obj)->
      params =
        method:"waitWindow"
        required : true
        requiredMessage : "waitWindow failed"
        timeout : opts.common.timeouts.run
      if typeof obj is "string"
        params.name=obj
      else
        _.assign( params, obj)
      new DesktopWindow yp EdgeCall( params )


    getWindows : (obj)->
      (yp EdgeCall(_.assign({
        method:"getWindows"
        all:false
      },obj))
        .map((w)-> new DesktopWindow(w)))

    closeWindow : (obj)->
      yp EdgeCall(_.assign({
        method:"closeWindow"
        names : getWindowList( obj )
      },obj))


    delay : (ms)->
      #fool proof delay
      yp Q(true).delay(Math.min(ms,@timeout))

    runProgram : (name)->
      @progs?=[]
      name?=@testName

      LDcmd = path.join(runner.environ.LYCIA_DIR,"client","LyciaDesktop.exe")
      lyciaWebUrl = "http://"+opts.appHost+":9090/LyciaWeb/"
      webUrl = url.parse(lyciaWebUrl).host
      params = [
        "--server=#{webUrl}",
        "--instance=#{opts.qatDefaultInstance}",
        "-c",
        "--command=\"#{name}\" -d #{opts.common.options.databaseProfile}"]
      child = spawn(LDcmd,params)

      @progs.push( name : name, child : child )

    waitConsole : (timeout)->
      timeout?= 5000
      @waitWindow( name:"LyciaConsole", timeout:timeout, requiredMessage:"Console not found!" )

    # close all LD windows and console
    cleanUp : ()->
      yp EdgeCall(method:"cleanUp")

    robot : runner.robot

    assert : runner.assert

    assertEqual : (actual,expected,message="")->
      if actual isnt expected
        if message.length then message+=" "
        message+="Expected : #{expected}, Actual : #{actual}"
        if @aggregateError
          @errorMessage+=message
        else
          throw new Error(message)
      true

    assertNotEqual : (actual,expected,message="")->
      if actual is expected
        if message.length then message+=" "
        message+="Expected notEqual to: #{expected}, Actual : #{actual}"
        if @aggregateError
          @errorMessage+=message
        else
          throw new Error(message)
      true


    mustHave : (actual, expected, msg="", path="")->
      for prop,val of expected
        unless actual.hasOwnProperty(prop)
          msg+="#{prop} property is missing in actual result.\n"
        else
          if typeof val is "object" and val isnt null
            msg+=@mustHave(actual[prop],val,"",path+prop+".")
          else
            if actual[prop] isnt val
              msg+="#{path}#{prop} mismatch. Expected #{val}. Actual #{actual[prop]}.\n"
      msg
    DesktopDefaults : DesktopDefaults


  @reg
    name : "ld"
    setup : true
    before : "globLoader"
    enable : true
    promise : ->
      plugin = @
      runner.regLD = (info)->
        binfo = _.clone info
        binfo.data = _.assign({ kind : "win.desktop", source : info.source }, info.data )
        testContext = _.assign({
          timeout : opts.common.timeouts.run
          errorMessage : ""
          testName : info.name
          }, binfo.data , DesktopFunctions )
        binfo.promise = ->
          (yp.frun ->
            res = info.syn.call testContext
            if testContext.errorMessage and testContext.errorMessage.length
              throw new Error(testContext.errorMessage)
            if typeof res is "undefined" then res = "ok"
            res)
          .timeout( testContext.timeout )
          .finally( ->
            testContext.progs.forEach( killProg )
            EdgeCall(method:"cleanUp")
          )
        @reg binfo
      true
