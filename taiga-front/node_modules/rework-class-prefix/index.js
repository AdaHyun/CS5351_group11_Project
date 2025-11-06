'use strict';

var isPresent = require('is-present');
var hasClassSelector = require('has-class-selector');

module.exports = function classPrefix(prefix, options) {
  options = options || {};
  var ignored = options.ignored;

  return function prefixRules(styling) {
    styling.rules.forEach(function(rule) {

      if (rule.rules) {
        return prefixRules(rule);
      }

      if (!rule.selectors) return rule;

      rule.selectors = rule.selectors.map(function(selector) {
        var shouldIgnore = false;

        if (hasClassSelector(selector)) {
          // Ensure that the selector doesn't match the ignored list
          if (isPresent(ignored)) {
            shouldIgnore = ignored.some(function(opt) {
              if (typeof opt == 'string') {
                return selector === opt;
              } else if (opt instanceof RegExp) {
                return opt.exec(selector);
              }
            });
          }

          return shouldIgnore ? selector : selector.split('.').join('.' + prefix);
        } else {
          return selector;
        }
      });
    });
  };
};
