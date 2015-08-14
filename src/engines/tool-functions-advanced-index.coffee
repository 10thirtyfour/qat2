genProgram = require("./gen/fglbuilder").program
genForm =  require("./gen/formbuilder")

module.exports = ->
  {Q,yp,fs,path,_} = runner = @ 
  runner.extfuns =  
    #uniformName : runner.toolfuns.uniformName
    log : console.log
    CheckXML: (testData) ->
      rr = @runner
      yp.frun => 
        testData.fileName?=testData.fn or rr.toolfuns.filenameToTestname(@fileName)
        testData.method?="select"
        testData.reverse?=testData.fail
        testData.timeout?=10000
        testData.fileName = path.resolve(path.dirname(@fileName),testData.fileName)
        testData.options?=testData.opts
        
        testData.ext=path.extname(testData.fileName).toLowerCase()
        unless testData.ext
          testData.ext=".per" #if fs.existsSync(testData.fileName+".fm2") then ".fm2" else ".per"
        else  
          testData.fileName = path.join(path.dirname(testData.fileName), path.basename(testData.fileName,testData.ext))

        suspectTestName = path.relative(path.dirname(@fileName), testData.fileName)
        
        if testData.ext is ".per"
          compileTestName = rr.toolfuns.uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}.per")
          unless compileTestName of rr.tests
            rr.reg
              name: compileTestName
              failOnly: true
              data:
                kind: "compile"+testData.ext
              testData: 
                fileName: testData.fileName+".per"
                options: testData.options
              promise: rr.toolfuns.regCompile 
          testData.ext = ".fm2"
          
        testData.fileName = testData.fileName+".fm2"
        formTestName = rr.toolfuns.uniformName("advanced$#{@relativeName}$xpath$#{suspectTestName}")
        n = 0
        loop
          testName = "#{formTestName}$#{n}"
          n+=1
          unless testName of rr.tests then break
        
        unless formTestName of rr.tests
          rr.reg
            name : formTestName
            data :
              kind : "xpath"
            promise : -> 
              @runner.Q("OK")

        rr.reg
          name: testName
          after: compileTestName
          before : formTestName
          failOnly: true
          data:
            kind: "xpath"
          testData: testData
          promise: rr.toolfuns.regXPath
        return ->
          nop=0
        
    Compile: (arg, additionalParams) ->
      rr = @runner
      yp.frun =>
        if typeof arg is "string"
          testData = _.defaults(fileName:arg,additionalParams)
        else
          testData = if arg? then arg else fileName:rr.toolfuns.filenameToTestname(@fileName)

        testData.fileName?=(testData.fn or rr.toolfuns.filenameToTestname(@fileName))
        testData.reverse?=testData.fail
        testData.errorCode?=(testData.error or testData.err)
        testData.options?=testData.opts
        
        if testData.errorCode? then testData.reverse = (true)  
        
        delete testData.fail 
        delete testData.fn
       
        if testData.ext? 
          unless testData.ext[0] is "." then testData.ext="."+testData.ext
        else
          # .4gl used as default extension"
          testData.ext=".4gl"
        testData.fileName = path.join(path.resolve path.dirname(@fileName), path.dirname(testData.fileName),path.basename(testData.fileName))
        
        unless path.extname(testData.fileName).length 
          testData.fileName+=testData.ext
        else
          testData.ext=path.extname(testData.fileName)

        suspectTestName = path.relative path.dirname(@fileName), testData.fileName
          
        rr.reg
          name: rr.toolfuns.uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}")
          data:
            kind: "compile"+testData.ext.toLowerCase()
          testData: testData
          promise: rr.toolfuns.regCompile 
        return ->
          nop=0
       
    Build: (arg, testData={}) ->
      rr = @runner
      
      if typeof arg is "string"
        testData.programName = arg
      else
        testData = arg ? {}
      
      testData.testFileName = @fileName
      testData = rr.toolfuns.combTestData(testData)
      
      unless testData.programName? then throw "Build. Can not read programName"
      unless testData.projectPath? then throw "Build. Can not read projectPath"
      
      testData.fileName = path.join(testData.projectPath,testData.projectSource,"."+testData.programName+".fgltarget")
      progRelativeName = path.relative rr.tests.globLoader.root, path.join(testData.projectPath, testData.projectSource, testData.programName)
      testData.buildTestName = rr.toolfuns.uniformName("advanced$#{@relativeName}$build$#{progRelativeName}")
      
      # storing test name and program name in test context for future use in WD test
      @lastBuiltTestName = testData.buildTestName
      @lastBuilt = testData.programName
      
      if testData.buildMode is "all"
        testData.deployTestName = rr.toolfuns.uniformName("advanced$#{@relativeName}$deploy$#{progRelativeName}")        
        testData.buildMode = "rebuild"
        @lastBuiltTestName = testData.deployTestName
      
      # ------  deploy workaround
      if testData.deployTestName?
        rr.reg
          name: testData.deployTestName
          after: [ testData.buildTestName ]
          silent : (true)
          data:
            kind: "deploy"
          testData: testData  
          promise: rr.toolfuns.regDeploy
      # ------ end of deploy workaround

      testData.failOnly ?= testData.deploy
      
      rr.reg 
        name: testData.buildTestName
        data:
          kind: "build"
        testData: testData  
        failOnly : testData.failOnly
        promise: rr.toolfuns.regBuild
      
      testData.buildTestName
      
    RegWD : (obj, params) ->
      rr = @runner
      if _.isFunction obj
        params ?= {}
        params.syn = obj
      else
        params = obj
      params.after     ?= @lastBuiltTestName ? []
      params.name      ?= rr.toolfuns.uniformName(path.relative(rr.tests.globLoader.root,@fileName))
      params.lastBuilt ?= @lastBuilt
      params.testId    ?= params.lastBuilt
      if params.testId? then params.name+="$"+params.testId

      rr.regWD params
      
    reg : (params...) ->
      @runner.reg params...
    
    form : genForm.form
    formitems : genForm.formitems

    program : ( name , root ) ->
      name ?= @runner.toolfuns.filenameToTestname(@fileName)
      root ?= path.join @runner.tests.globLoader.root,(@runner.generatorProject ? "qatproject")
      genProgram( name, root )
      
      

 