module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true
    
    common:
      options:
        databaseProfile: "informix"

    scenario: "default"

    browserList :
      chrome: (true)
      edge: (true)

    common:
      timeouts:
        wd: 120000
        wait: 30000

    logger:
      disable:
        couchdb: false
      transports:
        console:
          level: "info"
    globLoader:
      root: "./tests"

    defaultAssemblyPath:
      win_ia32: "C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.6.1/"
      win_x64:  "C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.6.1/"

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
        DBDATE: "MDY4/"
