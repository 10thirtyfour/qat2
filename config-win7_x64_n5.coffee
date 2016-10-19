module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: false

    scenario: "firefox"
    common:
      options:
        databaseProfile: "informix"
        env:
          DBDATE: "MDY4/"

    logger:
      disable:
        couchdb: true
      transports:
        console:
          level: "info"

    globLoader:
      root: "./tests"

    browserList :
      chrome: (false)
      opera: (true)
      firefox: (true)
      edge: (false)
      ie: (false)
      safari : (false)

    common:
      timeouts:
        wd: 50000
        wait: 10000

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
        DBDATE: "MDY4/"
