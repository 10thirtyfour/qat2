module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    environCommand: "cmd /c C:\\PROGRA~1\\Querix\\LYCIA3~1.1\\Lycia\\bin\\environ.bat > nul & node -e console.log(JSON.stringify(process.env))"
    common:
      options:
        buildMode: "rebuild"
        databaseProfile: "informix" 
        env:
          QX_QAT: 1
          DBDATE: "MDY4/"
    logger:
      disable:
        couchdb: true

      transports:
        console:
          level: "info"
        couchdb:
          host: "10.38.57.55"
    globLoader:
      root: "./temp"
    dbprofiles:
      informix:
        INFORMIXDIR: "C:\\Program Files\\IBM\\Informix\\Client-SDK\\"


