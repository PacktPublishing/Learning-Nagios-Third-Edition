var fs = require('fs');
var os = require('os');

var Nagios = function () {
  var pipeFileName = '/var/nagios/rw/nagios.cmd';
  var writeCommand = function (command, callback) {
    fs.appendFile(pipeFileName, command + os.EOL, callback);
  };
  this.scheduleHostCheck = function (host, when, callback) {
    if (when === undefined) {
      when = Math.round(Date.now() / 1000);
    }
    writeCommand('SCHEDULE_FORCED_HOST_CHECK;' + host + ';' + when, callback);
  };
  this.scheduleServiceCheck = function (host, svc, when, callback) {
    if (when === undefined) {
      when = Math.round(Date.now() / 1000);
    }
    writeCommand('SCHEDULE_FORCED_SVC_CHECK;' + host + ';' + svc + ';' + when, callback);
  };
};

var nagios = new Nagios();
nagios.scheduleHostCheck('host1');
var when = new Date();
when.setDate(when.getDate() + 1); // tomorrow
nagios.scheduleServiceCheck('localhost', 'APT', Math.round(when.getTime() / 1000));
