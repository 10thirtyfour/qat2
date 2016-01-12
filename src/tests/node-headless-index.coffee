process.maxTickDepth = Infinity

splitByCommas = (str)->
  str.replace(/[\[\]\"\']/g,"").split(",")

module.exports = ->
  {path,yp,toolfuns} = runner = @

  #relfn = (fn)->
  #  path.relative runner.tests.globLoader.root, path.resolve(fn)

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
                    runner.info("#{fn}. Skipping on this platform")
                    return true
                # test names might be specified in tlog
                testData.testName?="#{testData.projectName}/#{path.basename(fn, ".tlog")}"
                testData.buildTestName?="#{testData.projectName}/#{testData.programName}"

                testReq = []
                if typeof testData.after is "string"
                  testReq = testReq.concat( splitByCommas(testData.after) )
                unless runner.argv["skip-build"]
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
                      after : testReq.slice()
                      promise: toolfuns.regBuild

                  testReq.push(testData.buildTestName)

                runner.reg
                  name: testData.testName
                  data:
                    kind: "tlog"
                    src : runner.relativeFn(fn)
                  testData : testData
                  after: testReq
                  promise: toolfuns.regLogRun
                true
              catch e
                runner.info "#{fn}. registration failed! #{e}"
                return true
        (true)
