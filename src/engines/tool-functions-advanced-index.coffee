"use strict"

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
          testData.projectName ?= runner.toolfuns.calcProjectName(testData.fileName)
          compileTestName = "#{testData.projectName}/#{path.basename(suspectTestName,testData.ext)}/qform"

          unless compileTestName of runner.tests
            runner.reg
              name: compileTestName
              failOnly: true
              after: ["atomic/start"]
              data:
                kind: "compile"+testData.ext
                src : @fileName
              testData:
                fileName: testData.fileName+".per"
                options: testData.options
              promise: runner.toolfuns.regCompile
          testData.ext = ".fm2"

        testData.fileName = testData.fileName+".fm2"
        formTestName = "#{testData.projectName}/#{path.basename(suspectTestName,testData.ext)}/xpath"
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
              src : runner.relativeFn(@fileName)
            promise : ->
              @runner.Q("OK")

        runner.reg
          name: testName
          after: compileTestName
          before : formTestName
          failOnly: true
          data:
            kind: "xpath"
            src : runner.relativeFn(@fileName)
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

        testData.projectName ?= runner.toolfuns.calcProjectName(testData.fileName)

        testData.name = "#{testData.projectName}/#{path.basename(suspectTestName,testData.ext)}/"

        testData.name = testData.name+"qfgl" if testData.ext is ".4gl"
        testData.name = testData.name+"qform" if testData.ext is ".per"

        runner.reg
          name: testData.name
          after: ["atomic/start"]
          data:
            kind: "compile"+testData.ext.toLowerCase()
            src : runner.relativeFn(@fileName)
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

      testData.atomic_before ?= []

      unless testData.programName?
        throw new Error("Build. Can not read programName")
      unless testData.projectPath?
        throw new Error("Build. Can not read projectPath")

      testData.fileName = path.join(
        testData.projectPath,
        testData.projectSource,
        "."+testData.programName+".fgltarget")

      if testData.name
        testData.buildTestName ?= "#{testData.projectName}/#{testData.name}/build"
      else
        testData.buildTestName ?= "#{testData.projectName}/#{testData.programName}/build"

      if testData.atomic?
        testData.buildTestName ?= "atomic/#{testData.atomic}"

      # storing test name and program name in test context for future use in WD
      @lastBuiltTestName = testData.buildTestName
      @lastBuilt = testData.programName

      if testData.buildMode is "all"
        if testData.name?
          testData.deployTestName = "#{testData.projectName}/#{testData.name}/deploy"
        else
          testData.deployTestName = "#{testData.projectName}/#{testData.programName}/deploy"

        testData.buildMode = "build"
        @lastBuiltTestName = testData.deployTestName

      # ------  deploy workaround
      unless testData.buildTestName of runner.tests
        if testData.deployTestName? && testData.deploy? && testData.deploy
          runner.reg
            name: testData.deployTestName
            after: [ testData.buildTestName ]
            silent : (true)
            data:
              kind: "deploy"
              src : runner.relativeFn(@fileName)
            testData: testData
            promise: runner.toolfuns.regDeploy
      # ------ end of deploy workaround

        if testData.deploy
          testData.failOnly ?= testData.deploy
        testData.failOnly ?= false
        testData.after ?= []
        testData.atomic_before.forEach (e)->
          testData.after.push("atomic/#{e}")
        if  testData.after.length == 0 then testData.after = ["atomic/start"]
        if (testData.atomic?) && (testData.atomic == "start")
          testData.buildTestName = "atomic/" + testData.atomic
          testData.after = []
        unless runner.tests.async.disabled then testData.after = []
        runner.reg
          name: testData.buildTestName
          after: testData.after
          data:
            kind: "build"
            src : runner.relativeFn(@fileName)
          testData: testData
          failOnly : testData.failOnly
          promise: runner.toolfuns.regBuild

        testData.buildTestName
      testData.buildTestName

    RegLD : (obj, params) ->
      return if process.platform[0] isnt "w"
      runner = @runner
      if _.isFunction obj
        params ?= {}
        params.syn = obj
      else
        params = obj
      params.testFileName = @fileName

      params.projectName ?= runner.toolfuns.calcProjectName(params.testFileName)

      params.name ?= path.basename(@fileName, "-ld-test.coffee")

      params.name = params.projectName+"/"+params.name+"/desktop"
      params.after?= []
      if @lastBuiltTestName?
        params.after.push(@lastBuiltTestName)

      params.name      ?= @testName
      params.source     = path.relative( runner.tests.globLoader.root, @fileName)

      params.data ?= {}
      params.data.src ?= runner.relativeFn(@fileName)

      runner.regLD params

    RegWD : (obj, params) ->
      runner = @runner
      if _.isFunction obj
        params ?= {}
        params.syn = obj
      else
        params = obj
      params.after ?= []
      params.data ?= {}
      params.data.src ?= runner.relativeFn(@fileName)
      params.after.push(@lastBuiltTestName) if @lastBuiltTestName?
      params.atomic_before ?= []

      params.atomic_before.forEach (e)->
        if params.after.indexOf("atomic/#{e}")==-1 then params.after.push("atomic/#{e}")
      params.testFileName = @fileName

      params.projectName ?= runner.toolfuns.calcProjectName(params.testFileName)

      params.name ?= path.basename(@fileName, "-wd-test.coffee")

      params.name = params.projectName+"/"+params.name

      if params.atomic then  params.name = "atomic/#{params.atomic}"

      params.lastBuilt ?= @lastBuilt
      params.testId    ?= params.lastBuilt

      runner.regWD params

    RunLean : (opts={})->
      opts.lastBuilt = @lastBuilt
      opts.testName = @testName
      runner.runLean(opts)

    reg : (obj,other...) ->
      obj.data?={}
      obj.data.src?=runner.relativeFn(@fileName)
      obj.name?=@testName

      @runner.reg(obj,other...)

    form : genForm.form
    formitems : genForm.formitems

    program : ( name , root ) ->
      name ?= @runner.toolfuns.filenameToTestname(@fileName)
      root ?= path.join @runner.tests.globLoader.root,(@runner.generatorProject ? "qatproject")
      genProgram( name, root )
