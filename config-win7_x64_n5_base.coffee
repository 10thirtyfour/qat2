module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    common:
      options:
        databaseProfile: "informix"

    scenario: "default"

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
