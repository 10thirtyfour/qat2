module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    common:
      options:
        databaseProfile: "informix"  
    
    scenario: "default"

    logger:
      transports:
        console:
          level: "info"
        couchdb:
          host: "10.38.57.55"
    globLoader:
      root: "./tests"

    dbprofiles:
      informix:         
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
        DBDATE: "MDY4/"


  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "d:\work\selenium-server-standalone-2.39.0.jar"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
  @deployPath = "C:/ProgramData/Querix/Lycia 7/progs"

