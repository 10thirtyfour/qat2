throw "skip"
# Created by SeZa 
# 2 Feb 2015

# Programs created :
# form_preferred_size_stretch-formbuild-layout0
# form_preferred_size_stretch-formbuild-layout1
# form_preferred_size_stretch-formbuild-layout2

forms = []
forms.push form(testName+forms.length).gridpanel().size(300,300)
  .textfield().size(350,350).at(0,0).up()
  .rows().auto().up()
  .cols().auto().up()
  .up().end()

forms.push form(testName+forms.length).gridpanel().size(300,300)
  .textfield().at(0,0).up()
  .rows().pixels(350).up()
  .cols().pixels(350).up()
  .up().end()

forms.push form(testName+forms.length).gridpanel().size(330,330).border(10)
  .textfield().at(0,0).up()
  .rows().pixels(330).up()
  .cols().pixels(330).up()
  .up().end()


for f,index in forms
  Build program().openForm(f).save(testName+index).target
  RegWD -> 
    @startApplication @lastBuilt
    @check @lastBuilt, width:350, height:350
    @check "textfield1", width:350, height:350
    @invokeElement "accept"
    @waitExit()



