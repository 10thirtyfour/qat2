#Build project: "c:/qat/tests/other-demos/form_demo" ,deploy:true
#RegWD ->
#  @startApplication "form_demo/fm_attribute_action"
#  @checkSize "qx-ident-accept",76,27
#  el=@formField "accept"
#  @checkSize el,76,27
#      
#  #@checkActionToolbar defaultKeys : ["Accept","Cancel"]
#  #@invoke(accept)
#  #@waitExit()

