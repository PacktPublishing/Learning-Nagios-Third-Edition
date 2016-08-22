var net = require('net');

var client = net.connect({
  path: '/var/nagios/rw/nagios.qh'
}, function () {
  client.write('@core loadctl jobs_max=9999\0');
  client.write('@core loadctl\0');
});

client.on('data', function (data) {
  data.toString().split(';').forEach(function (line) {
    console.log(line);
  });
  client.end();
})

client.on('error', function (err) {
    console.log(err);
})
