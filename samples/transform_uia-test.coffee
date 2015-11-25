# transformWindow sample program
# transformWindow accepts an object argument with following properties :
#  name : "window name"
#  move : [ x,y ] an array with coords
#  resize : [ w,h ] an array with dimensions
#
#  .transformWindow( name : "w", move : [100,200], resize : [ 400, 400 ] )
#  .transformWindow( name : "w", move : [100,200] )
#  .transformWindow( name : "w", resize : [ 400, 400 ] )
#
# name property can be omitted! In this case it will be acquired 
# from previous function (currently only waitWindow is supported)
#
#  .waitWindow( name : "w" )
#  .transformWindow( move : [100,200], resize : [ 400, 400 ] )
#
# WARNING! Problems may occure due to immediate invocation of transformWindow
# after waitWindow. Window content may not be ready and will not be resized.
# At least 1000ms delay is recommended. Delay passes value though so following code works fine
#
#  .waitWindow( name : "w" )
#  .delay(1000)
#  .transformWindow( move : [100,200], resize : [ 400, 400 ] )



reg
  data:
    kind : "uia"
  promise : ->
    runner.uia()
    .runProgram("04_input_by_name.exe")
    .waitWindow( name : "w" )
    .delay(1000)
    .transformWindow( move : [100,200], resize : [ 700, 400 ] )
    .delay(5000)
    .done()
