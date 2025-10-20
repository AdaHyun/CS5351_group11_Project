var assert    = require('assert'),
    fs        = require('fs'),
    rework    = require('rework'),
    classPrfx = require('..');

function fixture(name) {
  return fs.readFileSync('test/fixtures/' + name, 'utf8').trim();
}

describe('rework-class-prefix', function() {

  it('prefixes all classes', function() {
    var output = rework(fixture('source.css')).use(classPrfx('prfx-')).toString().trim();
    var expected = fixture('source.css.expected');

    assert.equal(output, expected);
  });

  it('correctly ignores selectors when specified', function() {
    var output = rework(fixture('ignored-selectors.css'))
                   .use(
                     classPrfx('prfx-', { ignored: ['.ignored-class', /prefix/] })
                   ).toString().trim();

    var expected = fixture('ignored-selectors.css.expected');

    assert.equal(output, expected);
  });
});
