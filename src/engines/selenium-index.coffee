log = console.log

UI_elements = require "./ui-element-defaults"
dnd_helper = require "./drag_and_drop_helper"


module.exports = ->
  {opts,fs,Q,path,_,EventEmitter,yp} = runner = @
  # TODO: Safari doesn't support typeing into content editable fields
  # http://code.google.com/p/selenium/issues/detail?id=5353
  # so we need to simulate it from within the page
  wd = @wd = require "wd"
  @chai = chai = require "chai"
  chaiAsPromised = require "chai-as-promised"
  spawn = require("child_process").spawn
  {exec} = require 'child_process'
  ex = require('child_process').exec;
  url = require "url"
  chaiAsPromised.transferPromiseness = wd.transferPromiseness
  chai.use chaiAsPromised
  chai.should()
  # taken from wd/promise-webdriver.js
  # if it is changed there it should be changed here
  filterPromisedMethods = (obj) ->
    _(obj).functions().filter((fname) ->
      not fname.match("^newElement$|^toJSON$|^toString$|^_") and
        not EventEmitter.prototype[fname]
      ).value()

  # transform input element to css selector for most methods
  getSelector = (el)->
    # exact selector was provided
    if el.selector? then return el.selector
    # string as id
    if _.isString(el)
      if el[0] is "."
        return el
      return ".qx-identifier-#{el.toLowerCase()}"
    # table row selector
    if el.table? and el.row?
      return ".qx-identifier-#{el.table} table.qx-tbody tr:nth-child(#{(el.row+1)})"

  @reg
    name: "wd"
    # CFGOPT: default wait timeout
    defaultWaitTimeout: runner.opts.common.timeouts.wait
    defaultIdleTimeout: runner.opts.common.timeouts.idle
    lyciaWebUrl : "http://"+runner.opts.appHost+":9090/LyciaWeb/"
    setup: (true)
    before: "globLoader"
    enable:
      browser: runner.opts.browserList
    links:
      chrome: "http://localhost:9515/"
      edge: "http://localhost:17556/"
      firefox: "http://localhost:4444/wd/hub/"
      ie: "http://localhost:5555/"
      safari: "http://localhost:4444/wd/hub/"
      opera: "http://localhost:9516/"
    browsers:
      chrome:
        browserName: "chrome"
      edge:
        browserName: "edge"
      firefox:
        browserName: "firefox"
      ie:
        browserName: "ie"
      safari:
        browserName: "safari"
      opera:
        browserName: "opera"
    hacks:
      justType:
        safari: (true)
        firefox: (true)
      resize:
        chrome: (false)
        safari: (true)
        firefox: (true)
        ie:(true)
        edge:(true)
      invoke:
        firefox: (false)

    promise: ->

      plugin = @

      wd.addPromiseMethod(
        "waitIdle",
        (timeout,idleTimeout) ->
          timeout ?= plugin.defaultWaitTimeout
          idleTimeout ?= plugin.defaultIdleTimeout
          @waitForElementByCssSelector('.qx-application[data-qx-state="idle"]', timeout).sleep(idleTimeout)
          )


      wd.addPromiseMethod(
        "runProgram"
        (prog) ->
          cmd = path.join(runner.environ.LYCIA_DIR,"client","LyciaDesktop.exe")
          wurl = opts.appHost.toString()+":9090"

          params = [
            " --remote-debugging-port=8888",
            "--server=#{wurl}",
            "--instance=#{opts.qatDefaultInstance}",
            "-c",
            "--command=\"#{prog}\" -d #{opts.common.options.databaseProfile}"]

          yp spawn(cmd,params)
          yp @sleep(6000)
          return yp @get("localhost:8888")
          )

      wd.addPromiseMethod(
        "startApplication"
        (command, params) ->
          try
            @executedPrograms?=[]
            @executedPrograms.push(command)
            params ?= {}
            params.wait ?= (true)
            params.instance ?= runner.opts.qatDefaultInstance
            command += ".exe" if process.platform[0] is "w"
            programUrl = plugin.lyciaWebUrl + "run/" + params.instance + "/" + command
            if params.args then programUrl+=params.args+"&cache=check&timeout=0&autotest" else programUrl+="?cache=check&timeout=0&autotest"
            if params.wait
              yp @get(programUrl).waitIdle().sleep(5000) if @qx$browserName == "safari"
              yp @get(programUrl).waitIdle().sleep(500)
            else
              yp @get(programUrl).sleep(1000)
          catch e
            throw "StartApplication <#{command}> failed. Error:"+e
          (true)
          )

      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          try
            timeout ?= 3000
            yp @waitForElementByCssSelector("#qx-application-restart",timeout)
          catch e
            throw "Exit application failed. Error: "+e
          (true)
          )

      wd.addPromiseMethod(
        "elementExists"
        (el) ->
          unless @qx$browserName == "ie"
            if yp(@execute("return $('#{getSelector(el)}').length")) > 0
              return (true)
            return (false)
          return (true)
          )

      wd.addPromiseMethod(
        "waitElement"
        (el,timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          for i in [1..10]
            if ((yp(@execute("return $('"+getSelector(el)+":visible').length")))<1)
              yp @sleep (timeout/10)
            else
              yp(@sleep (timeout)) if @qx$browserName == "firefox"
              return (true)
          return throw "Element #{el} not exists"
          )

      wd.addPromiseMethod(
        "waitMessageBox",
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector(
            ".qx-message-box"
            timeout)
          )

      wd.addPromiseMethod(
        "waitAppReady"
        () ->
          @get(plugin.lyciaWebUrl)
            .waitIdle()
          )

      wd.addPromiseMethod(
        "getElement"
        (el) -> @elementByCss "#{getSelector(el)}")

      wd.addPromiseMethod(
        "getElementInrernal"
        (el) ->
          if yp @elementExists(el)
            elenent = yp @execute("return $('#{yp(getSelector(el))}')")
            return elenent
          return null
          )
      wd.addPromiseMethod(
        "getContextMenu"
        (el) ->
          yp @execute("return $('#{getSelector(el)}').mousedown()").waitIdle(3000,3000)
          return yp @elementByCss("#{getSelector("contextmenu")}")
          )

      wd.addPromiseMethod(
        "getWindow"
        (wnd) ->
          yp @setDialogID(wnd,"win_qat")
          @elementByCss ".qx-identifier-win_qat"
          )

      wd.addPromiseMethod(
        "resizeWindow"
        (wnd,dx,dy,h) ->
          if plugin.hacks.resize[@qx$browserName]
            if @qx$browserName in ["ie"]
              throw "resizeWindow does not support on current version IE browser"
            yp @setDialogID(wnd,"win_qat")
            dlSize = yp @getRect("win_qat")
            wbSize = yp @getRect("win_qat .qx-window-border")
            if @qx$browserName in ["firefox"]
              dx1 = dlSize.width+dx
              dy1 = dlSize.height+dy
              obj = '"width":"'+dx1+'px","height":"'+dy1+'px"'
              str1 = '$(".qx-identifier-win_qat").css({'+obj+'})'
              dx2 = wbSize.width+dx
              dy2 = wbSize.height+dy
              obj = '"width":"'+dx2+'px","height":"'+dy2+'px"'
              str2 = '$(".qx-identifier-win_qat .qx-window-border").css({'+obj+'})'
              @execute(str1)
              @execute(str2)
              yp @waitIdle()
              return (true)
            if @qx$browserName in ["edge"]
              if dx>0 then dx=dx-9 else dx=dx-9
              #if dy>0 then dy=dy-9 else dx=dy+9
            yp @remoteCall("win_qat","css",{"width":"#{dlSize.width+dx}px";"height":"#{dlSize.height+dy}px";})
            yp @remoteCall("win_qat .qx-window-border","css",{"width":"#{wbSize.width+dx}px";"height":"#{wbSize.height+dy}px";})
            yp @waitIdle()
            return (true)
          h?="se"
          yp @setDialogID(wnd,"win_qat")
          r = yp @getRect(selector:".qx-identifier-win_qat > .ui-resizable-#{h}")
          x = Math.round(r.left + r.width / 2)-1
          y = Math.round(r.top + r.height / 2)-1
          yp @elementByCss(".qx-identifier-win_qat")
            .moveTo( x, y )
            .buttonDown(0)
            .moveTo( x + Math.floor(dx) , y + Math.floor(dy) )
            .buttonUp(0)
            .buttonUp(0)
            .waitIdle()
          return (true)
          if @qx$browserName in ["edge"]
            r = yp @getRect(selector:".qx-identifier-win_qat > .ui-resizable-nw")
            x = Math.round(r.left + r.width / 2)-1
            y = Math.round(r.top + r.height / 2)-1
            yp @elementByCss(".qx-identifier-win_qat")
              .moveTo( x, y )
              .buttonDown(0)
              .moveTo( x + Math.floor(5) , y + Math.floor(5) )
              .buttonUp(0)
              .waitIdle()
          return (true)
        )

      wd.addPromiseMethod(
        "moveWindow"
        (wnd,dx,dy) ->
          if plugin.hacks.resize[@qx$browserName] then return true
          yp @setDialogID(wnd,"win_qat")
          r = yp @execute "return $('.qx-identifier-win_qat > div.ui-dialog-titlebar')[0].getBoundingClientRect()"
          x = Math.round(r.left + r.width / 2)
          y = Math.round(r.top + r.height / 2)
          yp @elementByCss('#qx-home-form')
            .moveTo( x, y )
            .buttonDown(0)
            .moveTo( x + Math.floor(dx) , y + Math.floor(dy) )
            .buttonUp(0)
            .waitIdle()
          return (true)
        )

      wd.addPromiseMethod(
        "resizeElement"
        (el,dx,dy,h) ->
          if plugin.hacks.resize[@qx$browserName] then return true
          h?="e"
          r = yp @execute "return $('.qx-identifier-#{el.toLowerCase()} .ui-resizable-#{h}')[0].getBoundingClientRect()"
          x = Math.round(r.left + r.width / 2)
          y = Math.round(r.top + r.height / 2)

          yp @elementByCss('#qx-home-form')
            .moveTo( x, y )
            .buttonDown(0)
            .moveTo( x + Math.floor(dx) , y + Math.floor(dy) )
            .buttonUp(0)
        )

      wd.addPromiseMethod(
        "fglFocused",
        -> @elementByCss(".qx-focused"))
      wd.addPromiseMethod(
        "toTextEl",
        -> @then((e) -> e.elementByCss ".qx-text"))
      wd.addPromiseMethod(
        "justType",
        (val) ->
          if plugin.hacks.justType[@qx$browserName]
            el = yp  @elementByCss(".qx-focused .qx-text")
            @elementByCss(".qx-focused .qx-text").type(val)
          else
            @elementByCss(".qx-focused .qx-text").type(val))

      wd.addPromiseMethod(
        "invoke",
        (el) ->
          unless el.click?
            el = yp(@elementByCssSelectorIfExists(getSelector(el))) ? yp(@elementByCss(getSelector(el)))
          el.click()
          )

      wd.addPromiseMethod(
        "getClasses",
        (el) ->
          if yp(@elementExists(el))
            attr = yp(@remoteCall(getSelector(el),"attr","class"))
          if attr?
            return attr.split(" ")
          return []
      )

      wd.addPromiseMethod(
        "checkClasses",
        (el, params) ->
          classes = yp @getClasses el
          #console.log classes
          params.good?=params.required
          params.bad?=params.forbidden

          goodClasses = if _.isString(params.good) then params.good.split(' ') else params.good ? []
          badClasses = if _.isString(params.bad ) then params.bad.split(' ') else params.bad ? []

          mess=""
          for badClass in badClasses
            mess+="#{el} has class #{badClass}\n" if badClass in classes

          for goodClass in goodClasses
            mess+="#{el} does not have class #{goodClass}\n" unless goodClass in classes

          params.deferred?=@aggregateError

          return "" unless mess.length>0

          if params.mess?
            mess=params.mess+' '+mess

          throw mess unless params.deferred

          @errorMessage?=""
          @errorMessage+=mess
          return mess
      )

      wd.addPromiseMethod(
        "invokeElement",
        (el) ->
          unless el.click?
            el = yp(@elementByCssSelectorIfExists(getSelector(el))) ? yp(@elementByCss(getSelector(el)))
          el.click()
            .waitIdle()
          )

      wd.addPromiseMethod(
        "remoteCall"
        (el, nm, args...) ->
          if @qx$browserName == "firefox"
            if args.length > 0
              return yp @execute("return $('#{getSelector(el)}').#{nm}('#{args}')")
            if nm is "click"
              return yp @execute("$('#{getSelector(el)}').#{nm}()")
            return yp @execute("return $('#{getSelector(el)}').#{nm}()")
          if _.isString el
            yp @execute("return $().#{nm}.apply($('#{getSelector(el)}'),arguments)",args)
          else
            yp @execute("return $().#{nm}.apply($(arguments[0]),arguments[1])",[el,args])
            )

      wd.addPromiseMethod(
        "hasScroll"
        (el) ->
          @execute("""
                     el=$('#{getSelector(el)}');
                     if(el.css('overflow')=='hidden') {return false;}
                     if((el.prop('clientWidth' )!=el.prop('scrollWidth' )) ||
                        (el.prop('clientHeight')!=el.prop('scrollHeight'))) { return true;}
                     return false;
                   """)
      )

      wd.addPromiseMethod(
        "getRect"
        (el) ->
          if @qx$browserName == "ie"
            s = {}
            sel = getSelector(el)
            s.width = yp @execute "return $('#{sel}')[0].getBoundingClientRect().width"
            s.height = yp @execute "return $('#{sel}')[0].getBoundingClientRect().height"
            s.left = yp @execute "return $('#{sel}')[0].getBoundingClientRect().left"
            s.right = yp @execute "return $('#{sel}')[0].getBoundingClientRect().right"
            s.top = yp @execute "return $('#{sel}')[0].getBoundingClientRect().top"
            s.bottom = yp @execute "return $('#{sel}')[0].getBoundingClientRect().bottom"
          s ?= yp @execute "return $('#{getSelector(el)}')[0].getBoundingClientRect()"
          s.w = s.width = Math.round(s.width)
          s.h = s.height = Math.round(s.height)
          s.l = s.left = Math.round(s.left)
          s.r = s.right = Math.round(s.right)
          s.t = s.top = Math.round(s.top)
          s.b = s.bottom = Math.round(s.bottom)
          return s
      )

      wd.addPromiseMethod(
        "getFontSize"
        () ->
          s = {}
          s_leng = yp @execute "return $('.qx-font-test span:nth-child(4)').text().length"
          s.width = yp @execute "return $('.qx-font-test span:nth-child(4)')[0].getBoundingClientRect().width"
          s.height = yp @execute "return $('.qx-font-test span:nth-child(4)')[0].getBoundingClientRect().height"
          s.width = (s.width)/s_leng
          s.w = s.width
          s.h = s.height
          return s
      )

      wd.addPromiseMethod(
        "getCellSize"
        () ->
          s = {}
          s.width = yp @execute "return querix.rjqui.getCellWidth()"
          s.height = yp @execute "return querix.rjqui.getCellHeight()"
          s.w = s.width
          s.h = s.height
          return s
      )

      wd.addPromiseMethod(
        "getConsoleText"
        () ->
          return yp @execute "return $('.qx-text-console .ui-widget-content textarea').val()"
      )
      wd.addPromiseMethod(
        "check"
        (el, options) ->
          if _.isString el
            params = options
            el_type = yp @getType el
          else
            params = el
            el_type = params.type
            el_type?= "unknown"
          itemSelector = yp getSelector(el)

          params.mess?=""

          unless @qx$browserName in ["ie"]
            unless yp(@elementExists(el))? then throw "Item #{itemSelector} not found! "+params.mess

          res = {}
          if @qx$browserName in ["ie","edge"]
            res = yp @getRect(el)
          else
            res = yp @execute "return $('#{itemSelector}')[0].getBoundingClientRect()"

          res.width = Math.floor(res.width)
          res.height = Math.floor(res.height)
          res.left = Math.floor(res.left)
          res.top = Math.floor(res.top)
          res.type = el_type

          params.width = params.w if (params.w?)
          params.height = params.h if (params.h?)
          params.left = params.x if (params.x?)
          params.top = params.y if (params.y?)
          params.precision?=0
          precision = params.precision.toString()
          mess = [params.mess,el_type,itemSelector].join " "
          errmsg = ""
          for attr,expected of params
            continue if attr in ["mess","precision","selector","w","h","x","y","deferred"]

            if attr of UI_elements[el_type].get
              res[attr] = yp @execute UI_elements[el_type].get[attr](itemSelector)

            if expected is "default"
              expected = UI_elements[el_type].get.default(attr, @qx$browserName+"$"+process.platform[0])

            if attr in ["width","height","left","top"]
              if typeof(params.precision) is "string" and params.precision.toString().indexOf("%") != -1
                checkPrecision = parseFloat(params.precision.split("/[^0-9,.]/")[0])/100
                unless (res[attr]-res[attr]*checkPrecision <= expected <=res[attr]+res[attr]*checkPrecision)
                  errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>. "

              else
                unless (res[attr]-params.precision <= expected <=res[attr]+params.precision)
                  errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>. "

            else
              unless res[attr] is expected
                errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>. "


          if errmsg is "" then return ""

          mess+=" : #{errmsg}"

          if params.precision.toString() != "0" then mess +="\n Precision = <#{precision}>"

          params.deferred?=@aggregateError
          unless params.deferred
            throw mess
          @errorMessage?=""
          @errorMessage+=mess+"\n"
          return mess
      )

      # adding getSomething methods
      for method of UI_elements.unknown.get
        do =>
          name = "get"+method.charAt(0).toUpperCase() + method.slice(1);
          attr = method
          wd.addPromiseMethod(
            name
            (el,el_type) ->
              el_type ?= yp @getType(el)
              return yp @execute UI_elements[el_type].get[attr](getSelector(el),el)
          )

      wd.addPromiseMethod(
        "getType"
        (el) ->
          classList = yp @getClasses(el)
          for name of UI_elements
            if (classList.indexOf("qx-aum-#{name}") != -1)
              return name
          "unknown"
      )

      wd.addPromiseMethod(
        "setValue"
        (el, value) ->
          try
            yp UI_elements[ yp @getType(el) ].set.value.apply(@,[getSelector(el),value,el])
          catch e
            plugin.info "#{el} setValue failed"
            return (false)
          (true)
      )

      wd.addPromiseMethod(
        "setTabId"
        (el, v) ->
          v ?= "h_"+el.toLowerCase()
          return yp @execute "$('[aria-controls='+$('.qx-identifier-#{el}').prop('id') +']').addClass('qx-identifier-#{v}')"
      )
      wd.addPromiseMethod(
        "toolbutton"
        (title) ->
          @elementByCss(""".qx-aum-toolbar-button[title="#{title}"]"""))

      wd.addPromiseMethod(
        "statusBarText"
        (mType) ->
          mType ?= "message"
          yp (@execute("return $('div.qx-identifier-statusbar#{mType}:visible .qx-text').text()")) ? ""
      )

      wd.addPromiseMethod(
        "dndInit",
        (el,button=0)->
          @execute dnd_helper
      )

      wd.addPromiseMethod(
        "dragNDrop",
        (el,button=0)->
          @execute "$('#{getSelector(el)}').simulateDragDrop({ dropTarget: '.qx-identifier-table2'});"
      )

      wd.addPromiseMethod(
        "dropAt",
        (el)->
          return unless @draggable.button?
          selector = getSelector(el)
          @elementByCss("#{selector}").moveTo().buttonUp(@draggable.button)
          @draggable={}
      )

      wd.addPromiseMethod(
        "messageBox"
        (action,params) ->
          switch action
            when "getText" then yp(@execute("return $('.qx-message-box:visible pre').text()"))
            when "getValue" then yp(@execute("return $('.qx-message-box:visible input').val()"))
            when "wait" then yp(@waitMessageBox().sleep(300))
            when "click" then yp(@execute ("$('.qx-button-#{params}').click()"))
            else
              throw "Isn't implemented for this messageBox element yet"
      )

      wd.addPromiseMethod(
        "setDialogID", (el,id)->
          if _.isString(el) then id?="d_"+el
          if el.selector? then id?="d_"+el.id
          return yp @execute("$('#{getSelector(el)}').closest('.ui-dialog').addClass('qx-identifier-#{id.toLowerCase()}')")
      )

      wd.addPromiseMethod(
        "getSelector", (el)->
          if el.selector? then return el.selector

          if _.isString(el) then return ".qx-identifier-#{el.toLowerCase()}"
          if el.table? and el.row?
            return ".qx-identifier-#{el.table} table.qx-tbody tr:nth-child(#{(el.row+1)})"
      )
      # Adding properties for wd test' this
      synproto =
        SPECIAL_KEYS:wd.SPECIAL_KEYS

      wrap = (m,n) ->
        (args...) ->
          yp @browser[n].apply @browser, args
      for m in filterPromisedMethods wd.PromiseWebdriver.prototype
        synproto[m] = wrap wd.PromiseWebdriver.prototype[m], m
      runner.synWd = (t,act) ->
        yp.frun ->
          _.assign t, synproto
          act.call t

      runner.regWD = (info) ->
        info.timeout ?= @opts.common.timeouts.wd
        d = info.data ?= {}
        #_.merge d, kind: "wd"
        info.enable = _.merge {}, plugin.enable, info.enable
        b = {}
        for i,v of plugin.browsers when info.enable.browser[i]
          b.first?=i
          do (i,v,b) =>
            binfo = _.clone info
            binfo.duration ?= {}
            binfo.data = _.clone info.data
            binfo.data.kind ?= "wd"
            binfo.data.kind +="-#{i}"
            promise = binfo.promise
            unless promise?
              if binfo.syn?
                binfo.name = "#{info.name}/#{i}"
                if binfo.name.substring(0,7) is "atomic/"
                  if binfo.data.kind is "wd-"+b.first
                    binfo.name = binfo.name.split("/")[0]+"/"+ binfo.name.split("/")[1]
                  else
                    return (true)
                unless binfo.data.kind is "wd-"+b.first
                  if binfo.after.indexOf(_.tempName)==-1 then binfo.after = [ _.tempName ]
                _.tempName = binfo.name

                promise = (browser) ->
                  yp.frun( ->
                    testContext = _.create binfo,_.assign {browser:browser}, synproto, {errorMessage:""}
                    testContext.browser.errorMessage=""
                    testContext.aggregateError=(true)
                    try
                      binfo.duration.startTime = new Date()
                      binfo.syn.call testContext
                      binfo.duration.finishTime = new Date()
                    catch e
                      #TODO : kill qrun here
                      for cmd in testContext.browser.executedPrograms
                        if process.platform[0] is "w"
                          runner.trace "taskkill /F /T /IM #{cmd}.exe"
                          exec "taskkill /F /T /IM #{cmd}.exe"

                      if ((_.deepGet(e,'cause.value.message')) ? "").split("\n")[0] is "unexpected alert open"
                        alertText = yp(testContext.browser.alertText())
                        testContext.errorMessage+=alertText+" alert caught! "+e.message
                      else
                        throw e
                    testContext.errorMessage+=testContext.browser.errorMessage
                    if testContext.errorMessage.length>0
                      throw testContext.errorMessage
                    ).timeout(info.timeout)
              else
                promise = ->

            binfo.promise = ->
              if plugin.links[i]?
                browser = wd.promiseChainRemote plugin.links[i]
              else
                browser = wd.promiseChainRemote()
              if plugin.wdTrace
                browser.on("status", (info) -> plugin.trace info.cyan)
                browser.on("command", (meth, path, data) -> plugin.trace "> #{meth.yellow}", path.grey, data || '')
              if v.browserName in ["chrome","opera"]
                r = browser.init(v).maximize().then(=> promise.call @, browser)
              else
                r = browser.init(v).then(=> promise.call @, browser)
              browser.qx$browserName = i
              unless binfo.closeBrowser is false or plugin.closeBrowser is (false)
                r = r.finally =>
                  if process.platform[0] is "w"
                    browser.quit() unless v.browserName in ["firefox"]
                    if v.browserName in ["firefox"]
                      exec("taskkill /F /T /IM firefox.exe")
                  else
                    browser.quit() unless v.browserName in ["firefox"]
                    if v.browserName in ["firefox"]
                      exec("killall -s KILL firefox")
              return r.then(-> "Pass")
            @reg binfo
            binfo.data.browser = i
      Q({})
