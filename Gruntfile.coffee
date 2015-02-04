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
module.exports = (grunt) ->
  matchdep = require("matchdep")
  matchdep.filterAll("grunt-*").forEach(grunt.loadNpmTasks)
  config =
    clean:
      options:
        force: true
      main: ["lib"]
    coffee:
      main:
        options:
          sourceMap: true
        expand: true
        cwd: "src"
        dest: "lib"
        src: "**/*.coffee"
        ext: ".js"
    copy:
      main:
        expand: true
        cwd: "src/"
        src: "**/*.js"
        dest: "lib"
    mkdir:
      all:
        options:
          create: ["tmp"]
    watch:
      main:
        files: ["src/**"]
        tasks: "coffee"
    markdown:
      main:
        files: [
          expand: true
          src: "README.md"
          dest: "lib"
          ext: ".html"
          ]

  grunt.initConfig config
  grunt.registerTask "default", ["clean","coffee","copy","mkdir","markdown"]
