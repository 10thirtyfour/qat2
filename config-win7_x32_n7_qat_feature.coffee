module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,


    scenario: "qat_feature"

    notes: "!!! its an internal test suite for testing new features"

    logger:
      disable:
        couchdb:false

    globLoader:
      root: "./tests"

