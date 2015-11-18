edge = require('edge')
platform = if process.env.hasOwnProperty('ProgramFiles(x86)') then "win_x64" else "win_ia32"
spawn = require("child_process").spawn
exec = require("child_process").exec
url = require "url"
robot = require "robotjs"

module.exports = ()->
  { opts, _, path, Q } = runner = @
  opts.assemblyPath?=opts.defaultAssemblyPath[platform]
  refs = [
      "UIAutomationClient.dll",
      "UIAutomationTypes.dll",
      "WindowsBase.dll"].map( (dll)->
        opts.assemblyPath + dll
      )

  getWindows = edge.func(
    source : ->
      ###
        using System;
        using System.Windows;
        using System.Windows.Automation;
        using System.Threading.Tasks;
        using System.Collections.Generic;

        public class Winfo
        {
          public string Name { get; set; }
          public string AutomationId { get; set; }
          public int Width { get; set; }
          public int Height { get; set; }
          public int Top { get; set; }
          public int Left { get; set; }
        }

        public class Startup {
          public async Task<object> Invoke(dynamic input) {
            //return await Task.Run<object>(async () => {
              var els = AutomationElement.RootElement.FindAll(
                TreeScope.Children,
                Condition.TrueCondition);
              List<Winfo> ww = new List<Winfo>{};
              foreach (AutomationElement el in els) {
                object obr = el.GetCurrentPropertyValue(
                  AutomationElement.BoundingRectangleProperty,
                  true);
                System.Windows.Rect r = (System.Windows.Rect)obr;
                //Console.WriteLine(el.Current.Name);
                ww.Add( new Winfo {
                  Name = el.Current.Name
                  ,AutomationId = el.Current.AutomationId
                  ,Width = (int)r.Width
                  ,Height = (int)r.Height
                  ,Top = (int)r.Top
                  ,Left = (int)r.Left
                });
              }
              return(ww);

            //});
          }
        }
      ###

    ,
    references : refs
  )

  turnToPromise = (fun)->
    (obj)->
      def = Q.defer()
      fun( obj, (er,res)->
        if (er) then def.reject(er)
        def.resolve(res)
      )
      return def.promise

  class UIauto
    constructor: ( params={} )->
      @timeout=params.timeout ? 30000
      @promise = Q( {} )
      @progs = []
      @progNames = []
      @

    then : (arg)->
      @promise = Q(@promise).then(arg)
      @

    done : (res)->
      @promise=Q(@promise).finally( ( ->
        console.log "done"
        for prog in @progs
          if typeof prog.kill is "function" then prog.kill('SIGKILL')
        for name in @progNames
          console.log "taskkill /F /T /IM #{name}"
          exec "taskkill /F /T /IM #{name}"
        res
      ).bind(@)
      )
      return @promise

    delay : (t)->
      @promise = Q(@promise).delay(t)
      @

    getWindows : ->
      @promise = Q( @promise ).then( turnToPromise getWindows )
      @

    runProgram : (prog)->
      @progNames.push(prog)
      @promise = Q( @promise ).then( (->
        cmd = path.join(runner.environ.LYCIA_DIR,"client","LyciaDesktop.exe")
        wurl = url.parse(opts.lyciaWebUrl).host
        params = [
          "--server=#{wurl}",
          "--instance=#{opts.qatDefaultInstance}",
          "-c",
          "--command=\"#{prog}\" -d #{opts.common.options.databaseProfile}"]
        @progs.push spawn(cmd,params)
        ).bind(@))
      return @

  runner.uia = ( progname )->
    new UIauto()
  runner.robot = robot
