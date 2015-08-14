runner = {}

log = console.log

class WStools
  constructor: (p)->
    @promise = runner.Q {}
    @webUrl = "#{runner.opts.lyciaWebUrl}sapi/"
    @flag = runner.path.join( runner.opts.deployPath, p+".txt" )
    @program = p
    @

  request : ( path )-> 
    it = @
    @promise = runner.Q( @promise ).then( ->  
      path?=runner.opts.qatDefaultInstance + "/" + it.program    
      it.headers?= {}
      it.recentPath = path
      runner.qio.http.request( url : it.webUrl + path, headers : it.headers )
      .then( (res)->
        it.res=res
        res
      )
    )
    @

  saveCookie : ->
    it = @
    @promise = runner.Q(@promise).then( ->
      it.headers.cookie?= /(JSESSIONID=.*);/.exec(it.res.headers["set-cookie"][0])[1]
      log it.headers.cookie
    )
    @

  checkStatus : ( exp = 200 )->
    it = @
    @promise = runner.Q( @promise ).then( ->
      if it.res.status isnt exp then throw "#{it.recentPath} status mismatch. Expected : #{exp}, Actual : #{it.res.status}"
    )
    @
  
  delay : ( msec=1000 )->  
    @promise = runner.Q(@promise).delay( msec )
    @
      
  checkFlag : ->      
    it = @
    @promise = runner.Q(@promise).then( ->
      runner.qio.fs.remove( it.flag )
      .fail( -> throw it.flag + " can not be found. Program may not be executed successfully." ) 
    )
    @
      
  clearFlag : ->      
    it = @
    @promise = runner.Q(@promise).then( ->
      runner.qio.fs.remove( it.flag )
      .fail(-> "No file on start, but its ok.")
    )
    @
  
  end : (message="ok")->
    runner.Q(@promise).then( -> message )
    
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

  
