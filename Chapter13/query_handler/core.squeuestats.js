var net = require('net');

var client = net.connect({
  path: '/var/nagios/rw/nagios.qh'
}, function () {
  client.write('@core squeuestats\0');
});

client.on('data', function (data) {
  data.toString().split(';').sort().forEach(function (line) {
    console.log(line);
  });
  client.end();
})

client.on('error', function (err) {
    console.log(err);
})
