elements = 

  "blob-viewer" :
    qxclass : "qx-aum-blob-viewer"
    get :
      image : (el)-> "return $('.qx-identifier-#{el} .qx-blob-content>img')[0].src"

  "browser" :
    qxclass : "qx-aum-browser"
    get :
      image : (el) -> "return $('.qx-identifier-#{el}').prop('src')"
    
  "button" :
    qxclass : "qx-aum-button"
    selector : (el)-> "return ($(':not(div.qx-ff-button) > .qx-identifier-#{el}.qx-aum-button').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} .qx-tal>img')[0].src"
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
    defaults :
      height : 24
      chrome$l:
        height : 23
    
  "calendar" :
    qxclass : "qx-aum-calendar"
    get :
      image : (el)-> "return $('.qx-identifier-#{el} img')[0].src"
      text : (el)-> "return $('.qx-identifier-#{el} input').val()"
      
    #defaults :
    #  width : 1
    #  chrome$w :
    #    width : 2

  "canvas" :
    qxclass : "qx-aum-canvas"
    get :
      image : (el) -> "return $('.qx-identifier-#{el}').prop('src')"

  "check-box" :
    qxclass : "qx-aum-check-box"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} label').text()"
      value : (el) -> "var cb = $('.qx-identifier-#{el} input');
                        if (cb.prop('indeterminate')) {return 'indeterminate';} 
                        if (cb.prop('checked')) {return 'checked';}
                        if (typeof cb.prop('checked') == 'undefined') {return false;}
                        return 'unchecked';"
    defaults :
      height : 16
      chrome$l:
        height : 15
        
  "combo-box" :
    qxclass : "qx-aum-combo-box"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 22
      
  "function-field-abs" :
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-function-field-abs').length > 0)"
    qxclass : "qx-aum-function-field-abs" 
    defaults:
      height : 24
      chrome$l :
        height : 23
    
  "group-box" :
    qxclass : "qx-aum-group-box"  
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"

  "label" :
    qxclass  : "qx-aum-label"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} img').prop('src')"
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 23
      chrome$l :
        height : 21
    
  "progress-bar" :
    qxclass : "qx-aum-progress-bar"
    defaults :
      height : 26.65625

  "scroll-bar" :
    qxclass : "qx-aum-scroll-bar"
    defaults : 
      height : 9    
      
  "slider" :
    qxclass : "qx-aum-slider"
    #get_value returns percent
    get :
      value : (el) -> "if ($('div.qx-aum-slider.qx-identifier-#{el} > div').hasClass('ui-slider-horizontal')) {
                          return $('div.qx-aum-slider.qx-identifier-#{el} a')[0].style.left.slice(0,-1) }
                        if ($('div.qx-aum-slider.qx-identifier-#{el} > div').hasClass('ui-slider-vertical')) {
                        return $('div.qx-aum-slider.qx-identifier-#{el} a')[0].style.bottom.slice(0,-1) }"
    
      state : (el) -> "if ($('div.qx-aum-slider.qx-enabled.qx-identifier-#{el}:not(.qx-disabled) > 
                              div:not(.ui-state-disabled):not(.ui-slider-disabled)').length > 0) { return 'enabled' }
                      if ($('div.qx-aum-slider.qx-disabled.qx-identifier-#{el}:not(.qx-enabled) > 
                              div.ui-state-disabled.ui-slider-disabled').length > 0) { return 'disabled' }                               
                      return $('div.qx-aum-slider.qx-identifier-#{el}').attr('class');"
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

  "tab" :
    qxclass : "qx-aum-tab"
    get :
      value : (el) -> "return $('div.qx-identifier-#{el}.qx-aum-tab li.ui-tabs-active')[0].className.match(/qx-h-identifier-(.*)/)[1]"
    set :
      value : (el,val) -> 
        return @execute "return $('div.qx-identifier-#{el}.qx-aum-tab li.qx-h-identifier-#{val} > .qx-focus-target')[0].click()"
    
  "tab-page" :
    qxclass : "qx-aum-tab-page"
    
  "tab-page-header" :
    qxclass : "qx-h-aum-tab-page"
    selector : (el) -> "return false;"
    get :
      image : (el) -> "return $('.qx-h-identifier-#{el} .qx-image')[0].src"

  "text-area" :
    qxclass : "qx-aum-text-area"
    #get_text : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    defaults :
      height : 22
      chrome$l :
        height : 21

  "text-field" :   
    qxclass : "qx-aum-text-field"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
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
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      image : (el) -> "return $('.qx-identifier-#{el} .qx-htal>img')[0].src"

  "unknown" :
    qxclass : "unknown"
    get :
      text : () -> "return;"
      image : () -> "return;"
      value : () -> "return;"
      state : () -> "return;"


getState = 
      
      
for name,item of elements
  item.qxclass   ?= "qx-aum-"+name
  item.selector  ?= (el)-> "return ($('.qx-identifier-#{el}."+@qxclass+"').length > 0)"
  item.get       ?= {}
  item.get.qxclass = item.qxclass 
  item.get.state ?= (el)-> "if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled).qx-enabled').length > 0) { return 'enabled' }
                   if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled).qx-disabled').length > 0) { return 'disabled' }
                   return $('div."+@qxclass+".qx-identifier-#{el}').attr('class');"
  
  for method of elements.unknown.get
    item.get[method]?= (el)-> "return 'Warning! id : #{el}, type : #{@qxclass}. get #{method} is not implemented';"

  item.get.default = (attr , platform)->
    if @defaults?
      if platform? and @defaults[platform]?
        def = @defaults[platform][attr]
      def ?= @defaults[attr]  
      return def
module.exports = elements
