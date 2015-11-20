module.exports = ()->
  return if process.platform[0] isnt "w"

  { opts, _, path, Q } = runner = @

  runner.robot = require('robotjs')
  edge = require('edge')
  url = require "url"
  platform = if process.env.hasOwnProperty('ProgramFiles(x86)') then "win_x64" else "win_ia32"
  spawn = require("child_process").spawn
  exec = require("child_process").exec

  opts.assemblyPath?=opts.defaultAssemblyPath[platform]
  refs = [
      "UIAutomationClient.dll",
      "UIAutomationTypes.dll",
      "WindowsBase.dll"].map( (dll)->
        opts.assemblyPath + dll
      )

  turnToPromise = (fun)->
    (obj)->
      def = Q.defer()
      fun( obj, (er,res)->
        if (er) then def.reject(er)
        def.resolve(res)
      )
      return def.promise


  getElement = turnToPromise edge.func(
    source : ->
      ###
        using System;
        using System.Windows;
        using System.ComponentModel;
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
            string prop = (string)input.id;
            Console.WriteLine( prop );
            Winfo w = new Winfo();
            return(w);
          }
        }
      ###

    ,
    references : refs
  )
  # getConsoleText()
  getConsoleText = turnToPromise edge.func(
    source : ->
      ###
        using System;
        using System.Windows;
        using System.Windows.Automation;
        using System.Threading.Tasks;

        public class Startup {
          public async Task<object> Invoke(dynamic input) {
            string text="";
            try {
              var el = AutomationElement.RootElement
                .FindFirst( TreeScope.Children,
                  new PropertyCondition( AutomationElement.NameProperty,
                  "Lycia Console"))
                .FindFirst( TreeScope.Children,
                  new PropertyCondition( AutomationElement.ClassNameProperty,
                  "Edit"));
                object pObj;
                if (el.TryGetCurrentPattern(TextPattern.Pattern, out pObj)) {
                  var textPattern = (TextPattern)pObj;
                  text = textPattern.DocumentRange.GetText(-1);
                }

              } catch {
                Console.WriteLine("error");
                text = "";
              }
            return(text);
          }
        }
      ###

    ,
    references : refs
  )


  # getWindows( [all : <bool>] ) return windows with basic params.
  # returns all or Desktop only windows with attributes.
  # all : bool.  default "false"
  getWindows = turnToPromise edge.func(
    source : ->
      ###
        using System;
        using System.Windows;
        using System.Windows.Automation;
        using System.Threading.Tasks;
        using System.Collections.Generic;

        public class myRect
        {
          public int Width { get; set; }
          public int Height { get; set; }
          public int Top { get; set; }
          public int Left { get; set; }
          public myRect( AutomationElement el ) {
            System.Windows.Rect r = (System.Windows.Rect)(
            el.GetCurrentPropertyValue(
              AutomationElement.BoundingRectangleProperty,
              true));
            Width  = (int)r.Width;
            Height = (int)r.Height;
            Top    = (int)r.Top;
            Left   = (int)r.Left;
          }
        }

        public class Winfo
        {
          public string Name { get; set; }
          public string AutomationId { get; set; }
          public int ProcessId { get; set; }
          public myRect window { get; set; }
          public myRect browser { get; set; }
        }


        public class Startup {
          public async Task<object> Invoke(dynamic input) {
            var els = AutomationElement.RootElement.FindAll(
              TreeScope.Children,
              Condition.TrueCondition);

            List<Winfo> windowList = new List<Winfo>{};
            bool all;
            try { all = (bool)input.all; } catch { all = false; };

            foreach (AutomationElement el in els) {
              Winfo w = new Winfo {
                Name = el.Current.Name,
                AutomationId = el.Current.AutomationId,
                ProcessId = el.Current.ProcessId };
              try {
                var tmpWeb = el
                  .FindFirst( TreeScope.Descendants,
                    new PropertyCondition(
                      AutomationElement.ClassNameProperty,
                      "CefBrowserWindow") )
                  .FindFirst( TreeScope.Descendants,
                    new PropertyCondition(
                      AutomationElement.NameProperty,
                      "Chrome Legacy Window"));
                w.browser = new myRect(tmpWeb);

              } catch {
                if(!all) { continue;}
              }

              w.window = new myRect(el);
              windowList.Add( w );
            }
            return(windowList);
          }
        }
      ###

    ,
    references : refs
  )


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

    getConsoleText : ->
      @promise = Q( @promise )
        .then( getConsoleText )
      @

    getWindows : (obj)->
      @promise = Q( @promise )
        .then( -> getWindows(obj) )
      @

    getElement : (obj)->
      @promise = Q( @promise )
        .then( -> getElement(obj) )
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
