runner = {}

stopResponces = ['<interact_wswaitcall/>']
log = console.log
requestTimeout = 5000
testTimeout = 20000
wsStartUpDelay = 1000

getResponse = (s)->
  r=/<response>([\s\S]*)<\/response>/.exec(s)
  return r[1] if r?
  ""

class WStools
  constructor: ( opts={} )->
    @promise = runner.Q({})
    @webUrl = "#{runner.opts.lyciaWebUrl}sapi/"
    if opts.program?
      @program = opts.program 
      @flag = runner.path.join( runner.opts.deployPath, @program+".txt" )
    @

  promRequest : ( opts )->
    it = @
    it.recentPath = opts.path
    runner.logger.trace "Request : #{opts.path}"

    req =
      url : @webUrl + opts.path
      headers : @headers
      timeout : requestTimeout
      method : "GET"
      
    if opts.body?
      req.body = [opts.body]
      req.headers['Content-Length'] = Buffer.byteLength( opts.body, 'utf8')
      req.headers['Content-Type']   = 'text/plain'
    
    p = runner.qio.http.request( req )
    .fail( (e)-> throw "Connection failed or timed out : '#{e}'" )
    if opts.noresult then return p
    p.then( (res)->
      it.res=res
      unless opts.body or opts.all then return res
      it.res.body.read()
      .then( (b)->
        it.body=b.toString()
        runner.logger.trace "#{it.res.status} : #{it.body}"
        if opts.all and stopResponces.indexOf( getResponse(it.body) )==-1 
          return it.promRequest( opts )
        it.body
      )
    )
    
  request : ( opts={} )-> 
    it = @
    @promise = runner.Q( @promise ).then( ->  
      if typeof opts is "string"
        opts = { path : opts }
      else
        opts.path?=runner.opts.qatDefaultInstance + "/" + it.program    
       
      it.headers?= {}
      it.promRequest( opts )
    )
    @

  saveCookie : ( opts={} )->
    it = @
    @promise = runner.Q(@promise).then( ->
      it.headers.cookie?= /(JSESSIONID=.*);/.exec(it.res.headers["set-cookie"][0])[1]
      if opts.show
        runner.logger.trace it.headers.cookie
    )
    @

  checkStatus : ( exp = 200 )->
    it = @
    @promise = runner.Q( @promise ).then( ->
      if it.res.status isnt exp 
        st = it.res.status
        return it.promRequest( path : 'quit' ).then( ->
          throw "#{it.recentPath} status mismatch. Expected : #{exp}, Actual : #{st}"
        )
    )
    @
  
  delay : ( msec=wsStartUpDelay )->  
    @promise = runner.Q(@promise).delay( msec )
    @
      
  removeFlag : ( f )->      
    it = @
    @promise = runner.Q(@promise).then( ->
      it.flag = f if f?
      runner.qio.fs.remove( it.flag )
      .fail( -> throw it.flag + " can not be found. Program may not be executed successfully." ) 
    )
    @
    
  readBody : ( opts )->
    it = @
    @promise = runner.Q(@promise).then( ->
      it.res.body.read()
      .then( (b)->
        it.body=b.toString()
        runner.logger.trace it.body
        if opts.expected?
          if opts.expected isnt it.body
            return it.promRequest( path : 'quit' ).then( ->
              throw "Wrong body response. Expected : #{opts.expected}. Actual : #{it.body}."
            )
        it.body
      )
    )
    @
    
  clearFlag : ( f )->      
    it = @
    @promise = runner.Q(@promise).then( ->
      it.flag = f if f?
      runner.qio.fs.remove( it.flag )
      .fail(-> "No file on start, but its ok.")
    )
    @
  
  end : (message="ok")->
    runner.Q(@promise).then( -> message ).timeout(testTimeout)
    
  then : (args...)->
    @promise = runner.Q(@promise).then(args...)
    @
    
    
module.exports = ->
  runner = @
  
  runner.qio =
    http : require "q-io/http"
    fs : require "q-io/fs"
  
  runner.WebService = (p)->
    new WStools(p)

  
