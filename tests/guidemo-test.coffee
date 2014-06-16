Build("guidemo3","D:/workspace/guidemo3-2014")
RegWD
  syn: ->
    @startApplication "guidemo3/guidemo3", "default-1889"
    ex = @formField("actexit")
    @invoke(ex)
    @waitExit()
