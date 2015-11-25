# transformWindow sample program
# transformWindow accepts an object argument with following properties :
#  name : "window name"
#  move : [ x,y ] an array with coords
#  resize : [ w,h ] an array with dimensions or following values :
#  "min", "max", "normal"

#
#  .transformWindow( name : "w", move : [100,200], resize : [ 400, 400 ] )
#  .transformWindow( name : "w", move : [100,200] )
#  .transformWindow( name : "w", resize : [ 400, 400 ] )
#  .transformWindow( name : "w", resize : "max" )
#
# name property can be omitted! In this case it will be acquired 
# from previous function (currently only waitWindow, transformWindow is supported)
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
    .delay(2000)
    .transformWindow( resize : "max" )
    .delay(2000)
    .transformWindow( resize : [ 600, 600 ] )
    .delay(2000)
    .transformWindow( resize : "min" )
    .delay(2000)
    .transformWindow( move : [100,200], resize : [ 700, 400 ] )
    .delay(2000)
    .transformWindow( resize : "normal" )
    .delay(2000)
    .transformWindow( move : [800,600], resize : [ 50, 50 ] )
    .delay(2000)

    .done()
