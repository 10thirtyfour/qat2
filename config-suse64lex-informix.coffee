module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    common:
      options:
        databaseProfile: "informix" 
    logger:
      disable:
        couchdb: false

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

