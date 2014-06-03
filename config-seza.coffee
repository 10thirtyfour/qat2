module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    common:
      timeouts:
        line: 12000
        run: 60000
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
          INFORMIXSERVER: "querix_tcp"
          LOGNAME: "informix"
          INFORMIXPASS: "default2375"
          INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client_SDK\\"
          DBDATE: "MDY4/"
          TNS_ADMIN: "c:\\Oracle"
        headless:
          QX_HEADLESS_MODE: 1  

    logger:
      conf:
        transports:
          console:
            level: "trace"
    globLoader:
      root: "c:/temp"
  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "d:\work\selenium-server-standalone-2.39.0.jar"
  @seleniumServerPort = 9515
