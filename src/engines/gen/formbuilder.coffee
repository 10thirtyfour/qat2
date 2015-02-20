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
_ = require "lodash"
prettyjson = require "prettyjson"

formitems = 
  containers : []
  widgets : []
  rangefields : [ "progressbar", "scrollbar", "slider", "spinner" ]

class Builder

class ElemBuilder extends Builder
  constructor: (@elem,type,@par) ->
    @elem ?= {}
    _.merge @elem, 
      _type: type
      _widget: true
      enable: true
      visible: true
  attr: (val) ->
    _.merge @elem, val
    @
  border: (thickness=1,col="Black") ->
    @attr
      elementborder:
        type:"lineborder"
        thickness:
          left:thickness
          top:thickness
          bottom:thickness
          right:thickness
        borderbrush:
          type:"systemcolor"
          systemColorName:col
  background: (col="LightRed") ->
    @attr
      background:
        fillcolor:
          type: "systemcolor"
          systemColorName:col
  val: (t) ->
    @elem._fglVal = t
    @
  up: -> @par
  end: -> @elem

getBuilder = (param, parent, el) ->
  if _.isString param
    b = tyToBuilder[param]
    throw new Error("no builder for #{param}") unless b?
    el ?= {}
    return [_.merge(b(el, param, parent), parent._ext), el]
  if param.end?
    return [parent, param.end()]
  if _.isObject param and param._type?
    return [parent, param]
  throw new Error "incorrect content type"

class ContBuilder extends ElemBuilder
  constructor: (elem, type, par) ->
    super elem, type, par
  contFieldName: "content"
  _ext: {}
  content: (param,opts) ->
    [b,el] = getBuilder param, @
    _.merge el, opts
    throw new Error("container already has an element") if @elem[@contFieldName]?
    @elem[@contFieldName]  = el
    b

class ItemsBuilder extends ContBuilder
  constructor: (elem, type, par) ->
    super elem, type, par
  contFieldName: "items"
  content: (param,opts) ->
    items = @elem[@contFieldName] ?= []
    [b,el] = getBuilder param, @
    _.merge el, opts
    items.push el
    b
    
class TableColumnBuilder extends ContBuilder
  constructor: (elem, type, par) ->
    super elem, type, par
  contFieldName: "control"
  
  _ext: {}

    
class TableBuilder extends ItemsBuilder
  constructor: (elem, ty, par) ->
    super elem, ty, par
    @elem.tabledatamodel = tablecolumns:[]
  content: (param,opts) ->
    throw new Error("Only tablecolumns may be created inside table!") unless param is "tablecolumn"
    items = @elem.tabledatamodel.tablecolumns
    [b,el] = getBuilder param, @
    _.merge el, opts
    items.push el
    b
    
  _ext: {}
  

class GridBuilder extends ItemsBuilder
  constructor: (elem, ty, par) ->
    super elem, ty, par
    @rowBuilder = new GridLenBuilder @, "gridrowdefinitions"
    @colBuilder = new GridLenBuilder @, "gridcolumndefinitions"
    @cur = 0
  rows: -> @rowBuilder
  cols: -> @colBuilder
  content: (params, opts) ->
    cols = @colBuilder.cur.length
    cur = @cur++
    super(params, opts).at(
      cur % cols
      Math.floor(cur / cols))
  _ext:
    at: (x,y) ->
      x = +x ? 0
      y = +y ? 0
      throw new Error("wrong container") unless _.isNumber(x) and _.isNumber(y)
      @attr griditemlocation: { gridx: x, gridy: y }
      @
    rowspan: (v) -> @attr griditemlocation: gridheight: v
    colspan: (v) -> @attr griditemlocation: gridwidth: v

class CoordPanelBuilder extends ItemsBuilder
  constructor: (elem, ty, par) ->
    super elem, ty, par
  _ext:
    at: (x,y) ->
      x = +x ? 0
      y = +y ? 0
      throw new Error("wrong container") unless _.isNumber(x) and _.isNumber(y)
      @attr location: {xcoord:x, ycoord:y}
      @

class BorderPanelBuilder extends ItemsBuilder 
  constructor: (elem, ty, par) ->
    super elem, ty, par
  _ext:
    at: (loc) -> @attr borderpanelitemlocation: loc

class GridLenBuilder extends Builder
  constructor: (@gridBuilder,name) ->
    @cur = @gridBuilder.elem[name] ?= []
  absolute: (n, opts) ->
    @cur.push _.merge(
      {gridLength: gridLengthType: "Absolute", gridLengthValue: n}
      opts)
    @
  relative: (n, opts) ->
    if _.isObject n
      opts = n
      n = 1
    n = 1 unless n?
    @cur.push _.merge(
      {gridLength: gridLengthType: "Relative", gridLengthValue: n}
      opts)
    @
    
  pixels: (n, opts) ->
    @cur.push _.merge(
      {gridLength: gridLengthType: "Pixels", gridLengthValue: n}
      opts)
    @
  percent: (n, opts) ->
    if _.isObject n
      opts = n
      n = 1
    n = 1 unless n?
    @cur.push _.merge(
      {gridLength: gridLengthType: "Percent", gridLengthValue: n}
      opts)
    @    
  min: (val) ->
    if @cur.length is 0
      throw new Error("no elements")
    @cur[@cur.length-1].gridLength.gridMinLength = val
    @
  max: (val) ->
    if @cur.length is 0
      throw new Error("no elements")
    @cur[@cur.length-1].gridLength.gridMaxLength = val
    @
  auto: (opts) ->
    @cur.push _.merge {gridLength: gridLengthType: "Auto"}, opts
    @
  up: -> @gridBuilder


class FormBuilder extends ContBuilder
  constructor: (@elem) ->
    @elem ?= {}
  contFieldName: "rootcontainer"

class TextWidgetBuilder extends ElemBuilder
  constructor: (el,ty,par) ->
    super el, ty, par
  textFieldName: "text"
  text: (t) ->
    unless t?
      delete @elem[@textFieldName] if @elem[@textFieldName]
      return @
    @elem[@textFieldName] = t
    
    @

tyToBuilder = {}
labelFields = 
  checkbox : "title"
  label : "text"
  button : "text"
  radiobutton: "title"
  
defaultOpts = {}


class RangeWidgetBuilder extends ElemBuilder
  constructor: (el,ty,par) ->
    super el, ty, par
    @range()
    @steps()
    @elem._fglType="INT"
  orientation: (orient) ->
    orient = "Vertical" if orient in ["v","V","vertical"]
    orient = "Horizontal" if orient in ["h","H","horizontal"]
    @elem.orientation=orient
    @
  range: (min=0,max=100) ->
    @elem.minValue=min
    @elem.maxValue=max
    @
  steps: (small=1,large=10) ->
    switch @elem._type
      when "scrollbar" 
        @elem.smallStep=small
        @elem.largeStep=large
      when "spinner","progressbar"
        @elem.step=small
      when "slider"
        @elem.minorTick=small
        @elem.majorTick=large
    @

class BoolWidgetBuilder extends ElemBuilder    
  constructor: (el,ty,par) ->
    super el, ty, par
    @values(1,0)
  values: ( checked, unchecked ) ->
    @elem.checkedvalue = 
      type:"stringliteral"
      stringValue : checked
    @elem.uncheckedvalue = 
      type:"stringliteral"
      stringValue : unchecked
    @  
    
regBuilder = (name, builder) ->
  formitems.containers.push name
  ContBuilder.prototype[name] = (opts) -> @content name
  tyToBuilder[name] = (el,ty,par) -> new builder el, ty, par

regSimpleField = (name, topts, builder) ->
  formitems.widgets.push name
  defaultOpts[name] = topts
  builder ?= TextWidgetBuilder
  ContBuilder.prototype[name] = (opts) ->
    if opts?
      opts = _.merge {}, opts, topts
      return @content(name).attr(opts).end()
    res = @content(name)
    res.attr(topts) if topts?
    return res
  tyToBuilder[name] = (el,ty,par) -> new builder el, ty, par

class ComboBuilder extends TextWidgetBuilder
  constructor: (elem, type, par) ->
    super elem, type, par
  editable: (val) -> 
    val ?= (true)
    @attr editable: val
  items: (items...) ->
    res = @elem.comboBoxItems ?= []
    for i in items
      selected = false  
      if i[0] is "+"
        selected = (true) 
        i = i.substr 1
      res.push
        _type : "comboboxitem"
        text: i
        isSelected: selected
    @
  
 

regBuilder "borderpanel", BorderPanelBuilder
regBuilder "coordpanel", CoordPanelBuilder
regBuilder "gridpanel", GridBuilder
regBuilder "tablecolumn", TableColumnBuilder
regBuilder "table", TableBuilder


regSimpleField "button", _record: "FormOnly"
regSimpleField "checkbox", _record: "FormOnly" , BoolWidgetBuilder
regSimpleField "combobox", _record: "FormOnly", ComboBuilder

regSimpleField "label"

regSimpleField "radiobutton", _record: "FormOnly", groupIdentifier: "group1", BoolWidgetBuilder

regSimpleField "scrollbar", _record: "FormOnly" , RangeWidgetBuilder
regSimpleField "spinner", _record: "FormOnly", RangeWidgetBuilder
regSimpleField "slider", _record: "FormOnly", RangeWidgetBuilder
regSimpleField "progressbar", _record: "FormOnly", RangeWidgetBuilder

regSimpleField "textarea", _record: "FormOnly"
regSimpleField "textfield", _record: "FormOnly"


ElemBuilder::record = (name) -> @attr 
  _record: (name ? "FormOnly")
  fieldType: "FORM_ONLY"
  fieldtable: "formonly"

lift = (old, fun) ->
  if _.isString old and _.isFunction tyToBuilder[old]
    return tyToBuilder[old] = lift tyToBuilder[old], fun
  if _.isFunction old
    return (args...) -> fun.call @, old.apply @, args

regField = (name) ->
  lift name, -> 
    #console.log "RECORD"
    @record()

regField "textfield"
regField "textarea"

ElemBuilder::dfs = (fun) ->
  go = (obj) -> 
    for i, v of obj
     continue unless v?  
     if v.length
      if v.length > 0 and v[0]._type?
        for j in v
          res = fun.call j
          return false if res is (false) 
          if res isnt (true) 
            return (false) if go(j) is (false) 
     else if _.isObject v
      res = (null)
      if v._type?
        res = fun.call v
        return false if res is (false)
      if res isnt (true)
        return false if go(v) is (false)
  go @elem

ElemBuilder::fields = (fun) ->
  @dfs ->
    return fun.call(@) if @_record?

ElemBuilder::widgets = (fun) ->
  @dfs ->
    return fun.call(@) if @_widget?

class ScreenRecordBuilder extends Builder
  constructor: (@rec) ->
  isGrid: (v) -> @rec._isGrid = v
  field: (f) -> 
    return @ for i in @rec.fields when i["#text"] is f.name
    @rec.fields.push
      "#text": f.identifier
      _val: f
    @

FormBuilder::screenrec = (name) ->
  recs = @elem.screenrecords ?= []
  return new ScreenRecordBuilder(i) for i in recs when i.identifier is name
  rec =
    identifier: name
    fields: []
  recs.push rec
  new ScreenRecordBuilder rec

FormBuilder::end = ->
  records = {}
  names = {}
  knownNames = {}
  form = @
  @widgets ->
    # default names
    {identifier:name, _type:type} = @
    
    if name?
      grid = knownNames[name]
      knownNames[name] = (true)  
    else
      cur = names[type] ?= 0
      loop
        name = type + ++cur
        break unless knownNames[name]?
      knownNames[name] = (true)
      names[type] = cur
      @identifier = name

    if type is "table"
      form.screenrec(@identifier).isGrid(true)
      for f in @tabledatamodel.tablecolumns
        f.control._record = @identifier
        
    if @_record?
      rec = form.screenrec(@_record).field(@)
      rec.isGrid(true) if grid
    if @_actions
      for i,n of @_actions
        unless n?
          n ?= "#{i}@#{@identifier}"
          @[i] = @actions[i] = n
        @[i] =
          type: "actioneventhandler"
          actionName: n
    if labelFields[type]? and not @[labelFields[type]]?
      @[labelFields[type]] = @identifier
    return
  res = super()
  #console.log "widgets:", prettyjson.render res
  
  res

ElemBuilder::size = (w,h) -> @attr preferredsize: { width: w, height: h }
ElemBuilder::minSize = (w,h) -> @attr minsize: { width: w, height: h }
ElemBuilder::maxSize = (w,h) -> @attr maxsize: { width: w, height: h }

event = (name) ->
  (msg) ->
    obj = {}
    obj[name] = msg ? (true)  
    @attr _actions: obj

ElemBuilder::event = (name,msg) -> event(name).call(@, msg)

ElemBuilder::invoke = event "OnInvoke"
ElemBuilder::keyDown = event "OnKeyDown"
ElemBuilder::keyUp = event "OnKeyUp"
ElemBuilder::mouseDown = event "OnMouseDown"
ElemBuilder::mouseUp = event "OnMouseUp"
ElemBuilder::click = event "OnMouseClick"
ElemBuilder::doubleclick = event "OnMouseDoubleClick"
ElemBuilder::focusin = event "OnFocusIn"
ElemBuilder::focusout = event "OnFocusOut"
ElemBuilder::change = event "OnValueChanged"
ElemBuilder::check = event "OnCheck"
ElemBuilder::uncheck = event "OnUncheck"
# TODO: the rest

module.exports =
    form: (name)-> new FormBuilder( {_name:name} )
    formitems: -> 
      formitems.elements = formitems.widgets.concat(formitems.containers)
      formitems
