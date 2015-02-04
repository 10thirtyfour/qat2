###
# #%L
# QUERIX
# %%
# Copyright (C) 2014 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel ; +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
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
        res = """LET #{varname}.#{i} ="""
        switch v.ty
            when "STRING"
              if v.val._fglVal
                res += "\"#{v.val._fglVal}\""
              else if @_withDefaults or not v.val.text?
                res += "\"str-#{varname}-#{i}#{if x? then "-#{x}" else ""}\""
              else
                res += "\"#{v.val.text}\""
            when "INT"
              if v.val._fglVal
                res += v.val._fglVal
              else
                res += if x? then x else "100"
            else 
              if v.val._fglVal
                res += v.val._fglVal
              else
                res += "NULL"
        @par.commands.push res
      return
    @par.globals.push @globDef()
    unless @varname?
      @varname = @par.uniq.newName_ @name
    @par.defs.push """DEFINE #{@varname} #{@typeRef()}"""
    if @isGrid
      @par.commands.push """
        FOR i = 1 TO 100
          #{initSingle "#{@varname}[i]", i}
        END FOR"""
    else
      #console.log "init record:", @varname, prettyjson.render @
      initSingle @varname
  field: (name, ty, val) ->
    ty?= val._fglType
    @fields[name] = 
      ty: ty ? "STRING"
      val: val
  typeRef: -> "OF #{@typeName}"
  type: -> 
    """TYPE AS #{if @isGrid then "DYNAMIC ARRAY OF " else ""}RECORD
    #{punctuate ("  #{n} #{t.ty}" for n, t of @fields)}
    END RECORD"""
  globDef: ->
    unless @typeName?
      @typeName = @par.uniq.newName_ "type#{@name}"
    """DEFINE #{@typeName}#{indent @type()}"""

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
  windowWithForm: (name) ->
    @commands.push """OPEN WINDOW #{name} AT 1,1 WITH FORM "form/#{name}" ATTRIBUTE(BORDER)"""
  inputScreenRec: (screenRec) ->
    b = new RecordBuilder(@)
    b.field(v["#text"], v._fglType, v._val) for v in screenRec.fields
    b.name = screenRec.identifier.toLowerCase()
    b.initCode()
    wd = if screenRec._withDefaults then "" else " WITHOUT DEFAULTS"
    attrib = if screenRec._attributes? then " ATTRIBUTES(#{screenRec._attributes})" else ""
    stmt = if @isGrid
      """INPUT ARRAY #{b.varname}#{wd} FROM #{screenRec.identifer}.*#{attrib}"""
    else
      """INPUT BY NAME #{b.varname}.*#{wd}#{attrib}"""
    for {_val:{_actions:i}} in screenRec.fields when i?
      for v of i
        stmt += """
                  
                  ON ACTION(#{v})
                    DISPLAY "#{v}"
                """
    stmt += """
               
               ON KEY(F10)
                  EXIT INPUT
               END INPUT"""
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
  command: (str) ->
    @commands.push str
    @
  closeWindow: (name) -> @command "CLOSE WINDOW #{name}"
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
  
  save: ( name , root ) ->
    
    name ?= @name ? "main"
    root ?= @projectRoot
    
    # target for Build command
    @target = 
      projectPath : root
      programName : name
      deploy : true
    
    mkdirp.sync "#{root}/source/form"
    fs.writeFileSync "#{root}/source/#{name}.4gl", @end()
    for i in @forms
      fs.writeFileSync "#{root}/source/form/#{i._name}.fm2", format.write i
    
    # create or update project file here
    unless fs.existsSync("#{root}/.project")
      fs.writeFileSync "#{root}/.project", 
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
    
    if fs.existsSync("#{root}/.fglproject")
      xml = new dom().parseFromString fs.readFileSync("#{root}/.fglproject",'utf8')
    else 
      xml = new dom().parseFromString(
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
        )

    targets = xml.getElementById("com.querix.fgl.core.buildtargets")
    targetExists = false
    for el in targets.getElementsByTagName("buildTarget")
      if el.getAttribute("name") is name then targetExists = true
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