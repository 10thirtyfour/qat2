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
  # we run scripts in following order
  # ./config (js or coffee)
  # ./config-$HOST (js or coffee)
  # ./config-$USER (js or coffee)
  # ./config-$HOST-$USER (js or coffee)
  # ~/.qat (js or coffee)
  # $QAT_CONFIG
  # config argument (may be many)

  {_,os,utils} = @
  @argv = argv = require("optimist").argv ? {}
  home = process.env.HOME ? process.env.USERPROFILE
  unless home? and process.env.HOMEPATH and process.env.HOMEDRIVE
    home = process.env.HOMEPATH + process.env.HOMEDRIVE
  unless home? and process.env.HOMEPATH
    home = process.env.HOMEPATH
  @home = home
  user = process.env.USERNAME ? process.env.USER
  @user = user
  qreqconfig = (name) =>
    try
      require(name).call @
  qreqconfig "../config"
  qreqconfig "../config-#{os.hostname()}"
  if user?
    qreqconfig "../config-#{user}"
    qreqconfig "../config-#{os.hostname()}-#{user}"
  qreqconfig("#{home}/.qat") if home?
    
  if process.env.QAT_CONFIG?
    qreqconfig "#{process.env.QAT_CONFIG}"
  if @config?
    qreqconfig("#{i}") for i in utils.mkArray argv.config
  _.merge @opts, argv
  return

# different locale is actually different users

