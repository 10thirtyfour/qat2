module.exports = 
  widgets : 
    "function-field-abs" : {}
    "calendar" :
      text : (el) -> @execute("return $('.qx-identifier-#{el} input').val()")
    "text-field" :
      text : (el) -> @execute("return $('.qx-identifier-#{el} .qx-text').text()")
    "button" :
      text : (el) -> @execute("return $('.qx-identifier-#{el} .qx-text').html()")
      image : (el) -> @execute("return $('.qx-identifier-#{el} .qx-image-cell img')[0].src")
    "browser" :
      image : (el) -> @execute("return $('.qx-identifier-#{el}').attr('src')")
    "toolbar-button" :
      text : (el) -> @execute("return $('.qx-identifier-#{el} .qx-text').html()")
    "check-box" :
      text : (el) -> yp(@execute("return $('.qx-identifier-#{el} label').text()"))
      value : (el) ->
        if yp(@execute("return $('.qx-identifier-#{el} input').prop('indeterminate')")) then return "indeterminate"
        if yp(@execute("return $('.qx-identifier-#{el} input').prop('checked')")) then return "checked"
        if (yp(@execute("return $('.qx-identifier-#{el} input').prop('checked')")))? then return "unchecked"
        false
    "canvas" :
      image : (el) -> @execute("return $('.qx-identifier-#{el}').attr('src')")
    "browser" :
      text : (el) -> @execute("return $('.qx-identifier-#{el}').attr('src')")
    "spinner" : {}
    "text-area" : {}
    "slider" : {}
    "scroll-bar" : {}
    "time-edit-field" : {}
  

  
