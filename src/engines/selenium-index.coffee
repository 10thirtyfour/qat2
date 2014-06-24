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
        "formField"
        (name) -> @elementByCss ".qx-ident-#{name}")
     
      wd.addPromiseMethod(
        "waitExit"
        (timeout) ->
          timeout ?= plugin.defaultWaitTimeout
          @waitForElementByCssSelector("#qx-home-form, #qx-application-restart",
            timeout))
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
        "remoteCall"
        (el,nm) ->
          if _.isString el 
            @execute("return $().#{nm}.apply($('.qx-ident-#{el}'),arguments)")
          else
            @execute(
              "return $().#{nm}.apply($(arguments[0]))"
              [el]))
              
      wd.addPromiseMethod(
        "fieldWidth"
        (el) -> 
          @execute("return $('.qx-ident-#{el}').width()")
        )   
        
      wd.addPromiseMethod(
        "fieldHeight"
        (el) -> 
          @execute("return $('.qx-ident-#{el}').height()")
        )          
      wd.addPromiseMethod(
        "fieldText"
        (el) -> @remoteCall el, "fieldText")
     

      wd.addPromiseMethod(
        "checkSize"           
        (el,w,h) -> 
          if _.isString el then el = @elementByCss ".#{el}"
          el.getSize().then( (i) ->
            unless w is i.width and h is i.height 
              Q.reject("size mismatch. Expected #{w}x#{h}. Actual #{i.width}x#{i.height}")
          )
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
                    binfo.syn.call _.create binfo,
                    _.assign {browser:browser}, synproto
              else
                promise = ->
            binfo.promise = ->
              if plugin.links[i]?
                browser = wd.promiseChainRemote plugin.links[i]
              else
                browser = wd.promiseChainRemote()
              if plugin.wdTrace
                browser.on("status", (info) -> plugin.trace info.cyan)
                browser.on("command", (meth, path, data) ->
                plugin.trace "> #{meth.yellow}", path.grey, data || '')
              r = browser.init(v).then(=> promise.call @, browser)
              browser.qx$browserName = i
              unless binfo.closeBrowser is false or plugin.closeBrowser is false 
                r = r.finally ->
                  # taskkill                
                  processName = runner.path.basename(info.name).split("-test")[0]+".exe"
                  exec('taskkill /F /T /IM '+ processName, (error, stdout, stderr) -> 
                    browser.quit() )

              return r.then(-> "OK")
            @reg binfo
            binfo.data.browser = i
      Q({})
