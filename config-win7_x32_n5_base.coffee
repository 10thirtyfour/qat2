module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    scenario: "default"

    logger:
      disable:
        couchdb:false

    globLoader:
      root: "./tests"
