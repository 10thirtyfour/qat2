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

    headless:
      QX_HEADLESS_MODE: 1  

    logger:
      disable:
        couchdb: false
      transports:
        console:
          level: "info"
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

      oracle:
        TNS_ADMIN: "c:\\Oracle"

      "mssql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        SQLSERVER:"DSN=msodbc;Uid=ak2;Pwd=ak2;" 

      "mysql-odbc":
        LYCIA_DB_DRIVER: "odbc"
        ODBC_DSN: "myodbc"



