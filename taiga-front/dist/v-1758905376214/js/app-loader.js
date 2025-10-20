
/*
 * This source code is licensed under the terms of the
 * GNU Affero General Public License found in the LICENSE file in
 * the root directory of this source tree.
 *
 * Copyright (c) 2021-present Kaleidos INC
 */

(function() {
  var loadApp, loadJS, loadPlugin, loadPlugins, loadStylesheet, mainLoad, promise;

  window._version = "v-1758905376214";

  window.taigaConfig = {
    "api": "http://localhost:8000/api/v1/",
    "newsletterSubscriberUrl": "https://newsletter-subscriber.taiga.io",
    "eventsUrl": null,
    "tribeHost": null,
    "eventsMaxMissedHeartbeats": 5,
    "eventsHeartbeatIntervalTime": 60000,
    "debug": false,
    "defaultLanguage": "en",
    "themes": ["taiga", "taiga-legacy", "material-design", "high-contrast"],
    "defaultTheme": "taiga",
    "publicRegisterEnabled": true,
    "feedbackEnabled": true,
    "supportUrl": null,
    "privacyPolicyUrl": null,
    "termsOfServiceUrl": null,
    "maxUploadFileSize": null,
    "enableAsanaImporter": false,
    "enableGithubImporter": false,
    "enableJiraImporter": false,
    "enableTrelloImporter": false,
    "contribPlugins": [],
    "baseHref": "/"
  };

  window.taigaContribPlugins = [];

  window._decorators = [];

  window.addDecorator = function(provider, decorator) {
    return window._decorators.push({
      provider: provider,
      decorator: decorator
    });
  };

  window.getDecorators = function() {
    return window._decorators;
  };

  loadStylesheet = function(path) {
    var link;
    link = document.createElement('link');
    link.href = path;
    link.type = 'text/css';
    link.rel = 'stylesheet';
    return document.getElementsByTagName('head')[0].appendChild(link);
  };

  loadJS = function(path) {
    return new Promise(function(resolve, reject) {
      var script;
      script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = path;
      script.onload = resolve;
      script.onerror = function(err) {
        return reject(err, s);
      };
      return document.body.appendChild(script);
    });
  };

  loadPlugin = function(pluginPath) {
    return new Promise(function(resolve, reject) {
      var fail, success;
      success = function(plugin) {
        var i, item, len, ref;
        if (plugin.isPack) {
          ref = plugin.plugins;
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            window.taigaContribPlugins.push(item);
          }
        } else {
          window.taigaContribPlugins.push(plugin);
        }
        if (plugin.css) {
          loadStylesheet(plugin.css);
        }
        if (plugin.js) {
          return loadJS(plugin.js).then(resolve);
        } else {
          return resolve();
        }
      };
      fail = function(jqXHR, textStatus, errorThrown) {
        return console.error("Error loading plugin", pluginPath, errorThrown);
      };
      return fetch(pluginPath).then((function(_this) {
        return function(response) {
          return response.json();
        };
      })(this)).then(success, fail);
    });
  };

  loadPlugins = function(plugins) {
    var promises;
    promises = [];
    plugins.forEach(function(pluginPath) {
      return promises.push(loadPlugin(pluginPath));
    });
    return Promise.all(promises);
  };

  mainLoad = function() {
    var emojisPromise;
    emojisPromise = fetch(window._version + "/emojis/emojis-data.json").then((function(_this) {
      return function(response) {
        return response.json();
      };
    })(this)).then(function(emojis) {
      return window.emojis = emojis;
    });
    if (window.taigaConfig.contribPlugins.length > 0) {
      return loadJS(window._version + "/js/libs.js").then((function(_this) {
        return function() {
          return loadJS(window._version + "/js/templates.js");
        };
      })(this)).then((function(_this) {
        return function() {
          return loadPlugins(window.taigaConfig.contribPlugins);
        };
      })(this)).then((function(_this) {
        return function() {
          return loadApp(emojisPromise);
        };
      })(this));
    } else {
      return loadJS(window._version + "/js/libs.js").then((function(_this) {
        return function() {
          return loadJS(window._version + "/js/templates.js");
        };
      })(this)).then((function(_this) {
        return function() {
          return loadApp(emojisPromise);
        };
      })(this));
    }
  };

  loadApp = function(emojisPromise) {
    return loadJS(window._version + "/js/elements.js").then(function() {
      return loadJS(window._version + "/js/app.js").then(function() {
        return emojisPromise.then(function() {
          return angular.bootstrap(document, ['taiga']);
        });
      });
    });
  };

  promise = fetch("conf.json");

  promise.then((function(_this) {
    return function(response) {
      return response.json();
    };
  })(this)).then(function(data) {
    var base;
    window.taigaConfig = Object.assign({}, window.taigaConfig, data);
    base = document.querySelector('base');
    if (base && window.taigaConfig.baseHref) {
      base.setAttribute("href", window.taigaConfig.baseHref);
    } else if (!base && window.taigaConfig.baseHref) {
      base = document.createElement('base');
      base.setAttribute("href", window.taigaConfig.baseHref);
      document.head.appendChild(base);
    }
    return mainLoad();
  });

  promise["catch"](function() {
    console.error("Your conf.json file is not a valid json file, please review it.");
    return mainLoad();
  });

}).call(this);
