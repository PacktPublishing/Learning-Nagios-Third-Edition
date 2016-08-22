var fs = require('fs');
var os = require('os');

var Nagios = function () {
  var pipeFileName = '/var/nagios/rw/nagios.cmd';
  var writeCommand = function (command, callback) {
    fs.appendFile(pipeFileName, command + os.EOL, callback);
  };

  this.writeStatus = function (host, svc, code, output, callback) {
    var time = Math.round(Date.now() / 1000);
    writeCommand('[' + time + '] PROCESS_SERVICE_CHECK_RESULT;' + host + ';' + svc + ';' + code + ';' + output, callback);
  };
};

var nagios = new Nagios();

var performTest = function () {
  //to be implemented
  return {
    code: 0,
    output: 'check_service: OK'
  }
};

setInterval(function () {
  var result = performTest();
  nagios.writeStatus('hostname', 'service', result.code, result.output, function (err) {
    console.log(err);
  });
}, 300 * 1000); //every 5 minutes


