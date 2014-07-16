process.maxTickDepth = Infinity

module.exports = ->
  {Q,yp,toolfuns} = runner = @
  
  @reg
    name: "tlogLoader"
    before: "globLoader"
    setup: true 
    disabled: false
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$headless-indexer"
        pattern: ["**/*.tlog"]
        parseFile: (fn) ->
          yp.frun( =>
            testData = toolfuns.regLoadHeaderData(fn)

            unless testData.programName?
              runner.info "Can not read programName from "+testData.fileName
              return ->
                "Can not read programName from "+testData.fileName
                
            unless testData.projectPath?
              runner.info "projectPath undefined"
              return ->
                "projectPath undefined"

            buildPromiseName=[]

            unless runner.argv["skip-build"]
              buildPromiseName=["headless$build$#{testData.projectPath}$#{testData.programName}"]
              runner.reg 
                name: buildPromiseName[0]
                data:
                  kind: "build" 
                testData : testData  
                promise: toolfuns.regBuild
              
            runner.reg
              name: "headless$play$#{testData.projectName}$#{testData.programName}$"+testData.fileName
              data:
                kind: "common-tlog"
              testData : testData  
              after: buildPromiseName
              promise: toolfuns.regLogRun

            return ->
              nop=0
                            
            
          )
      Q({})

