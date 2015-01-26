###
# #%L
# QUERIX
# %%
# Copyright (C) 2014 QUERIX
# %%
# ALL RIGTHS RESERVED.
# 50 THE AVENUE
# SOUTHAMPTON SO17 1XQ
# UNITED KINGDOM
# Tel ; +(44)02380 385 180
# Fax : +(44)02380 635 118
# http://www.querix.com/
# #L%
###
_ = require "lodash"
builder = require "xmlbuilder"

opts = {}

kindOf = (v) ->
  if _.isArray v then "array"
  else if _.isNumber v then "number"
  else if _.isObject v then "object"
  else if _.isDate v then "date"
  else if _.isBoolean v then "bool"
  else if _.isString v then "string"
  else null

read = ->
  throw new Error "not implemented"

module.exports = (opts) ->
  atomicField = (cur, name, val) ->
    cur.att name, val.toString()
  opts = _.merge {}, opts,
    arrayElemName: []
    array: (cur, name, val) ->
      throw new Error("array without name") unless name?
      elname = @arrayElemName[name]
      elname = name.substring(0,name.length-1) unless elname?
      cur = cur.ele name
      cur = @field(cur, elname, i, true) for i in val
      cur.up()
    object: (cur, name, val, nameopt) ->
      curname = name
      if val._type?
        if name? and not nameopt
          tyattr = val._type
        else
          curname = val._type
      curname ?= "object"
      if not name? and val._type?
        curname = val._type
      else
        name ?= "object"
      cur = cur.ele curname
      if tyattr?
        cur = cur.att "type", tyattr
      cur = @objectInner cur, val
      cur.up()
    objectInner: (cur, val) ->
      for n, v of val when n[0] isnt "_"
        cur = @field(cur, n, v) 
      cur
    number: atomicField
    date: atomicField
    bool: atomicField
    string: atomicField
    "field#text": (cur, name, val) -> cur.txt val
    field: (cur, name, val, noopt) ->
      nmspec = "field#{name}"
      if name? and @[nmspec]?
        return @[nmspec](cur, name, val, noopt) if @[nmspec]?
      k = kindOf val
      unless k? and @[k]
        throw new Error "cannot print: #{val} / #{k}"
      @[k] cur, name, val, noopt
  read: ->
    throw new Error "not implemented"
  write: (obj) ->
    opts.objectInner(
      builder.create("form", {version: '1.0', encoding: 'UTF-8'}).att("xmlns","http://namespaces.querix.com/2011/fglForms")
      obj).end pretty: true

