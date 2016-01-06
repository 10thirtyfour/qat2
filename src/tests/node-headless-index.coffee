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

process.maxTickDepth = Infinity

splitByCommas = (str)->
  str.replace("[","").replace("]","").replace('"',"").replace("'","").split(",")

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
                    runner.info("#{fn}. Skipping on this platform")
                    return true

                testReq = []
                if typeof testData.after is "string"
                  testReq = testReq.concat( splitByCommas(testData.after) )
                unless runner.argv["skip-build"]
                  buildTestName="#{testData.projectName}/#{testData.programName}"
                  if buildTestName of runner.tests
                    testReq.forEach (r)->
                      if runner.tests[buildTestName].after.indexOf(r)==-1
                        runner.tests[buildTestName].after.push(r)
                  else
                    runner.reg
                      name: buildTestName
                      failOnly: true
                      data:
                        kind: "build"
                        src : fn
                      testData : testData
                      after : testReq.slice()
                      promise: toolfuns.regBuild

                  testReq.push(buildTestName)

                runner.reg
                  name: "#{testData.projectName}/#{testData.testName}"
                  data:
                    kind: "tlog"
                    src : fn
                  testData : testData
                  after: testReq
                  promise: toolfuns.regLogRun
                true
              catch e
                runner.info "#{fn}. registration failed! #{e}"
                return true
        (true)
