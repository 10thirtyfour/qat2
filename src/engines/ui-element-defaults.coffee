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
      value : (el) -> "return $('.qx-identifier-#{el} .qx-htal>img')[0].src"
      state : (el) -> "if ($('div.qx-aum-button.qx-active.qx-not-readonly.qx-identifier-#{el}
                       :not(.qx-disabled):not(.ui-state-disabled):not(.qx-inactive):not(.qx-readonly)').length > 0) { return 'enabled' }
                      if ($('div.qx-aum-button.qx-disabled.qx-inactive.qx-readonly.ui-state-disabled.qx-identifier-#{el}
                        :not(.qx-enabled):not(.qx-active):not(.qx-not-readonly)').length > 0) { return 'disabled' }
                      return $('div.qx-aum-button.qx-identifier-#{el}').attr('class');"
      defaults :
        height : 20
        chrome$l :
          height : 20

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
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      value : (el) -> "var cb = $('.qx-identifier-#{el} input');
                        if (cb.prop('indeterminate')) {return 'indeterminate';}
                        if (cb.prop('checked')) {return 'checked';}
                        if (typeof cb.prop('checked') == 'undefined') {return false;}
                        return 'unchecked';"
      defaults :
        height : 24
        firefox$w:
          height : 22
        chrome$l:
          height : 22

  "combo-box" :
    qxclass : "qx-aum-combo-box"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} div.qx-text').text()"
      defaults :
        height : 18

  "coord-panel" :
    qxclass : "qx-aum-coord-panel"

  "function-field-abs" :
    qxclass : "qx-aum-function-field-abs"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-function-field-abs').length > 0)"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} div .qx-text').text()"
      defaults :
        height : 20
        chrome$l :
          height : 20

  "grid-panel" :
    qxclass : "qx-aum-grid-panel"

  "group-box" :
    qxclass : "qx-aum-group-box"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-groupbox-header .qx-text').html()"

  "label" :
    qxclass  : "qx-aum-label"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-label').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} img').prop('src')"
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      value : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      defaults :
        height : 24
        firefox$w :
          height : 22
        chrome$l :
          height : 22

  "list-box" :
    qxclass : "qx-aum-list-box"
    get :
      state : (el) -> "if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled' }
                   if ($('div."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled' }
                   return $('div."+@qxclass+".qx-identifier-#{el}').attr('class');"
      text : (el) -> "return $('.qx-identifier-#{el} option').text()"

  "menu-command" :
    qxclass  : "qx-aum-menu-command"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-menu-command').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} .qx-image')[0].src"
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      state : (el) -> "if ($('li."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled' }
                   if ($('li."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled' }
                   return $('li."+@qxclass+".qx-identifier-#{el}').attr('class');"
  "menu-group" :
    qxclass  : "qx-aum-menu-group"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-menu-group').length > 0)"
    get :
      image : (el) -> "return $('.qx-identifier-#{el} .qx-image')[0].src"
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      state : (el) -> "if ($('li."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled' }
                   if ($('li."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled' }
                   return $('li."+@qxclass+".qx-identifier-#{el}').attr('class');"

  "menu-separator" :
    qxclass  : "qx-aum-menu-separator"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-menu-separator').length > 0)"

  "place-holder" :
    qxclass : "qx-aum-place-holder"

  "progress-bar" :
    qxclass : "qx-aum-progress-bar"
    get :
      defaults :
        height : 20
        chrome$l :
          height : 20
      orientation : (el) -> """
                                if($('div.qx-aum-progress-bar.qx-identifier-#{el}').hasClass('qx-vertical')) {
                                  return 'vertical';
                                  }
                                return 'horizontal';
                            """
      value : (el) -> """
                      var obj = $('div.qx-aum-progress-bar.qx-identifier-#{el}');
                      var attr = 'width';
                      if (obj.hasClass('qx-vertical')) { attr = 'height'; };

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
      value : (el) -> "var rb = $('.qx-identifier-#{el} input');
                        if (rb.prop('checked') == true) {return 'checked';}
                        else if (rb.prop('checked') == false) {return 'unchecked';}"
      defaults :
        height : 24
        ie$w :
          height : 23
        firefox$w :
          height : 20
        chrome$l :
          height : 22

  "radio-button-list" :
    qxclass : "qx-aum-radio-button-list"
    get :
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text').text()"
      state : (el)-> "if ($('ul."+@qxclass+".qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled' }
                   if ($('ul."+@qxclass+".qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled' }
                   return $('ul."+@qxclass+".qx-identifier-#{el}').attr('class');"

  "radio-button-list-item" :
    qxclass : "qx-aum-radio-button-list-item"
    get :
      text  : (el) -> "return $('.qx-identifier-#{el} .qx-text-cell.qx-text').html()"
      value : (el) -> "var rb = $('.qx-identifier-#{el} input');
                        if (rb.prop('checked') == true) {return 'checked';}
                        else if (rb.prop('checked') == false) {return 'unchecked';}"

  "separator" :
    qxclass : "qx-aum-separator"

  "scroll-bar" :
    qxclass : "qx-aum-scroll-bar"
    get :
      orientation : (el) -> "if($('div.qx-aum-scroll-bar.qx-identifier-#{el}.qx-horizontal').length) {return 'horizontal';}
                             if($('div.qx-aum-scroll-bar.qx-identifier-#{el}.qx-vertical').length) {return 'vertical';}"
      value : (el)->  """
                        var elem = $('div.qx-aum-scroll-bar.qx-identifier-#{el}');
                        var scaleRect = elem.find('div.qx-scb-scell')[0].getBoundingClientRect();
                        var handleRect = elem.find('div.qx-scroll-handler')[0].getBoundingClientRect();
                        if (elem.hasClass('qx-horizontal')) {
                          if (scaleRect.width === handleRect.width) {return 0;}
                          return Math.round(100 * (handleRect.left - scaleRect.left) / (scaleRect.width - handleRect.width));
                        }
                        if (elem.hasClass('qx-vertical')) {
                          if (scaleRect.height === handleRect.height) {return 0;}
                          return Math.round(100 * (handleRect.top - scaleRect.top) / (scaleRect.height - handleRect.height));
                        }
                      """
      defaults :
        height : 20

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
            @waitIdle

        (true)

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
      defaults :
        height : 20
        chrome$l :
          height : 20

  "spinner" :
    qxclass  : "qx-aum-spinner"
    get :
      text : (el) -> "return $('div.qx-identifier-#{el} > input').val()"
      value: (el) -> "return parseInt($('div.qx-identifier-#{el} > input').val());"
      defaults :
        height : 20
        firefox$w :
          height : 24
    set :
      value : (el,val)->
        # setValue with mouse
        if val.smallStep?
          count=Math.abs(val.smallStep)
          selector = "div.qx-identifier-#{el}.qx-aum-spinner a.ui-spinner-"+ if val.smallStep>0 then "up" else "down"
          while count>0
            count-=1
            @invoke selector
            @waitIdle
          return
        # click on textfield, clear value and enver new one
        el = @elementByCss("div.qx-identifier-#{el}.qx-aum-spinner input.qx-text.ui-spinner-input")
        el.click()
        @waitIdle
        el.sendKeys(['\uE009','a','\uE009','\uE017']).sendKeys(val)

  "stack-panel" :
    qxclass : "qx-aum-stack-panel"

  "tab" :
    qxclass : "qx-aum-tab"
    get :
      value : (el) -> "return $('div.qx-identifier-#{el}.qx-aum-tab li.ui-tabs-active')[0].className.match(/qx-h-identifier-(.*)/)[1]"
    set :
      value : (el,val) ->
        return @execute "return $('div.qx-identifier-#{el} li[aria-controls='+$('.qx-identifier-#{val}').prop('id') +'] a').click()"

  "tab-page" :
    qxclass : "qx-aum-tab-page"
    get :
      text : (el) -> "return $('ul.qx-tab-header li[aria-controls='+$('.qx-identifier-#{el}').prop('id') +'] a').text()"
      state : (el) -> "var pageHeader = $('li.qx-h-identifier-#{el}.qx-h-aum-tab-page');
                       if (pageHeader.length == 0 ) { return 'page not found';}
                       if (pageHeader.hasClass('ui-tabs-active')) { return 'active';} else { return 'inactive';}"
    set :
      ident : (el) -> yp @execute "return $('[aria-controls='+$('.qx-identifier-#{val}').prop('id') +']').addClass('qx-identifier-h_#{el}')"

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
    get :
      text: (el) -> "return $('.qx-identifier-#{el} .qx-text').val()"
      value : (el) -> "return $('.qx-identifier-#{el} textarea').val()"
      defaults :
        height : 38
        firefox$w :
          height : 48
        chrome$l :
          height : 34
     set :
       value : (el,val)->
         @elementByCss(".qx-identifier-#{el}.qx-aum-text-area").click()
         @waitIdle
         @elementByCss(".qx-identifier-#{el}.qx-aum-text-area .qx-text")
         .sendKeys(['\uE009','a','\uE009','\uE017'])
         .sendKeys(val)
         @waitIdle()

  "tree-table" :
    qxclass : "qx-aum-tree-table"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-tree-table.qx-aum-abstract-data-table').length > 0)"

  "text-field" :
    qxclass : "qx-aum-text-field"
    selector : (el)-> "return ($('.qx-identifier-#{el}.qx-aum-text-field').length > 0)"
    get :
      text : (el) -> "return $('.qx-identifier-#{el}.qx-aum-text-field .qx-text').text()"
      value : (el) -> "return $('.qx-identifier-#{el}.qx-aum-text-field .qx-text').text()"
      defaults :
        height : 20
        chrome$l :
          height : 20
     set :
       value : (el,val)->
         @elementByCss(".qx-identifier-#{el}.qx-aum-text-field").click()
         @waitIdle
         @elementByCss(".qx-identifier-#{el}.qx-aum-text-field .qx-text")
         .sendKeys(['\uE009','a','\uE009','\uE017'])
         .sendKeys(val)
         @waitIdle()


  "time-edit-field" :
    qxclass :  "qx-aum-time-edit-field"
    set :
      #Warning!!! not work
      value : (el,h,m) -> "return(@execute($('.ui-timepicker-hours .ui-timepicker tbody tr td a')[#{h}].click()).execute($('.ui-timepicker-minutes .ui-timepicker tbody tr td a')[#{m}].click()))"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} input').val()"
      defaults :
        height : 20
        chrome$l :
          height : 20

  "toolbar" :
    qxclass : "qx-aum-toolbar"

  "toolbar-button" :
    qxclass : "qx-aum-toolbar-button"
    get :
      text : (el) -> "return $('.qx-identifier-#{el} .qx-text').html()"
      image : (el) -> "return $('.qx-identifier-#{el} .qx-htal>img')[0].src"
      state : (el) -> "if ($('.qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled'; }
                   if ($('.qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled'; }
                   return $('.qx-identifier-#{el}').attr('class');"

  "toolbar-separator" :
    qxclass : "qx-aum-toolbar-separator"

  "web-component" :
    qxclass : "qx-aum-web-component"
    get :
      image : (el) -> "return $('iframe.qx-identifier-#{el}').prop('src')"

  "window" :
    qxclass : "qx-aum-window"
    get :
      text : (el) -> "return $('.qx-identifier-#{el}').closest('.ui-dialog').find('span:first').text()"

  "text-element" :
    qxclass : "qx-text"
    get :
      text : (el) -> "return $('.qx-identifier-#{el}.qx-text').text()"

  "unknown" :
    qxclass : "unknown"
    get :
      text  : (el) -> "return $('.qx-identifier-#{el}').text()"
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
  item.get.state ?= (el)-> "if ($('.qx-identifier-#{el}:not(.qx-disabled):not(.qx-readonly):not(.qx-inactive).qx-active.qx-not-readonly').length > 0) { return 'enabled' }
                   if ($('.qx-identifier-#{el}:not(.qx-enabled):not(.qx-not-readonly):not(.qx-active).qx-disabled.qx-inactive.qx-readonly').length > 0) { return 'disabled' }
                   return $('.qx-identifier-#{el}').attr('class');"

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
