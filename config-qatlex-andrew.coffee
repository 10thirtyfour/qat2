module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    common:
      timeouts:
        line: 12000
        run: 60000
        compile: 20000
        build: 60000
        download: 600000
        unzip: 180000
        install: 600000
      options:
        buildMode: "rebuild"
        env:
          QX_QAT: 1
        commondb:
          LYCIA_DB_DRIVER: "informix"
          INFORMIXSERVER: "querix_test"
          LOGNAME: "informix"
          INFORMIXPASS: "default2375"
          INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"
          DBDATE: "MDY4/"
          TNS_ADMIN: "c:\\Oracle"
          QX_REFRESH_LEVEL: 2
          #LYCIA_LEAVE_WS: 1
        headless:
          QX_HEADLESS_MODE: 1  
    logger:
      transports:
        console:
          level: "info"
        couchdb:
          host: "10.38.57.55"
    globLoader:
      root: "./tests"

  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "d:\work\selenium-server-standalone-2.39.0.jar"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
  @deployPath = "C:/ProgramData/Querix/Lycia 6/progs"