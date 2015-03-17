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


angular.module('shadowsocks').provider('storage', function() {
  
  var storageArea = 'local';

  this.setStorageArea = function(area) {
    storageArea = area;
  };

  this.$get = ['$q', '$injector', '$rootScope', function($q, $injector, $rootScope) {
    return $injector.instantiate(function() {
      this.get = function(keys) {
        var deferred = $q.defer();
        chrome.storage[storageArea].get(keys, function(items) {
          deferred.resolve(items);
        });
        return deferred.promise;
      };

      this.set = function(items) {
        var deferred = $q.defer();
        chrome.storage[storageArea].set(items, function() {
          deferred.resolve();
        });
        return deferred.promise;
      };

      this.remove = function(keys) {
        var deferred = $q.defer();
        chrome.storage[storageArea].remove(keys, function() {
          deferred.resolve();
        });
        return deferred.promise;
      };

      this.clear = function() {
        var deferred = $q.defer();
        chrome.storage[storageArea].clear(function() {
          deferred.resolve();
        });
        return deferred.promise;
      };

      chrome.storage.onChanged.addListener(function(changes, areaName) {
        if (areaName === storageArea) {
          $rootScope.$broadcast('storageChanged', changes);
        }
      });
    });
  }];
});