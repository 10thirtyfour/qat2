module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,

    common:
      options:
        databaseProfile: "informix"
      timeouts:
        wd: 120000
        wait: 30000

    scenario: "default"

    browserList :
      chrome: (true)
      #firefox: (true)
      edge: (true)
      ie: (true)

    logger:
      disable:
        couchdb: true
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

    #inetEnvironment:
    #  QXDEBUG: "zA"
