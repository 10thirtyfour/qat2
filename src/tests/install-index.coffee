platforms =
  winia32:
    url:"/repository/downloadAll/bt80/.lastSuccessful"
    environ: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIAI~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
    commands: [
      "cvs.exe -d :pserver:seza@cvs.qx:/demo co ."
      "unzip.exe -j package.zip *LyciaDesktop-1.1-*.msi"
      "cmd /c ren LyciaDesktop-1.1-*.msi ldnet.msi"
      "cmd /c ldnet.msi /quiet"
      "unzip.exe -j package.zip *Lycia-nt-32*.exe"
      "cmd /c ren Lycia-nt-32*.exe lycia2.exe"
      "lycia2.exe /S"
    ]
   
  winx64:
    url:"/repository/downloadAll/bt7/.lastSuccessful"
    environ: 'cmd /c C:\\PROGRA~1\\Querix\\LYCIAI~1.2\\Lycia\\bin\\environ.bat >nul & node -e console.log(JSON.stringify(process.env))'
    commands: [
      "cvs.exe -d :pserver:seza@cvs.qx:/demo co ."
      "unzip.exe -j package.zip *LyciaDesktop-1.1-*.msi"
      "cmd /c ren LyciaDesktop-1.1-*.msi ldnet.msi"
      "cmd /c ldnet.msi /quiet"
      "unzip.exe -j package.zip *Lycia-nt-64*.exe"
      "cmd /c ren Lycia-nt-64*.exe lycia2.exe"
      "lycia2.exe /S"
    ]
    
  linia32:
    url:"/repository/downloadAll/bt45/.lastSuccessful"
  
  linx64:
    url:"/repository/downloadAll/bt51/.lastSuccessful"
    environ: '. /opt/Querix/Lycia/environ >nul && node -e "console.log(JSON.stringify(process.env))"'


module.exports = ->
  {os,path,Q,utils,toolfuns,yp} = runner = @
  auth = "Basic " + new Buffer("qx\\robot:2p4u-Zz").toString("base64")

    
  precursor = []
  
  tempPath = runner.tempPath
  packageName = path.join(tempPath,"package.zip")
  runner.platform = os.platform().substr(0,3)+os.arch()
  
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
        path: platforms[runner.platform].url
        headers:
          "Authorization": auth
    promise: toolfuns.regDownloadPromise
  
  runner.reg
    name: "lycia$install"
    setup: true 
    disabled: true
    before: ["globLoader","read$environ"]
    promise: ->
      precursors = ["lycia$install"]
      commandIndex = 1
      for command in platforms[runner.platform].commands
        runner.reg
          name: "lycia$install$command"+commandIndex
          after: precursors
          before: ["read$environ"]
          setup: true
          data:
            command: command
            options:
              cwd: path.resolve(tempPath)
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
      command: platforms[runner.platform].environ
    promise: toolfuns.regGetEnviron
    
  runner.sync()

