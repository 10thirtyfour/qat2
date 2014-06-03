module.exports = ->
  @regWD
    promise: (browser) ->
      browser
        .startApplication("sleep_during_input","UI_tests")
        .justType("hi there fine there")
        .waitIdle(10000)
        .fieldText("f001")
          .should.eventually.equal("hi there ")
        .formField("f004")
        .then((el) -> browser.fieldText(el))
          .should.eventually.equal("ine there")
        .toolbutton("Accept")
        .then((el) -> browser.invoke(el)
          .waitIdle().invoke(el))
        .waitExit()
