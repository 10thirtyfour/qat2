log = console.log
exec = require('child_process').exec

module.exports = ->
  {Q,_,EventEmitter,yp} = runner = @
  # TODO: Safari doesn't support typeing into content editable fields
  # http://code.google.com/p/selenium/issues/detail?id=5353
  # so we need to simulate it from within the page
  wd = @wd = require "wd"
  @chai = chai = require "chai"
  chaiAsPromised = require "chai-as-promised"
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
  @reg
    name: "wd"
    # CFGOPT: default wait timeout
    defaultWaitTimeout: 30000
    setup: true
    before: "globLoader"
    enable:
      browser:
        chrome: true
    links:
      chrome: "http://localhost:9515/"
      ie: "http://localhost:5555/"
    browsers:
      chrome:
        browserName: "chrome"
      firefox:
        browserName: "firefox"
      ie:
        browserName: "internet explorer"
      safari:
        browserName: "safari"
      opera:
        browserName: "opera"
    hacks:
      justType:
        safari: true  
      invoke:
        firefox: true
    promise: ->
      plugin = @
      wd.addPromiseMethod(
        "waitIdle",
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector(
            ".qx-application.qx-state-idle"
            timeout))
      wd.addPromiseMethod(
        "toolbutton"
        (title) ->
          @elementByCss(""".qx-aum-toolbar-button[title="#{title}"]"""))
          
      wd.addPromiseMethod(
        "startApplication"
        (command,instance) ->
          instance ?= runner.qatDefaultInstance
          runner.wd.lastExecuted = command + ".exe"
          @get(runner.lyciaWebUrl)
            .then((i) ->
              plugin.trace "Starting #{command} at #{instance}"
              i)
            .elementById("qx-home-instance")
            .type(instance)
            .elementById("qx-home-command")
            .type(command)
            .elementById("qx-home-form")
            .submit()
            .waitIdle()) 

      wd.addPromiseMethod(
        "justStartApp"
        (command,instance) ->
          instance ?= runner.qatDefaultInstance
          @get(runner.lyciaWebUrl)
            .then((i) ->
              plugin.trace "Starting #{command} at #{instance}"
              i)
            .elementById("qx-home-instance")
            .type(instance)
            .elementById("qx-home-command")
            .type(command)
            .elementById("qx-home-form")
            .submit())
             
      
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
        "dragNDrop"
        (el, left, top) -> 
          el
            .moveTo()
            .buttonDown()
            .moveTo(left,top)
            .buttonUp()
      )

      wd.addPromiseMethod(
        "formField"
        (name) -> @elementByCss ".qx-identifier-#{name}")

      # alias for formField. should be used instead!        
      wd.addPromiseMethod(
        "getElement"
        (name) -> @elementByCss ".qx-identifier-#{name}")
        
      wd.addPromiseMethod(
        "getWindow"
        (name) -> @elementByCss ".qx-o-identifier-#{name}")

      wd.addPromiseMethod(
        "resizeWindow"
        (wnd,dx,dy,h) -> 
          h?="se"
          yp(@elementByCss(".qx-o-identifier-#{wnd} .ui-resizable-#{h}").then( (p)->
            p
              .moveTo()
              .buttonDown()
              .moveTo(dx,dy)
              .buttonUp()
          ))
        )
        
      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector("#qx-home-form, #qx-application-restart",timeout))
             
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
          unless el.click? then el = @elementByCss ".#{el}"
          if plugin.hacks.invoke[@qx$browserName]
            @remoteCall el, "click"
          else
            el.click())

      wd.addPromiseMethod(
        "invokeElement",
        (el) ->
          unless el.click? then el = @elementByCss ".qx-identifier-#{el}"
          if plugin.hacks.invoke[@qx$browserName]
            @remoteCall(el, "click")
              .waitIdle()
          else
            el
              .click()
              .waitIdle())
            
      wd.addPromiseMethod(
        "remoteCall"
        (el,nm) ->
          if _.isString el 
            @execute("return $().#{nm}.apply($('.qx-identifier-#{el}'),arguments)")
          else
            @execute(
              "return $().#{nm}.apply($(arguments[0]))"
              [el]))
              
      wd.addPromiseMethod(
        "cssProperty"
        (el,cls) ->
          if _.isString el 
            @execute("return $().css.apply($('.qx-identifier-#{el}'),['#{cls}'])")
          else
            @execute(
              "return $().css.apply($(arguments[0]),['#{cls}'])"
              [el]))  

      wd.addPromiseMethod(
        "check"
        (el,params) ->
          if _.isString el then el=@getElement(el)
          unless params? then el          
          params.mess?="Error"
          
          # TODO : make calculations optional
          # must be done, prior to add more attributes
          size = yp el.getSize()
          loc =  yp el.getLocationInView()
          
          errmsg = ""
          for attr,expected of params
            actual = switch attr
              when "mess" then expected
              when "w","width" then size.width
              when "h","height" then size.height
              when "x" then loc.x
              when "y" then loc.y
              else   
                @info "no method for #{attr}"
                expected
            unless expected is actual
              errmsg+="#{attr} mismatch! Actual : <#{actual}>, Expected : <#{expected}>"

          params.mess?="Error"
          
          unless errmsg is ""
            throw params.mess+":\n"+errmsg
          el
      )
      wd.addPromiseMethod(
        "getText"
        (id) ->
        
          #a = ["calendar","textfield"]

          log yp @elementByCss(".qx-identifier-#{elId}.qx-aum-calendar")
          
          @assert.deepEqual(@getGeometry("f1"),{x:10,y:60,w:50,h:50})
          
          
          #el = switch
          #  when @elementByCss(".qx-identifier-#{elId}.qx-aum-calendar")
          #switch
          #when (yp(@execute("return $('.qx-identifier-#{el}').hasClass('qx-aum-calendar')"))).toString() == "true" then yp(@execute("return $('.qx-identifier-#{el} input').val()"))
          #when (yp(@execute("return $('.qx-identifier-#{el}').hasClass('qx-aum-button')"))).toString() == "true" then yp(@execute("return $('.qx-identifier-#{el} .qx-text').html()"))
          #throw "Isn't implemented for this widget yet"
        )
   
      wd.addPromiseMethod(
        "getFromMessageBox"
        (mb) ->
          switch
            when mb is "text" then yp(@execute("return $('.qx-message-box:visible pre').text()")) 
            else
              throw "Isn't implemented for this messageBox element yet"
        ) 

      wd.addPromiseMethod(
        "getImage"
        (el) ->
            switch
              when (yp(@execute("return $('.qx-identifier-#{el}').hasClass('qx-aum-button')"))).toString() == "true" then yp(@execute("return $('.qx-identifier-#{el} .qx-image-cell>img')[0].src"))
              else throw "Isn't implemented for this widget yet"
        )
      
              
      synproto = {}
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
        #plugin = @
        d = info.data ?= {}
        _.merge d, kind: "wd"
        info.enable = _.merge {}, plugin.enable, info.enable
        for i,v of plugin.browsers when info.enable.browser[i]
          do (i,v) =>
            binfo = _.clone info
            binfo.data = _.clone info.data
            binfo.data.kind = "wd-#{i}"
            promise = binfo.promise
            unless promise?
              if binfo.syn?
                binfo.name="wd$#{i}$#{info.name}"
                promise = (browser) ->
                  yp.frun ->
                    try 
                      binfo.syn.call _.create binfo,_.assign {browser:browser}, synproto
                    finally
                      exec('taskkill /F /T /IM '+ runner.wd.lastExecuted)
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
              unless binfo.closeBrowser is false or plugin.closeBrowser is false  
                r = r.finally ->
                  browser.quit()
              return r.then(-> "OK")
            @reg binfo
            binfo.data.browser = i
      Q({})
