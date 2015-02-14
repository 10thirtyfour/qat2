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
        databaseProfile: "informix" 
        env:
          QX_QAT: 1
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

    dbprofiles:
      informix:         
          LYCIA_DB_DRIVER: "informix"
          INFORMIXSERVER: "querix_test"
          LOGNAME: "informix"
          INFORMIXPASS: "default2375"
          INFORMIXDIR: "/opt/IBM/informix"
          DBDATE: "MDY4/"
          LD_LIBRARY_PATH: "/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:/opt/Querix/Lycia/lib:/opt/Querix/Lycia/axis2/lib:/opt/Querix/Common/lib:/opt/Querix/lycia-desktop:/usr/lib64/jvm/jdk1.8.0_25/jre/lib/amd64/server:"

      oracle:
        TNS_ADMIN: "c:\\Oracle"

      "mssql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        SQLSERVER:"DSN=msodbc;Uid=ak2;Pwd=ak2;" 

      "mysql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        ODBC_DSN: "myodbc"


  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "d:\work\selenium-server-standalone-2.39.0.jar"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
  @deployPath = "/opt/Querix/Lycia/progs"

