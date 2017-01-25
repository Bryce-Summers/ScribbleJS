module.exports = function (grunt) {
  grunt.initConfig({
    includeSource: {
      options: {
        basePath: './'
      },
      myTarget: {
        files: {
          'index.html': 'index.tpl.html'
        }
      }
    },
    uglify: {
        bar: {
            // uglify task "bar" target options and files go here.
        }
    },

    concat: {
        options: {
            separator: '\n',
            banner: '/*! Scribble JS, a project by Bryce Summers.\n *  Single File concatenated by Grunt Concatenate on <%= grunt.template.today("dd-mm-yyyy") %>\n */\n'
        },
        dist: {
            // Include one level down, two levels down, three levels down, then main
            src: [ // Bryce Data Structures Library Dependancy.
            'src/namespace.js', 'lib/*/*.js', 'lib/*/*/*.js', 'lib/*/*/*/*.js'],
            dest: 'builds/a_current_build.js',
        },
    },

    watch: {
        scripts: {
            files: ['lib/*.js'],
            tasks: ['concat'],
            options: {
                spawn: false,
            },
        },
    },

  });
 
  // Source Inclusion.
  grunt.loadNpmTasks('grunt-include-source');

  // Minification and Uglification.
  grunt.loadNpmTasks('grunt-contrib-uglify');

  // File concatenation into one file.
  grunt.loadNpmTasks('grunt-contrib-concat');

  // Run grunt tasks every time the source is modified.
  grunt.loadNpmTasks('grunt-contrib-watch');

  grunt.registerTask('default', function (target) {
    //grunt.task.run('includeSource');

    // build the files together.
    grunt.task.run('concat');

    // Rebuild the files everytime they are modified.
    //grunt.task.run('watch');
  });
};