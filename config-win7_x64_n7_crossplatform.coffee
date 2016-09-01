module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    scenario: "crossbrowsers"
    common:
      options:
        databaseProfile: "informix"
        env:
          DBDATE: "MDY4/"

    logger:
      disable:
        couchdb: false
      transports:
        console:
          level: "info"

    globLoader:
      root: "./tests"

    browserList :
      chrome: (true)
      firefox: (true)
      opera: (true)
      ie: (false)
      edge: (false)

    common:
      timeouts:
        wd: 120000
        wait: 30000

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
        DBDATE: "MDY4/"
