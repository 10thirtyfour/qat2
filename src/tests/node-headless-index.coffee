process.maxTickDepth = Infinity

module.exports = ->
  {Q,yp,toolfuns} = runner = @
  
  @reg
    name: "node-headless-search"
    before: "globLoader"
    setup: true 
    promise: ->
      @runner.tests.globLoader.regGlob
        name: "node$headless-indexer"
        pattern: ["**/*.tlog"]
        parseFile: (fn) ->
          yp.frun( =>
            logData = toolfuns.regLoadHeaderData(fn)

            unless logData.programName?
              runner.info "Can not read programName from "+logData.fileName
              return ->
                "Can not read programName from "+logData.fileName
                
            unless logData.projectPath?
              runner.info "projectPath undefined"
              return ->
                "projectPath undefined"

            buildPromiseName=[]
            unless runner.argv["skip-build"]
              buildPromiseName=["headless$build$#{logData.projectPath}$#{logData.programName}"]
              runner.reg 
                name: buildPromiseName[0]
                data:
                  kind: "build" 
                logData : logData  
                promise: toolfuns.regBuild
              
            runner.reg
              name: "headless$play$#{logData.projectName}$#{logData.programName}$"+logData.fileName
              data:
                kind: "common-tlog"
              logData : logData  
              after: buildPromiseName
              promise: toolfuns.regLogRun

            return ->
              nop=0
                            
            
          )
      Q({})

