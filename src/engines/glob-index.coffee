# module which scans some folder for specified pattern and execute scripts
# form it

module.exports = ->
  {Q,glob,utils,path,minimatch,_} = runner = @
  @reg
    name: "globLoader"
    
    
    items: {}
    setup: true
    root: process.env.QAT_TESTS_ROOT ? "../tests"
    # CONFOPT: let disabling search by pattern, name or root dir
    disable:
      root: {}
      pattern: {}
      file: {}
    # CONFOPT: only files matching patterns listed in only.file.pattern
    # will be imported
    only:
      file: {}
    regGlob: (info) ->
      @items[info.name] = info
    promise: ->
      runner.forEachTest (info) =>
        unless info.name?
          if @_curName?
            newName = @_curName
            newName += "$#{@_curCnt}" if @_curCnt isnt 0
            @_curCnt++
            info.name = newName
      res = for name, {pattern, root, opts, parseFile} of @items
        continue if @disable[name]
        continue if @disable.pattern[pattern]
        for d in utils.mkArray (root ? @root), path.delimiter
          continue if @disable.root[d]
          nopts = _.assign {cwd: d}, opts
          for p in utils.mkArray pattern
            do (d,name,parseFile) =>
              Q.nfcall(glob, p, nopts)
                .then((fn) =>
                  @trace "found files:", fn
                  chainPromise = Q {}
                  for i in fn
                    if @disable.file.pattern?
                      if _.some(
                        for j in utils.mkArray @disable.file.pattern
                          minimatch i, j)
                        @trace "#{i} matched disabling pattern"
                        continue 
                    if @only.file.pattern?
                      unless _.some(
                        for j in utils.mkArray @only.file.pattern
                          minimatch i, j)
                        @trace "#{i} didn't match any `only` pattern"
                        continue 
                    do (i) =>
                      fullname = "#{d}/#{i}"
                      dir = path.dirname(i).replace(/\//g, "$")
                        .replace(/\W/g,"")
                      nm = name + "$"
                      if dir.length isnt 0
                        nm += dir + "$"
                      nm += path.basename(i,path.extname(i))
                      chainPromise = chainPromise.then(() -> parseFile(fullname)).then((mod) =>
                        @trace "parsing file: ", fullname
                        if not mod? or not mod.call
                          throw new Error "wrong test format for #{fullname}"
                        @_curName = nm
                        @_curCnt = 0
                        res = mod.call runner
                        @_curName = null 
                        res)
                  chainPromise.then(=>
                      runner.sync()
                      true)
                  )
      Q.all _.flatten res
