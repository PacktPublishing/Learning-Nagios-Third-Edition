var fs = require('fs');
var parse = require('nagios-status-parser');

var status = parse(fs.readFileSync('./status.dat', 'utf8'));

var findObject = function (status, type, filter) {
  var array = status[type];
  if (array) {
    return array.filter(function(entry) {
      return Object.keys(filter).every(function(key) {
        return filter[key] === entry[key];
      });
    });
  }
};

var type = 'servicestatus';
var filter = {
  last_hard_state: 2,
  host_name: 'localhost'
};
findObject(status, type, filter).forEach(function (object) {
  console.log(object.service_description, '-> Last state change:', new Date(object.last_state_change * 1000).toLocaleDateString("en-US"));
});
