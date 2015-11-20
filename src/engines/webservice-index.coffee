runner = {}

stopResponces = ['<interact_wswaitcall/>','']
log = console.log
requestTimeout = 5000
testTimeout = 30000
WS_defaultDelay = 1000
WS_initialDelay = 2000 # this is must be removed, once appserver gni is fixed

getResponse = (s)->
  r=/<response>([\s\S]*)<\/response>/.exec(s)
  return r[1] if r?
  ""

getResults = (s)->
  r=/<response><results>([\s\S]*)<\/results><\/response>/.exec(s)
  return r[1] if r?
  ""

class WStools
  constructor: ( opts={} )->
    opts.delay?=WS_initialDelay
    opts.timeout?=testTimeout
    @timeout=opts.timeout
    @promise = runner.Q({}).delay( opts.delay );
    @quitSent = false
    @webUrl = "#{runner.opts.lyciaWebUrl}sapi/"
    @headers = {}
    if opts.program?
      @program = opts.program
      @flag = @program+".txt"
    @

  promRequest : ( opts )->
    it = @
    @recentPath = opts.path
    runner.logger.trace " >>> Request : #{opts.path}"
    runner.logger.trace "     #{@headers.cookie}"


    req =
      url : @webUrl + opts.path
      headers : @headers
      timeout : requestTimeout
      method : "GET"

    if opts.body?
      req.body = [opts.body]
      req.headers['Content-Length'] = Buffer.byteLength( opts.body, 'utf8')
      req.headers['Content-Type'] = 'text/plain'

    return runner.qio.http.request( req ).then(
      (res)->
        it.res=res
        runner.logger.trace " <<< response : #{opts.path}"
        runner.logger.trace "     #{it.headers.cookie}"
        runner.logger.trace "     status : #{res.status}"

        it.headers.cookie?= /(JSESSIONID=.*);/.exec(res.headers["set-cookie"][0])[1]

        if opts.path is "quit" then it.quitSent=true

        if (opts.all) and (res.status isnt 200) then throw "STATUS : "+res.status
        unless opts.body or opts.all then return res

        it.res.body.read()
        .then( (b)->
          it.body=b.toString()
          runner.logger.trace "     body : #{it.body}"
          if opts.all and stopResponces.indexOf( getResponse(it.body) )==-1
            # repeat request
            return it.promRequest( opts )
          it.body
        )
      (e)->
        runner.logger.trace " !!! ERROR : "
        runner.logger.trace e
        throw "Connection failed or timed out : '#{e}'"
    )


  request : ( p1, opts={} )->
    it = @
    @promise = runner.Q( @promise ).then( ->
      if typeof p1 is "string"
        opts.path=p1
      else
        opts=p1 ? {}
      opts.path?=runner.opts.qatDefaultInstance + "/" + it.program
      it.promRequest( opts )
    )
    @

  checkStatus : ( exp = 200 )->
    it = @
    @promise = runner.Q( @promise ).then( ->
      if it.res.status isnt exp
        st = it.res.status
        throw "#{it.recentPath} status mismatch. Expected : #{exp}, Actual : #{st}"
    )
    @

  delay : ( msec=WS_defaultDelay )->
    @promise = runner.Q(@promise).delay( msec )
    @

  checkFlag : ( f )->
    it = @
    @promise = runner.Q(@promise).then( ->
      f?=it.flag
      f=runner.path.join( runner.opts.deployPath, f )
      runner.qio.fs.exists( f )
      .then( (exists)->
        unless exists then throw f + " can not be found. Program may not be executed successfully."
      )
    )
    @

  body : ( opts = {} )->
    it = @
    @promise = runner.Q(@promise).then( ->
      it.res.body.read()
      .then( (b)->
        it.body=b.toString()
        runner.logger.trace "     Body : "+it.body
        if opts.expected?
          if opts.expected isnt it.body
            throw "Wrong response body. Expected : #{opts.expected}. Actual : #{it.body}."
        if opts.response?
          r = getResponse(it.body)
          if opts.response isnt r
            throw "Wrong body response. Expected : #{opts.response}. Actual : #{r}."
        if opts.results?
          r = getResults(it.body)
          if opts.results isnt r
            throw "Wrong body results. Expected : #{opts.results}. Actual : #{r}."
        it.body
      )
    )
    @

  clearFlag : ( f )->
    it = @
    @promise = runner.Q(@promise).then( ->
      f?=it.flag
      f=runner.path.join( runner.opts.deployPath, f )
      runner.qio.fs.remove( f )
      .fail(-> "No file on start, but its ok.")
    )
    @

  promQuit : ->
    it = @
    runner.logger.trace " >>> Quit on " + @headers.cookie
    @promRequest( path : "quit" ).then( -> it.quitSent=true )

  quit : ->
    it = @
    @promise = runner.Q(@promise).then( -> it.promQuit )
    @

  end : ( opts = {message : "ok"})->
    runner.Q( @promise )
    .timeout( @timeout )
    .finally( ((r)->
      if @quitSent or opts.noquit
        return r
      runner.logger.trace " >>> sending quit"
      @promQuit()
    ).bind(@))
    .then( -> opts.message )

  then : (args...)->
    @promise = runner.Q(@promise).then(args...)
    @


module.exports = ->
  runner = @

  runner.qio =
    http : require "q-io/http"
    fs : require "q-io/fs"
  runner.Q.allFulfilled = (args...)->
    runner.Q.allSettled(args...)
    .then( (results)->
      if results.some( (res)-> res.state isnt 'fulfilled')
        throw results.map( (res)-> res.reason ? res.value )
      results.map( (res)-> res.value )
    )

  runner.WebService = (p)->
    new WStools(p)
