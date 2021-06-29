const gulp = require('gulp');
const ts = require("gulp-TypeScript");
const sourcemaps = require("gulp-sourcemaps");
const filter = require("gulp-filter");
const watch = require("gulp-watch");
const rimraf = require("rimraf");
const tsProject = ts.createProject("./tsconfig.json");


gulp.task("transpile", () => {
  const tsResult = tsProject
        .src()
        .pipe(sourcemaps.init())
        .pipe(tsProject(ts.reporter.fullReporter()))
        .on("error", () => null);
  return tsResult.js.pipe(sourcemaps.write("./")).pipe(gulp.dest("./dist/src"));

});


gulp.task("watch-server", ["transpile"], function() {
  return watch(["src/**/*.{ts,tsx}"], function() {
    gulp.start("transpile");
  });
});


gulp.task("initial-clean", function(done) {
  rimraf("./dist", done);
});


gulp.task("start-watch", ["initial-clean"], () => {
  gulp.start("watch-server");
});

gulp.task("watch", ["start-watch"]);
