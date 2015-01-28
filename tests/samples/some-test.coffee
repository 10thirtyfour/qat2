throw new Error "Skipping this file"
forms = {}
for w in ["textfield","combobox"]
  forms[w] = form(w).gridpanel()[w]().at(0,0).up()
    .rows().auto().auto().auto().up()
    .cols().auto().auto().auto().up()
    .up().end()
target = program( ).openForm(forms["textfield"]).save().target
Build target
RegWD ->
  @startApplication @lastBuilt
  @sleep 10000
  @waitExit()
  

    
