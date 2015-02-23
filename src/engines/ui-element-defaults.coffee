###
# #%L
# QUERIX
# %%
# Copyright (C) 2015 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel : +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
elements = 

  "blob-viewer" :
    qxclass : "qx-aum-blob-viewer"
    get :
      image : (el)-> "return $('.qx-identifier-#{el} .qx-blob-content>img')[0].src"

  "border-panel" :
    qxclass : "qx-aum-border-panel"

  "browser" :
    qxclass : "qx-aum-browser"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} iframe').prop('src')"
    
  "button" :
    qxclass : "qx-aum-button"
    selector : (el)-> "return ($(':not(div.qx-ff-button) > .qx-identifier-#{el}.qx-aum-button').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} .qx-htal>img')[0].src"
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
      defaults :
        width : 1
        chrome$w :
          width : 2

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
        height : 22
        chrome$l:
          height : 21
        
  "combo-box" :
    qxclass : "qx-aum-combo-box"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-combo-content .qx-text').text()"
      defaults :
        height : 22

  "coord-panel" :
    qxclass : "qx-aum-coord-panel"

  "function-field-abs" :
    qxclass : "qx-aum-function-field-abs" 
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-function-field-abs').length > 0)"
    get :
      defaults:
        height : 20
        chrome$l :
          height : 19

  "grid-panel" :
    qxclass : "qx-aum-grid-panel"

  "group-box" :
    qxclass : "qx-aum-group-box"  
    get :
      text : (el) -> "return $('.qx-identifier-#{el} legend').html()"

  "label" :
    qxclass  : "qx-aum-label"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-label').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} img').prop('src')"
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      value : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      defaults :
        height : 22
        chrome$l :
          height : 21
    
  "progress-bar" :
    qxclass : "qx-aum-progress-bar"
    get :
      defaults :
        height : 26.65625
      orientation : (el) -> """
                                if($('div.qx-aum-progress-bar.qx-identifier-#{el}').hasClass('qx-orientation-vertical')) {
                                  return 'vertical';
                                  } 
                                return 'horizontal';
                            """
      value : (el) -> """
                      var obj = $('div.qx-aum-progress-bar.qx-identifier-#{el}');
                      var attr = 'width';
                      if (obj.hasClass('qx-orientation-vertical')) { attr = 'height'; };

                      var logicVal = parseInt("0"+obj.children('div.ui-progressbar').attr('aria-valuenow'));
                      var physicVal = parseInt("0"+obj.find('div > div.ui-progressbar-value')[0].style[attr].slice(0,-1));
                      
                      
                      if(Math.abs(logicVal-physicVal) < 5) { 
                        return logicVal 
                      } else { 
                        return 'Logical (aria-valuenow): '+logicVal+', Visual (.ui-progressbar-value.'+attr+'): '+physicVal;
                      }
                      
                      """


  "radio-button" :
    qxclass : "qx-aum-radio-button"
    get :
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
 
  "radio-button-list" :
    qxclass : "qx-aum-radio-button-list"
    get :
      # Warning!!! Need testing it  
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-aum-radio-button-list-item.qx-active .qx-title-cell.qx-text').html()"

  "radio-button-list-item" :
    qxclass : "qx-aum-radio-button-list-item"
    get :
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-title-cell.qx-text').html()"

  "scroll-bar" :
    qxclass : "qx-aum-scroll-bar"
    get :
      orientation : (el) -> "if($('div.qx-aum-scroll-bar.qx-identifier-#{el}.qx-prop-horizontal').length) {return 'horizontal';}
                             if($('div.qx-aum-scroll-bar.qx-identifier-#{el}.qx-prop-vertical').length) {return 'vertical';}"
      value : (el)->  """
                        var elem = $('div.qx-aum-scroll-bar.qx-identifier-#{el}');
                        var scaleRect = elem.find('div.qx-scb-scell')[0].getBoundingClientRect();
                        var handleRect = elem.find('div.qx-scroll-handler')[0].getBoundingClientRect();
                        if (elem.hasClass('qx-prop-horizontal')) {
                          if (scaleRect.width === handleRect.width) {return 0;}
                          return Math.round(100 * (handleRect.left - scaleRect.left) / (scaleRect.width - handleRect.width));
                        }
                        if (elem.hasClass('qx-prop-vertical')) {
                          if (scaleRect.height === handleRect.height) {return 0;}
                          return Math.round(100 * (handleRect.top - scaleRect.top) / (scaleRect.height - handleRect.height));
                        }
                      """
      defaults : 
        height : 9    
    set :
      value : (el,val) -> 
        # step direction and count must be placed into val property, like 
        # setValue "scrollbar1", smallStep:3
        # setValue "scrollbar1", largeStep:-1
        # numeric value treated as % to drag
        # setValue "scrollbar1", 10
        count=0
        if val.smallStep
          count=Math.abs(val.smallStep)
          selector = 'div.qx-aum-scroll-bar.qx-identifier-'+el+' a.qx-scb-'+ if val.smallStep<0 then 'up' else 'down'
          while count>0
            count-=1
            @invoke selector
            @sleep 100 

        return true
        
   "scroll-viewer" :
    qxclass : "qx-aum-scroll-viewer"

  "slider" :
    qxclass : "qx-aum-slider"
    #get_value returns percent
    get :
      orientation : (el) -> "if($('div.qx-aum-slider.qx-identifier-#{el} > div.ui-slider-horizontal').length) {return 'horizontal';}
                             if($('div.qx-aum-slider.qx-identifier-#{el} > div.ui-slider-vertical').length) {return 'vertical';}"
    
      value : (el) -> "if ($('div.qx-aum-slider.qx-identifier-#{el} > div').hasClass('ui-slider-horizontal')) {
                          return parseInt($('div.qx-aum-slider.qx-identifier-#{el} a')[0].style.left.slice(0,-1)); }
                        if ($('div.qx-aum-slider.qx-identifier-#{el} > div').hasClass('ui-slider-vertical')) {
                        return parseInt($('div.qx-aum-slider.qx-identifier-#{el} a')[0].style.bottom.slice(0,-1));}"
    
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
    get :
      text : (el) -> "return $('div.qx-identifier-#{el} .qx-main-cell > input').val()"
      value: (el) -> "return parseInt('0'+$('div.qx-identifier-#{el} .qx-main-cell > input').val())"
      defaults :
        height : 19
        chrome$l :
          height : 17
    set :
      value : (el,val) ->
        
        
        true

  "tab" :
    qxclass : "qx-aum-tab"
    get :
      value : (el) -> "return $('div.qx-identifier-#{el}.qx-aum-tab li.ui-tabs-active')[0].className.match(/qx-h-identifier-(.*)/)[1]"
    set :
      value : (el,val) -> 
        return @execute "return $('div.qx-identifier-#{el}.qx-aum-tab li.qx-h-identifier-#{val} > .qx-focus-target')[0].click()"
    
  "tab-page" :
    qxclass : "qx-aum-tab-page"
    get :
      text : (el) -> "return $('li.qx-h-identifier-#{el}.qx-h-aum-tab-page > a').text()"
      state : (el) -> "var pageHeader = $('li.qx-h-identifier-#{el}.qx-h-aum-tab-page');
                       if (pageHeader.length == 0 ) { return 'page not found';}
                       if (pageHeader.hasClass('ui-tabs-active')) { return 'active';} else { return 'inactive';}"
    
  "tab-page-header" :
    qxclass : "qx-h-aum-tab-page"
    selector : (el) -> "return false;"
    get :
      image : (el) -> "return $('.qx-h-identifier-#{el} .qx-image')[0].src"

  "table" :
    qxclass : "qx-aum-table"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-table.qx-aum-abstract-data-table').length > 0)"

  "table-column" :
    qxclass : "qx-aum-table-column"
    selector : (el)-> "return ($('.qx-tbody .qx-identifier-#{el}.qx-aum-table-column').length > 0)"
    get :
      text : (el) -> "return $('.qx-tbody .qx-identifier-#{el} a.qx-text').text()"

  "text-area" :
    qxclass : "qx-aum-text-area"
    #get_text : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
    get :
      text: (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      value : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      defaults :
        height : 18
        chrome$l :
          height : 17

  "tree-table" :
    qxclass : "qx-aum-tree-table"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-tree-table.qx-aum-abstract-data-table').length > 0)"

  "text-field" :   
    qxclass : "qx-aum-text-field"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-text-field').length > 0)"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      value : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      defaults :
        height : 18
        chrome$l :
          height : 17
    set :
      value : (el,val)->
        true 
        
  "time-edit-field" :
    qxclass :  "qx-aum-time-edit-field"
    set :
      #Warning!!1 not work 
      value : (el,h,m) -> "return(@execute($('.ui-timepicker-hours .ui-timepicker tbody tr td a')[#{h}].click()).execute($('.ui-timepicker-minutes .ui-timepicker tbody tr td a')[#{m}].click()))"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} input').val()"
      defaults :
        height : 16
        chrome$l :
          height : 15
      
  "toolbar-button" :
    qxclass : "qx-aum-toolbar-button"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      image : (el) -> "return $('.qx-identifier-#{el} .qx-htal>img')[0].src"

  "web-component" :
    qxclass : "qx-aum-web-component"
    get :
      image : (el) -> "return $('iframe.qx-identifier-#{el}').prop('src')"

  "window" :
    qxclass : "qx-aum-window"
    get :
      text : (el) -> "return $('.qx-o-identifier-#{el} span').html()"

  "text-element" :
    qxclass : "qx-text"
    get :
      text : (el) -> "return $('.qx-identifier-#{el}.qx-text').text()"
  
  "unknown" :
    qxclass : "unknown"
    get :
      text : () -> "return;"
      image : () -> "return;"
      value : () -> "return;"
      state : () -> "return;"

for name,item of elements
  item.qxclass   ?= "qx-aum-"+name
  item.selector  ?= (el)-> "return ($('.qx-identifier-#{el}."+@qxclass+"').length > 0)"
  item.get       ?= {}
  item.get.qxclass = item.qxclass 
  item.get.text  ?= (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
  item.get.image ?= (el) -> "return $('.qx-identifier-#{el} .qx-image')[0].src"
  item.get.state ?= (el)-> "if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled).qx-enabled').length > 0) { return 'enabled' }
                   if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled).qx-disabled').length > 0) { return 'disabled' }
                   return $('div."+@qxclass+".qx-identifier-#{el}').attr('class');"
  
  for method of elements.unknown.get
    do =>
      m = method
      item.get[method]?= (el)-> "return 'Warning! id : #{el}, type : #{@qxclass}. get #{m} is not implemented';"

  item.get.default = (attr , platform)->
    if @defaults?
      if platform? and @defaults[platform]?
        def = @defaults[platform][attr]
      def ?= @defaults[attr]  
      return def
module.exports = elements
