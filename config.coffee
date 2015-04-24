module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,

    environCommands:
      win_ia32: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIA3~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
      win_x64: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIA3~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
      lin_ia32: 'sh -c source /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'
      lin_x64: 'sh -c source /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'

    defaultDeployPath:
      win_ia32: 'C:/ProgramData/Querix/Lycia 6/progs'
      win_x64: 'C:/ProgramData/Querix/Lycia 6/progs'
      lin_ia32: '/opt/Querix/Lycia/progs'
      lin_x64: '/opt/Querix/Lycia/progs'
   
    common:
      timeouts:
        line: 12000
        run: 60000
        compile: 20000
        build: 60000
        wd: 120000
      options:
        buildMode: "rebuild"
        databaseProfile: "informix" 
        env:
          QX_QAT: 1

          DBDATE: "MDY4/"
    headless:
      QX_HEADLESS_MODE: 1  
      QX_REFRESH_LEVEL: 2
    logger:
      transports:
        console:
          level: "info"
          #couchdb:
          #host: "10.38.57.55"
    globLoader:
      root: "./tests2"

    dbprofiles:
      informix:         
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"

      oracle:
        LYCIA_DB_DRIVER: "oracle"
        TNS_ADMIN: "c:\\Oracle"

      "mssql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        SQLSERVER:"DSN=msodbc;Uid=ak2;Pwd=ak2;" 

      "mysql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        ODBC_DSN: "myodbc"


  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"

