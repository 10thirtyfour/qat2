byline = require "byline"
spawn = require("child_process").spawn
http = require "http"
fse = require "fs-extra"

{CallbackReadWrapper} = require "./readercallback"

module.exports = ->
  {yp,fs,_,Q,path,xpath,dom} = runner = @
  
  # acquiring test data from filename if needed
  cutofTest = (testName) ->
    return path.basename testName[0...(testName.length-5-path.extname(testName).length)]

  parceError = (raw) ->
    errorMessage = raw : raw
    errorMessage.xml = new dom().parseFromString(raw)
    
    try
      errorMessage.code = xpath.select1("/problem/error/code/text()",errorMessage.xml).toString()
    catch 
      errorMessage.code=-1
    finally
      errorMessage.code?=-1
     
    try 
      errorMessage.line = xpath.select1("/problem/source/@first_line",errorMessage.xml).value
    catch
      errorMessage.line=-1
    finally
      errorMessage.line?=-1
       
    try   
      errorMessage.message = xpath.select1("/problem/error/message/text()",errorMessage.xml).toString()
    catch
      errorMessage.message = raw 
    
    errorMessage

  getTestData = (params) ->
    
    testData = 
      programName : (params.programName or params.program)
      projectPath : (params.projectPath or params.project or params.prj)
      reverse : (params.reverse or params.fail)
      timeout : params.timeout
      buildMode : if params.deploy is true then "all" else "rebuild"
      
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
    if process.platform is "ia32" or process.platform is "x64" then testData.programExecutable+=".exe" 

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
            throw "ERROR in line : #{nextLogLine(1)}\nActual :#{actualLine}\nExpected :#{expectedLine}"
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
      child = spawn command,args

	      
      child.on "exit", (code) ->
        runner.info name+" "+runner.platform
        runner.tests[name].env = JSON.parse(child.stdout.read().toString('utf8'))
        def.resolve code
        
      child.on "error", (e) -> def.reject("environ.bat execution failed")
      
      return def.promise
      
    regExecPromise: ->
      @info @data.command   
      [command,args...] = @data.command.split(" ")
      {stdout,stdin} = child = spawn command,args,@data.options
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
        
        @testData.timeout?=20000
        
        switch (path.extname(@testData.fileName)).toLowerCase()
          when ".4gl" then @data.cmdLine = "qfgl.exe #{@testData.fileName} -d #{opt.env.LYCIA_DB_DRIVER} -o #{path.join( path.dirname(@testData.fileName), path.basename(@testData.fileName,'.4gl'))}.4o --xml-errors"
          when ".per" then @data.cmdLine = "qform.exe #{@testData.fileName} -db #{opt.env.LYCIA_DB_DRIVER} -p #{path.dirname(@testData.fileName)}"

        if @testData.options? then @data.cmdLine+=" #{@testData.options}"
        
        [command,args...] = @data.cmdLine.split(" ")
        
        command = path.join(opt.env.LYCIA_DIR,"bin",command)
        
        try
          {stderr} = child = spawn( command , args , opt) 
          
          result = (yp exitPromise(child).timeout(@testData.timeout))
          if result
            txt = stderr.read().toString('utf8')
            errorMessage = parceError(txt)
            
            if @testData.reverse
              if (not @testData.errorCode) or (parseInt(@testData.errorCode,10) is parseInt(errorMessage.code,10))
                return "Code matched:#{errorMessage.code}. Line:#{errorMessage.line}."
              else 
                throw "ErrorCode mismatch! Expected: #{@testData.errorCode}, Actual :#{errorMessage.code} at Line:#{errorMessage.line}."

            # construction error message
            @data.failMessage=errorMessage.message
            throw "Compilation failed. Code: #{errorMessage.code}, Line: #{errorMessage.line}"
            
        finally 
          child.kill('SIGTERM')
        if @testData.reverse then throw "Successful compilation, but fail expected!"
        return "Successful compilation."

        
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
          child = spawn( exename , params , opt) 
          result = (yp exitPromise(child).timeout(@testData.timeout))
          if result
            if @testData.reverse 
              return "Build has been failed as expected."
            throw child.stdout.read().toString('utf8')
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
          ].concat( @testData.programArgs )
          
          
          
          @data.commandLine = "qrun "+ params.join(" ")
          child = spawn( exename, params, opt)
                       
          @testData.ignoreHeadlessErrorlevel = true; #????
          
          childPromise = exitPromise(child, @testData.ignoreHeadlessErrorlevel ).timeout(@timeouts.run, "Log timeout")
          logPromise = yp.frun( => runLog( child , @testData.fileName, @timeouts.line, setCurrentStatus) )
          yp Q.all( [ childPromise, logPromise ] )
        finally
          child.kill('SIGTERM')
      )
      
    LoadHeaderData : (logFileName) ->
      testData =
        fileName: logFileName

      logStream = fs.createReadStream(logFileName, encoding: "utf8")
      nextLogLine = lineFromStream logStream
      try
        while (line=nextLogLine())
          break if line is "<<<"
          if (matches=(line.match "^<< *(.*?) *>>$"))
            cmd = matches[1]
            # handling both, quoted and unquoted program name
            if (matches=(cmd.match '"(.*?)" *(.*)'))
              testData.programName=matches[1]
              testData.programArgs=matches[2].split(" ")
            else
              [testData.programName,testData.programArgs...]=cmd.split(" ")
            break
        # removing database arg if found one
        if testData.programArgs.indexOf("-d")>-1
          testData.programArgs.splice(testData.programArgs.indexOf("-d"),2)   

        # removing ".exe"  
        if testData.programName.lastIndexOf(".exe")>testData.programName.length - 5
           testData.programName=testData.programName.substr(0,testData.programName.length - 4)
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
      catch e
        console.log e
      return testData    
  

    regXPath : ->
      yp.frun => 
        rawxml=fs.readFileSync(@testData.fileName,'utf8').replace(' xmlns="http://namespaces.querix.com/2011/fglForms"',"")
        xml = new dom().parseFromString(rawxml)
        s = xpath[@testData.method](@testData.query, xml).toString()
        
        if s is @testData.sample
          return "Matched!"
        else
          throw "String mismatch. Expected: #{@testData.sample}. Actual: #{s}."
      
    
  runner.extfuns =  
  
    CheckXML: (testData) ->
      yp.frun => 
        testData.fileName?=testData.fn or cutofTest(@fileName)
        testData.method?="select"
        testData.reverse?=testData.fail
        testData.timeout?=10000
        testData.fileName = path.resolve(path.dirname(@fileName),testData.fileName)
        testData.options?=testData.opts
        
        
        
        testData.ext = path.extname(testData.fileName).toLowerCase()
        unless testData.ext
          testData.ext= if fs.existsSync(testData.fileName+".fm2") then ".fm2" else ".per"
        else  
          testData.fileName = path.join(path.dirname(testData.fileName), path.basename(testData.fileName,testData.ext))

        suspectTestName = path.relative(path.dirname(@fileName), testData.fileName)
        
        if testData.ext is ".per"
          compileTestName=["advanced$#{@relativeName}$compile$#{suspectTestName}.per"]
          unless compileTestName[0] of runner.tests
            runner.reg
              name: compileTestName[0]
              data:
                kind: "compile"+testData.ext
              testData: 
                fileName: testData.fileName+".per"
                options: testData.options
              promise: runner.toolfuns.regCompile 
          testData.ext = ".fm2"
          
        testData.fileName = testData.fileName+".fm2"
        n = 0
        loop
          testName="advanced$#{@relativeName}$xpath$#{suspectTestName}$#{n}"
          n+=1
          unless testName of @runner.tests then break
        
        runner.reg
          name: testName
          after: compileTestName
          data:
            kind: "xpath"
          testData: testData
          promise: runner.toolfuns.regXPath
        return ->
          nop=0
        
    Compile: (arg, additionalParams) ->
      yp.frun =>
        if typeof arg is "string"
          testData = _.defaults(fileName:arg,additionalParams)
        else
          testData = if arg? then arg else fileName:cutofTest(@fileName)

        testData.fileName?=(testData.fn or cutofTest(@fileName))
        testData.reverse?=testData.fail
        testData.errorCode?=(testData.error or testData.err)
        testData.options?=testData.opts
        
        if testData.errorCode? then testData.reverse = true 
        
        delete testData.fail
        delete testData.fn
       
        if testData.ext?
          unless testData.ext[0] is "." then testData.ext="."+testData.ext
        else
          # .4gl used as default extension"
          testData.ext=".4gl"
        testData.fileName = path.join(path.resolve path.dirname(@fileName), path.dirname(testData.fileName),path.basename(testData.fileName))
        
        unless path.extname(testData.fileName).length 
          testData.fileName+=testData.ext
        else
          testData.ext=path.extname(testData.fileName)

        suspectTestName = path.relative path.dirname(@fileName), testData.fileName
          
          
        runner.reg
          name: "advanced$#{@relativeName}$compile$#{suspectTestName}"
          data:
            kind: "compile"+testData.ext.toLowerCase()
          testData: testData
          promise: runner.toolfuns.regCompile 
        return ->
          nop=0
       
    Build: (arg, additionalParams={}) ->
      yp.frun =>
        if typeof arg is "string"
          testData = additionalParams
          testData.program = arg
        else
          testData = arg

        testData.testFileName = @fileName
        testData = getTestData(testData)
        unless testData.programName? then throw "Can not read programName from "+@fileName
        unless testData.projectPath? then throw "projectPath undefined"

        testData.fileName = path.join(testData.projectPath,"source","."+testData.programName+".fgltarget")
        testData.relativeFileName =  path.relative runner.tests.globLoader.root, testData.fileName

        # ------  deploy workaround
        if testData.buildMode is "all"
          testData.buildMode = "rebuild"
          runner.reg
            name:"advanced$#{@relativeName}$deploy$#{testData.relativeFileName}"
            after:["advanced$#{@relativeName}$build$#{testData.relativeFileName}"]
            data:
              kind: "deploy-workaround"
            promise: ->
              yp.frun( =>
                try 
                  rawxml=fs.readFileSync(testData.fileName,'utf8').replace(' xmlns="http://namespaces.querix.com/lyciaide/target"',"")
                  xml = new dom().parseFromString(rawxml)
                  filesToCopy = [testData.programName+".exe"]
                  
                  # 
                  formExtCare = (fn) -> 
                    unless path.extname(fn) is ".per" then return fn else return fn.substr(0,fn.lastIndexOf(".")) + ".fm2"
    
                  filesToCopy.push formExtCare(fn.value) for fn in xpath.select('//fglBuildTarget/sources[@type="form"]/*/@location',xml)
                  filesToCopy.push fn.value for fn in xpath.select('//fglBuildTarget/mediaFiles/file[@client="true"]/@location',xml)
                  tr2file = '<?xml version="1.0" encoding="UTF-8"?>\n<Resources>\n'

                  for fn in filesToCopy
                    sourceFile = path.join(testData.projectPath,"output",fn)
                    targetFile = path.join(runner.deployPath,fn)
                    fse.ensureDirSync path.dirname(targetFile)
                    fse.copySync(sourceFile,targetFile)
                    tr2file+='  <Resource path="'+fn+'"/>\n'
                  tr2file+='</Resources>\n'
                  fs.writeFileSync(path.join(runner.deployPath,testData.programName+".tr2"),tr2file)

                                        
                catch e
                  throw e
                
              )
             
        # ------ end of deploy workaround
        
        runner.reg 
          name: "advanced$#{@relativeName}$build$#{testData.relativeFileName}"
          data:
            kind: if testData.reverse then "build-reverse" else "build"
          testData: testData  
          promise: runner.toolfuns.regBuild
        return ->
          nop=0
          
    RegWD : (obj,testId) ->
      testName = path.relative runner.tests.globLoader.root,@fileName
      if testId then testName+="$"+testId 
      runner.regWD
        syn: obj
        name: testName
        
      
