f = form().coordpanel().size(300,300)
  .spinner().at(20,10).size(200,12).range(0,100).up()
  #.spinner().at(20,50).size(200,20).up()
  #.spinner().at(20,90).size(200,30).up()
  #.spinner().at(20,130).size(200,50).up()
  .up().end()
  
ptarget = program().openForm(f).command('MESSAGE formonly1.spinner1').getKey().save().target

Build ptarget

RegWD -> 
  @startApplication @lastBuilt
  @justType "9999"
  @invokeElement "accept"
  @check "statusbarmessage", text: "100"
  @waitExit()

