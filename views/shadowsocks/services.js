/*
Copyright (c) 2015 Sunny

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


angular.module('shadowsocks').service('storage',
  ['$q', '$rootScope', function($q, $rootScope) {

  var defaultArea = 'local';

  this.setDefaultArea = function(area) {
    defaultArea = area;
  };

  this.get = function(keys, area) {
    if (area == null)
      area = defaultArea;
    var deferred = $q.defer();
    chrome.storage[area].get(keys, function(items) {
      if (chrome.runtime.lastError)
        deferred.reject(chrome.runtime.lastError);
      deferred.resolve(items);
    });
    return deferred.promise;
  };

  this.set = function(items, area) {
    if (area == null)
      area = defaultArea;
    var deferred = $q.defer();
    chrome.storage[area].set(items, function() {
      if (chrome.runtime.lastError)
        deferred.reject(chrome.runtime.lastError);
      deferred.resolve();
    });
    return deferred.promise;
  };

  this.remove = function(keys, area) {
    if (area == null)
      area = defaultArea;
    var deferred = $q.defer();
    chrome.storage[area].remove(keys, function() {
      if (chrome.runtime.lastError)
        deferred.reject(chrome.runtime.lastError);
      deferred.resolve();
    });
    return deferred.promise;
  };

  this.clear = function(area) {
    if (area == null)
      area = defaultArea;
    var deferred = $q.defer();
    chrome.storage[area].clear(function() {
      if (chrome.runtime.lastError)
        deferred.reject(chrome.runtime.lastError);
      deferred.resolve();
    });
    return deferred.promise;
  };

  chrome.storage.onChanged.addListener(function(changes, areaName) {
    $rootScope.$broadcast('storageChanged', changes, areaName);
  });
}]);


angular.module('shadowsocks').service('ProfileManager',
  ['$rootScope', 'storage', function($rootScope, storage) {

  var createUUID = function() {
    var d = Date.now();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random() * 16) % 16 | 0;
        d = Math.floor(d / 16);
        return (c == 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
  };

  var createProfile = function() {
    return {
      id: createUUID(),
      server: null,
      server_port: null,
      password: null,
      local_port: null,
      method: 'aes-256-cfb',
      timeout: 300,
      one_time_auth: false
    }
  };

  var _this = this;
  storage.get(['config', 'profiles']).then(function(result) {
    _this.config = result.config || {currentProfile: null};
    _this.profiles = result.profiles || {};
    var _curProfile = _this.profiles[_this.config.currentProfile];
    if (_curProfile && !('one_time_auth' in _curProfile)) {
      _curProfile.one_time_auth = false;
    }
    _this.currentProfile = angular.copy(_curProfile || createProfile());
    $rootScope.$broadcast('ProfileManagerReady');
  });

  this.createProfile = function() {
    return _this.currentProfile = createProfile();
  };

  this.switchProfile = function(profileId) {
    _this.currentProfile = angular.copy(_this.profiles[profileId]);
    if (!'one_time_auth' in _this.currentProfile) {
      _this.currentProfile.one_time_auth = false;
    }
    return _this.currentProfile;
  };

  this.saveAsCurrent = function() {
    _this.profiles[_this.currentProfile.id] = _this.currentProfile;
    return storage.get(['config']).then(function(result) {
      result.config = result.config || {};
      result.config.currentProfile = _this.currentProfile.id;
      result.profiles = _this.profiles;
      return storage.set(result);
    });
  };

  this.deleteProfile = function(profileId) {
    delete _this.profiles[profileId];
    return storage.get(['config']).then(function(result) {
      result.config = result.config || {};
      if (result.config.currentProfile == profileId) {
        result.config.currentProfile = Object.keys(_this.profiles)[0] || null;
      }
      result.profiles = _this.profiles;
      return storage.set(result).then(function() {
        _this.currentProfile = angular.copy(_this.profiles[_this.config.currentProfile] || createProfile());
      });
    });
  };

}]);


angular.module('shadowsocks').filter('contains', function() {
  return function(input, data) {
    var result = [];
    angular.forEach(input, function(info) {
      if (data && info.name.indexOf(data) !== -1) {
        this.push(info);
      }
    }, result);
    return result;
  };
});
