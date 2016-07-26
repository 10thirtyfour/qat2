module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    scenario: "Crossbrowsers"
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
