module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,


    scenario: "default"
 
    logger:
      disable:
        couchdb:false

    globLoader:
      root: "./tests"

