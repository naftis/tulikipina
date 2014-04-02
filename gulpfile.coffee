path       = require 'path'
gulp       = require 'gulp'
gutil      = require 'gulp-util'
jade       = require 'gulp-jade'
stylus     = require 'gulp-stylus'
CSSmin     = require 'gulp-minify-css'
browserify = require 'gulp-browserify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
coffeeify  = require 'coffeeify'
lr         = require 'tiny-lr'
livereload = require 'gulp-livereload'
plumber    = require 'gulp-plumber'
prefix     = require 'gulp-autoprefixer'
express    = require 'express'
reloadServer = lr()

compileCoffee = (debug = false) ->
  bundle = gulp
    .src('./src/coffee/main.coffee', read: false)
    .pipe(plumber())
    .pipe(browserify(debug: debug))
    .pipe(rename('bundle.js'))

  bundle.pipe(uglify()) unless debug

  bundle
    .pipe(gulp.dest('./public/js/'))
    .pipe(livereload(reloadServer))

compileJade = (debug = false) ->
  gulp
    .src('src/jade/*.jade')
    .pipe(jade(pretty: debug))
    .pipe(gulp.dest('public/'))
    .pipe livereload(reloadServer)

compileStylus = (debug = false) ->
  styles = gulp
    .src('src/stylus/style.styl')
    .pipe(stylus({set: ['include css']}))
    .on('error', gutil.log)
    .on('error', gutil.beep)
  styles.pipe(CSSmin()) unless debug

  styles
    .pipe(prefix('last 1 version', '> 1%', 'ie 8', 'ie 7'))
    .pipe(gulp.dest('public/css/'))
    .pipe livereload reloadServer

copyAssets = (debug = false) ->
  gulp
    .src('src/assets/**/*.*')
    .pipe gulp.dest 'public/'

copyFonts = (debug = false) ->
  gulp
    .src('vendor/font-awesome/fonts/*.*')
    .pipe gulp.dest 'public/fonts/'

# Build tasks
gulp.task "jade-production", -> compileJade()
gulp.task 'stylus-production', ['fonts-production'], -> compileStylus()
gulp.task 'coffee-production', -> compileCoffee()
gulp.task 'assets-production', -> copyAssets()
gulp.task 'fonts-production', -> copyFonts()

# Development tasks
gulp.task "jade", -> compileJade(true)
gulp.task 'stylus', -> compileStylus(true)
gulp.task 'coffee', -> compileCoffee(true)
gulp.task 'assets', -> copyAssets(true)
gulp.task 'fonts', -> copyFonts(true)

gulp.task "server", ->
  app = express()

  app.configure ->
    app.use express.static path.join __dirname, 'public'

  app.get '/*', (req, res) ->
    res.sendfile path.join __dirname, 'public/index.html'

  app.listen 9001

gulp.task "watch", ->
  reloadServer.listen 35729, (err) ->
    console.error err if err?

    gulp.watch "src/coffee/**/*.coffee", ["coffee"]
    gulp.watch "src/jade/**/*.jade", ["jade"]
    gulp.watch "src/stylus/**/*.styl", ["stylus"]
    gulp.watch "src/assets/**/*.*", ["assets"]

gulp.task "build", ["coffee-production", "jade-production", "stylus-production", "assets-production", "fonts-production"]
gulp.task "default", ["coffee", "jade", "stylus", "assets", "fonts", "watch", "server"]
