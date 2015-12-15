genProgram = require("./gen/fglbuilder").program
genForm =  require("./gen/formbuilder")

module.exports = ->
  {Q,yp,fs,path,_, opts} = runner = @
  runner.extfuns?={}
  _.merge runner.extfuns,
    #uniformName : runner.toolfuns.uniformName
    log : console.log
    ver : (v)->
      if opts.version<v
        throw "Update QAT! Required version : #{v}. Current : #{opts.version}"
    CheckXML: (testData) ->
      yp.frun =>
        testData.fileName?=testData.fn or runner.toolfuns.filenameToTestname(@fileName)
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
          compileTestName = runner.toolfuns.uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}.per")
          unless compileTestName of runner.tests
            runner.reg
              name: compileTestName
              failOnly: true
              data:
                kind: "compile"+testData.ext
              testData:
                fileName: testData.fileName+".per"
                options: testData.options
              promise: runner.toolfuns.regCompile
          testData.ext = ".fm2"

        testData.fileName = testData.fileName+".fm2"
        formTestName = runner.toolfuns.uniformName("advanced$#{@relativeName}$xpath$#{suspectTestName}")
        n = 0
        loop
          testName = "#{formTestName}$#{n}"
          n+=1
          unless testName of runner.tests then break

        unless formTestName of runner.tests
          runner.reg
            name : formTestName
            data :
              kind : "xpath"
            promise : ->
              @runner.Q("OK")

        runner.reg
          name: testName
          after: compileTestName
          before : formTestName
          failOnly: true
          data:
            kind: "xpath"
          testData: testData
          promise: runner.toolfuns.regXPath
        return ->
          nop=0

    Compile: (arg, additionalParams) ->
      yp.frun =>
        if typeof arg is "string"
          testData = _.defaults(fileName:arg,additionalParams)
        else
          testData = if arg? then arg else fileName:runner.toolfuns.filenameToTestname(@fileName)

        testData.fileName?=(testData.fn or runner.toolfuns.filenameToTestname(@fileName))
        testData.reverse?=testData.fail
        testData.errorCode?=(testData.error or testData.err)
        testData.options?=testData.opts

        if testData.errorCode? then testData.reverse = (true)

        delete testData.fail
        delete testData.fn

        if testData.ext?
          unless testData.ext[0] is "." then testData.ext="."+testData.ext
        else
          testData.ext=".4gl"
        testData.fileName = path.join(path.resolve path.dirname(@fileName), path.dirname(testData.fileName),path.basename(testData.fileName))

        unless path.extname(testData.fileName).length
          testData.fileName+=testData.ext
        else
          testData.ext=path.extname(testData.fileName)

        suspectTestName = path.relative path.dirname(@fileName), testData.fileName

        runner.reg
          name: runner.toolfuns.uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}")
          data:
            kind: "compile"+testData.ext.toLowerCase()
          testData: testData
          promise: runner.toolfuns.regCompile
        return ->
          nop=0

    Build: (arg, testData={}) ->
      if typeof arg is "string"
        testData.programName = arg
      else
        testData = arg ? {}

      testData.testFileName = @fileName
      testData = runner.toolfuns.combTestData(testData)

      unless testData.programName? then throw "Build. Can not read programName"
      unless testData.projectPath? then throw "Build. Can not read projectPath"

      testData.fileName = path.join(testData.projectPath,testData.projectSource,"."+testData.programName+".fgltarget")
      progRelativeName = path.relative runner.tests.globLoader.root, path.join(testData.projectPath, testData.projectSource, testData.programName)
      testData.buildTestName = runner.toolfuns.uniformName("advanced$#{@relativeName}$build$#{progRelativeName}")

      # storing test name and program name in test context for future use in WD test
      @lastBuiltTestName = testData.buildTestName
      @lastBuilt = testData.programName

      if testData.buildMode is "all"
        testData.deployTestName = runner.toolfuns.uniformName("advanced$#{@relativeName}$deploy$#{progRelativeName}")
        testData.buildMode = "rebuild"
        @lastBuiltTestName = testData.deployTestName
      # ------  deploy workaround
      if testData.deployTestName?
        runner.reg
          name: testData.deployTestName
          after: [ testData.buildTestName ]
          silent : (true)
          data:
            kind: "deploy"
          testData: testData
          promise: runner.toolfuns.regDeploy
      # ------ end of deploy workaround

      testData.failOnly ?= testData.deploy

      runner.reg
        name: testData.buildTestName
        data:
          kind: "build"
        testData: testData
        failOnly : testData.failOnly
        promise: runner.toolfuns.regBuild

      testData.buildTestName

    RegLD : (obj, params) ->
      return if process.platform[0] isnt "w"
      runner = @runner
      if _.isFunction obj
        params ?= {}
        params.syn = obj
      else
        params = obj
      params.after     ?= @lastBuiltTestName ? []
      params.name      ?= @testName
      params.source     = path.relative( runner.tests.globLoader.root, @fileName)
      runner.regLD params

    RegWD : (obj, params) ->
      runner = @runner
      if _.isFunction obj
        params ?= {}
        params.syn = obj
      else
        params = obj
      params.after     ?= @lastBuiltTestName ? []
      params.name      ?= runner.toolfuns.uniformName(path.relative(runner.tests.globLoader.root,@fileName))
      params.lastBuilt ?= @lastBuilt
      params.testId    ?= params.lastBuilt
      if params.testId? then params.name+="$"+params.testId
      runner.regWD params

    RunLean : (opts={})->
      opts.lastBuilt = @lastBuilt
      opts.testName = @testName
      runner.runLean(opts)

    reg : (obj,other...) ->
      obj.name?=@testName
      @runner.reg(obj,other...)

    form : genForm.form
    formitems : genForm.formitems

    program : ( name , root ) ->
      name ?= @runner.toolfuns.filenameToTestname(@fileName)
      root ?= path.join @runner.tests.globLoader.root,(@runner.generatorProject ? "qatproject")
      genProgram( name, root )
