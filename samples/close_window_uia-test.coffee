# closeWindow example
# closeWindow method can be used in various cases :

# close ALL windows with title "title"
#   .closeWindow("Lycia Console")
# or 
#   .closeWindow( name : "Lycia Console" )

# close ALL windows with listed titles
#   .closeWindow(["Lycia Console","window1"])
# or 
#   .closeWindow([{name : "Lycia Console"},{ name : "window1" }])
# 
# so output of "getWindows" or "waitWindow" method can be used as input :
#   .getWindows().closeWindow()
#   .waitWindow("w").closeWindow()

# do not use closeWindow

reg
  data:
    kind : "uia"
  promise : ->
    runner.uia()
    #.closeWindow("Lycia Console")
    #.closeWindow(["w","Lycia Console"])
    #.closeWindow( name : "w" )
    .getWindows()
    .closeWindow()
    .done()
