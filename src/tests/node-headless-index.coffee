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
  {path,Q,yp,toolfuns} = runner = @
  
  @reg
    name: "tlogLoader"
    before: ["globLoader"]
    setup: true  
    disabled: false 
    promise: ->
      yp.frun( =>
        @runner.tests.globLoader.regGlob
          name: "node$headless-indexer"
          pattern: ["**/*.tlog"]
          parseFile: (fn) ->
            yp.frun( =>
              testData = toolfuns.LoadHeaderData(fn)
              unless testData.programName?
                runner.info "Can not read programName from "+testData.fileName
                return ->
                  "Can not read programName from "+testData.fileName
                  
              unless testData.projectPath?
                runner.info "projectPath undefined"
                return ->
                  "projectPath undefined"

              progRelativeName = path.relative(runner.tests.globLoader.root, path.join(testData.projectPath, testData.projectSource,testData.programName))
              buildPromiseName = []

              unless runner.argv["skip-build"] 
                buildPromiseName = runner.toolfuns.uniformName("headless$#{progRelativeName}$build")
                unless buildPromiseName of runner.tests
                  runner.reg 
                    name: buildPromiseName
                    failOnly: true
                    data:
                      kind: "build" 
                    testData : testData  
                    promise: toolfuns.regBuild
                
              logRelativeName = path.relative(runner.tests.globLoader.root, fn)
              runner.reg
                name: runner.toolfuns.uniformName("headless$#{logRelativeName}$play")
                data:
                  kind: "common-tlog"
                testData : testData  
                after: buildPromiseName
                promise: toolfuns.regLogRun
              true
            )
        )


