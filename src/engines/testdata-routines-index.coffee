# tlog header may contain program arguments and additional data
# << "15086_if_condition.exe" >>
# << testData # runTimeout=600000 >>
# << testData # runTimeout=600000 >>

getTlogCommandLine = (line)->
  if (matches=(line.match "^<< *(.*?) *>>"))
    cmd = matches[1]
    # handling both, quoted and unquoted program name
    if (matches=(cmd.match '"(.*?)" *(.*)'))
      prog = matches[1]
      args = matches[2].split(" ")
    else
      [prog,args...]=cmd.split(" ")
    # remove database argument
    if args.indexOf("-d")>-1 then args.splice(args.indexOf("-d"),2)
    # removing .exe
    if prog.endsWith(".exe") then prog=prog.substring(0, prog.length - 4)
  return [ prog or null, args or [] ]

module.exports = ->
  {Q,yp,fs,path, _, opts} = runner = @

  findProjectPath = (fn)->
    tempPath = path.resolve(fn)
    while (tempPath != ( tempPath = path.dirname tempPath ))
      if fs.existsSync(path.join(tempPath,".fglproject"))
        return tempPath
    return ""

  class TestData

    constructor : (fileName)->
      @extension = path.extname(fileName)
      @fileName  = fileName
      if @extension is ".tlog"
        @getTlogHeader()
        @getProjectInfo()
        @testName = @tlogHeader.data.name or
                    @tlogHeader.data.testName or
                    path.basename( @fileName, @extension )

    getProjectInfo : ()->
      unless (@projectInfo?)
        @projectInfo =
          path : findProjectPath( @fileName )

        @projectInfo.name = path.basename @projectInfo.path

        # here can be implemented XML parce of project file.
        # Currently using default paths
        @projectInfo.source = 'source'
        @projectInfo.output = 'output'

        @projectInfo.executable = path.join(
          @projectInfo.path,
          @projectInfo.output,
          path.basename( @getTlogHeader().prog ))
        if process.platform is "win32"
          @projectInfo.executable+=".exe"
      @projectInfo


    getTlogHeader : ()->
      unless(@tlogHeader?)
        tlog = fs.readFileSync( @fileName , encoding : "utf8" )

        tlogHeader =
          prog : null
          args : []
          data : {}

        tlog.substring(0,tlog.indexOf("<<<"))
          .split('\n')
          .map( (line)->line.trim() )
          .filter( (line)->line.startsWith("<<") and line.endsWith(">>"))
          .forEach (line)->
            if (matches=(line.match "^<< *testData *# *(.*?) *= *(.*?) *>>"))
              # inserting params into testData with path

              matches[1].split('.').reduce( ( obj, prop, i, ar )->
                if i==ar.length-1
                  return (obj[prop]=matches[2])
                else
                  return (obj[prop]?={})
              , tlogHeader.data)
            else
              unless tlogHeader.prog?
                [ tlogHeader.prog, tlogHeader.args ]=getTlogCommandLine(line)
        @tlogHeader = tlogHeader
      @tlogHeader


  runner.TestData = TestData
