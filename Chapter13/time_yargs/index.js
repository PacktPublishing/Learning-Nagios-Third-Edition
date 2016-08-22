var ntpClient = require('ntp-client');

var argv = require('yargs')
  .help('H')
  .alias('H', 'help')
  .options({
    h: {
      alias: 'hostname',
      describe: 'Network Time Protocol server',
      default: 'ntp2a.mcc.ac.uk',
      nargs: 1
    },
    w: {
      alias: 'warning',
      describe: 'positive number of seconds',
      default: '300',
      type: 'number',
      nargs: 1
    },
    c: {
      alias: 'critical',
      describe: 'positive number of seconds',
      default: '600',
      type: 'number',
      nargs: 1
    }
  })
  .argv;

['warning', 'critical'].forEach(function (param) {
  if (argv[param] <= 0) {
    console.log('Invalid', param, 'time specified');
    process.exit(3);
  }
});

ntpClient.getNetworkTime(argv.hostname, 123, function(err, date) {
    if(err) {
        console.error(err);
        return;
    }
    var states = ['OK', 'WARNING', 'CRITICAL'];
    var diff = Math.abs((new Date().getTime()) - date.getTime());
    var i = diff < argv.warning ? 0 : (diff < argv.critical ? 1 : 2);
    console.log('check_time', states[i] + ':', diff, 'seconds difference');
    process.exit(i);
});