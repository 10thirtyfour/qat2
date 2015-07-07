module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
  
    common:
      options:
        databaseProfile: "mssql-odbc" 

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