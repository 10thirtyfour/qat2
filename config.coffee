module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    version : 3.0
    appHost: "localhost"
    qatDefaultInstance : "default"
    tempPath : "./tests"
    powerOff: false

    environCommands:
      win_ia32: "cmd /c C:\\PROGRA~1\\Querix\\LYCIA3~1.1\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))"
      win_x64: "cmd /c C:\\PROGRA~1\\Querix\\LYCIA3~1.1\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))"
      lin_ia32: 'sh -c source /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'
      lin_x64: 'sh -c source /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'
      dar_x64: 'sh -c source /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'

    defaultDeployPath:
      win_ia32: 'C:/ProgramData/Querix/Lycia/progs'
      win_x64: 'C:/ProgramData/Querix/Lycia/progs'
      lin_ia32: '/opt/Querix/Lycia/progs'
      lin_x64: '/opt/Querix/Lycia/progs'

    defaultAssemblyPath:
      win_ia32: "C:/Program Files/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.5/"
      win_x64:  "C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.5/"

    common:
      timeouts:
        line: 10000
        run: 60000
        compile: 30000
        build: 60000
        wd: 60000
        wait: 10000
        idle: 300

      options:
        buildMode: "build"
        databaseProfile: "informix"
        env:
          QX_QAT: 1
          QX_WRAPPER: 1
          DBDATE: "MDY4/"

    headless:
      QX_HEADLESS_MODE: 1
      QX_REFRESH_LEVEL: 2

    logger:
      transports:
        console:
          level: "info"
        couchdb:
          host: "10.38.57.55"

    globLoader:
      root: "./tests"
      disable:
        file:
          pattern: ["**/*-perf-rest.tlog","**/output/**"]

    browserList :
      chrome: (true)
      edge: (false)
      firefox: (false)
      opera: (false)
      ie: (false)
      safari: (false)

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
        SQLSERVER:"DSN=msodbc;Uid=informix;Pwd=default2375;"

      "mysql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        ODBC_DSN: "myodbc"

      "pgsql-odbc":
        LYCIA_DB_DRIVER: "odbc"

    inetEnvironment:
      inet_var1: "var1_value"
      inet_var1_nested: "inherits_from_%inet_var1%"
