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
          
    logger:
      transports:
        console:
          level: "info"
          #couchdb:
          #host: "10.38.57.55"
          
    globLoader:
      root: "./tests"
      
    browserList :
      chrome: (true)
      firefox: (true)

    common:
      timeouts:
        wd: 1200000

   dbprofiles:
      informix:         
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_tcp"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"

