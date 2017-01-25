"use strict"

module.exports = ()->
  { yp, opts, _, path, Q } = runner = @

  runner.qio ?=
    http : require "q-io/http"
    fs : require "q-io/fs"

  urlRunApp = (appName)->
    "http://#{runner.opts.appHost}:9090/LyciaWeb/run/#{runner.opts.qatDefaultInstance}/#{appName}"

  class WebSession
    constructor: (params={})->
      @timeout = params.timeout or 30000
      appName = params.program or params.name or params.lastBuilt
      @promise = Q( {} ).timeout( @timeout )
      @request( url : urlRunApp(appName) )
      @getCookie()
      @getCidPid()
      @

    then : (fun)->
      @queue(fun)

    queue : (fun, args...)->
      @promise = runner.Q( @promise ).then( fun.bind(@, args...) )
      @

    getCookie : ->
      @queue ->
        @cookie = /(JSESSIONID=.*);/.exec(@last.headers["set-cookie"][0])[1]

    getCidPid : ->
      @queue ->
        ci = @last.body.indexOf('querix.comms.startup("/LyciaWeb/",')
        if ci<1
          throw new Error("can't get cid.")
        pi = @last.body.indexOf(",", ci + 35 )
        @cid = @last.body.substring(ci+35,pi).trim()
        @pid = @last.body.substring(pi+1,@last.body.indexOf(",", pi+1)).trim()

    delay : ( msec=1000 )->
      @promise = runner.Q(@promise).delay( msec )
      @

    update : (body="")->
      r = {}
      @queue ->
        r =
          method : "POST"
          url : "http://#{runner.opts.appHost}:9090/LyciaWeb/update?cid=#{@cid}&pid=#{@pid}"
          headers :
            'Content-Length' : Buffer.byteLength( body, 'utf8')
            'Content-Type' :'text/plain'
            body : [body]
            cookie : @cookie
      @request(r)

    show : ()->
      console.log "show"
      @queue ->
        console.log @last.headers
        console.log @last.cid
        console.log @last.pid
        console.log @last.path
        console.log @last.url


    request : (opts)->
      @queue ->
        @last = {
          request : _.assign({ method : "GET" }, opts)
        }
        #console.log @last
        runner.qio.http.request(@last.request)
        .then( ((res)->
          @last =
            status : res.status
            headers : res.headers
          res.body.read().then( ((b)->
            @last.body = b.toString()
          ).bind(@))
        ).bind(@))


  runner.WebSession = WebSession
    #(opts)->
    #return new session(opts)
