module.exports = ->
  {_,opts} = @
  _.merge opts,
    environCommand: "cmd /c C:\\PROGRA~2\\Querix\\LYCIA3~1.1\\Lycia\\bin\\environ.bat > nul & node -e console.log(JSON.stringify(process.env))"
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


