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
module.exports = ->
  {_,proto} = @
  # transitive reduction algorithm implementation
  # adapted from here:
  # https://github.com/ellson/graphviz/blob/master/cmd/tools/tred.c
  proto.utils =
    mkArray: (v,s) ->
      return [] unless v?
      return v if _.isArray v
      v.split(s ? ",") if _.isString v
      return [v]
    transRed: (g,root) ->
      visited = {}
      dfs = (n,link) ->
        visited[n] = true
        for e in g.inEdges n
          continue if e is link
          g.delEdge(e) if visited[g.source e]
        for e in g.outEdges n
           # the edge may deleted during recursive invocation
          continue unless g.hasEdge e
          t = g.target e
          if visited[t]
            #TODO: better cycles detection this way the cycle detection
            # in runner isn't needed
            @logger.warn "cycles in dependencies #{n} -> #{t}"
          else
            dfs t, e
        delete visited[n]
        return
      if root?
        dfs root
      else
        dfs(i) for i in g.nodes()
