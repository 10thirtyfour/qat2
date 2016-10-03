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

    scenario: "informix_odbc"
