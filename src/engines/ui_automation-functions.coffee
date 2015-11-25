module.exports =
  getConsoleText : ->
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

  getWindows : ->
    ###
      using System;
      using System.Windows;
      using System.Windows.Automation;
      using System.Threading.Tasks;
      using System.Collections.Generic;

      public class myRect
      {
        public int width { get; set; }
        public int height { get; set; }
        public int top { get; set; }
        public int left { get; set; }
        public myRect( AutomationElement el ) {
          System.Windows.Rect r = (System.Windows.Rect)(
          el.GetCurrentPropertyValue(
            AutomationElement.BoundingRectangleProperty,
            true));
          width  = (int)r.Width;
          height = (int)r.Height;
          top    = (int)r.Top;
          left   = (int)r.Left;
        }
      }

      public class Winfo
      {
        public string name { get; set; }
        public string automationId { get; set; }
        public int processId { get; set; }
        public myRect window { get; set; }
        public myRect browser { get; set; }
      }

      public class Startup {

        private Winfo getWinInfo( AutomationElement el ) {
          if ( el == null ) return( null );
          Winfo winfo = new Winfo {
            name = el.Current.Name,
            automationId = el.Current.AutomationId,
            processId = el.Current.ProcessId,
            window = new myRect(el)
          };

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

            winfo.browser = new myRect(tmpWeb);
          } catch { winfo.browser = null; }

          return(winfo);
        }

        public async Task<object> Invoke(dynamic input) {
          var els = AutomationElement.RootElement.FindAll(
            TreeScope.Children,
            Condition.TrueCondition);

          List<Winfo> windowList = new List<Winfo>{};
          bool all;
          try { all = (bool)input.all; } catch { all = false; };

          foreach (AutomationElement el in els) {
            Winfo winfo = getWinInfo(el);
            if ((winfo!=null) && (all || (winfo.browser!=null))) {
              windowList.Add( winfo );
            }
          }
          return(windowList);
        }
      }
    ###

  waitWindow : ->
    ###
      using System;
      using System.Windows;
      using System.Diagnostics;
      using System.ComponentModel;
      using System.Windows.Automation;
      using System.Threading.Tasks;
      using System.Threading;
      using System.Collections.Generic;

      public class myRect {
        public int width { get; set; }
        public int height { get; set; }
        public int top { get; set; }
        public int left { get; set; }
        public myRect( AutomationElement el ) {
          System.Windows.Rect r = (System.Windows.Rect)(
          el.GetCurrentPropertyValue(
            AutomationElement.BoundingRectangleProperty,
            true));
          width  = (int)r.Width;
          height = (int)r.Height;
          top    = (int)r.Top;
          left   = (int)r.Left;
        }
      }

      public class Winfo
      {
        public string name { get; set; }
        public string automationId { get; set; }
        public int processId { get; set; }
        public myRect window { get; set; }
        public myRect browser { get; set; }
      }

      public class Startup {
        private static AutoResetEvent waitHandle;

        private Winfo getWinInfo( AutomationElement el ) {
          if ( el == null ) return( null );
          Winfo winfo = new Winfo {
            name = el.Current.Name,
            automationId = el.Current.AutomationId,
            processId = el.Current.ProcessId,
            window = new myRect(el)
          };

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

            winfo.browser = new myRect(tmpWeb);
          } catch { winfo.browser = null; }

          return(winfo);
        }

        public async Task<object> Invoke(dynamic input) {
          bool gotWindow;
          int t;
          try { t = (int)input.timeout; } catch { t = 0; };

          string wname;
          try { wname = (string)input.name; } catch { wname = ""; };

          AutomationElement el = AutomationElement.RootElement.FindFirst(
            TreeScope.Children,
            new PropertyCondition( AutomationElement.NameProperty, wname ));

          if ( el == null ) {
            waitHandle = new AutoResetEvent(false);
            Automation.AddAutomationEventHandler(
              WindowPattern.WindowOpenedEvent,
              AutomationElement.RootElement,
              TreeScope.Children,
              (sender, e) => {
                var obj = sender as AutomationElement;
                if (obj.Current.Name == wname) {
                  el = obj;
                  waitHandle.Set();
                }
              }
            );

            var watch = Stopwatch.StartNew();
            gotWindow = waitHandle.WaitOne(t);
            watch.Stop();
            t -= (int)watch.ElapsedMilliseconds;
            Automation.RemoveAllEventHandlers();

          }

          if((t>0) && (el!=null)) {
            // Still have some time to wait for ready
            (el.GetCurrentPattern(WindowPattern.Pattern)
              as WindowPattern).WaitForInputIdle(t);
            el.SetFocus();
          }
          return( getWinInfo(el) );
        }
      }
    ###

  transformWindow : ->
    ###
      using System;
      using System.Windows;
      using System.ComponentModel;
      using System.Windows.Automation;
      using System.Threading.Tasks;
      using System.Threading;
      using System.Collections.Generic;

      public class myRect {
        public int width { get; set; }
        public int height { get; set; }
        public int top { get; set; }
        public int left { get; set; }
        public myRect( AutomationElement el ) {
          System.Windows.Rect r = (System.Windows.Rect)(
          el.GetCurrentPropertyValue(
            AutomationElement.BoundingRectangleProperty,
            true));
          width  = (int)r.Width;
          height = (int)r.Height;
          top    = (int)r.Top;
          left   = (int)r.Left;
        }
      }

      public class Winfo
      {
        public string name { get; set; }
        public string automationId { get; set; }
        public int processId { get; set; }
        public myRect window { get; set; }
        public myRect browser { get; set; }
      }

      public class Startup {
        private Winfo getWinInfo( AutomationElement el ) {
          if ( el == null ) return( null );
          Winfo winfo = new Winfo {
            name = el.Current.Name,
            automationId = el.Current.AutomationId,
            processId = el.Current.ProcessId,
            window = new myRect(el)
          };

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

            winfo.browser = new myRect(tmpWeb);
          } catch { winfo.browser = null; }

          return(winfo);
        }

        public async Task<object> Invoke(dynamic input) {
          string wname = (string)input.name;
          AutomationElement el = AutomationElement.RootElement.FindFirst(
            TreeScope.Children,
            new PropertyCondition( AutomationElement.NameProperty, wname ));
            var p = (el.GetCurrentPattern(TransformPattern.Pattern)
              as TransformPattern);


          try {
            string sizeMode = (string)input.resize;
            var wp=el.GetCurrentPattern(WindowPattern.Pattern) as WindowPattern;
            if(sizeMode=="max") {
              wp.SetWindowVisualState(WindowVisualState.Maximized);
            }
            if(sizeMode=="min") {
              wp.SetWindowVisualState(WindowVisualState.Minimized);
            }
            if(sizeMode=="normal") {
              wp.SetWindowVisualState(WindowVisualState.Normal);
            }
          } catch {}


          try {
            object[] resize = (object[])input.resize;
            p.Resize((int)resize[0],(int)resize[1]);
          } catch { }

          try {
            object[] move = (object[])input.move;
            p.Move((int)move[0],(int)move[1]);
          } catch { }


        return(getWinInfo(el));

        }
      }
    ###


  closeWindow : ->
    ###
      using System;
      using System.Windows;
      using System.ComponentModel;
      using System.Windows.Automation;
      using System.Threading.Tasks;
      using System.Threading;
      using System.Collections.Generic;

      public class myRect {
        public int width { get; set; }
        public int height { get; set; }
        public int top { get; set; }
        public int left { get; set; }
        public myRect( AutomationElement el ) {
          System.Windows.Rect r = (System.Windows.Rect)(
          el.GetCurrentPropertyValue(
            AutomationElement.BoundingRectangleProperty,
            true));
          width  = (int)r.Width;
          height = (int)r.Height;
          top    = (int)r.Top;
          left   = (int)r.Left;
        }
      }

      public class Winfo
      {
        public string name { get; set; }
        public string automationId { get; set; }
        public int processId { get; set; }
        public myRect window { get; set; }
        public myRect browser { get; set; }
      }

      public class Startup {
        public async Task<object> Invoke(dynamic input) {
          var names = (object[])input;
          int closedWindowsCount = 0;
          foreach (object oname in names) {
            string wname = oname as string;

            var els = AutomationElement.RootElement.FindAll(
              TreeScope.Children,
              new PropertyCondition( AutomationElement.NameProperty, wname ));

            foreach (AutomationElement el in els) {
              try {
                (el.GetCurrentPattern(WindowPattern.Pattern)
                  as WindowPattern).Close();
                closedWindowsCount++;
              } catch {
                Console.WriteLine("Cant close {0}",wname);
              }
            }
          }
          return(closedWindowsCount);
        }
      }
    ###
