module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
    logger:
      conf:
        transports:
          console:
            level: "trace"
    globLoader:
      root: "C:/work/qat/tests"
  @lyciaWebUrl = "http://localhost:8080/LyciaWeb/index.html"
  @pathToSeleniumJar = "C:\bin\selenium\selenium-server-standalone-2.39.0.jar"
  @seleniumServerPort = 4444
