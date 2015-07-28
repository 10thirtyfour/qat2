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
      transports:
        console:
          level: "info"
        couchdb:
          host: "10.38.57.55"
          
    globLoader:
      root: "./tests"
      
    browserList :
      chrome: (true)
      firefox: (true)

    common:
      timeouts:
        wd: 1200000

