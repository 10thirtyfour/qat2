platforms =
  win32:
    url:"/repository/downloadAll/bt80/.lastSuccessful"
    environ: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIAI~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
    commands: [
      "timeout 2"
      "unzip.exe -j package.zip *LyciaDesktop-1.1-*.msi"
      "cmd /c ren LyciaDesktop-1.1-*.msi ldnet.msi"
      "cmd /c ldnet.msi /quiet"
      "unzip.exe -j package.zip *Lycia-nt-32*.exe"
      "cmd /c ren Lycia-nt-32*.exe lycia2.exe"
      "lycia2.exe /S"
      "cvs.exe -d :pserver:seza@cvs.qx:/demo co ."
    ]
   
  win64:
    url:"/repository/downloadAll/bt7/.lastSuccessful"
    
  lnx32:
    url:"/repository/downloadAll/bt45/.lastSuccessful"
  
  lnx64:
    url:"/repository/downloadAll/bt51/.lastSuccessful"


module.exports = ->
  {path,Q,utils,toolfuns,yp} = runner = @
  auth = "Basic " + new Buffer("qx\\robot:2p4u-Zz").toString("base64")
  
  precursor = []
  
  tempPath = runner.tests.globLoader.root
  packageName = path.join(tempPath,"package.zip")
  
  runner.reg
    name: "lycia$download"
    setup: true 
    disabled: true 
    before:["lycia$install"] 
    data:
      filename: packageName 
      retries: 3
      options:
        host: "buildsystem.qx"
        path: platforms.win32.url
        headers:
          "Authorization": auth
    promise: toolfuns.regDownloadPromise
  
  runner.reg
    name: "lycia$install"
    setup: true 
    disabled: true
    before: ["globLoader"]
    promise: ->
      precursors = ["lycia$install"]
      commandIndex = 1
      for command in platforms.win32.commands
        runner.reg
          name: "lycia$install$command"+commandIndex
          after: precursors
          before: ["read$environ"]
          setup: true
          data:
            command: command
            options:
              cwd: tempPath
              stdio:"ignore"
          promise: toolfuns.regExecPromise
          
        precursors = ["lycia$install$command"+commandIndex]
        commandIndex++    
      runner.sync()

  runner.reg
    name: "read$environ"
    setup: true
    before: ["globLoader"]
    data:
      command: platforms.win32.environ
    promise: toolfuns.regGetEnviron
    
  runner.sync()

