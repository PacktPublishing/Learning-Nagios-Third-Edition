var net = require('net');

var client = net.connect({
  path: '/var/nagios/rw/nagios.qh'
}, function () {
  client.write('@nerd subscribe hostchecks\0');
  client.write('@nerd subscribe servicechecks\0');
});

var statuses = {
  host: ['UP', 'DOWN', 'UNREACHABLE'],
  service: ['OK', 'WARNING', 'CRITICAL',  'UNKNOWN']
};

var serviceRegExp = /(.*?);(.*?) from ([0-9]+) -> ([0-9]+): (.*)$/;
var hostRegExp = /(.*?) from ([0-9]+) -> ([0-9]+): (.*)$/;
client.on('data', function (data) {
  var msg = data.toString().trim();
  if (serviceRegExp.test(msg)) {
    var tokens = serviceRegExp.exec(msg);
    var status = Math.max(0, Math.min(tokens[4], 3));
    console.log('Service', tokens[2], 'on', tokens[1], 'is', statuses.service[status], ':', tokens[5]);
  } else if (hostRegExp.test(msg)) {
    var tokens = hostRegExp.exec(msg);
    var status = Math.max(0, Math.min(tokens[3], 2));
    console.log('Host', tokens[1], 'is', statuses.host[status], ':', tokens[4]);
  }
})

client.on('error', function (err) {
    console.log(err);
})
