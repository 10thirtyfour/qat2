sizes = [ {w:80,h:22}, {w:200,h:30},{w:100,h:100}, {w:15,h:15}]
forms = {}

for widget,index in formitems().elements
  f = form(testName+"_"+widget).coordpanel().attr(identifier:"rootpanel").size(400,400)
  top = 10
  for {w,h},sizeindex in sizes
    f = f[widget]().size(w,h).at(10,top).attr(background : { fillcolor : { type:"systemcolor", systemColorName:"Purple"}}).up()
    top+=h+10

  forms[widget]=f.up().end()

for widget,f of forms
  Build program().openForm(f).getKey().save(testName+"_"+widget).target 
  RegWD 
    widgetname : widget
    syn : -> 
      @startApplication @lastBuilt
      for {w,h},sizeindex in sizes

        id = @widgetname + (sizeindex+1)
        @check id , w:w, h:h
        #if @elementByCssSelectorIfExists(".qx-identifier-#{id} > *")
        #  @check selector: ".qx-identifier-#{id} > *", w:w, h:h
      @invoke "qx-identifier-accept"
      @waitExit()


