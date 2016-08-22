var ntpClient = require('ntp-client');

var args = process.argv.slice(2);
var host = args[0];
var warnDiff = args[1];
var critDiff = args[2];

ntpClient.getNetworkTime(host, 123, function(err, date) {
    if(err) {
        console.error(err);
        return;
    }
    var states = ['OK', 'WARNING', 'CRITICAL'];
    var diff = Math.abs((new Date().getTime()) - date.getTime());
    var i = diff < warnDiff ? 0 : (diff < critDiff ? 1 : 2);
    console.log('check_time', states[i] + ':', diff, 'seconds difference');
    process.exit(i);
});