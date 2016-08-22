var page = require('webpage').create();
var system = require('system');

var url = system.args[1];
var user = system.args[2];
var password = system.args[3];

page.open(url, function (status) {
  if (status !== 'success') {
    console.log('WORDPRESS CRITICAL: Could not open page.');
    phantom.exit(2);
  }
  page.onLoadFinished = function () {
    var loggedIn = page.evaluate(function () {
      var logoutElement = document.getElementById('wpcontent');
      return !!logoutElement;
    });
    if (loggedIn) {
      console.log('WORDPRESS OK: Administrative panel loaded correctly.');
      phantom.exit(0);
    } else {
      console.log('WORDPRESS CRITICAL: Administrative panel does not work.');
      phantom.exit(2);
    }
  };

  var err = page.evaluate(function (user, password) {
    try {
      document.getElementById('user_login').value=user;
      document.getElementById('user_pass').value=password;
      document.getElementById('loginform').submit();
    } catch (err) {
      return err;
    }
  }, user, password);
  if (err) {
    console.log('WORDPRESS CRITICAL: Administrative panel DOM incorrect.');
    phantom.exit(2);
  }
});
