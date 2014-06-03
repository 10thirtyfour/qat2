platforms =
  win32:
    url:"/repository/downloadAll/bt80/.lastSuccessful"
    environ: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIAI~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
    commands: [
      "unzip.exe -j package.zip *Lycia-nt-32*.exe"
      "cmd /c ren Lycia-nt-32*.exe lycia2.exe"
      "lycia2.exe /S"
      "unzip.exe -j package.zip *LyciaDesktop-1.1-*.msi"
      "cmd /c ren LyciaDesktop-1.1-*.msi ldnet.msi"
      "cmd /c ldnet.msi /quiet"
      "cvs.exe -d :pserver:seza@cvs.qx:/demo co ."
    ]
   
  win64:
    url:"/repository/downloadAll/bt7/.lastSuccessful"
    
  lnx32:
    url:"/repository/downloadAll/bt45/.lastSuccessful"
  
  lnx64:
    url:"/repository/downloadAll/bt51/.lastSuccessful"


module.exports = ->
  {Q,utils,toolfuns} = runner = @
  auth = "Basic " + new Buffer("qx\\robot:2p4u-Zz").toString("base64")
  
  precursor = []

  if runner.argv["install-lycia"]
    @reg
      name: "lycia$download"
      setup: true;
      data:
        filename: "c:\\temp\\package.zip"
        retries: 3
        options:
          host: "buildsystem.qx"
          path: platforms.win32.url
          headers:
            "Authorization": auth
      promise: toolfuns.regDownloadPromise
    precursor = ["lycia$download"]
  
    commandIndex = 1
    for command in platforms.win32.commands
      @reg
        name: "lycia$install$cmd"+commandIndex
        setup: true;
        after: precursor
        data:
          command: command
          options:
            cwd:"c:\\temp"
#            env:
#              path:"c:\\windows\\system32\\bats"
            stdio:"ignore"
        promise: toolfuns.regExecPromise
      precursor = "lycia$install$cmd"+commandIndex
      commandIndex++
  
  unless runner.argv["skip-environ"]
    @reg
      name: "lycia$install$environ"
      setup: true;
      after: [precursor]
      data:
        command: platforms.win32.environ
      promise: toolfuns.regGetEnviron
    
  runner.sync()

