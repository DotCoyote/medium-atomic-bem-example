browserSync         = require 'browser-sync'
chalk               = require 'chalk'
gulp                = require 'gulp'
gutil               = require 'gulp-util'
notify              = require 'gulp-notify'
plumber             = require 'gulp-plumber'
rename              = require 'gulp-rename'
sourcemaps          = require 'gulp-sourcemaps'
uglify              = require 'gulp-uglify'
watch               = require 'gulp-watch'


relative_theme_path = ''

paths =
  folders :
    css:              relative_theme_path + 'css'
    sass:             relative_theme_path + 'sass'
    babel:            relative_theme_path + 'src/js'
    scripts:          relative_theme_path + 'js'
    images:           relative_theme_path + 'img'
    imagesprites:     relative_theme_path + 'img/icons'
    templates:        relative_theme_path + 'src/tpl'

  files :
    css:              relative_theme_path + 'css/**/*.css'
    sass:             relative_theme_path + 'sass/**/*.sass'
    babel:            relative_theme_path + 'src/js/scripts.js'
    scripts:          relative_theme_path + 'js/*.js'
    images:           relative_theme_path + 'img/**/*'
    imagesprites:     relative_theme_path + 'img/**/*.svg'
    templates:        relative_theme_path + 'src/tpl/*.pug'

paths.files.svgFiles = [paths.files.imagesprites, '!' + paths.folders.imagesprites + '/sprite.svg', '!' + paths.folders.imagesprites + '/single/*.svg']

# Compile only specified file
#var compileOnly = paths.folders.sass + "/landingpage.scss";
compileOnly = false;

# onError Start
onError = ( err ) ->

  notify(
    title: err.name + ': [' + err.plugin + ']'
    message: 'See console.').write err

  chalkError  = gutil.colors.red
  chalkInfo   = gutil.colors.magenta
  chalkShy    = gutil.colors.gray
  chalkShyAlt = gutil.colors.yellow


  if err.plugin == 'gulp-sass'

    # Initial building up of the error
    errorString = chalkError(err.name+': ') + chalkInfo('[' + err.plugin + ']') + '\n'
    errorString += ' ' + err.formatted

  else if err.plugin == 'gulp-coffee'

    # Initial building up of the error
    errorString = chalkError(err.name+': ') + chalkInfo('[' + err.plugin + ']')
    errorString += ' ' + err.message.replace("\n",''); # Removes new line at the end

    # If the error contains the filename or line number add it to the string
    if err.location.first_line
      errorString += chalkShy(' on line ') + err.location.first_line

    if err.location.first_column
      errorString += ':' + err.location.first_column

    if err.location.first_line != err.location.last_line || (typeof err.location.last_line != 'undefined' and err.location.first_line == err.location.last_line and err.location.first_column != err.location.last_column)
      errorString += chalkShy(' - ') + err.location.last_line + ':' + err.location.last_column


    if err.filename
      errorString += '\n'
      errorString += chalkShyAlt(err.filename)

  else if err.plugin == 'gulp-jade' or err.plugin == 'gulp-babel' or err.plugin == 'gulp-pug'

    # Initial building up of the error
    errorString = chalkError(err.name+': ') + chalkInfo('[' + err.plugin + ']') + '\n'
    errorString += ' ' + err.message

  else
    console.log err

  # This will output an error like the following:
  # [gulp-sass] error message in file_name on line 1
  console.error(errorString);

  this.emit( 'end' )

ignoreError = ( err ) ->
  this.emit( 'end' )

# Map error for Browserify
map_error = (err) ->

  if err.fileName
    # regular error
    gutil.log chalk.red(err.name) + ': ' + chalk.yellow(err.fileName.replace(__dirname + '/src/es6/', '')) + ': ' + 'Line ' + chalk.magenta(err.lineNumber) + ' & ' + 'Column ' + chalk.magenta(err.columnNumber or err.column) + ': ' + chalk.blue(err.description)
  else
    # browserify error..
    gutil.log chalk.red(err.name) + ': ' + chalk.yellow(err.message)

# END



# Styles
gulp.task 'styles', ->

  sass                = require 'gulp-sass'
  nano                = require 'cssnano'
  postcss             = require 'gulp-postcss'
  postcssrgba         = require 'postcss-color-rgba-fallback'
  postcssshort        = require 'postcss-short'
  postcssflexbugs     = require 'postcss-flexbugs-fixes'
  pxtorem             = require 'postcss-pxtorem'
  rucksack            = require 'gulp-rucksack'
  sassGlob            = require 'gulp-sass-glob'

  if compileOnly != false
    srcFile = compileOnly
  else
    srcFile = paths.files.sass

  processors = [
    postcssshort()
    nano()
    pxtorem(
      replace: false
      prop_white_list: [
        'padding'
        'padding-left'
        'padding-right'
        'padding-top'
        'padding-bottom'
        'margin'
        'margin-left'
        'margin-top'
        'margin-right'
        'margin-bottom'
        'width'
        'height'
        'min-width'
        'min-height'
        'max-width'
        'max-height'
        'font'
        'font-size'
        'line-height'
        'letter-spacing'
        'top'
        'left'
        'bottom'
        'right'
      ]
      selector_black_list: [
        'body'
        'html'
      ])
    postcssflexbugs()
    postcssrgba(properties: [
      'background-color'
      'background'
      'color'
      'border'
      'border-color'
      'outline'
      'outline-color'
      'box-shadow'
      'text-shadow'
    ])
  ]

  gulp.src([ srcFile ], base: paths.folders.sass)
    .pipe(plumber(errorHandler: onError))
    .pipe(sourcemaps.init())
    .pipe(sassGlob())
    .pipe(sass(
      sourcemap: true
      style: 'compact'
    ))
    .pipe(rucksack(
      autoprefixer: true
    ))
    .pipe(postcss(processors))
    .pipe(sourcemaps.write('./maps',
      sourceRoot: null
    ))
    .pipe(gulp.dest(paths.folders.css))
    .pipe(browserSync.reload(stream: true))
    .pipe notify(
      message: 'Styles task complete'
      title: 'Styles'
      onLast: true)
    .on('error', onError)
# END



# SVG Sprite
gulp.task 'svgSprite', ->

  imagemin            = require 'gulp-imagemin'
  svgSprite           = require 'gulp-svg-sprite'
  size                = require 'gulp-size'
  cheerio             = require 'gulp-cheerio'

  gulp.src(paths.files.svgFiles)
    .pipe(plumber(errorHandler: onError))
    .pipe(imagemin(
      svgoPlugins:
        "cleanupIDs": false,
        "removeComments": true,
        "removeViewBox": false,
        "removeDesc": true,
        "removeTitle": true,
        "removeUselessDefs": false,
        "removeDoctype": true,
        "removeEmptyText": true,
        "removeUnknownsAndDefaults": true,
        "removeEmptyContainers": true,
        "collapseGroups": true,
        "sortAttrs": true,
        "removeUselessStrokeAndFill": true,
        "convertStyleToAttrs": true
    ))
    .pipe(svgSprite(
      shape:
        dimension:
          maxWidth: 40
          maxHeight: 40
        spacing: padding: 0
        dest: './single/'
      mode: symbol:
        dest: '.'
        sprite: 'sprite.svg'
        inline: false))
    .on('error', onError)
    .pipe(gulp.dest(paths.folders.imagesprites))
    .pipe(size())
    .pipe(cheerio(
      run: ($) ->
        $('[fill^="#"]').removeAttr 'fill'
        $('[fill^="none"]').removeAttr 'fill'
        $('[fill-rule]').removeAttr 'fill-rule'
        return
      parserOptions: xmlMode: true
    ))
    .pipe gulp.dest(paths.folders.imagesprites)





gulp.task 'lint', ->
  eslint    = require('gulp-eslint')

  gulp.src(paths.files.babel)
    # eslint() attaches the lint output to the "eslint" property
    # of the file object so it can be used by other modules.
    .pipe(eslint())
    # eslint.format() outputs the lint results to the console.
    # Alternatively use eslint.formatEach() (see Docs).
    .pipe(eslint.format())
    .pipe notify(
      message: 'Lint task complete'
      title: 'Babel'
      onLast: true)

# Babel
gulp.task 'babel', ['lint'], ->

  browserify = require('browserify')
  babelify  = require('babelify')
  source    = require('vinyl-source-stream')
  buffer    = require('vinyl-buffer')
  merge     = require('utils-merge')
  rename    = require('gulp-rename')
  uglify    = require('gulp-uglify')

  browserify(paths.files.babel)
    .transform("babelify", {presets: ["es2015"]})
    .bundle()
    .on('error', (error) ->
      console.log('error')
      map_error(error)
      this.emit('end')
    )
    .pipe(source('scripts.js'))
    .pipe(buffer())
    .pipe(sourcemaps.write('./maps'))
    .pipe(gulp.dest(paths.folders.scripts))
    .pipe(rename('scripts.min.js'))
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(uglify())
    .pipe(sourcemaps.write('./maps'))
    .pipe gulp.dest(paths.folders.scripts + '/min')
    .pipe(browserSync.reload(stream: true))
    .pipe notify(
      message: 'ES6 task complete'
      title: 'Babel'
      onLast: true)
# END


# Pug Templates
gulp.task 'pug', ->
  pug                = require 'gulp-pug'

  gulp.src(paths.files.templates)
    .pipe(plumber(errorHandler: onError))
    .pipe(pug(pretty: '  '))
    .pipe(gulp.dest('.'))
    .pipe(browserSync.reload(stream: true))
    .pipe notify(
      message: 'Template task complete'
      title: 'Pug'
      onLast: true)
    .on('error', onError)
# END

# Browser Sync
gulp.task 'browser-sync', ->
  browserSync
    server: baseDir: '.'
    notify: false
    port: 5000
  return

gulp.task 'default', [
  'styles'
  'browser-sync'
], ->
  gulp.watch paths.files.sass, [ 'styles' ]
  return
