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


angular.module('shadowsocks').controller('shadowsocks',
  ['$scope', '$rootScope', '$timeout', 'ProfileManager', function($scope, $rootScope, $timeout, ProfileManager) {

  var generateProfileKeys = function() {
    var result = [], profile;
    for (key in $scope.profiles) {
      profile = $scope.profiles[key];
      result.push({name: profile.server + ':' + profile.server_port, key: key, server: profile.server});
    }
    return result;
  };

  $rootScope.$on('ProfileManagerReady', function() {
    $scope.allowSave = true;
    $scope.currentProfile = ProfileManager.currentProfile;
    $scope.profiles = ProfileManager.profiles;
    $scope.profileKeys = generateProfileKeys();
  });

  var timeoutPromise = null, originAlert = null;
  chrome.runtime.onMessage.addListener(function(msg, sender, sendResponse) {
    if (msg.type !== "LOGMSG") return;
    if (msg.timeout) {
      if (timeoutPromise)
        $timeout.cancel(timeoutPromise);
      else
        originAlert = $scope.alert;
      timeoutPromise = $timeout(function() {
        $scope.alert = originAlert;
        timeoutPromise = null;
      }, msg.timeout);
    }
    $scope.alert = msg.data;
    $scope.$apply();
  });

  $scope.createNewProfile = function() {
    $scope.currentProfile = ProfileManager.createProfile();
  };

  $scope.switchProfile = function(profileId) {
    $scope.currentProfile = ProfileManager.switchProfile(profileId);
  };

  $scope.saveAndApply = function() {
    if (!$scope.currentProfile.server   || !$scope.currentProfile.server_port ||
        !$scope.currentProfile.password || !$scope.currentProfile.local_port ||
        !$scope.currentProfile.method   || !$scope.currentProfile.timeout) {
      $scope.alert = { type: 'danger', msg: 'Fill all blanks before save' };
      return;
    }

    $scope.allowSave = false;
    ProfileManager.saveAsCurrent().then(function() {
      $scope.profiles = ProfileManager.profiles;
      $scope.profileKeys = generateProfileKeys();

      chrome.runtime.sendMessage({
        type: "SOCKS5OP",
        config: $scope.currentProfile
      }, function(info) {
        $scope.allowSave = true;
        $scope.alert = { type: 'info', msg: info };
        $scope.$apply();
      });

    });
  };

  $scope.deleteCurrentProfile = function() {
    ProfileManager.deleteProfile($scope.currentProfile.id).then(function() {
      $scope.profiles = ProfileManager.profiles;
      $scope.currentProfile = ProfileManager.currentProfile;
      $scope.profileKeys = generateProfileKeys();
    });
  };

  $scope.reloadApp = function() {
    chrome.runtime.reload();
  };

  $scope.about = function() {
    window.open('https://github.com/shadowsocks/shadowsocks-chromeapp');
  };
}]);