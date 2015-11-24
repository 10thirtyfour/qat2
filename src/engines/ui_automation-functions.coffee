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

            waitHandle.WaitOne(t);
            Automation.RemoveAllEventHandlers();
          }

          return( getWinInfo(el) );
        }
      }
    ###
