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

    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM Informix Client SDK\\"
