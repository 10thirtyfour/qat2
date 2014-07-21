byline = require "byline"
spawn = require("child_process").spawn
http = require "http"

{CallbackReadWrapper} = require "./readercallback"

module.exports = ->
  {yp,fs,_,Q,path,xpath,dom} = runner = @
  
  # acquiring test data from filename if needed
  cutofTest = (testName) ->
    return path.basename testName[0...(testName.length-5-path.extname(testName).length)]

  getTestData = (params) ->
    
    testData = 
      programName : (params.programName or params.program)
      projectPath : (params.projectPath or params.project or params.prj)
      reverse : (params.reverse or params.fail)
      timeout : params.timeout
      buildMode : if params.deploy? then "all" else "rebuild"
      
    unless testData.programName?
      # cutting filename by 12 chars
      testData.programName = cutofTest(params.testFileName)

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
      
    regCompile: ->
      yp.frun( =>
        opt = 
          env: @runner.tests["read$environ"].env
          
        _.merge opt.env, @options.commondb
        switch (@testData.ext).toLowerCase()
          when ".4gl" then @data.cmdLine = "qfgl.exe #{@testData.fileName} -d #{@options.commondb.LYCIA_DB_DRIVER} -o #{path.join(@runner.tempPath,path.basename(@testData.fileName,'.4gl'))}.4o --xml-errors"
          when ".per" then @data.cmdLine = "qform.exe #{@testData.fileName} -db #{@options.commondb.LYCIA_DB_DRIVER} -p #{@runner.tempPath}"
        [command,args...] = @data.cmdLine.split(" ")
        
        command = path.join(opt.env.LYCIA_DIR,"bin",command)
        
        try
          {stdout,stderr} = child = spawn( command , args , opt) 
          stdout.setEncoding('utf8')
          stderr.setEncoding('utf8')
          result = (yp exitPromise(child).timeout(@testData.timeout))
          if result
            try
              errorMessage = stderr.read()
              xmlerr = new dom().parseFromString(errorMessage)
              @data.failReason = xpath.select("/problem/error/code",xmlerr)[0].firstChild.data
            catch 
              @data.failReason = errorMessage or stdout.read()
            
            if @testData.reverse
              if (not @testData.errorCode) or (parseInt(@testData.errorCode,10) is parseInt(@data.failReason,10))
                return "Compilation has been failed as expected."
              @data.failReason = "ErrorCode mismatch! expected : #{@testData.errorCode}, actual : #{@data.failReason}."
            throw @data.failReason
        catch errorMessage
          throw errorMessage
        finally 
          child.kill('SIGTERM')
        if @testData.reverse then throw "Compilation successful but fail expected!"
        return "Compilation successful"

        
      )      
    
    regBuild: ->
      yp.frun( => 
        opt = 
          env: @runner.tests["read$environ"].env
          cwd: @testData.projectPath
        
        _.merge opt.env, @options.commondb

        exename = path.join(opt.env.LYCIA_DIR,"bin","qbuild")
        
        @testData.buildMode ?= @options.buildMode 
        @testData.timeout ?= @timeouts.build
        params = [ "-M", @testData.buildMode, @testData.projectPath, path.basename(@testData.programName) ]
        @data.commandLine = "qbuild " + params.join(" ")
        try
          {stdout} = child = spawn( exename , params , opt) 
          stdout.setEncoding('utf8')
          result = (yp exitPromise(child).timeout(@testData.timeout))
          if result
            if @testData.reverse 
              return "Build has been failed as expected."
            throw stdout.read()
        catch e
          @data.failReason = e
          throw "Build failed!"
        finally 
          child.kill('SIGTERM')
        if @testData.reverse then throw "Build OK but fail expected!"
        return "Build OK."
      )
      
    regLogRun : ->
      yp.frun( => 
        try
          opt = 
            env: @runner.tests["read$environ"].env
            cwd: path.join(@testData.projectPath,"output")
 
          _.merge opt.env, @options.commondb
          _.merge opt.env, @options.headless

          setCurrentStatus = (logLine,outLine) =>
            @data.logLine = logLine
            @data.outLine = outLine
            
          exename = path.join(opt.env.LYCIA_DIR, "bin", "qrun")
          
          params = [
            @testData.programExecutable
            "-d"
            @options.commondb.LYCIA_DB_DRIVER
          ]
          
          @data.commandLine = "qrun "+ params.join(" ")
          child = spawn( exename, params, opt)
                       
          @testData.ignoreHeadlessErrorlevel = true; #????
          
          childPromise = exitPromise(child, @testData.ignoreHeadlessErrorlevel ).timeout(@timeouts.run, "Log timeout")
          logPromise = yp.frun( => runLog( child , @testData.fileName, @timeouts.line, setCurrentStatus) )
          yp Q.all( [ childPromise, logPromise ] )
        finally
          child.kill('SIGTERM')
      )
      
    regLoadHeaderData : (logFileName) ->
      testData =
        fileName: logFileName
    
      logStream = fs.createReadStream(logFileName, encoding: "utf8")
      nextLogLine = lineFromStream logStream
    
      while (line=nextLogLine())
        break if line is "<<<"
        # << "something.exe" whatever >> turn to 'something' and can handle names with or without .exe
        if (matches=(line.match /^<< "?(.*?)(?:.exe)?"? -d.*>>/))
          testData.programName = matches[1]
        #if (matches=(line.match /^<< "?(.*?)(?:.exe)?"? -d.*>>/))
          #testData.programName = matches[1]
        # TODO : ticket number search here and some other params
        # also can be placed inside testData
   
      #looking for .fglproject file. Moving up from logFname
      tempPath = path.resolve(logFileName)
      while (tempPath != ( tempPath = path.dirname tempPath ))
        if fs.existsSync(path.join(tempPath,".fglproject")) 
          testData.projectPath = tempPath
          break
      if testData.projectPath?
        testData.projectName = path.basename testData.projectPath  
    
      testData.programExecutable = path.join(testData.projectPath,"output",path.basename(testData.programName))
      #looks like on win32 shown also for x64 platform
      if process.platform is "win32" then testData.programExecutable+=".exe"
      #testData.projectPath = path.resolve(testData.projectPath)
      return testData    

    
  runner.extfuns =  
  
    Compile: (arg, additionalParams) ->
      yp.frun =>
        if typeof arg is "string"
          testData = _.defaults(fileName:arg,additionalParams)
        else
          testData = if arg? then arg else fileName:cutofTest(@fileName)

        testData.fileName?=(testData.fn or cutofTest(@fileName))
        testData.reverse?=testData.fail
        testData.timeout?=20000
        testData.errorCode?=(testData.error or testData.err)

        if testData.errorCode? then testData.reverse = true
        
        delete testData.fail
        delete testData.fn
        
       
        if testData.ext?
          unless testData.ext[0] is "." then testData.ext="."+testData.ext
        else
          # .4gl used as default extension"
          testData.ext=".4gl"
        testData.fileName = path.join(path.resolve path.dirname(@fileName), path.dirname(testData.fileName),path.basename(testData.fileName))
        
        unless path.extname(testData.fileName) 
          testData.fileName+=testData.ext
        else
          testData.ext=path.extname(testData.fileName)
        
        runner.reg
          name: "headless$#{@fileName}$compile$#{testData.fileName}"
          data:
            kind: "compile"+testData.ext
          testData: testData
            
          promise: runner.toolfuns.regCompile 
        return ->
          nop=0
       
    Build: (arg, additionalParams) ->
      yp.frun =>
        if typeof arg is "string"
          testData = additionalParams
          testData.program = arg
        else
          testData = arg

        testData.testFileName = @fileName
        testData = getTestData(testData)
        
        unless testData.programName? then throw "Can not read programName from "+testData.fileName
        unless testData.projectPath? then throw "projectPath undefined"

        runner.reg 
          name: "headless$build$#{testData.projectPath}$#{testData.programName}"
          data:
            kind: if testData.reverse then "build-reverse" else "build"
          testData: testData  
          promise: runner.toolfuns.regBuild
        return ->
          nop=0
          
    RegWD : (obj) ->
      runner.regWD
        syn: obj
        name: @fileName
        
      
