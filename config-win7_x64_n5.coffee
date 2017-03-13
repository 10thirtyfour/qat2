module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: false

    common:
      options:
        databaseProfile: "informix"
        env:
          DBDATE: "MDY4/"
      timeouts:
        wd: 50000
        wait: 10000
        idle: 600


    logger:
      disable:
        couchdb: true
      transports:
        console:
          level: "info"

    globLoader:
      root: "./tests"

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
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
