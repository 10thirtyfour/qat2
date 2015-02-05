###
# #%L
# QUERIX
# %%
# Copyright (C) 2015 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel : +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
glob = require "glob"
_ = require "lodash"
Q = require "q"
graphlib = require "graphlib"
prettyjson = require "prettyjson"
dot = require "graphlib-dot"
Q.longStackSupport = true
fs = require "fs"
assert = require "assert"
xpath = require "xpath"
dom = require("xmldom").DOMParser


syncNo = 0

class Runner
  constructor: ->
    @tests = {}
    @notInGraph = []
    @runner = @
  name: "runner"
  glob: glob
  minimatch: require "minimatch"
  _: _
  Q: Q
  xpath: xpath
  dom: dom
  graphlib: graphlib
  prettyjson: (v) -> prettyjson.render v,
    keysColor: "magenta"
    dashColor: "magenta"
  os: require "os"
  graph: new graphlib.Digraph
  fs: fs
  colors: require "colors"
  EventEmitter: require("events").EventEmitter
  yp: require "yield-on-promise"
  path: require "path"
  winston: require "winston"
  opts:
    common:
      data: {}
  common:
    assert: assert
  prePromise: -> Q {}
  postPromise: (i) -> i
  reg: (descr) ->
    {name} = descr
    if @graph.hasNode(name)
      @info "Warning! "+name+" already in graph"
      return name
    descr.runner = @
    @tests[name] = descr
    _.merge descr, @common, @opts.common, @opts[name]
    @notInGraph.push descr
    @graph.addNode name
  # schedules next actions for execution
  # res - initial result, there report is aggregating 
  # may be some statistics information
  # this is default implantation and may be overridden by some extension
  # default implementation simply runs all tests sequentially
  schedule: (actions) ->
    actions.reduce(
      (prev,cur) =>
        prev.then(cur)
      Q {})
  # executes provided node and schedules its children
  crawl: (node) ->
    # what's wrong, crawl should return promise
    # with the test case result
    # we need bind here!
    {tests} = @
    t = tests[node]
    @trace "crawling #{node}"
    if t.started
      throw new Error "trying to crawl already started node: #{node}"
    t.error = false
    for i in @graph.predecessors(node)
      pt = tests[i]
      unless pt.done
        @trace "not all dependencies satisfied #{i}"
        return Q({})
      t.error = t.error or pt.error is true
    t.started = true
    r = @prePromise()
    if not t.disabled and t.promise? and (not t.error or t.runAnyway)
      r = r.then(-> t.promise())
        .catch (e) ->
          t.error = true 
          throw e
    else
      @trace "skipping #{node}"
    if @opts.stopOnError
      r = r.catch (r) =>
        @info "exit on first error", @prettyjson r
        process.exit -1
    else
      r = r.catch (e) =>
        #@info "error", @prettyjson e
        Q {}
    r = r.finally =>
          @trace "done #{node}, next", @graph.successors node
          t.done = true
          next = for i in @graph.successors node
            do (i) =>
              => @crawl i
          @schedule next
    r = @postPromise r
    r
  forEachTest: (fun) ->
    fun(i) for x,i of @tests when not i.started
    prevReg = @reg
    @reg = (i) ->
      fun.call @, i
      prevReg.call @, i
  # CONFOPT: enables/or disables tracing 
  sync: ->
    graph = @graph
    t = @tests
    syncNo++
    @info "building dependencies graph"
    @info "number of nodes:#{graph.nodes().length}"
    for descr in @notInGraph
      {name,before,after,setup} = descr
      @trace "building: #{name}"
      if name isnt "setup" and name isnt "run"
       if setup
          graph.addEdge null, "setup", name
          graph.addEdge null, name, "run"
        else
          graph.addEdge null, "run", name
      graph.addEdge null, name, "done"
      if before?
        for i in @utils.mkArray before
          unless @tests[i]
            throw new Error "Unknown dependency #{i} in `before` of #{name}"
          graph.addEdge(null, name, i)
      if after?
        for i in @utils.mkArray after
          unless @tests[i]
            throw new Error "Unknown dependency #{i} in `after` of #{name}"
          graph.addEdge(null, i, name) 
    @notInGraph.length = 0
    @info "number of edges:#{graph.edges().length}"
    fs.writeFileSync "tmp/graph-#{syncNo}", dot.encode(graph)
    cycles = graphlib.alg.findCycles graph
    if cycles.length isnt 0
      throw "cycles in test dependencies: #{@prettyjson cycles}"
    @info "no dependency cycles"
    @utils.transRed @graph, "setup"
    fs.writeFileSync "tmp/graph-red-#{syncNo}", dot.encode(graph)
    @info "number of edges after reduction:#{graph.edges().length}"
  go: ->
    try
      fs.mkdirSync "tmp"
    @trace "options:", @opts
    @info "start crawling"
    @sync()
    @logger.profile "run"
    @crawl("setup")

_.merge Runner.prototype, Runner.prototype.common
runner = new Runner
runner.proto = Runner.prototype
runner.reg
  name: "setup"
runner.reg
  name: "run"
  after: "setup"
runner.reg
  name: "done"
  silent: true
  runAnyway: true
  promise: ->
    @runner.logger.profile "run"
    Q {}
require("./utils").call runner

module.exports = runner

