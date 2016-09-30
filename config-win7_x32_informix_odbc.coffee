module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    common:
      options:
        databaseProfile: "informix-odbc"

    logger:
      disable:
        couchdb: false

    globLoader:
      disable:
        file:
          pattern: ["**/*-wd-test.coffee","**/*-mssql-odbc-db-rest.tlog","**/*-mysql-odbc-db-rest.tlog","**/*-pgsql-odbc-db-rest.tlog","**/*-oracle-db-rest.tlog"]

    browserList :
      chrome: (false)
      firefox: (false)
      ie: (false)

    scenario: "informix_odbc"
