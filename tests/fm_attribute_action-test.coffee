#Build project:"D:/workspace/form_demo" ,deploy:true
RegWD ->
  @startApplication "form_demo/fm_attribute_action"
  @checkSize "qx-ident-accept",76,27
  el=@formField "accept"
  @checkSize el,76,27
  #@invoke "scroll-right"
  #@invoke "scroll-right"
      
  #@checkActionToolbar defaultKeys : ["Accept","Cancel"]
  #@invoke(accept)
  #@waitExit()

