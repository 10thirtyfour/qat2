module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
  
    common:
      options:
        buildMode: "rebuild"
        databaseProfile: "informix" 
        env:
          DBDATE: "MDY4/"

    common:
      options:
        databaseProfile: "informix"  
    
    scenario: "dev"

    logger:
      disable:
        couchdb: true
      transports:
        console:
          level: "info"
          
    globLoader:
      root: "./tests"
      
    browserList :
      chrome: (true)
      #edge: (true)
      #ie: (true)

    dbprofiles:
      informix:         
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
        DBDATE: "MDY4/"

