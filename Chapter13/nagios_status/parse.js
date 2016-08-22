var fs = require('fs');
var parse = require('nagios-status-parser');

var status = parse(fs.readFileSync('./status.dat', 'utf8'));

console.log(status.info);