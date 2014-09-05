#!/usr/bin/env node

var fs         = require('fs');
var path       = require('path');
var uglifyjs   = require('uglify-js');
var browserify = require('browserify');
var banner     = fs.readFileSync(__dirname + '/../LICENSE').toString()
var src        = __dirname + '/../src/land.coffee';
var target     = __dirname + '/../lib/land';
var pkg        = require('../package.json');

function minify(source) {
  var opts = { fromString: true, mangle: {
    toplevel: true
  }};
  return uglifyjs.minify(source, opts).code;
}

var bannerLines = banner.split("\n");
for (var i = 0, ii = bannerLines.length; i < ii; i++) {
  bannerLines[i] = "* " + bannerLines[i]
};
bannerLines.unshift("/*");
bannerLines.push("* ", "* Version: "+pkg['version'], "*/", "");
banner = bannerLines.join("\n");

var writeOut = function (suffix, content, cb) {
  var fileName = path.resolve(target + suffix);
  fs.writeFile(fileName, content, function(err) {
    if (err) {
      console.log("Error while writing to: ", fileName);
      console.error(err.stack || err);
    }
    else {
      console.log('Written file '+fileName);
    }
    cb && cb();
  });
}

var coffee = require('coffee-script');
var compiled = coffee.compile(fs.readFileSync(src).toString(), {
  bare: true
});
writeOut('.js', banner + compiled, function() {

  var bundleOptions = {
    entries: target + '.js',
    standalone: 'land',
  };

  browserify(bundleOptions).bundle(function(err, buf) {
    if (err) {
      console.log("Error during bundling");
      return console.error(err.stack || err);
    }
    var out = buf.toString();
    writeOut('-browser.js', out);
    writeOut('-browser.min.js', banner + minify(out));
  });
});

writeOut('.min.js', banner + minify(compiled));