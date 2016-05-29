module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,

    environCommands:
      lin_ia32: 'sh -c . /opt/Querix/Lycia/environ ; sleep 1; export LD_LIBRARY_PATH=/opt/IBM/informix/lib:/opt/IBM/informix/lib/esql:$LD_LIBRARY_PATH ; node -e "console.log(JSON.stringify(process.env))"'

    common:
      timeouts:
        build: 120000
        wd: 180000
        wait: 40000
        idle: 500
      options:
        databaseProfile: "informix"

    globLoader:
      disable:
        file:
          pattern: ["**/*-perf-rest.tlog"]
    browserList :
      chrome: (false)
      firefox: (true)

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

    scenario: "default"
