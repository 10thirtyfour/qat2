byline = require "byline"
spawn = require("child_process").spawn
http = require "http"

{CallbackReadWrapper} = require "./readercallback"

module.exports = ->
  {yp,fs,_,Q,path} = runner = @
  
  # acquiring test data from filename if needed
  getTestData = (fn,programName,projectPath) ->
    testData = 
      programName : programName
      projectPath : projectPath
    unless programName?
      # cutting filename by 12 chars
      testData.programName = path.basename(fn[0...(fn.length-12)])

    unless projectPath?
      tempPath = fn
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
    
    regNegativeBuild: ->  
      yp.frun( => 
        try
          opt = 
            env: @runner.tests["read$environ"].env
            cwd: path.join(@logData.projectPath,"output")
          _.merge opt.env, @options.commondb

          exename = path.join(opt.env.LYCIA_DIR,"bin","qbuild")
          
          params = [
            "-M"
            @options.buildMode
            @logData.projectPath
            path.basename(@logData.programName)
          ]
          
          @data.commandLine = "qbuild " + params.join(" ")
          
          child = spawn(exename, params, opt) 
          {stdout} = child 
    
          stdout.setEncoding('utf8')
          text = yp exitPromise(child).timeout(@timeouts.build)

          unless fs.existsSync(@logData.programExecutable)
            return "Build failed, can't locate executable "+@logData.programExecutable
          else
            @data.failReason = "Build successful"        
            throw "Build successful"
                          
        finally 
          child.kill('SIGTERM')
        return "Build failed"
      )

    regBuild: ->
      yp.frun( => 
        try

          opt = 
            env: @runner.tests["read$environ"].env
            cwd: path.join(@logData.projectPath,"output")

          _.merge opt.env, @options.commondb

          exename = path.join(opt.env.LYCIA_DIR,"bin","qbuild")
          unless @logData.buildMode?
            @logData.buildMode = @options.buildMode 
          params = [
            "-M"
            @logData.buildMode
            @logData.projectPath 
            path.basename(@logData.programName)
          ]
          
          @data.commandLine = "qbuild " + params.join(" ")
     
          
          child = spawn( exename , params , opt) 
          {stdout} = child 
          
          stdout.setEncoding('utf8')
          @logData.timeout ?= @timeouts.build
          text = yp exitPromise(child).timeout(@logData.timeout)
           
          unless fs.existsSync(@logData.programExecutable)
            @data.failReason = "Failed to build executable"
            @data.output = text 
            throw "Build failed, can't locate executable "+@logData.programExecutable
                          
        finally 
          if @data.failReason? 
            @data.failMessage = stdout.read()
          child.kill('SIGTERM')
        return "Build"
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
    ReverseBuild: (programName,projectPath,delay) ->
      yp.frun =>
      
        testData = getTestData(@fileName,programName,projectPath)
        
        unless testData.programName? then return -> "Can not read programName from "+testData.fileName
        unless testData.projectPath? then return -> "projectPath undefined"

        runner.reg 
          name: "headless$negative-build$#{testData.projectPath}$#{testData.programName}"
          data:
            kind: "negative-build" 
          logData: testData  
          promise: runner.toolfuns.regNegativeBuild
        return ->
          nop=0

    Build: (programName,projectPath,timeout) ->
      yp.frun =>
        
        testData = getTestData(@fileName,programName,projectPath)
       
        #enabling deploy
        testData.buildMode = "all"
        testData.timeout = timeout
        
        unless testData.programName? then throw "Can not read programName from "+testData.fileName
        unless testData.projectPath? then throw "projectPath undefined"

        runner.reg 
          name: "headless$build$#{testData.projectPath}$#{testData.programName}"
          data:
            kind: "build" 
          logData: testData  
          promise: runner.toolfuns.regBuild
        return ->
          nop=0
          
    RegWD : (obj) ->
      unless obj.name? 
        obj.name = @fileName
          
      runner.regWD obj
      
    Compile : (fileName, expectedResult) ->
      yp.frun =>
        console.log fileName