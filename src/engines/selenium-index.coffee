log = console.log

UI_elements = require "./ui-element-defaults"
dnd_helper = require "./drag_and_drop_helper"


module.exports = ->
  {fs,Q,_,EventEmitter,yp} = runner = @
  # TODO: Safari doesn't support typeing into content editable fields
  # http://code.google.com/p/selenium/issues/detail?id=5353
  # so we need to simulate it from within the page
  wd = @wd = require "wd"
  @chai = chai = require "chai"
  chaiAsPromised = require "chai-as-promised"
  {exec} = require 'child_process'
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
    if _.isString(el) then return ".qx-identifier-#{el.toLowerCase()}"
    # table row selector
    if el.table? and el.row?
      return ".qx-identifier-#{el.table} table.qx-tbody tr:nth-child(#{(el.row+1)})"

  @reg
    name: "wd"
    # CFGOPT: default wait timeout
    defaultWaitTimeout: 10000
    setup: (true)
    before: "globLoader"
    enable:
      browser: runner.opts.browserList
    links:
      chrome: "http://localhost:9515/"
      ie: "http://localhost:5555/"
      edge: "http://localhost:17556/"
      firefox: "http://localhost:4444/wd/hub/"
    browsers:
      chrome:
        browserName: "chrome"
      firefox:
        browserName: "firefox"
      ie:
        browserName: "ie"
      edge:
        browserName: "edge"
      safari:
        browserName: "safari"
      opera:
        browserName: "opera"
    hacks:
      justType:
        safari: (true)
      invoke:
        firefox: (false)
    promise: ->

      plugin = @

      wd.addPromiseMethod(
        "waitIdle",
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector('.body:not(.qx-app-busy)', timeout).sleep(300)
          )

      wd.addPromiseMethod(
        "startApplication"
        (command, params) ->
          @executedPrograms?=[]
          @executedPrograms.push(command)

          params ?= {}
          params.wait ?= (true)
          params.instance ?= runner.opts.qatDefaultInstance

          command += ".exe" if process.platform[0] is "w"
          programUrl = runner.opts.lyciaWebUrl + "run/" + params.instance + "/" + command

          if params.args then programUrl+=params.args+"&cache=check&timeout=0&skipunload" else programUrl+="?cache=check&timeout=0&skipunload"

          if params.wait
            return @get(programUrl).waitIdle(30000).sleep(500)
          else
            return @get(programUrl).sleep(500)
          )

      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          timeout ?= 3000
          if @qx$browserName != "edge"
            @waitForElementByCssSelector("#qx-application-restart",timeout))


      wd.addPromiseMethod(
        "elementExists"
        (el) ->
          if @qx$browserName == "edge"
            if yp(@execute "return $('#{getSelector(el)}').length") > 0 then return (true) else return (false)
          else
            yp(@elementByCssSelectorIfExists(getSelector(el)))?
          )

      wd.addPromiseMethod(
        "waitMessageBox",
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector(
            ".qx-message-box"
            timeout))

      wd.addPromiseMethod(
        "waitAppReady"
        () ->
          @get(runner.lyciaWebUrl)
            .waitIdle())

      wd.addPromiseMethod(
        "getElement"
        (el) -> @elementByCss "#{getSelector(el)}")

      wd.addPromiseMethod(
        "getWindow"
        (wnd) ->
          yp @setDialogID(wnd,"win_qat")
          @elementByCss ".qx-identifier-win_qat")

      wd.addPromiseMethod(
        "resizeWindow"
        (wnd,dx,dy,h) ->
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
            .waitIdle()
        )

      wd.addPromiseMethod(
        "moveWindow"
        (wnd,dx,dy) ->
          yp @setDialogID(wnd,"win_qat")
          r = yp @execute "return $('.qx-identifier-win_qat > div.ui-dialog-titlebar')[0].getBoundingClientRect()"
          x = Math.round(r.left + r.width / 2)
          y = Math.round(r.top + r.height / 2)
          yp @elementByCss('#qx-home-form')
            .moveTo( x, y )
            .buttonDown(0)
            .moveTo( x + Math.floor(dx) , y + Math.floor(dy) )
            .buttonUp(0)
        )

      wd.addPromiseMethod(
        "resizeElement"
        (el,dx,dy,h) ->
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
        (val) -> @elementByCss(".qx-focused .qx-text").type(val))
      wd.addPromiseMethod(
        "invoke",
        (el) ->
          unless el.click?
            el = yp(@elementByCssSelectorIfExists(getSelector(el))) ? yp(@elementByCss("#{el.toLowerCase()}"))
          if plugin.hacks.invoke[@qx$browserName]
            @remoteCall el, "click"
          else
            el.click())

      wd.addPromiseMethod(
        "getClasses",
        (el) ->
          element = yp(@elementByCssSelectorIfExists(".qx-identifier-#{el.toLowerCase()}")) ? yp(@elementByCssIfExists("#{el.toLowerCase()}")) ? (null)
          if element is (null)
            return ""
          yp(element.getAttribute("class")).split(" ")
      )

      wd.addPromiseMethod(
        "checkClasses",
        (el, params) ->
          classes = yp @getClasses el
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
          unless el.click? then el = @elementByCss ".qx-identifier-#{el.toLowerCase()}"
          if plugin.hacks.invoke[@qx$browserName]
            @remoteCall(el, "click")
              .waitIdle()
          else
            el
              .click()
              .waitIdle())

      wd.addPromiseMethod(
        "remoteCall"
        (el, nm, args...) ->
          if _.isString el
            @execute(
              "return $().#{nm}.apply($('.qx-identifier-#{el.toLowerCase()}'),arguments)"
              args)
          else
            @execute(
              "return $().#{nm}.apply($(arguments[0]),arguments[1])"
              [el,args])
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
            sel = @getSelector(el)
            s.width = yp @execute "return $('#{sel}')[0].getBoundingClientRect().width"
            s.height = yp @execute "return $('#{sel}')[0].getBoundingClientRect().height"
            s.left = yp @execute "return $('#{sel}')[0].getBoundingClientRect().left"
            s.right = yp @execute "return $('#{sel}')[0].getBoundingClientRect().right"
            s.top = yp @execute "return $('#{sel}')[0].getBoundingClientRect().top"
            s.bottom = yp @execute "return $('#{sel}')[0].getBoundingClientRect().bottom"
            s.width = Math.round(s.width)
            s.height = Math.round(s.height)
            s.left = Math.round(s.left)
            s.top = Math.round(s.top)
            return s
          return yp @execute "return $('#{getSelector(el)}')[0].getBoundingClientRect()"
      )

      wd.addPromiseMethod(
        "check"
        (el, options) ->
          if _.isString el
            params = options
            el_type = yp @getType el
            itemSelector = ".qx-identifier-#{el}"
          else
            params = el
            el_type = params.type
            el_type?= "unknown"
            itemSelector = params.selector

          params.mess?=""

          throw "Item #{itemSelector} not found! "+params.mess unless yp(@elementByCssSelectorIfExists(".qx-identifier-#{el}"))?

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
              res[attr] = yp @execute UI_elements[el_type].get[attr](el)

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
              return yp @execute UI_elements[el_type].get[attr](el)
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
            yp UI_elements[ yp @getType(el) ].set.value.apply(@,[el,value])
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
          @execute "$('#{@getSelector(el)}').simulateDragDrop({ dropTarget: '.qx-identifier-table2'});"
      )

      #wd.addPromiseMethod(
      #  "startDrag",
      #  (el,button=0)->
      #    b=el.button ? button
      #    r = yp @getRect el
      #    x = Math.round(r.left + r.width / 2)
      #    y = Math.round(r.top + r.height / 2)
      #    console.log x,y
      #    e = yp @elementByCss('#qx-home-form')
      #      #.moveTo( x, y )
      #      #.dragNDrop(b)
      #      #.moveTo( x + 30 , y + 30 )
      #      #.buttonDown(b)
      #      #.moveTo( x + 60 , y + 60 )
      #      #.buttonUp(b)
      #      #.buttonDown(b)
      #      #.moveTo( x + 10 , y + 3 )
      #      #.moveTo( x + 20 , y + 23 )
      #      #.buttonUp(b)
      #
      #    @draggable = { button : b }
      #)

      wd.addPromiseMethod(
        "dropAt",
        (el)->
          return unless @draggable.button?
          selector = @getSelector(el)
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
          return yp @execute("$('#{@getSelector(el)}').closest('.ui-dialog').addClass('qx-identifier-#{id.toLowerCase()}')")
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
        wdTimeout = @opts.common.timeouts.wd
        d = info.data ?= {}
        #_.merge d, kind: "wd"
        info.enable = _.merge {}, plugin.enable, info.enable
        for i,v of plugin.browsers when info.enable.browser[i]
          #wdTimeout = @opts.common.timeouts.wd[i]
          do (i,v) =>
            binfo = _.clone info
            binfo.duration ?= {}
            binfo.data = _.clone info.data
            binfo.data.kind ?= "wd"
            binfo.data.kind +="-#{i}"
            promise = binfo.promise
            unless promise?
              if binfo.syn?
                binfo.name = "#{info.name}/#{i}"
                if binfo.data.kind is "wd-chrome"
                  if binfo.name.substring(0,7) is "atomic/"
                    binfo.name = binfo.name.split("/")[0]+"/"+ binfo.name.split("/")[1]
                  _.tempName = binfo.name
                else
                  unless binfo.after.indexOf(_.tempName)!=-1 then binfo.after = _.tempName
                promise = (browser) ->
                  yp.frun( ->
                    testContext = _.create binfo,_.assign {browser:browser}, synproto, {errorMessage:""}
                    testContext.browser.errorMessage=""
                    testContext.aggregateError=(false)
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
                          #else
                          #exec("pkill -9 #{cmd}")
                      if ((_.deepGet(e,'cause.value.message')) ? "").split("\n")[0] is "unexpected alert open"
                        alertText = yp(testContext.browser.alertText())
                        testContext.errorMessage+=alertText+" alert caught! "+e.message
                      else
                        throw e
                    testContext.errorMessage+=testContext.browser.errorMessage
                    if testContext.errorMessage.length>0
                      throw testContext.errorMessage
                    ).timeout(wdTimeout)
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
              r = browser.init(v).then(=> promise.call @, browser)
              browser.qx$browserName = i
              unless binfo.closeBrowser is false or plugin.closeBrowser is (false)
                r = r.finally =>
                  browser.quit()
              return r.then(-> "Pass")
            @reg binfo
            binfo.data.browser = i
      Q({})
