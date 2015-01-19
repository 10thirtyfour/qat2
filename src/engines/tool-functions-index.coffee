byline = require "byline"
spawn = require("child_process").spawn
http = require "http"
qs = require "querystring"
fse = require "fs-extra"

{CallbackReadWrapper} = require "./readercallback"

uniformName = (tn) ->
  tn.replace(/\\/g, "/")

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

  combTestData = (testData) ->
    testData.programName ?= testData.program
    testData.projectPath ?= (testData.project or testData.prj)
    testData.reverse ?= testData.fail
    testData.buildMode = if testData.deploy is true then "all" else "rebuild"
      
    unless testData.programName?
      # cutting filename by 12 chars ("-test.coffee")
      testData.programName = cutofTest(testData.testFileName)

    unless testData.projectPath?
      tempPath = testData.testFileName
      while (tempPath != ( tempPath = path.dirname tempPath ))
        if fs.existsSync(path.join(tempPath,".fglproject")) 
          testData.projectPath = tempPath
          break

        
    if testData.projectPath?
      testData.projectName = path.basename testData.projectPath  
      # here can be implemented XML parce of project file. Currently using default paths
      testData.projectSource = 'source' 
      testData.projectOutput = 'output'


    testData.programExecutable = path.join( testData.projectPath , testData.projectOutput , path.basename(testData.programName) )
 
    #looks like on win32 shown also for x64 platform
    if process.platform[0] is "w" then testData.programExecutable+=".exe" 

    return testData

  runLog = (child, testData, setCurrentStatus) ->
    passMessage = ""
    errMessage = ""
    delimeterSent = false 
    writeBlock = ( stream , message, lineTimeout ) ->
      writeLine = ( line ) ->
        yp Q.ninvoke(stream,"write",line+"\n").timeout( lineTimeout , "Log line timed out")
      unless delimeterSent
        writeLine( ">>>" )
        delimeterSent=true  
      writeLine line for line in message

    {stderr,stdout,stdin} = child 
    stdout.setEncoding('utf8')

    stderr.on "data", (e)->
      errMessage+=e.toString('utf8')
   
    nextLogLine = lineFromStream fs.createReadStream( testData.fileName , encoding: "utf8")
    nextOutLine = lineFromStream stdout
    # reading headless greeting delimeter
    # TODO - check it
    readBlock(nextOutLine,"<<<")
      
    while (logBlock = readBlock(nextLogLine))[0]
      setCurrentStatus(nextLogLine("getLine"),nextOutLine("getLine"))
      #log expectedBlock.join "\n"
      switch logBlock[logBlock.length-1]
        when ">>>" 
          # TODO : ensure that nothing in the output
          #if (logBlock = readBlock(nextOutLine,"<<<")).length>1
          #  throw "ERROR : Program output not empty in sending point at line: " + nextLogLine("LineCount")
          writeBlock( stdin , logBlock , testData.lineTimeout )
        when "<<<"
          actualBlock = readBlock(nextOutLine,"<<<")
          actualLine = actualBlock.join "\n"
          expectedLine = logBlock.join "\n"
          fail = (false)
          if actualLine isnt expectedLine
            fail = (true)
            # report double EOL workaround. Skip empty lines
            a1 = _.remove(actualBlock, (i)-> (typeof i is 'string')).join '\n'
            e1 = _.remove(logBlock, (i)-> (typeof i is 'string')).join '\n'
            if a1 is e1
              passMessage=" WARNING : Empty lines was skipped!"
              fail = (false)

            # executable check workaround
            if fail and process.platform[0] is "l" 
              modulename = path.basename testData.programExecutable
              e1 = expectedLine.replace( new RegExp(modulename+'.exe','g'),modulename)
              if actualLine is e1 
                passMessage=" WARNING : .exe removed!"
                fail = (false)

          if fail then throw errMessage + "Stopped at line : #{nextLogLine(1)}\nActual :#{actualLine}\nExpected :#{expectedLine}"
          
    if (logBlock = readBlock(nextOutLine,"<<<")).length>1
      throw errMessage + "ERROR : Program output not empty at the end of scenario. " + logBlock
    return "Lines : [#{nextLogLine("getLine")},#{nextOutLine("getLine")}]."+ passMessage

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

  exitPromise = (child, opt={}) ->
    def = Q.defer()
    child.on "exit", (code) ->
      if opt.returnOutput?
        def.resolve child.stdout.read()
      else 
        def.resolve code
    if opt.ignoreError?
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
    spammer: (fun,params)->
      params.function = fun
      params.contact = "REST protocol"
      http.get("http://"+runner.logger.transports.couchdb.host+":14952/d&"+qs.stringify(params))
      .on "error", (e)-> 
        #console.log fun+" post failed"
        return (true)  
    
    getEnviron: ->
      runner = @runner
      _this=@
      
      runner.sysinfo = 
        host : runner.os.hostname()
        starttimeid : (new Date()).toISOString()
        platform : process.platform.substring(0,3)+'_'+process.arch
        ver : runner.os.release()
        user : process.env.USER ? process.env.USERNAME
        build : "unknown" 
      
      @info runner.sysinfo.platform + " " + runner.sysinfo.ver
      
      [command,cc,args...] = _.compact @data.command.split(" ")
      
      exitPromise( spawn(command,[cc,args.join(" ")]), returnOutput:true) 
      .then( (envtext)->
        runner.environ = JSON.parse(envtext.toString('utf8'))
        exitPromise( spawn( path.join(runner.environ.LYCIA_DIR,"bin","qfgl"),["-V"], env : runner.environ ), returnOutput:true))
      .then( (qfglout)->
        if qfglout?
          runner.sysinfo.build = qfglout.toString('utf8').split("\n")[2].substring(7)
          runner.logger.pass "qatstart",runner.sysinfo
          runner.toolfuns.spammer "sendMessage", message:"!! "+runner.sysinfo.starttimeid+"\nQAT started on #{runner.sysinfo.host}\nPlatform : #{runner.sysinfo.platform}\nLycia build : "+runner.sysinfo.build
        return runner.sysinfo)
      .catch( (err)->
        _this.fail err.message
        throw "Unable to read environ : "+err.message
      )  
      
    regExecPromise: ->
      @info @data.command   
      [command,args...] = _.compact @data.command.split(" ")
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
          env: {}
          cwd: path.dirname(@testData.fileName)

        _.merge opt.env, @runner.environ
        _.merge opt.env, @options.commondb
        
        #@data.sysinfo = @runner.sysinfo
        
        @testData.compileTimeout?=20000
        cmdLine = ""
        switch (path.extname(@testData.fileName)).toLowerCase()
          when ".4gl" then cmdLine = "qfgl #{@testData.fileName} --xml-errors -d #{opt.env.LYCIA_DB_DRIVER} -o #{path.join( path.dirname(@testData.fileName), path.basename(@testData.fileName,'.4gl'))}.4o -e Cp1252"
          when ".per" then cmdLine = "qform #{@testData.fileName} -xmlout -xml -db #{opt.env.LYCIA_DB_DRIVER} -p #{path.dirname(@testData.fileName)} -e Cp1252"
        if @testData.options? then cmdLine+=" #{@testData.options}"
        
        [command,args...] = _.compact cmdLine.split(" ")
        
        command = path.join(opt.env.LYCIA_DIR,"bin",command)

        #looks like on win32 shown also for x64 platform
        #if process.platform is "ia32" or process.platform is "x64" then command+=".exe"
        try
          {stderr} = child = spawn( command , args , opt )
          result = (yp exitPromise(child, ignoreError:true ).timeout(@testData.compileTimeout))
          if result
            txt = stderr.read()
            if txt?
              errorMessage = parceError(txt.toString('utf8'))

            errorMessage?= { text:txt, code:-1, line:-1 }
            if @testData.reverse
              if (not @testData.errorCode) or (parseInt(@testData.errorCode,10) is parseInt(errorMessage.code,10))
                return "Code matched:#{errorMessage.code}. Line:#{errorMessage.line}."
              else 
                throw "ErrorCode mismatch! Expected: #{@testData.errorCode}, Actual :#{errorMessage.code} at Line:#{errorMessage.line}."

            # construction error message
            @data.failMessage=errorMessage.message
            throw "Compilation failed. Code: #{errorMessage.code}, Line: #{errorMessage.line}"
            
        finally 
          child.kill('SIGKILL')
        if @testData.reverse then throw "Successful compilation, but fail expected!"
        return "Successful compilation."

        
      )      
    
    regBuild: ->
      yp.frun( => 
        opt = 
          env: {}
          cwd: path.resolve(@testData.projectPath)
        
        _.merge opt.env, @runner.environ
        _.merge opt.env, @options.commondb

        exename = path.join(opt.env.LYCIA_DIR,"bin","qbuild")
        
        @testData.buildMode ?= @options.buildMode 
        @testData.buildTimeout ?= @timeouts.build
        params = [ "-M", @testData.buildMode, opt.cwd, path.basename(@testData.programName) ]
        #@data.commandLine = "qbuild " + params.join(" ")
        try
          child = spawn( exename , params , opt) 
          result = (yp exitPromise(child).timeout(@testData.buildTimeout,"Build timed out"))
          if result
            if @testData.reverse 
              return "Build has been failed as expected."
            message = ""
            text = child.stdout.read()
            if text? then message=text.toString('utf8')
            throw text
        catch e
          throw "Build failed with message : "+e
        finally 
          child.kill('SIGKILL')
        if @testData.reverse then throw "Build OK but fail expected!"
        return "Build OK."
      )
      
    regLogRun : ->
      yp.frun( => 
        try
          
          opt = 
            env: {}
            cwd: path.resolve(@testData.projectPath,@testData.projectOutput)

          _.merge opt.env, @runner.environ
          _.merge opt.env, @options.commondb
          _.merge opt.env, @options.headless
          _.merge opt.env, @testData.env

          logLine = 0
          outLine = 0
          
          setCurrentStatus = (logL,outL) =>
            logLine = logL
            outLine = outL
            
          exename = path.join(opt.env.LYCIA_DIR, "bin", "qrun")
          
          params = [
            @testData.programExecutable
            "-d"
            opt.env.LYCIA_DB_DRIVER
          ].concat( @testData.programArgs )
          
          #@data.commandLine = "qrun "+ params.join(" ")
          child = spawn( exename, params, opt)
                       
          @testData.ignoreHeadlessErrorlevel = true; #????
          
          @testData.runTimeout ?= @timeouts.run
          @testData.lineTimeout ?= @timeouts.line
          
          childPromise = exitPromise(child, ignoreError : @testData.ignoreHeadlessErrorlevel ).timeout(@testData.runTimeout, "Log timeout")
          #logPromise = yp.frun( => runLog( child , @testData.fileName, @testData.lineTimeout, setCurrentStatus) )
          logPromise = yp.frun( => runLog( child , @testData, setCurrentStatus) )
          res = yp Q.all( [ childPromise, logPromise ] )
          
          "Code : "+res.join ". "
                
        finally
          child.kill('SIGKILL')
          
      )
      
    LoadHeaderData : (logFileName) ->
      testData =
        fileName: logFileName
        env : {}

      try
        logStream = fs.createReadStream(logFileName, encoding: "utf8")
        nextLogLine = lineFromStream logStream
        while (line=nextLogLine())
          break if line is "<<<"
          
          # environment variable search
          if (matches=(line.match "^<< *testData *# *(.*?)=(.*?) *>>$"))
            # inserting params into testData with path
            matches[1].split('.').reduce( (prev,curr,i,ar)-> 
              if i+1==ar.length then return (prev[curr]=matches[2]) else return (prev[curr]?={})
            , testData)

          else
            # trying to find programName only if it is not yet defined
            unless testData.programName?
              if (matches=(line.match "^<< *(.*?) *>>$"))
                cmd = matches[1]
                # handling both, quoted and unquoted program name
                if (matches=(cmd.match '"(.*?)" *(.*)'))
                  testData.programName=matches[1]
                  testData.programArgs=matches[2].split(" ")
                else
                  [testData.programName,testData.programArgs...]=cmd.split(" ")
 
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
          # here can be implemented XML parce of project file. Currently using default paths
          testData.projectSource = 'source' 
          testData.projectOutput = 'output'

        testData.programExecutable = path.join(testData.projectPath , testData.projectOutput , path.basename(testData.programName))
        #looks like on win32 shown also for x64 platform
        if process.platform is "win32" then testData.programExecutable+=".exe"
        #testData.projectPath = path.resolve(testData.projectPath)
      catch e
        testData.errorMessage = e
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
    uniformName : uniformName
    log : console.log
    
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
          compileTestName= uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}.per")
          unless compileTestName of runner.tests
            runner.reg
              name: compileTestName
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
          testName = uniformName("advanced$#{@relativeName}$xpath$#{suspectTestName}$#{n}")
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
        
        if testData.errorCode? then testData.reverse = (true)  
        
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
          name: uniformName("advanced$#{@relativeName}$compile$#{suspectTestName}")
          data:
            kind: "compile"+testData.ext.toLowerCase()
          testData: testData
          promise: runner.toolfuns.regCompile 
        return ->
          nop=0
       
    Build: (arg, additionalParams={}) ->
      if typeof arg is "string"
        testData = additionalParams
        testData.programName = arg
      else
        arg?={}
        testData = arg
      
      testData.testFileName = @fileName
      testData = combTestData(testData)
      
      unless testData.programName? then throw "Can not read programName from "+@fileName
      unless testData.projectPath? then throw "projectPath undefined"

      testData.fileName = path.join(testData.projectPath,testData.projectSource,"."+testData.programName+".fgltarget")
      progRelativeName = path.relative runner.tests.globLoader.root, path.join(testData.projectPath, testData.projectSource, testData.programName)
      testData.buildTestName = uniformName("advanced$#{@relativeName}$build$#{progRelativeName}")
      
      # storing test name and program name in test context for future use in WD test
      @lastBuiltTestName = testData.buildTestName
      @lastBuilt = testData.programName
      
      if testData.buildMode is "all"
        testData.deployTestName = uniformName("advanced$#{@relativeName}$deploy$#{progRelativeName}")        
        testData.buildMode = "rebuild"
        @lastBuiltTestName = testData.deployTestName
      
      # ------  deploy workaround
      if testData.deployTestName?
        runner.reg
          name: testData.deployTestName
          after: [ testData.buildTestName ]
          failOnly : (true)
          data:
            kind: "deploy"
          promise: ->
            yp.frun( =>
              try 
                rawxml=fs.readFileSync(testData.fileName,'utf8').replace(' xmlns="http://namespaces.querix.com/lyciaide/target"',"")
                xml = new dom().parseFromString(rawxml)
                filesToCopy = [testData.programName]
                if process.platform[0] is "w" then filesToCopy[0]+='.exe'
                
                formExtCare = (fn) -> 
                  unless path.extname(fn) is ".per" then return fn else return fn.substr(0,fn.lastIndexOf(".")) + ".fm2"
  
                filesToCopy.push formExtCare(fn.value) for fn in xpath.select('//fglBuildTarget/sources[@type="form"]/*/@location',xml)
                #filesToCopy.push fn.value for fn in xpath.select('//fglBuildTarget/mediaFiles/file[@client="true"]/@location',xml)
                filesToCopy.push fn.value for fn in xpath.select('//fglBuildTarget/mediaFiles/file/@location',xml)
                tr2file = '<?xml version="1.0" encoding="UTF-8"?>\n<Resources>\n'

                for fn in filesToCopy
                  try
                    sourceFile = path.join(testData.projectPath,testData.projectOutput,fn)
                    targetFile = path.join(runner.deployPath,fn)
                    fse.ensureDirSync path.dirname(targetFile)
                    fse.copySync(sourceFile,targetFile)
                  catch e
                    runner.info "Failed to copy file : "+fn
                  tr2file+='  <Resource path="'+fn+'"/>\n'
                tr2file+='</Resources>\n'
                fs.writeFileSync(path.join(runner.deployPath,testData.programName+".tr2"),tr2file)

                if process.platform[0] is "l"
                  ffn = path.join(runner.deployPath,filesToCopy[0])
                  fs.chmodSync( ffn , "755")
                
                "Files deployed : #{filesToCopy.length}"                          
              catch e
                throw e
            )
      # ------ end of deploy workaround

      testData.failOnly ?= testData.deploy
      
      runner.reg 
        name: testData.buildTestName
        data:
          kind: "build"
        testData: testData  
        failOnly : testData.failOnly
        promise: runner.toolfuns.regBuild
      return @lastBuiltApp
        
          
    RegWD : (obj, params) ->
      @lastBuiltApp?=[]
      params ?= {}
      params.after?=@lastBuiltTestName
      params.testName?= uniformName(path.relative(runner.tests.globLoader.root,@fileName))
      if params.testId then params.testName+="$"+params.testId 
      runner.regWD
        syn: obj
        name: params.testName
        after : params.after
        lastBuilt : @lastBuilt
            
        
        
    reg : (params...) ->
      runner.reg params...
      


 