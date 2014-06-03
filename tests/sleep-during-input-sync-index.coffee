module.exports = ->
  @regWD
    syn: ->

      @startApplication "sleep_during_input", "default-1889"
      @justType "hi there fine there"
      @waitIdle(20000)
      el = @formField "f001"
      @assert.equal (@fieldText el), "hi there "
      @assert.equal (@fieldWidth "f004"), 120
      
      
      @assert.equal (@fieldText "f004"), "ine there"
      accept = @toolbutton("Accept")
      @invoke(accept)
      @waitIdle()
      @invoke(accept)
      @waitExit()

