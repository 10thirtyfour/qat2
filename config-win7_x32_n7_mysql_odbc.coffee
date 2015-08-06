module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
  
    common:
      options:
        databaseProfile: "mysql-odbc" 
      timeouts:
        line: 120000
        run: 600000
        compile: 200000
        build: 600000

    logger:
      disable:
        couchdb: false
          
    globLoader:
      disable:
        file: 
          pattern: ["**/*-wd-test.coffee"]
      
    browserList :
      chrome: (false)
      firefox: (false)
      ie: (false)

    scenario: "MySQL"
