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


angular.module('shadowsocks').controller('shadowsocks', ['$scope', 'storage', function($scope, storage) {

  $scope.isLoaded = false;

  var config = null;

  storage.get(['config', 'profiles']).then(function(items) {
    config = items.config || {currentProfile: null};
    $scope.profiles = items.profiles || {};
    $scope.profileKeys = Object.keys($scope.profiles);

    if (config.currentProfile in $scope.profiles) {
      $scope.currentProfile = $scope.profiles[config.currentProfile];
      chrome.runtime.sendMessage($scope.currentProfile);
    } else {
      $scope.createNewProfile();
    }

    $scope.isLoaded = true;
  });


  $scope.createNewProfile = function() {
    $scope.alert = null;
    $scope.currentProfile = {method: 'aes-256-cfb', timeout: 300};
  };

  $scope.switchProfile = function(key) {
    $scope.alert = null;
    $scope.currentProfile = $scope.profiles[key];
  };

  $scope.saveProfile = function() {
    if (!$scope.currentProfile.server   || !$scope.currentProfile.server_port ||
        !$scope.currentProfile.password || !$scope.currentProfile.local_port ||
        !$scope.currentProfile.method   || !$scope.currentProfile.timeout) {
      $scope.alert = { type: 'danger', msg: 'Fill all blanks before save' };
      return;
    }
    var key = $scope.currentProfile.server + ":" + $scope.currentProfile.server_port;
    config.currentProfile = key;
    $scope.profiles[key] = {
      server:      $scope.currentProfile.server,
      server_port: $scope.currentProfile.server_port,
      password:    $scope.currentProfile.password,
      local_port:  $scope.currentProfile.local_port,
      method:      $scope.currentProfile.method,
      timeout:     $scope.currentProfile.timeout
    };
    storage.set({profiles: $scope.profiles, config: config}).then(function(){
      chrome.runtime.reload();
    });
  };

  $scope.deleteCurrentProfile = function() {
    var key = $scope.currentProfile.server + ":" + $scope.currentProfile.server_port;
    if (key in $scope.profiles) {
      delete $scope.profiles[key];
      config.currentProfile = Object.keys($scope.profiles)[0];
      storage.set({profiles: $scope.profiles, config: config}).then(function(){
        chrome.runtime.reload();
      });
    }
  };

}]);