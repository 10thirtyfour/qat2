byline = require "byline"
spawn = require("child_process").spawn
execSync = require("child_process").execSync
http = require "http"
qs = require "querystring"
fse = require "fs-extra"

{CallbackReadWrapper} = require "./readercallback"

module.exports = ->
  {yp,fs,_,Q,path,xpath,dom} = runner = @

  inetEnvSetDatabase = (dbProps) ->
    qatHeader="\n### QAT SECTION START\n"
    qatFooter="### QAT SECTION END\n"
    try
      listenerXml = new dom().parseFromString(fs.readFileSync(runner.environ.LISTENERXML).toString())
      inetEnvFn = xpath.select("/xml/service[name[text() = 'default-1889']]/envfile/text()",listenerXml).toString()
      inetEnv= fs.readFileSync(inetEnvFn).toString()
      inetEnvironments={}
      if inetEnv.indexOf(qatHeader)>-1
        if inetEnv.indexOf(qatFooter)>-1
          footer = inetEnv.slice(inetEnv.indexOf(qatFooter) + qatFooter.length)
        else
          footer = ""
        inetEnv=inetEnv.slice(0,inetEnv.indexOf(qatHeader)) + footer

      dbProps?=runner.opts.dbprofiles[runner.sysinfo.database]
      inetEnvironments=runner.opts.inetEnvironment

      inetEnv+=qatHeader
      for key,val of dbProps
        inetEnv+="#{key}=#{dbProps[key]}\n"
      for key,val of inetEnvironments
        inetEnv+="#{key}=#{inetEnvironments[key]}\n"
      inetEnv+=qatFooter

      fs.writeFileSync(inetEnvFn,inetEnv)

    catch e
      runner.logger.info "Failed to read listener.xml/inet.env"

  lineFromStream = (stream) ->
    options =
      keepEmptyLines : 1

    splitted = new byline.createStream(stream , options)
    iter = new CallbackReadWrapper splitted
    lineCount = 0
    line = (lineCountPrompt) =>
      if lineCountPrompt then return lineCount
      lineCount+=1
      lineText = yp Q.denodeify(iter.read)()
      return lineText
    return line

  cmdlineType = (str)->
    @args=[]
    @add = (params)->
      return unless params?
      parray=params.split(" ") if _.isString(params)
      parray=params if _.isArray(params)
      while parray.length
        arg=parray.shift()
        if arg in ["--e","--db","--p","-d","-e","-o"]
          value = parray.shift()
          index = @args.indexOf(arg)
          if value?
            if index is -1
              @args.push(arg)
              @args.push(value)
            else
              @args[index+1] = value
          else
            @args.splice(index,1)
        else
          @args.push(arg)
      return @args.length
    @toString = (sep=" ")->
      return @args.join(sep)
    @add(str)

  # acquiring test data from filename if needed
  filenameToTestname = (testName) ->
    return path.basename testName[0...(testName.length-5-path.extname(testName).length)]

  runner.relativeFn = (fn)->
    (path.relative runner.tests.globLoader.root, path.resolve(fn)).replace( /\\/g, "/" )

  parseError = (raw) ->
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

  runLog = (child, testData, setCurrentStatus) ->
    passMessage = ""
    errMessage = ""
    delimeterSent = (false)
    writeBlock = ( stream , message, lineTimeout ) ->
      writeLine = ( line ) ->
        yp Q.ninvoke(stream,"write",line+"\n").timeout( lineTimeout , "Log line timed out")
      unless delimeterSent
        writeLine( ">>>" )
        delimeterSent = (true)
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

  runner.spammer = (fun,params)->
    unless @argv["skype-notify"] then return
    params.contact ?= "REST protocol"
    http.get("http://"+@logger.transports.couchdb.host+"/skype/"+fun+"?"+qs.stringify(params))
    .on "error", (e)->
      return (true)

  runner.toolfuns =
    uniformName: (tn) ->
      tn.replace(/\\/g, "/")

    filenameToTestname : filenameToTestname

    calcProjectName: (testFileName) ->
      unless projectPath?
        tempPath = testFileName
        while (tempPath != ( tempPath = path.dirname tempPath ))
          if fs.existsSync(path.join(tempPath,".fglproject"))
            projectPath = tempPath
            break

      return path.basename projectPath

    combTestData: (testData) ->
      testData.programName ?= testData.program
      testData.buildTimeout ?= testData.timeout
      testData.projectPath ?= (testData.project or testData.prj)
      testData.reverse ?= testData.fail
      testData.buildMode ?= if testData.deploy is true then "all" else "rebuild"

      unless testData.programName?
        # cutting filename by 12 chars ("-test.coffee")
        testData.programName = filenameToTestname(testData.testFileName)

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

    getEnviron: ->
      _this=@


      runner.sysinfo =
        host : runner.os.hostname()
        starttimeid : (new Date()).toISOString()
        platform : process.platform.substring(0,3)+'_'+process.arch
        ver : runner.os.release()
        user : process.env.USER ? process.env.USERNAME
        build : "unknown"
        scenario : runner.opts.scenario
        database : @options.databaseProfile
      if runner.opts.notes? then runner.sysinfo.notes = runner.opts.notes
      if process.env.hasOwnProperty('ProgramFiles(x86)') then runner.sysinfo.platform="win_x64"

      runner.opts.environCommand?=runner.opts.environCommands[runner.sysinfo.platform]
      runner.opts.deployPath?=runner.opts.defaultDeployPath[runner.sysinfo.platform]

      @info runner.sysinfo.platform + " " + runner.sysinfo.ver

      [command,cc,args...] = _.compact runner.opts.environCommand.split(" ")

      exitPromise( spawn(command,[cc,args.join(" ")]), returnOutput:true)
      .then( (envtext)->
        runner.environ = JSON.parse(envtext.toString('utf8'))
        unless runner.environ.LYCIA_DIR? then throw new Error "LYCIA_DIR"
        exitPromise( spawn( path.join(runner.environ.LYCIA_DIR,"bin","qfgl"),["-V"], env : runner.environ ), returnOutput:true))
      .then( (qfglout)->
        if qfglout?
          runner.sysinfo.build = qfglout.toString('utf8').split("\n")[2].substring(7).split("\r")[0]
          runner.spammer "message", message: """
            !! #{runner.sysinfo.starttimeid}
            QAT started on #{runner.sysinfo.host}
            Platform : #{runner.sysinfo.platform} (#{runner.sysinfo.database})
            Lycia build : #{runner.sysinfo.build}
            """
          runner.logger.pass "qatstart",runner.sysinfo
        else
          throw new Error "Failed to get Lycia build form qfgl !!"

        return runner.sysinfo)
      .then( ->
        inetEnvSetDatabase())
      .catch( (err)->
        runner.spammer "message", message:"!! #{runner.sysinfo.starttimeid}\nQAT failed to start on #{runner.sysinfo.host}\nFailed to read environment!"
        _this.fail "Unable to read environ : "+err.message
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
        _.merge opt.env, @options.env
        _.merge opt.env, @runner.opts.dbprofiles[@options.databaseProfile]
        _.merge opt.env, @testData.env

        #@data.sysinfo = @runner.sysinfo

        @testData.compileTimeout?=20000
        cmdLine = new cmdlineType()
        switch (path.extname(@testData.fileName)).toLowerCase()
          #when ".4gl" then cmdLine.add("qfgl #{@testData.fileName} --xml-errors -d #{opt.env.LYCIA_DB_DRIVER} -o #{path.join( path.dirname(@testData.fileName), path.basename(@testData.fileName,'.4gl'))}.4o")
          when ".4gl"
            cmdLine.add("qfgl --xml-errors -d #{opt.env.LYCIA_DB_DRIVER}")
          #  cmdLine.add(['-o','"'+path.join( path.dirname(@testData.fileName), path.basename(@testData.fileName,'.4gl')+'.4o')+'"'])
            cmdLine.add(['-e','Cp1252',@testData.fileName])
          when ".per" then cmdLine.add("qform #{@testData.fileName} -xmlout -xml --db #{opt.env.LYCIA_DB_DRIVER} -p #{path.dirname(@testData.fileName)}")
          when ".4fd" then cmdLine.add("qxcompat #{@testData.fileName}")

        #cmdLine.add("-e Cp1252")
        cmdLine.add(@testData.options)
        @trace opt.cwd
        @trace cmdLine.toString()

        [command,args...] = cmdLine.args

        command = path.join(opt.env.LYCIA_DIR,"bin",command)

        #looks like on win32 shown also for x64 platform
        #if process.platform is "ia32" or process.platform is "x64" then command+=".exe"
        try
          {stderr} = child = spawn( command , args , opt )
          result = (yp exitPromise(child, ignoreError:true ).timeout(@testData.compileTimeout))
          if result
            txt = stderr.read()
            if txt?
              errorMessage = parseError(txt.toString('utf8'))

            errorMessage?= { text:txt, code:-1, line:-1 }
            if @testData.reverse
              if (not @testData.errorCode) or (parseInt(@testData.errorCode,10) is parseInt(errorMessage.code,10))
                return "Code matched:#{errorMessage.code}. Line:#{errorMessage.line}."
              else
                throw "ErrorCode mismatch! Expected: #{@testData.errorCode}, Actual :#{errorMessage.code} at Line:#{errorMessage.line}."

            # construction error message
            @data.failMessage=errorMessage.message
            throw "Compilation failed. Code: #{errorMessage.code}, Line: #{errorMessage.line}. Commandline : #{cmdLine.toString()}"

        finally
          child.kill('SIGKILL')
        if @testData.reverse then throw "Successful compilation, but fail expected!"
        return "Successful compilation."


      )

    regBuild: ->
      yp.frun( =>
        opt =
          cwd: path.resolve(@testData.projectPath)
          env: Object.assign( {},
            runner.environ,
            @options.env,
            runner.opts.dbprofiles[@options.databaseProfile],
            @testData.env)

        qrun = path.join(opt.env.LYCIA_DIR,"bin","qbuild")

        @testData.buildMode ?= @options.buildMode
        @testData.buildTimeout ?= @timeouts.build
        params = [ "-M", @testData.buildMode, opt.cwd, path.basename(@testData.programName) ]
        #@data.commandLine = "qbuild " + params.join(" ")
        try
          child = spawn( qrun , params , opt)
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
          _.merge opt.env, @runner.opts.headless
          _.merge opt.env, @options.env
          _.merge opt.env, @runner.opts.dbprofiles[@options.databaseProfile]
          _.merge opt.env, @testData.env
          _.merge opt.env, @testData.headless
          logLine = 0
          outLine = 0

          setCurrentStatus = (logL,outL) =>
            logLine = logL
            outLine = outL
          exename = path.join(opt.env.LYCIA_DIR, "bin", "qrun")

          params = new cmdlineType( [ @testData.programExecutable, "-d", opt.env.LYCIA_DB_DRIVER ] )
          params.add @testData.programArgs

          child = spawn( exename, params.args, opt)

          @testData.ignoreHeadlessErrorlevel = true #????

          @testData.runTimeout ?= @timeouts.run
          @testData.lineTimeout ?= @timeouts.line

          childPromise = exitPromise(child, ignoreError : @testData.ignoreHeadlessErrorlevel ).timeout(@testData.runTimeout, "Log timeout")
          logPromise = yp.frun( => runLog( child , @testData, setCurrentStatus) )

          promises = [ childPromise, logPromise ]

          if process.platform is "win32"
            d=@data
            statChild = spawn( "./utils/timem.exe" , [child.pid] )
            statChild.on "exit", ->
              result = JSON.parse(@stdout.read().toString())
              d.UserTime = result.UserTime
              d.KernelTime = result.KernelTime
              d.ElapsedTime = result.ElapsedTime
              d.PeakWorkingSetSize = result.PeakWorkingSetSize
            promises.push exitPromise(statChild).timeout(@testData.runTimeout)

          res = yp Q.all( promises )

          "Code : " + res.join ". "
        finally
          child.kill('SIGKILL')
      )



    LoadHeaderData : (logFileName) ->
      testData =
        fileName: logFileName
        env : {}

      logStream = fs.createReadStream(logFileName, encoding: "utf8")
      nextLogLine = lineFromStream logStream
      while (line=nextLogLine())
        break if line is "<<<"

        # environment variable search
        if (matches=(line.match "^<< *testData *# *(.*?) *= *(.*?) *>>"))
          # inserting params into testData with path
          matches[1].split('.').reduce( (td,prop,i,ar)->
            if i+1==ar.length
              return (td[prop]=matches[2])
            else
              return (td[prop]?={})
          , testData)

        else
          # trying to find programName only if it is not yet defined
          unless testData.programName?
            if (matches=(line.match "^<< *(.*?) *>>"))
              cmd = matches[1]
              # handling both, quoted and unquoted program name
              if (matches=(cmd.match '"(.*?)" *(.*)'))
                testData.programName=matches[1]
                testData.programArgs=matches[2].split(" ")
              else
                [testData.programName,testData.programArgs...]=cmd.split(" ")

      throw "Unable to read programName" unless testData.programName?
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

      unless testData.projectPath? then throw "Unable to read projectPath"

      testData.projectName = path.basename testData.projectPath
      # here can be implemented XML parce of project file. Currently using default paths
      testData.projectSource = 'source'
      testData.projectOutput = 'output'

      testData.programExecutable = path.join(testData.projectPath , testData.projectOutput , path.basename(testData.programName))
      #looks like on win32 shown also for x64 platform
      if process.platform is "win32" then testData.programExecutable+=".exe"
      #testData.projectPath = path.resolve(testData.projectPath)
      return testData

    regXPath : ->
      yp.frun =>
        rawxml=fs.readFileSync(@testData.fileName,'utf8').replace(/ xmlns="http:\/\/namespaces\.querix\.com\/20\d\d\/fglForms"/,"")
        xml = new dom().parseFromString(rawxml)
        s = xpath[@testData.method](@testData.query, xml).toString()
        if s is @testData.sample
          return "Matched!"
        else
          throw "String mismatch. Expected: #{@testData.sample}. Actual: #{s}."

    regDeploy : ->
      yp.frun( =>
        try
          rawxml=fs.readFileSync(@testData.fileName,'utf8')
          .replace(' xmlns="http://namespaces.querix.com/lyciaide/target"',"")
          xml = new dom().parseFromString(rawxml)
          filesToCopy = [@testData.programName]

          if rawxml.indexOf('type="fgl-program"')!=-1
            makeTr2file = true

          if rawxml.indexOf('type="fgl-library"')!=-1
            filesToCopy[0]+='.4a'
          else
            if process.platform[0] is "w" then filesToCopy[0]+='.exe'

          formExtCare = (fn) ->
            ext = path.extname(fn)
            base = fn.substr(0,fn.lastIndexOf("."))
            switch ext
              when ".per", ".4fm", ".4fd" then return base + ".fm2"
              when ".msg" then return base + ".erm"
              else return fn

          parseFilesToCopy = (xml,filesToCopy) ->
            filesToCopy.push formExtCare(fn.value) for fn in xpath.select('//fglBuildTarget/sources[@type="form"]/*/@location',xml)
            filesToCopy.push formExtCare(fn.value) for fn in xpath.select('//fglBuildTarget/sources[@type="message"]/*/@location',xml)
            #filesToCopy.push fn.value for fn in xpath.select('//fglBuildTarget/mediaFiles/file[@client="true"]/@location',xml)
            filesToCopy.push fn.value for fn in xpath.select('//fglBuildTarget/mediaFiles/file/@location',xml)
            return filesToCopy

          parseFilesToCopy(xml,filesToCopy)

          fn_Name = (xml,testData) ->
            libLocation = xpath.select('//fglBuildTarget/libraries/library/@location',xml)
            for fn,i in xpath.select('//fglBuildTarget/libraries/library/@name',xml)
              libLoc = libLocation[i].value.toString()+"\\"
              fileName = testData.projectPath + "\\source\\" + libLoc + "\\."  + fn.value + ".fgltarget"
              rawxml=fs.readFileSync(fileName,'utf8')
              .replace(' xmlns="http://namespaces.querix.com/lyciaide/target"',"")
              xml = new dom().parseFromString(rawxml)
              filesToCopy.push(libLoc + "\\"+fn.value+".4a")
              parseFilesToCopy(xml,filesToCopy)
              fn_Name(xml,testData)

          fn_Name(xml,@testData)
          if makeTr2file
            tr2file = '<?xml version="1.0" encoding="UTF-8"?>\n<Resources>\n'
          for fn,i in filesToCopy
            try
              sourceFile = path.join(@testData.projectPath,@testData.projectOutput,fn)
              targetFile = path.join(runner.opts.deployPath,fn)
              fse.ensureDirSync path.dirname(targetFile)
              fse.copySync(sourceFile,targetFile)
              if i > 0 and fn.indexOf(".4a")==-1
                if makeTr2file
                  tr2file+='  <Resource path="'+fn+'"/>\n'
            catch e
              runner.info "Failed to copy file : "+fn
          if makeTr2file
            tr2file+='</Resources>\n'
            fs.writeFileSync(path.join(runner.opts.deployPath,@testData.programName+".tr2"),tr2file)
          exeName=path.join(runner.opts.deployPath,filesToCopy[0])
          if process.platform[0] is "l"
            fs.chmodSync( exeName , "755")

          #build object cache

          if @testData.aot or @testData.unl
            opt =
              cwd: path.resolve(@testData.projectPath)
              env: _.assign(
                {}
                @runner.environ
                @options.env
                @runner.opts.dbprofiles[@options.databaseProfile]
                @testData.env
              )
            qrun = path.join(opt.env.LYCIA_DIR,"bin","qrun")

            if @testData.unl
              child = spawn( qrun , ["--aot","--unl",exeName] , opt)
            else
              child = spawn( qrun , ["--aot",exeName] , opt)
            result = (yp exitPromise(child).timeout(@testData.buildTimeout,"Build timed out"))
            if result
              err=child.stderr.read()
              throw new Error("Aot failed for #{exeName} with error : #{err}.")

          "Files deployed : #{filesToCopy.length}"
        catch e
          console.log e
          throw e
      )
