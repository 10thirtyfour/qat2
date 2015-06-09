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
    if _.isString(el) then return ".qx-identifier-#{el}"
    # table row selector
    if el.table? and el.row?
      return ".qx-identifier-#{el.table} table.qx-tbody tr:nth-child(#{(el.row+1)})"
      
  @reg
    name: "wd"
    # CFGOPT: default wait timeout
    defaultWaitTimeout: 60000
    setup: (true)
    before: "globLoader"
    enable:
      browser: runner.opts.browserList
    links:
      chrome: "http://localhost:9515/"
      ie: "http://localhost:5555/"
      firefox: "http://localhost:4444/wd/hub/"
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
          params.instance ?= runner.qatDefaultInstance
          
          command += ".exe" if process.platform[0] is "w"
          programUrl = runner.lyciaWebUrl + params.instance + "/" + command

          if params.args then programUrl+=params.args

          if params.wait
            return @get(programUrl).waitIdle()
          else
            return @get(programUrl).sleep(500)
          ) 

      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector("#qx-application-restart",timeout))
           
          
      wd.addPromiseMethod(
        "elementExists"
        (el) ->
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
        (name) -> @elementByCss ".qx-identifier-#{name}")
        
      wd.addPromiseMethod(
        "getWindow"
        (name) -> @elementByCss ".qx-o-identifier-#{name}")

      wd.addPromiseMethod(
        "resizeWindow"
        (wnd,dx,dy,h) -> 
          h?="se"
          r = yp @execute "return $('.qx-o-identifier-#{wnd} > .ui-resizable-#{h}')[0].getBoundingClientRect()"
          x = Math.round(r.left + r.width / 2)
          y = Math.round(r.top + r.height / 2)
          yp @elementByCss('#qx-home-form')
              .moveTo( x, y )
              .buttonDown(0)
              .moveTo( x + Math.floor(dx) , y + Math.floor(dy) )
              .buttonUp(0)
              .waitIdle()
        )

      wd.addPromiseMethod(
        "moveWindow"
        (wnd,dx,dy) -> 
          r = yp @execute "return $('.qx-o-identifier-#{wnd} > div.ui-dialog-titlebar')[0].getBoundingClientRect()"
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
          r = yp @execute "return $('.qx-identifier-#{el} .ui-resizable-#{h}')[0].getBoundingClientRect()"

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
            el = yp(@elementByCssSelectorIfExists(getSelector(el))) ? yp(@elementByCss("#{el}"))
          if plugin.hacks.invoke[@qx$browserName]
            @remoteCall el, "click"
          else
            el.click())

      wd.addPromiseMethod(
        "getClasses",
        (el) ->
          element = yp(@elementByCssSelectorIfExists(".qx-identifier-#{el}")) ? yp(@elementByCss("#{el}"))
          yp(element.getAttribute("class")).split(" ")
      )            
          
          
      wd.addPromiseMethod(
        "checkClasses",
        (el, params) ->
          classes = yp @getClasses el
          params.good?=params.required
          params.bad?=params.forbidden
          
          goodClasses = if _.isString(params.good) then params.good.split(' ') else params.good ? []
          badClasses  = if _.isString(params.bad ) then params.bad.split(' ') else params.bad ? []
          
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
          res.width = Math.floor(res.width)
          res.height = Math.floor(res.height)
          res.left = Math.floor(res.left)
          res.top = Math.floor(res.top)
          res.type = el_type
          
          params.width = params.w if (params.w?)
          params.height = params.h if (params.h?)
          params.left = params.x if (params.x?)
          params.top = params.y if (params.y?)
          
          mess = [params.mess,el_type,itemSelector].join " "
          errmsg = ""
          
          for attr,expected of params
            continue if attr in ["mess","precision","selector","w","h","x","y","deferred"]
            
            if attr of UI_elements[el_type].get
              res[attr] = yp @execute UI_elements[el_type].get[attr](el)

            if expected is "default"
              expected = UI_elements[el_type].get.default(attr, @qx$browserName+"$"+process.platform[0])
            
            if expected isnt res[attr]
              errmsg += "#{attr} mismatch! Actual : <#{res[attr]}>, Expected : <#{expected}>. "

              
          if errmsg is "" then return ""
          
          mess+=" : #{errmsg}" 
          
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
        "getRect"
        (el) -> 
          return yp @execute "return $('#{getSelector(el)}')[0].getBoundingClientRect()"
      )

      wd.addPromiseMethod(
        "toolbutton"
        (title) ->
          @elementByCss(""".qx-aum-toolbar-button[title="#{title}"]"""))
          
      wd.addPromiseMethod(
        "statusBarText"
        () ->
          yp(@execute('return $("div.qx-identifier-statusbarmessage:visible .qx-text").text()')) ? ""
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
        "getSelector", (el)->
          if el.selector? then return el.selector
          if _.isString(el) then return ".qx-identifier-#{el}"
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
        _.merge d, kind: "wd"
        info.enable = _.merge {}, plugin.enable, info.enable
        for i,v of plugin.browsers when info.enable.browser[i]
          #wdTimeout = @opts.common.timeouts.wd[i]
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
                    testContext = _.create binfo,_.assign {browser:browser}, synproto, {errorMessage:""}
                    testContext.browser.errorMessage=""
                    testContext.aggregateError=(false)
                    try
                      binfo.syn.call testContext
                    catch e
                      ###
					  TODO : kill qrun here
                      for cmd in testContext.browser.executedPrograms
                        if process.platform[0] is "w" 
                          runner.trace "taskkill /F /T /IM #{cmd}.exe"
                          exec("taskkill /F /T /IM #{cmd}.exe")
                        else
                          exec("pkill -9 #{cmd}")
                      ###
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
              return r.then(-> "OK")
              
            @reg binfo
            binfo.data.browser = i
      Q({})
