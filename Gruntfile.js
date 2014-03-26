module.exports = function(grunt) {
  var watchChanged = {}
  if (grunt.file.exists('watchChanged.json')) {
    watchChanged = grunt.file.readJSON('watchChanged.json')
  }
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    react: { // just for jsxhint, production transform is done
             // by browserify
      dynamic_mappings: {
        files: [
          {
            expand: true,
            cwd: 'page/jsx',
            src: ['*.jsx'],
            dest: 'tmp/jsx',
            ext: '.js'
          }
        ]
      }
    },
    jshint: {
      changed : [],
      js: ['Gruntfile.js', 'lib/*.js', 'page/js/*.js', 'tests/*.js'],
      jsx : ['tmp/jsx/*.js'],
      options: {
        "browser": true,
        "globals": {
          "React" : true,
          "CodeMirror" : true,
          "confirm" : true
        },
        "node" : true,
        "asi" : true,
        "globalstrict": false,
        "quotmark": false,
        "smarttabs": true,
        "trailing": false,
        "undef": true,
        "unused": false
      }
    },
    copy: {
      assets: {
        files: [
          // includes files within path
          {expand: true, cwd: 'page/', src: ['*'], dest: 'build/', filter: 'isFile'},

          // includes files within path and its sub-directories
          {expand: true, cwd: 'page/static', src: ['*.js', '*.jpg', '*.css'], dest: 'build/'}

          // makes all src relative to cwd
          // {expand: true, cwd: 'path/', src: ['**'], dest: 'dest/'},

          // flattens results to a single level
          // {expand: true, flatten: true, src: ['path/**'], dest: 'dest/', filter: 'isFile'}
        ]
      }
    },
    browserify:     {
      options:      {
        debug : true,
        transform:  [ require('grunt-react').browserify ]
      },
      app:          {
        src: 'page/js/main.js',
        dest: 'build/bundle.js'
      }
    },
    uglify: {
      options: {
        mangle: false,
        compress : {
          unused : false
        },
        beautify : {
          ascii_only : true
        }
      },
      assets: {
        files: {
          // 'build/bundle.min.js': ['build/bundle.js'],
          'build/vendor.min.js': ['page/vendor/*.js']
        }
      }
    },
    couchapp : {
      couchtalk: {
        db: 'http://localhost:59840/couchtalk',
        app: './lib/push.js',
        options: {
          okay_if_missing: true
        }
      }
    },
    watch: {
      scripts: {
        files: ['Gruntfile.js', 'lib/**/*.js', 'page/js/*.js'],
        tasks: ['jshint:changed', 'default'],
        options: {
          spawn: false,
        },
      },
      jsx: {
        files: ['page/jsx/*.jsx'],
        tasks: ['jsxhint', 'default'],
        options: {
          spawn: false,
        },
      },
      other : {
        files: ['page/**/*'],
        tasks: ['default'],
        options: {
          spawn: false,
        },
      }
    },
    notify: {
      "watch": {
        options: {
          message: 'Assets compiled.', //required
        }
      }
    }
  })
  grunt.loadNpmTasks('grunt-newer');
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-react');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-node-tap');
  // grunt.loadNpmTasks('grunt-static-inline');
  grunt.loadNpmTasks("grunt-image-embed");
  grunt.loadNpmTasks('grunt-express-server');
  grunt.loadNpmTasks('grunt-notify');
  grunt.loadNpmTasks('grunt-couchapp');

  grunt.registerTask('jsxhint', ['newer:react', 'jshint:jsx']);
  grunt.registerTask('default', ['jshint:js', 'jsxhint', 'build', 'couchapp', 'notify']);

  grunt.registerTask('dev', ['default', 'watch'])

  grunt.registerTask("build", ['copy:assets', 'browserify', 'uglify'])

  grunt.event.on('watch', function(action, filepath) {
    // for (var key in require.cache) {delete require.cache[key];}
    grunt.config('jshint.changed', [filepath]);
    grunt.file.write("watchChanged.json", JSON.stringify({
      node_tap : [filepath]
    }))
  });
};
