module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    
    scenario: "Crossbrowsers"
    common:
      options:
        buildMode: "rebuild"
        databaseProfile: "informix" 
        env:
          DBDATE: "MDY4/"
          
    logger:
      disable:
        couchdb: false
      transports:
        console:
          level: "info"
          
    globLoader:
      root: "./tests"
      
    browserList :
      chrome: (true)
      firefox: (true)
      ie: (true)

    common:
      timeouts:
        wd: 18000

