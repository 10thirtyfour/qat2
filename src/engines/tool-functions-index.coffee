byline = require "byline"
spawn = require("child_process").spawn
http = require "http"

{CallbackReadWrapper} = require "./readercallback"

module.exports = ->
  {yp,fs,_,Q,path} = runner = @
  
  # acquiring test data from filename if needed
  getTestData = (params) ->

    params.programName ?= params.program
    params.projectPath ?= params.project
    params.fail ?= params.reverse
  
    testData = 
      programName : params.programName
      projectPath : params.projectPath
      needFail : params.fail
      timeout : params.timeout
      buildMode : if params.deploy? then "all" else "rebuild"
      
    unless testData.programName?
      # cutting filename by 12 chars
      testData.programName = path.basename(params.testFileName[0...(params.testFileName.length-12)])

    unless testData.projectPath?
      tempPath = params.testFileName
      while (tempPath != ( tempPath = path.dirname tempPath ))
        if fs.existsSync(path.join(tempPath,".fglproject")) 
          testData.projectPath = tempPath
          break
        
    if testData.projectPath?
      testData.projectName = path.basename testData.projectPath  
 
    testData.programExecutable = path.join(testData.projectPath,"output",path.basename(testData.programName))
 
    #looks like on win32 shown also for x64 platform
    if process.platform is "win32" then testData.programExecutable+=".exe" 

    return testData
  
  runLog = (child,logFileName,linetimeout,setCurrentStatus) ->

    delimeterSent = false 
    
    writeBlock = ( stream , message, linetimeout=20000 ) ->
      writeLine = ( line ) ->
        yp Q.ninvoke(stream,"write",line+"\n").timeout( linetimeout )
      unless delimeterSent
        writeLine( ">>>" )
        delimeterSent=true
      writeLine line for line in message

    {stdout,stdin} = child 
   
    stdout.setEncoding('utf8')
    stdin.setEncoding('utf8')
    
    nextLogLine = lineFromStream fs.createReadStream(logFileName, encoding: "utf8")
    nextOutLine = lineFromStream stdout
    # reading headless greeting delimeter
    # TODO - check it
    readBlock(nextOutLine,"<<<")
      
    while (block = readBlock(nextLogLine))[0]
      setCurrentStatus(nextLogLine("getLine"),nextOutLine("getLine"))
      #log block.join "\n"
      switch block[block.length-1]
        when ">>>" 
          # TODO : ensure that nothing in the output
          #if (block = readBlock(nextOutLine,"<<<")).length>1
          #  throw "ERROR : Program output not empty in sending point at line: " + nextLogLine("LineCount")
          writeBlock( stdin , block , linetimeout )
        when "<<<"
          actualLine = readBlock(nextOutLine,"<<<").join "\n"
          expectedLine = block.join "\n"
          if actualLine!=expectedLine
            throw "ERROR in line : "+ nextLogLine(1)+"\nActual :\n"+actualLine+"\nExpected :\n"+expectedLine
    if (block = readBlock(nextOutLine,"<<<")).length>1
      throw "ERROR : Program output not empty at the end of scenario. " + block
    return nextLogLine("LineCount")

  lineFromStream = (stream) ->
    options = 
      keepEmptyLines : 1
    splitted = byline.createStream(stream , options)
    iter = new CallbackReadWrapper splitted
    lineCount = 0
    
    line = (lineCountPrompt) => 
      if lineCountPrompt then return lineCount 
      lineCount+=1
      lineText = yp Q.nfcall((cb) -> 
        iter.read((err,v) -> 
          cb err,v
          ))
      return lineText
    return line

  exitPromise = (child, ignoreError = false) ->
    def = Q.defer()
    child.on "exit", (code) -> def.resolve code
    if ignoreError?
      child.on "error", (code) -> def.resolve code
    else
      child.on "error", (code) -> def.reject code
    def.promise
   
  readBlock = (nextLine, dir) ->
    mess=[]
    while (line=nextLine())
      if line is ">>>" or line is "<<<"
        if dir is line
          mess.push line
          break
        dir = line
        continue
      if dir then mess.push line
    return mess
    
  runner.toolfuns =
    regGetEnviron: ->
      runner = @runner
      name = @name
      
      [command,args...] = @data.command.split(" ")
      
      def = Q.defer()
      child = spawn command,args,@data.options
      child.stdout.setEncoding('utf8')
      
      child.on "exit", (code) ->
        runner.info name
        runner.tests[name].env = JSON.parse(child.stdout.read())
        def.resolve code
        
      child.on "error", (e) -> def.reject("environ.bat execution failed")
      
      return def.promise
      
    regExecPromise: ->
      @info @data.command   
      [command,args...] = @data.command.split(" ")
      child = spawn command,args,@data.options
      exitPromise child
      
    regDownloadPromise: ->
      def = Q.defer()

      tryRequest = ()=>
        if (@data.retries--)<1
          @fail "Download failed"
          def.reject "Download failed"
          return

        @info "Download attempt " + (3-@data.retries)      
        try
          outFile = fs.createWriteStream @data.filename
        catch e
          @fail "Download failed"
          def.reject "Output file creation error. "+e
          return
          
        request = http.get @data.options 
      
        request.on "error", (e) -> tryRequest()
        request.on "response", (response)-> 
          response.on "end", (code) -> 
            def.resolve "Download complete"
          response.on "error", (e) -> tryRequest()
          response.pipe(outFile)
         
      tryRequest()
      def.promise
    
    regBuild: ->
      yp.frun( => 
        opt = 
          env: @runner.tests["read$environ"].env
          cwd: path.join(@logData.projectPath,"output")

        _.merge opt.env, @options.commondb

        exename = path.join(opt.env.LYCIA_DIR,"bin","qbuild")
        
        @logData.buildMode ?= @options.buildMode 
        @logData.timeout ?= @timeouts.build

        params = [ "-M", @logData.buildMode, @logData.projectPath, path.basename(@logData.programName) ]

        @data.commandLine = "qbuild " + params.join(" ")
   
        try
          {stdout} = child = spawn( exename , params , opt) 
          stdout.setEncoding('utf8')
 
          if (yp exitPromise(child).timeout(@logData.timeout))
            if @logData.needFail then return "Build has been failed as expected."
            throw stdout.read()
        catch e
          @data.failReason = e
          throw "Build failed!"
        finally 
          child.kill('SIGTERM')
        if @logData.needFail then throw "Build OK but fail expected!"
        return "Build OK."
      )
      
    regLogRun : ->
      yp.frun( => 
        try
          opt = 
            env: @runner.tests["read$environ"].env
            cwd: path.join(@logData.projectPath,"output")
 
          _.merge opt.env, @options.commondb
          _.merge opt.env, @options.headless

          setCurrentStatus = (logLine,outLine) =>
            @data.logLine = logLine
            @data.outLine = outLine
            
          exename = path.join(opt.env.LYCIA_DIR, "bin", "qrun")
          
          params = [
            @logData.programExecutable
            "-d"
            @options.commondb.LYCIA_DB_DRIVER
          ]
          
          @data.commandLine = "qrun "+ params.join(" ")
          child = spawn( exename, params, opt)
                       
          @logData.ignoreHeadlessErrorlevel = true; #????
          
          childPromise = exitPromise(child, @logData.ignoreHeadlessErrorlevel ).timeout(@timeouts.run, "Log timeout")
          logPromise = yp.frun( => runLog( child , @logData.fileName, @timeouts.line, setCurrentStatus) )
          yp Q.all( [ childPromise, logPromise ] )
        finally
          child.kill('SIGTERM')
      )
      
    regLoadHeaderData : (logFileName) ->
      logData =
        fileName: logFileName
    
      logStream = fs.createReadStream(logFileName, encoding: "utf8")
      nextLogLine = lineFromStream logStream
    
      while (line=nextLogLine())
        break if line is "<<<"
        # << "something.exe" whatever >> turn to 'something' and can handle names with or without .exe
        if (matches=(line.match /^<< "?(.*?)(?:.exe)?"? -d.*>>/))
          logData.programName = matches[1]
        #if (matches=(line.match /^<< "?(.*?)(?:.exe)?"? -d.*>>/))
          #logData.programName = matches[1]
        # TODO : ticket number search here and some other params
        # also can be placed inside logData
   
      #looking for .fglproject file. Moving up from logFname
      tempPath = logFileName
      while (tempPath != ( tempPath = path.dirname tempPath ))
        if fs.existsSync(path.join(tempPath,".fglproject")) 
          logData.projectPath = tempPath
          break
      if logData.projectPath?
        logData.projectName = path.basename logData.projectPath  
    
      logData.programExecutable = path.join(logData.projectPath,"output",path.basename(logData.programName))
      #looks like on win32 shown also for x64 platform
      if process.platform is "win32" then logData.programExecutable+=".exe"
    
      return logData    

    
  runner.extfuns =   
          
    Build: (params) ->
      yp.frun =>
        params.testFileName = @fileName
        testData = getTestData(params)
        
        unless testData.programName? then throw "Can not read programName from "+testData.fileName
        unless testData.projectPath? then throw "projectPath undefined"

        runner.reg 
          name: "headless$build$#{testData.projectPath}$#{testData.programName}"
          data:
            kind: if testData.needFail then "build-reverse" else "build"
          logData: testData  
          promise: runner.toolfuns.regBuild
        return ->
          nop=0
          
    RegWD : (obj) ->
      runner.regWD
        syn: obj
        name: @fileName
        
      
    Compile : (fileName, expectedResult) ->
      yp.frun =>
        console.log fileName