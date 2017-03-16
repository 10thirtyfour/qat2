module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: false
    input: true

    common:
      timeouts:
        wd: 100000
      options:
        buildMode: "build"
        databaseProfile: "informix"
        env:
          DBDATE: "MDY4/"

    logger:
      disable:
        couchdb: true
      transports:
        console:
          level: "info"

    defaultAssemblyPath:
      win_ia32: "C:/Program Files/Reference Assemblies/Microsoft/Framework/.NETFramework/v4.6/"

    globLoader:
      root: "./tests"

    tlogLoader:
      disabled: false

    advancedLoader:
      disabled: false

    browserList :
      chrome: (true)
      opera: (false)

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"

    inetEnvironment:
      QXDEBUG: "zA"
