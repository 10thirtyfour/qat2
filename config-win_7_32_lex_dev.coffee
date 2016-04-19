module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    common:
      timeouts:
        wd: 100000
      options:
        buildMode: "rebuild"
        databaseProfile: "informix"
        env:
          DBDATE: "MDY4/"

    logger:
      disable:
        couchdb: true
      transports:
        console:
          level: "info"

    globLoader:
      root: "./tests"

    tlogLoader:
      disabled: false

    advancedLoader:
      disabled: false

    browserList :
      chrome: (true)
      #firefox: (true)
      #ie: (true)


    dbprofiles:
      informix:
        LYCIA_DB_DRIVER: "informix"
        INFORMIXSERVER: "querix_tcp"
        LOGNAME: "informix"
        INFORMIXPASS: "default2375"
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"

    inetEnvironment:
      QXDEBUG: "zA"

  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
