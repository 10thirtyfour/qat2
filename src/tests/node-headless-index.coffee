process.maxTickDepth = Infinity

splitByCommas = (str)->
  str.replace(/[\[\]\"\']/g,"").split(",")

module.exports = ->
  {path,yp,toolfuns} = runner = @

  runner.tests.globLoader.disable.file.pattern?=[]
  for dbp of @opts.dbprofiles when dbp isnt @opts.common.options.databaseProfile
    runner.tests.globLoader.disable.file.pattern.push "**/*-#{dbp}-db-rest.tlog"

  @reg
    name: "tlogLoader"
    before: ["globLoader"]
    setup: true
    disabled: false
    promise: ->
      yp.frun ->
        runner.tests.globLoader.regGlob
          name: "node$headless-indexer"
          pattern: ["**/*.tlog"]
          parseFile: (fn) ->
            yp.frun ->
              try
                testData = toolfuns.LoadHeaderData(fn)
                if typeof testData.platform is "string"
                  if testData.platform.indexOf( runner.sysinfo.platform )==-1
                    return true
                testReq = []
                testData.name ?= path.basename(fn, "-rest.tlog")
                testData.testName ?= testData.name
                testData.testName = "#{testData.projectName}/"+testData.testName+"/runlog"
                testData.buildTestName?="#{testData.projectName}/#{testData.programName}/build"

                if typeof testData.atomic_before is "string"
                  temp = splitByCommas(testData.atomic_before)
                  temp.forEach (r,i)-> temp[i]="atomic/#{r}"
                  testReq = testReq.concat(temp)

                if typeof testData.atomic is "string"
                  testData.testName = "atomic/"+testData.atomic
                  #testData.before = ["xdep"]
                if typeof testData.after is "string"
                  testReq = testReq.concat( splitByCommas(testData.after) )

                testData.skipBuild ?= false
                unless testData.skipBuild
                  if testData.buildTestName of runner.tests
                    testReq.forEach (r)->
                      if runner.tests[testData.buildTestName].after.indexOf(r)==-1
                        runner.tests[testData.buildTestName].after.push(r)
                  else
                    runner.reg
                      name: testData.buildTestName
                      failOnly: true
                      data:
                        kind: "build"
                        src : runner.relativeFn(fn)
                      testData : testData
                      after : testReq
                      promise: toolfuns.regBuild
                    testReq = []

                testReq.push(testData.buildTestName)

                runner.reg
                  name: testData.testName
                  data:
                    kind: "tlog"
                    src : runner.relativeFn(fn)
                  testData : testData
                  after: testReq
                  #before: testData.before
                  promise: toolfuns.regLogRun
                true
              catch e
                runner.info "#{fn}. registration failed! #{e}"
                return true
        (true)
