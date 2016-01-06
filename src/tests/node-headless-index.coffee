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
              td = new runner.TestData(fn)
              if !td.projectInfo or !td.projectInfo.path or !td.projectInfo.name
                runner.info "#{fn}. Project info read failed!"
                return true

              buildPromiseName = []
              testData = toolfuns.LoadHeaderData(fn)

              unless runner.argv["skip-build"]
                buildPromiseName="#{td.projectInfo.name}/#{td.tlogHeader.prog}"
                unless buildPromiseName of runner.tests
                  runner.reg
                    name: buildPromiseName
                    failOnly: true
                    data:
                      kind: "build"
                      src : fn
                    testData : testData
                    promise: toolfuns.regBuild

              runner.reg
                name: "#{td.projectInfo.name}/#{td.testName}"
                data:
                  kind: "tlog"
                  src : fn
                testData : testData
                after: buildPromiseName
                promise: toolfuns.regLogRun
              (true)
        (true)
