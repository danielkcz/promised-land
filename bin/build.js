#!/usr/bin/env node

var fs         = require('fs');
var path       = require('path');
var uglifyjs   = require('uglify-js');
var browserify = require('browserify');

function bundle(file, options, callback) {
  bundleOptions = {
    entries: file,
    extensions: ['.coffee'],
    standalone: 'promised-land',
    bundleExternal: !options.solo
  };
  var b = browserify(bundleOptions);
  b.transform('coffeeify');
  return b.bundle(callback);
}

function addBanner(source) {
  var banner = fs.readFileSync(__dirname + '/banner').toString();
  return banner + source;
}

function minify(source) {
  var opts = { fromString: true };
  return uglifyjs.minify(source, opts).code;
}

function build(dest, options) {
  options = options || {};

  var src = __dirname + '/../src/land.coffee';

  bundle(src, options, function (err, bundled) {
    var bannered = addBanner(bundled);
    var content = options.minify ? minify(bannered) : bannered;
    fs.writeFileSync(dest, content);
    console.log('built', path.resolve(dest));
  });
}

build(__dirname + '/../promised-land-browser.js');
build(__dirname + '/../promised-land-browser.min.js', { minify: true });
build(__dirname + '/../promised-land-solo.js', { solo: true });
build(__dirname + '/../promised-land-solo-min.js', { solo: true, minify: true });