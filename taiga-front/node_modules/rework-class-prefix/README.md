# rework-class-prefix [![Build Status](https://travis-ci.org/johnotander/rework-class-prefix.svg?branch=master)](https://travis-ci.org/johnotander/rework-class-prefix)

Add a class prefix to further sandbox CSS styling for third-party imports.

This comes in handy when you want to import two different CSS modules that might
have conflictings styles. For example, if module A and module B both have a
`.media` class selector that have different use cases, you can run them through
`rework-class-prefix` and result in something like `.a-media` and `.b-media`.

__Example input__

```css
.grid { /* ... */ }
.grid-row { /* ... */ }
.grid-row-col { /* ... */ }
```

__Example output__
`classPrefix('flx-')`
```css
.flx-grid { /* ... */ }
.flx-grid-row { /* ... */ }
.flx-grid-row-col { /* ... */ }
```

## Installation

```
npm install --save rework-class-prefix
```

## Usage

```javascript
var fs        = require('fs'),
    rework    = require('rework'),
    classPrfx = require('rework-class-prefix');

var css = fs.readFileSync('css/my-file.css', 'utf8').toString();
var out = rework(css).use(classPrfx('my-prefix-')).toString();
```
#### In a gulpfile

```js
var gulp        = require('gulp'),
    name        = require('gulp-rename'),
    rework      = require('gulp-rework'),
    reworkNPM   = require('rework-npm'),
    classPrefix = require('rework-class-prefix');

gulp.task('css', function() {
  return gulp.src('index.css')
    .pipe(rework(reworkNPM(), classPrefix('prfx-')))
    .pipe(name('index-prefixed.css'))
    .pipe(gulp.dest('css'));
});
```

### Using the `ignored` option

```javascript
var fs        = require('fs'),
rework    = require('rework'),
classPrfx = require('rework-class-prefix');

var css = fs.readFileSync('css/my-file.css', 'utf8').toString();
var out = rework(css).use(
            classPrfx('my-prefix-', { ignored: [/\.ng-/, 'some-class-to-ignore'] })
          ).toString();
```

## License

MIT

## Acknowledgements

* Leverages <https://github.com/intesso/rework-walk>.
* Built on top of <https://github.com/reworkcss/rework>.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Crafted with <3 by [John Otander](http://johnotander.com) ([@4lpine](https://twitter.com/4lpine)).
