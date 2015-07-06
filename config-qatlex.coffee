module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
 
    logger:
      transports:
        couchdb:
          host: "10.38.57.55"
    globLoader:
      root: "./tests"

  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "x:\qat\selenium-server-standalone-2.46.0.jar"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
  @deployPath = "C:/ProgramData/Querix/Lycia 7/progs"