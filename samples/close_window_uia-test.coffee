# closeWindow example
# closeWindow method can be used in various cases :

# close ALL windows with title "title"

RegLD ->
  @closeWindow("Lycia Console")
  @closeWindow(["w","Lycia Console"])
  @closeWindow( name : "w" )
  @closeWindow( @getWindows() )
  w = @waitWindow( name : "w" )
  w.close()