log = console.log
exec = require('child_process').exec

UI_elements = require "./ui-element-defaults"

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
            timeout).sleep(300))
            
      wd.addPromiseMethod(
        "toolbutton"
        (title) ->
          @elementByCss(""".qx-aum-toolbar-button[title="#{title}"]"""))
          
      wd.addPromiseMethod(
        "startApplication"
        (command, params) ->
          @cmd = command
          params ?= {}
          params.wait ?= true
          params.instance ?= runner.qatDefaultInstance
          
          command += ".exe" if process.platform[0] is "w"
          programUrl = runner.lyciaWebUrl + params.instance + "/" + command

          if params.args then programUrl+=params.args
          
          if params.wait
            return @get(programUrl).waitIdle()
          else
            return @get(programUrl)
          ) 

      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector("#qx-home-form, #qx-application-restart",timeout))
           
          
      wd.addPromiseMethod(
        "elementExists"
        (el) ->
          yp(@elementByCssSelectorIfExists(".qx-identifier-#{el}"))?
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
        "dragNDrop"
        (el, left, top) -> 
          el
            .moveTo()
            .buttonDown()
            .moveTo(left,top)
            .buttonUp()
      )

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
          yp(@elementByCss(".qx-o-identifier-#{wnd} > .ui-resizable-#{h}").then( (p)->
            p
              .moveTo()
              .buttonDown()
              .moveTo(dx,dy)
              .buttonUp()
          ))
        )

      wd.addPromiseMethod(
        "resizeElement"
        (el,dx,dy,h) -> 
          h?="e"
          yp(@elementByCss(".qx-identifier-#{el} .ui-resizable-#{h}").then( (p)->
            p
              .moveTo()
              .buttonDown()
              .moveTo(dx,dy)
              .buttonUp()
          ))
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
        (el, nm, args...) ->
          if _.isString el 
            @execute(
              "return $().#{nm}.apply($('.qx-identifier-#{el}'),arguments)"
              args)
          else
            @execute(
              "return $().#{nm}.apply($(arguments[0]),arguments[1])"
              [el,args])
            )
            
      wd.addPromiseMethod(
        "check"
        (el,params) ->
          if _.isString el
            itemType = yp @getElementType el
            itemSelector = ".qx-identifier-#{el}"
          else
            itemType = "unknown"
            itemSelector = params.selector
            #delete params.selector
            
          res = yp @execute "return $('#{itemSelector}')[0].getBoundingClientRect()"
          res.type = itemType
          
          if params.w? 
            params.width=params.w
            delete params.w
          if params.h?
            params.height=params.h
            delete params.h
          if params.x?
            params.left=params.x
            delete params.x
          if params.y?
            params.top=params.y
            delete params.y
        
          mess = params.mess ?= itemType + " " + itemSelector
          errmsg = ""
          
          for attr,expected of params
            switch attr 
              when "mess","precision","selector" then continue
              when "text" then res.text = yp @getText(el, itemType)
              when "value" then res.value = yp @getValue(el, itemType)
              #else console.log "\nWarning! #{attr} not checked for #{itemSelector}"
              
            if expected is "default"
              expected = UI_elements[itemType].getDefault(attr, @qx$browserName + "$" + 
                         process.platform[0])
            
            if expected isnt res[attr]
              errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>"

          if errmsg isnt ""
            throw mess + " : "+errmsg
          return mess
      )
      
      wd.addPromiseMethod(
        "getText"
        (el,el_type) -> 
          el_type ?= yp @getElementType(el)
          return yp @execute UI_elements[el_type].getText(el)
      )
      
      wd.addPromiseMethod(
        "getImage"
        (el,el_type) -> 
          el_type ?= yp @getElementType(el)
          return yp @execute UI_elements[el_type].getImage(el)
      )

      wd.addPromiseMethod(
        "getValue"
        (el,el_type) -> 
          el_type ?= yp @getElementType(el)
          return yp @execute UI_elements[el_type].getValue(el)
      )      
      
      wd.addPromiseMethod(
        "getElementType"
        (el) ->
          for name,element of UI_elements
            if yp @execute element.selector(el)
              return name
          "unknown"
      ) 
      
      wd.addPromiseMethod(
        "switchTab"
        (el) ->
          @execute("$('.qx-h-identifier-#{el} .qx-focus-target').click()"))
                
      
      wd.addPromiseMethod(
        "messageBox"
        (action,params) ->
          switch action
            when "getText" then yp(@execute("return $('.qx-message-box:visible pre').text()"))
            when "getValue" then yp(@execute("return $('.qx-message-box:visible input').val()"))
            when "wait" then yp(@waitMessageBox())
            when "click" then yp(@execute ("$('.qx-button-#{params}').click()")) 
            else
              throw "Isn't implemented for this messageBox element yet"
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
                binfo.name= "wd$#{i}$#{info.name}"
                promise = (browser) ->
                  yp.frun ->
                    try
                      testContext = _.create binfo,_.assign {browser:browser}, synproto
                      binfo.syn.call testContext
                    finally
                      #task kill. command stored in browser.cmd
                      if process.platform[0] is "w" 
                        exec('taskkill /F /T /IM '+ browser.cmd + '.exe')
                      else
                        exec('pkill -9 '+ browser.cmd )
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
                r = r.finally ->
                  browser.quit()
              return r.then(-> "OK")
            @reg binfo
            binfo.data.browser = i
      Q({})
