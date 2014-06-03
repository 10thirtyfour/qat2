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
  grunt.registerTask "default", ["clean","coffee","markdown"]
