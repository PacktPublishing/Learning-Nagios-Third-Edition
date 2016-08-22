var net = require('net');

var msg = 'Query handler is working properly!'

var client = net.connect({
  path: '/var/nagios/rw/nagios.qh'
}, function () {
  client.write('@echo ' + msg + '\0');
});

client.on('data', function (data) {
  if(data.toString() === msg) {
    console.log('Returm message matches sent message');
    client.end();
    process.exit(0);
  } else {
    console.log('Return message does not match');
    client.end();
    process.exit(1);
  }
})

client.on('error', function (err) {
    console.log(err);
})
