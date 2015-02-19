###
# #%L
# QUERIX
# %%
# Copyright (C) 2015 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel : +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
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
        safari: (true)
      invoke:
        firefox: (true) 
    promise: ->
      plugin = @
      
      wd.addPromiseMethod(
        "waitIdle",
        (timeout) -> 
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector(".qx-application.qx-state-idle", timeout)
          )  
          
      wd.addPromiseMethod(
        "startApplication"
        (command, params) ->
          @executedPrograms?=[]
          @executedPrograms.push(command)
          
          params ?= {}
          params.wait ?= (true)
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
          r = yp @execute "return $('.qx-o-identifier-#{wnd} > .ui-resizable-#{h}')[0].getBoundingClientRect()"
          #h = yp @elementByCss(".qx-o-identifier-#{wnd} > .ui-resizable-#{h}")
          x = Math.round(r.left + r.width / 2)
          y = Math.round(r.top + r.height / 2)
          #console.log dx,dy
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
          unless el.click? 
            el = yp(@elementByCssSelectorIfExists(".qx-identifier-#{el}")) ? yp(@elementByCss(".#{el}"))
            
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
        "hasScroll"
        (id) ->      
          selector = id.selector ? ".qx-identifier-#{id}"
          @execute("""
            el=$('#{selector}');
            if(el.css('overflow')=='hidden') {return false;}
            if((el.prop('clientWidth' )!=el.prop('scrollWidth' )) || 
               (el.prop('clientHeight')!=el.prop('scrollHeight'))) { return true;}
            return false;
          """)
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
          
          res = yp @execute "return $('#{itemSelector}')[0].getBoundingClientRect()"
          res.type = el_type
          
          params.width = params.w if (params.w?)
          params.height = params.h if (params.h?)
          params.left = params.x if (params.x?)
          params.top = params.y if (params.y?)
          
          mess = [params.mess,el_type,itemSelector].join " "
          errmsg = ""
          
          for attr,expected of params
            continue if attr in ["mess","precision","selector","w","h","x","y"]
            
            if attr of UI_elements[el_type].get
              res[attr] = yp @execute UI_elements[el_type].get[attr](el)

            if expected is "default"
              expected = UI_elements[el_type].get.default(attr, @qx$browserName+"$"+process.platform[0])
            
            if expected isnt res[attr]
              errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>. "

          throw mess + " : "+errmsg if errmsg isnt ""
            
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
          for name,element of UI_elements
            if yp @execute element.selector(el)
              return name
          "unknown"
      ) 

      wd.addPromiseMethod(
        "setValue"
        (el, value) -> 
          try
            yp UI_elements[ yp @getType(el) ].set.value.apply(@,[el,value])
          catch e
            return (false)
          (true)
      )      

      wd.addPromiseMethod(
        "getRect"
        (el) -> 
          {selector} = el
          selector?= '.qx-identifier-' + el
          return yp @execute "return $('#{selector}')[0].getBoundingClientRect()"
      )

      wd.addPromiseMethod(
        "toolbutton"
        (title) ->
          @elementByCss(""".qx-aum-toolbar-button[title="#{title}"]"""))
      
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
        wdTimeout = @opts.common.timeouts.wd
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
                  yp.frun( ->
                    #try
                    testContext = _.create binfo,_.assign {browser:browser}, synproto, {errorMessage:""}
                    try
                      binfo.syn.call testContext
                    catch e
                      if ((_.deepGet(e,'cause.value.message')) ? "").split("\n")[0] is "unexpected alert open"
                        alertText = yp(testContext.browser.alertText())
                        testContext.errorMessage+=alertText+" alert caught! "+e.message
                      else
                        throw e
                      
                    throw testContext.errorMessage if testContext.errorMessage.length>0
                    #catch e
                    #  al = testContext.switchTo().alert()
                    #  al = driver.switchTo().alert(); 
                    # AlertText = al.getText();
                    #if e.cause.value.message is "unexpected alert open"
                    #    throw "SlientSideProblems"
                    # ======== no more kills here ========
                      #task kill. command stored in browser.executedPrograms
                      #if process.platform[0] is "w" 
                      #  exec('taskkill /F /T /IM '+ browser.cmd + '.exe')
                      #else
                      #  exec('pkill -9 '+ browser.cmd )
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
              return r.then(-> "OK")
              
            @reg binfo
            binfo.data.browser = i
      Q({})
