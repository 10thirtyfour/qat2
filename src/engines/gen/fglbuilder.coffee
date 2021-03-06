_ = require "lodash"
mkdirp = require "mkdirp"
format = require("./formxml")()
fs = require "fs"
prettyjson = require "prettyjson"
dom = require("xmldom").DOMParser
path = require "path"

indent = (str) -> (("  " + i) for i in str.split "\n").join "\n"
punctuate = (lines) ->
  ("#{i}," for i in lines[0...lines.length-1]).join("\n")+"\n"+
    lines[lines.length-1]

dummyProject =
  """
    <?xml version="1.0" encoding="UTF-8"?>
    <projectDescription>
      <name>project</name>
      <comment></comment>
      <projects></projects>
      <buildSpec>
        <buildCommand>
          <name>com.querix.fgl.core.fglbuilder</name>
          <arguments></arguments>
        </buildCommand>
      </buildSpec>
      <natures>
        <nature>com.querix.fgl.core.fglnature</nature>
      </natures>
    </projectDescription>
"""

dummyFglProject =
  """
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <fglProject name="qatproject">
      <data>
        <item id="com.querix.fgl.core.pathentries">
          <pathentry kind="src" path="source"/>
          <pathentry kind="out" path="output"/>
        </item>
        <item id="com.querix.fgl.core.buildtargets"></item>
      </data>
    </fglProject>
  """


class Builder

class SimpleBuilder extends Builder
  constructor: (@txt) ->
  end: -> @txt

class RecordBuilder extends Builder
  constructor: (@par) ->
    @fields = {}
  initCode: ->
    initSingle = (varname, x) =>
      for i,v of @fields
        res = """  LET #{varname}.#{i} ="""
        switch v.ty
            when "STRING"
              if v.val._fglVal?
                res += "\"#{v.val._fglVal}\""
              else if @_withDefaults or not v.val.text?
                res += "\"str-#{varname}-#{i}#{if x? then "-#{x}" else ""}\""
              else
                res += "\"#{v.val.text}\""
            when "INT"
              if v.val._fglVal?
                res += v.val._fglVal
              else
                res += if x? then x else "100"
            else
              if v.val._fglVal?
                res += v.val._fglVal
              else
                res += "NULL"
        @par.commands.push res
      return
    @par.globals.push @globDef()
    unless @varname?
      @varname = @par.uniq.newName_ @name
    @par.defs.push """DEFINE #{@varname} #{@typeRef()}"""

    if @_isGrid
      @_itemCount?=100
      @par.commands.push "FOR i = 1 TO #{@_itemCount}"
      initSingle "#{@varname}[i]",'"||i#'
      @par.commands.push "END FOR"
    else
      #console.log "init record:", @varname, prettyjson.render @
      initSingle @varname
  field: (name, ty, val) ->
    ty?= val._fglType
    @fields[name] =
      ty: ty ? "STRING"
      val: val
  typeRef: -> "#{@typeName}"
  type: ->
    """#{if @_isGrid then "DYNAMIC ARRAY OF " else ""}RECORD
    #{punctuate ("  #{n} #{t.ty}" for n, t of @fields)}
    END RECORD"""
  globDef: ->
    unless @typeName?
      @typeName = @par.uniq.newName_ "type#{@name}"
    """TYPE #{@typeName}#{indent @type()}"""

class UniqNames
  constructor: ->
    @scopes = {}
  newName: (scope) ->
    scope ?= "g"
    @scopes[scope] ?= 1
    =>
      cur = @scopes[scope]++
      "#{scope}#{cur}"
  newName_ : (scope) -> @newName(scope)()

class ProgramBuilder extends Builder
  constructor: ( name , root ) ->
    @name = name
    @projectRoot = root
    @commands = []
    @fglRecords = []
    @globals = []
    @defs = []
    @uniq = new UniqNames
    @newTypeName = @uniq.newName "type"
    @newVarName = @uniq.newName "var"
    @forms = []
    @activeWindowName =""
  windowWithForm: (name) ->
    @activeWindowName = name
    @commands.push """OPEN WINDOW #{name} AT 1,1 WITH FORM "form/#{name}" ATTRIBUTE(BORDER)"""


  initScreenRec: (screenRec) ->
    return if screenRec.fields.length is 0
    b = new RecordBuilder(@)
    b.field(v["#text"], v._fglType, v._val) for v in screenRec.fields
    b.name = screenRec.identifier.toLowerCase()
    b._isGrid = screenRec._isGrid
    b.initCode()
    return b.varname

  inputScreenRec: (screenRec, params = { dialog : false }) ->
    return if screenRec.fields.length is 0
    params.varname ?= @initScreenRec screenRec
    wd = if screenRec._withDefaults or params.dialog then "" else " WITHOUT DEFAULTS"
    attrib = if screenRec._attributes? then " ATTRIBUTES(#{screenRec._attributes})" else ""

    stmt = if screenRec._isGrid
      if params.dialog
        """DISPLAY ARRAY #{params.varname}#{wd} TO #{screenRec.identifier}.*#{attrib}"""
      else
        """INPUT ARRAY #{params.varname}#{wd} FROM #{screenRec.identifier}.*#{attrib}"""
    else
      """INPUT BY NAME #{params.varname}.*#{wd}#{attrib}"""


    interaction = stmt.split(" ")[0]
    for {_val:{_actions:i}} in screenRec.fields when i?
      for v of i
        stmt += """\n  ON ACTION #{v}\n    DISPLAY "#{v}" """

    #console.log screenRec._blocks
    if screenRec._blocks?
      for block in screenRec._blocks
        stmt += "\n  ON #{block.name}\n    #{block.text}"
        if block.name.substr(0,4) is "DRAG" or block.name.substr(0,4) is "DROP"
          # add dnd variable
          if @defs.indexOf("DEFINE dnd ui.DragDrop") is -1
            @defs.push "DEFINE dnd ui.DragDrop"


    unless params.dialog
      stmt += "\n  ON KEY(F10)\n    EXIT #{interaction}"

    stmt+= "\nEND #{interaction}\n"
    @commands.push stmt
  openForm: (form,x) ->
    @forms.push form
    name = form._name ?= @uniq.newName_ (@name + "_form")
    x ?= 0
    @windowWithForm name
    if form.screenrecords?
      @inputScreenRec form.screenrecords[x]
    #@closeWindow name
    @

  dialog: (form,attr)->
    @forms.push form
    name = form._name ?= @uniq.newName_ (@name + "_form")
    @windowWithForm name
    varnames = for sr in form.screenrecords
      @initScreenRec sr

    @commands.push "\nDIALOG" + if attr? then " ATTRIBUTES(#{attr})" else ""
    for sr,i in form.screenrecords
      @inputScreenRec sr, dialog:true, varname:varnames[i]
    @commands.push """
          ON ACTION cancel
            EXIT DIALOG
        END DIALOG
        """
    @
  action: (actName) ->
    @commands.push """
          ON ACTION #{actName}
            DISPLAY #{actName}
          """
    @

  showRecord: (f,x,sep)->
    f?=0
    x?=0
    sep?='>>>'
    if @forms?
      form=@forms[f]
      if form.screenrecords?
        mess = ""
        for field in form.screenrecords[x].fields
          if mess.length then mess+="||'#{sep}'||"
          mess+="NVL(formonly1.#{field._val.identifier},'NULL')"
        @commands.push "MESSAGE "+mess
    @

  command: (str) ->
    @commands.push str
    @
  closeWindow: (name) ->
    name?=@activeWindowName
    @command "CLOSE WINDOW #{name}"
  getKey: () -> @command "CALL fgl_getkey()"
  end: ->
    """
    GLOBALS
      #{(indent(i) for i in @globals).join("\n")}
    END GLOBALS

    MAIN
      DEFINE i INT
    #{(indent(i) for i in @defs).join("\n")}
    #{(indent(i) for i in @commands).join("\n")}
    END MAIN
    """

  save: (name, testData={}) ->
    if typeof name is "string"
        testData.name = name
      else
        testData = name ? {}
    testData.name ?= @name ? "main"
    testData.root ?= @projectRoot

    root = testData.root
    name = testData.name

    testData.atomic_before ?= []

    # target for Build command
    @target =
      projectPath : root
      programName : name
      deploy : (true)
      atomic_before: testData.atomic_before

    mkdirp.sync "#{root}/source/form"
    fs.writeFileSync "#{root}/source/#{name}.4gl", @end()
    for i in @forms
      fs.writeFileSync "#{root}/source/form/#{i._name}.fm2", format.write i

    # create or update project file here
    unless fs.existsSync "#{root}/.project" then fs.writeFileSync "#{root}/.project",dummyProject

    xml = new dom().parseFromString if fs.existsSync("#{root}/.fglproject")
      fs.readFileSync("#{root}/.fglproject",'utf8')
    else
      dummyFglProject

    targets = xml.getElementById("com.querix.fgl.core.buildtargets")
    # TODO:
    # Check this element for existence.
    # Empty eclipse project may don't have it.
    targetExists = (false)
    for el in targets.getElementsByTagName("buildTarget")
      if el.getAttribute("name") is name then targetExists = (true)
    unless targetExists
      targets.appendChild( xml.createTextNode("\n      "))
      targets.appendChild( new dom().parseFromString "<buildTarget location=\"\" name=\"#{name}\" type=\"fgl-program\"/>")

    fs.writeFileSync "#{root}/.fglproject", xml.toString()

    # create program file here
    target =  """
                <?xml version="1.0" encoding="UTF-8"?>
                <fglBuildTarget name="#{name}" xmlns="http://namespaces.querix.com/lyciaide/target" type="fgl-program">
                  <sources type="fgl">
                    <file location="#{name}.4gl"/>
                  </sources>
                  <sources type="form">
              """

    for i in @forms
      target += "\n    <file location=\"form/#{i._name}.fm2\"/>"
    target+=  """
              \n  </sources>
              </fglBuildTarget>
              """
    fs.writeFileSync "#{root}/source/.#{name}.fgltarget", target
    @

module.exports =
  program: (  name , root ) -> new ProgramBuilder(  name , root  )
