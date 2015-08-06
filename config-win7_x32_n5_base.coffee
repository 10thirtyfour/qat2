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

  @lyciaWebUrl = "http://localhost:9090/LyciaWeb/"
  @pathToSeleniumJar = "x:\qat\selenium-server-standalone-2.46.0.jar"
  @seleniumServerPort = 9515
  @qatDefaultInstance = "default-1889"
  @tempPath = "./tests"
  @deployPath = "C:/ProgramData/Querix/Lycia 7/progs"