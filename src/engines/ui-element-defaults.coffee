elements = 

  "blob-viewer" :
    qxclass : "qx-aum-blob-viewer"
    getImage : (el)-> "return $('.qx-identifier-#{el} .qx-blob-content>img')[0].src"

  "browser" :
    qxclass : "qx-aum-browser"
    getImage : (el) -> "return $('.qx-identifier-#{el}').prop('src')"
    
  "button" :
    qxclass : "qx-aum-button"
    selector : (el)-> "return ($(':not(div.qx-ff-button) > .qx-identifier-#{el}.qx-aum-button').length > 0)"
    getImage : (el) -> "return $('.qx-identifier-#{el} .qx-tal>img')[0].src"
    getText : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
    defaults :
      height : 25
      chrome$l:
        height : 23
    
  "calendar" :
    qxclass : "qx-aum-calendar"
    getImage : (el)-> "return $('.qx-identifier-#{el} img')[0].src"
    getText : (el)-> "return $('.qx-identifier-#{el} input').val()"
    #defaults :
    #  width : 1
    #  chrome$w :
    #    width : 2

  "canvas" :
    qxclass : "qx-aum-canvas"
    getImage : (el) -> "return $('.qx-identifier-#{el}').prop('src')"

  "check-box" :
    qxclass : "qx-aum-check-box"
    getText : (el) -> "return $('.qx-identifier-#{el} label').text()"
    getValue : (el) -> "var cb = $('.qx-identifier-#{el} input');
                        if (cb.prop('indeterminate')) {return 'indeterminate';} 
                        if (cb.prop('checked')) {return 'checked';}
                        if (typeof cb.prop('checked') == 'undefined') {return false;}
                        return 'unchecked';"
    defaults :
      height : 16
      chrome$l:
        height : 15
      
  "function-field-abs" :
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-function-field-abs').length > 0)"
    qxclass : "qx-aum-function-field-abs" 
    defaults:
      height : 24
    
  "group-box" :
    qxclass : "qx-aum-group-box"  
    getText : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"

  "label" :
    qxclass  : "qx-aum-label"
    getImage : (el) -> "return $('.qx-identifier-#{el} img').prop('src')"
    getText  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 23
      chrome$l :
        height : 21
    
  "progress-bar" :
    qxclass : "qx-aum-progress-bar"
    defaults :
      height : 27
      chrome$l :
        height : 27

  "scroll-bar" :
    qxclass : "qx-aum-scroll-bar"
    defaults : 
      height : 9    
      
  "slider" :
    qxclass : "qx-aum-slider"
    defaults : 
      height : 16
      chrome$l :
        height : 15
    
  "spinner" :
    qxclass  : "qx-aum-spinner"
    defaults :
      height : 19
      chrome$l :
        height : 17
      
  "tab-page-header" :
    qxclass : "qx-h-aum-tab-page"
    getImage : (el) -> "return $('.qx-h-identifier-#{el} .qx-image')[0].src"

  "text-area" :
    qxclass : "qx-aum-text-area"
    #getText : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 22
      chrome$l :
        height : 21
    
  "text-field" :   
    qxclass : "qx-aum-text-field"
    getText : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 22
      chrome$l :
        height : 21

  "time-edit-field" :
    qxclass :  "qx-aum-time-edit-field"
    defaults :
      height : 17
      chrome$l :
        height : 15
      
  "toolbar-button" :
    qxclass : "qx-aum-toolbar-button"
    getText : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
    getImage : (el) -> "return $('.qx-identifier-#{el} .qx-tal>img')[0].src"

  "unknown" :
    qxclass : "unknown"

      
for name,item of elements
  item.qxclass  ?= "qx-aum-"+name
  item.selector ?= (el)-> "return ($('.qx-identifier-#{el}."+@qxclass+"').length > 0)"
  item.getText  ?= (el)-> "return 'Warning! id : #{el}, type : #{@qxclass}. getText is not implemented';"
  item.getValue ?= (el)-> "return 'Warning! id : #{el}, type : #{@qxclass}. getValue is not implemented';"
  item.getImage ?= (el)-> "return 'Warning! id : #{el}, type : #{@qxclass}. getImage is not implemented';"
  item.getDefault = (attr , platform)->
    if @defaults?
      if platform? and @defaults[platform]?
        def = @defaults[platform][attr]
      def ?= @defaults[attr]  
      return def
module.exports = elements