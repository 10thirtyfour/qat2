# Scrollbar test demo
# You ought to add -demo.coffee pattern to globloader

f = form("form_1").gridpanel()
.scrollbar().val(25).at(1,1).background().up()
.rows().pixels(200).pixels(200).auto().pixels(200).up()
.cols().pixels(200).pixels(200).pixels(200).up()
.up().end()
    
Build program().openForm(f).getKey().save(testName+"1").target 
RegWD ->
  @startApplication @lastBuilt
  for i in [0..30]
    @keys @SPECIAL_KEYS['Right arrow']
    @info @getValue "scrollbar1" 
  @check "scrollbar1", value:25, orientation:"vertical"
  @invoke "qx-identifier-cancel"
  @waitExit()


f = form("form_2").gridpanel()
.scrollbar().attr(orientation:"Vertical").val(25).at(1,1).background().up()
.rows().pixels(200).pixels(200).auto().pixels(200).up()
.cols().pixels(200).pixels(200).pixels(200).up()
.up().end()

Build program().openForm(f).getKey().save(testName+"2").target 
RegWD ->
  @startApplication @lastBuilt
  for i in [0..30]
    @keys @SPECIAL_KEYS['Down arrow']
    @info @getValue "scrollbar1" 
  @check "scrollbar1", value:25, orientation:"vertical"
  @invoke "qx-identifier-cancel"
  @waitExit()
