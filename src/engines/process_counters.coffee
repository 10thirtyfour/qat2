
# NOTE : pid counters must be enabled
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\PerfProc\Performance
# DWORD ProcessNameFormat 2

# following selector can be used to gram qrun from .exe pid
# cnt = Counter( selector : "\\Process(*_#{child.pid}/qrun*)" )
if process.platform is "win32"
  cWinPerfCounter=require("cWinPerfCounter")

counters =
  worksetpeak : "Working Set Peak"


class Counter
  constructor: (opts) ->
    if typeof opts isnt "object"
      @selector = "\\Process(*_#{opts})"
    else
      @selector = opts.selector ? "\\Process(*_#{opts.pid})"
    @interval = opts.interval ? 10
    @data = {}
    @counters = {}
    for name of counters
      @data[name] = 0

    return false if process.platform isnt "win32"

    for name,cnt of counters
      try
        @counters[name] = new cWinPerfCounter("#{@selector}\\#{cnt}")
    @update()

  stop : ->
    @stopped = true
    for name of @counters
      delete @counters[name]
    @data
  update : ->
    try
      worksetpeak=@counters.worksetpeak.fnGetValue()
      @data.worksetpeak = worksetpeak if worksetpeak > @data.worksetpeak
      unless @stopped then setTimeout( =>
        @update()
      , @interval )
    catch e
      @stop()

module.exports = (opts) -> new Counter(opts)
