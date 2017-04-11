for widget,index in ["scrollbar","slider"]#formitems().widgets
  f = form(testName+"_"+widget+"_form").gridpanel()
  .attr(identifier:"rootpanel")[widget]().val(25).at(1,1).background().up()
  .rows().pixels(200).pixels(200).auto().pixels(200).up()
  .cols().pixels(200).pixels(200).pixels(200).up()
  .up().end()
    
  Build program().openForm(f).getKey().save(testName+"_"+widget).target 
  RegWD 
    widgetname : widget
    #testId: "item_"+widget
    syn : -> 
      @startApplication @lastBuilt
      for i in [0..30]
        @keys @SPECIAL_KEYS['Right arrow']
        @info @getValue @widgetname+"1" 
      @check @widgetname+"1", value:25, orientation:"vertical"
      #@check "scrollbar1", value:25, orientation:"vertical"
      @sleep 5000
      @invoke "qx-identifier-cancel"
      @waitExit()
