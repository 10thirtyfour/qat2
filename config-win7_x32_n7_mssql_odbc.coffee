module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
  
    common:
      options:
        databaseProfile: "mssql-odbc" 
      timeouts:
        line: 120000
        run: 600000
        compile: 200000
        build: 600000

    logger:
      transports:
        couchdb:
          host: "10.38.57.55"
          
    globLoader:
      disable:
        file: 
          pattern: ["**/*-wd-test.coffee"]
      
    browserList :
      chrome: (false)
      firefox: (false)
      ie: (false)

    scenario: "MSSQL"