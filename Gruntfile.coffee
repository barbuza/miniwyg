module.exports = (grunt) ->
  "use strict"
  grunt.initConfig
    clean:
      build: ["build"]
      release: ["release"]

    copy:
      static:
        files: [
          expand: true
          cwd: "source"
          matchBase: true
          src: ["*.*", "!*.styl", "!*.haml", "!*.ls"]
          dest: "build"
          filter: "isFile"
        ]
      release:
        files:
          "release/miniwyg.html": "build/miniwyg.html"

    parallel:
      server:
        tasks: ["watch", "connect:server"]
        options:
          grunt: true
          stream: true

    connect:
      server:
        options:
          port: 5678
          base: "build"
          keepalive: true

    watch:
      livescript:
        files: ["source/**/*.ls"]
        tasks: ["livescript"]
        options:
          livereload: true

      stylus:
        files: ["source/**/*.styl"]
        tasks: ["stylus", "autoprefixer"]
        options:
          livereload: true

      haml_html:
        files: ["source/**/*.haml", "!source/templates/**/*.haml"]
        tasks: ["haml:html"]
        options:
          livereload: true

      haml_templates:
        files: ["source/templates/**/*.haml"]
        tasks: ["haml:templates"]
        options:
          livereload: true

    livescript:
      options:
        sourceMap: yes

      compile:
        files: [
          expand: true
          cwd: "source"
          matchBase: true
          src: ["*.ls"]
          dest: "build"
          ext: ".js"
        ]

    stylus:
      compile:
        files: [
          expand: true
          cwd: "source"
          matchBase: true
          src: ["*.styl"]
          dest: "build"
          ext: ".css"
        ]

    autoprefixer:
      options:
        browsers: ["last 2 versions"]

      compile:
        files: [
          expand: true
          matchBase: true
          cwd: "build"
          src: "*.css"
          dest: "build"
        ]

    cssmin:
      compile:
        files: [
          expand: true
          matchBase: true
          cwd: "build"
          src: ["*.css"]
          dest: "release"
          ext: ".min.css"
        ]

    uglify:
      compile:
        files: [
          expand: true
          matchBase: true
          cwd: "build"
          src: ["*.js", "!jquery.js"]
          dest: "release"
          ext: ".min.js"
        ]

    haml:
      html:
        files: [
          expand: true
          cwd: "source"
          matchBase: true
          src: ["*.haml"]
          dest: "build"
          ext: ".html"
        ]
        options:
          target: "html"
          language: "coffee"


  require("fs").readdirSync("node_modules").forEach (name) ->
    grunt.loadNpmTasks name  if /^grunt-/.test(name)

  grunt.registerTask "server", ["parallel:server"]
  grunt.registerTask "build", ["copy:static", "stylus", "autoprefixer", "livescript", "haml"]
  grunt.registerTask "export", ["clean", "build", "cssmin", "uglify", "copy:release"]
  grunt.registerTask "default", ["clean", "build", "server"]
