module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,

    appHost: "10.38.57.170"

    common:
      options:
        databaseProfile: "informix"

    globLoader:
      only:
        file:
          pattern: "**/*+(-wd-test|-qbuild-test).+(tlog|coffee)"

    common:
      timeouts:
        wd: 300000
        wait: 60000
        idle: 2000

    browserList :
      chrome: (false)
      edge: (false)
      firefox: (false)
      opera: (false)
      ie: (false)
      safari: (true)

    logger:
      disable:
        couchdb: false
      transports:
        couchdb:
          host: "10.38.57.55"

    dbprofiles:
      informix:
          LYCIA_DB_DRIVER: "informix"
          INFORMIXSERVER: "querix_test"
          LOGNAME: "informix"
          INFORMIXPASS: "default2375"
          INFORMIXDIR: "/opt/IBM/informix"
          DBDATE: "MDY4/"
          LD_LIBRARY_PATH: "/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:/opt/Querix/Lycia/lib:/opt/Querix/Lycia/axis2/lib:/opt/Querix/Common/lib:/opt/Querix/lycia-desktop:/usr/lib64/jvm/jdk1.8.0_25/jre/lib/amd64/server:"

    inetEnvironment:
      inet_var1: "var1_value"
      inet_var1_nested: "inherits_from_%inet_var1%"
      CLASSPATH: "$CLASSPATH$;home/informix/qat/utils/InformixJdbcDriver/ifxjdbc.jar"

    scenario: "safari"
    build: "last_build"
    skip_lycia: true
