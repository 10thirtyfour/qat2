module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    common:
      options:
        databaseProfile: "informix"

    logger:
      disable:
        couchdb: false

    globLoader:
      disable:
        file:
          pattern: ["**/*-wd-test.coffee"]

    browserList :
      chrome: (false)
      firefox: (false)
      ie: (false)

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "odbc"
        ODBC_DSN: "infodbc"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"

    scenario: "informix_odbc"
