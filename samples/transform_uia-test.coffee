# transformWindow sample program
# transformWindow accepts an object argument with following properties :

RegLD ->
  @runProgram("04_input_by_name")
  w = @waitWindow( name : "w" )
  @delay 1000
  w.move( 500, 500 ).resize( 500,500 )
  log @getConsoleText()
  @delay 2000
  w.resize("max")
  @delay 1000

  ww = @getWindows()
  if ww.length>1
    ww[0].close()
    ww[1].resize("max")
  #w.close()
  #@closeWindow("w")
