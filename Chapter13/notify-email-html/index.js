var handlebars = require('handlebars')
var email = require('emailjs');
var fs = require('fs');

var map = {}
var args = process.argv.slice(2);
['template', 'email', 'type', 'hostname', 'hoststate', 'hostoutput'].forEach(function (key, index) {
  map[key] = args[index];
});


var template = fs.readFileSync(map.template, 'utf8');
var html = handlebars.compile(template)(map);

var server = email.server.connect({
  user:    process.env.SMTP_USER,
  password:process.env.SMTP_PASSWORD,
  host:    process.env.SMTP_HOST,
  ssl:     true
});

var message = {
  from:    'Nagios <nagios@yourcompany.com>',
  to:      map.email,
  subject: 'Notification from Nagios',
  attachment:
  [
     {
       data: html,
       alternative: true
     }
  ]
};

server.send(message, function(error, message) {
  console.log(error, message); 
});