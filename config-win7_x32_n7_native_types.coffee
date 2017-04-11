module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    powerOff: true

    common:
      timeouts:
        line: 600000
        run: 600000
        compile: 600000
        build: 600000

      options:
        databaseProfile: "informix" 
        env:
          QX_NATIVE_TYPES_ON: 1
          QX_NATIVE_VARNAMES_OFF: 1
          QX_OPT_LEVEL: 3
          QX_USE_SIMPLE_CACHE_PATH: 1
          QX_VERBOSE_CACHE: 1
          QX_WRAPPER: 1

    headless:
      QX_HEADLESS_MODE: 1  
      QX_REFRESH_LEVEL: 2

    logger:
      disable:
        couchdb:false

    globLoader:
      disable:
        file: 
          pattern: ["**/*-ld-test.coffee","**/*-wd-test.coffee","**/*-qfgl-test.coffee","**/*-qform-test.coffee","**/*-perf-rest.tlog","**/*-webservice-test.coffee"]

    scenario: "QX_NATIVE_TYPES_ON"

    dbprofiles:
      informix:         
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_test"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"