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
              #Q.nfcall(glob, p, nopts)
              Q.ninvoke(runner,"glob",p,nopts)
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
                      chainPromise = chainPromise.then(() -> parseFile(fullname))
                  return chainPromise.then( =>
                      runner.sync()
                      true)
                  
                  )

      return Q.all(_.flatten(res,true))
