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
          unless e.v.substr(0,7) is "atomic/"
            g.removeEdge(e) if visited[e.v]
        for e in g.outEdges n
           # the edge may deleted during recursive invocation
          continue unless g.hasEdge e
          t = e.w
          #console.log t+"__"+ visited
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
