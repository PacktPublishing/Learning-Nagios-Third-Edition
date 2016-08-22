var mysql      = require('mysql');
var args = process.argv.slice(2);
var connection = mysql.createConnection({
  host     : args[0],
  user     : args[1],
  password : args[2],
  database : args[3]
});

var tables = args[4];
var errors = [];
var count = 0;

connection.connect();

tables = tables.split(',').map(function (string) {return string.trim();});
var queriesLeft = tables.length;

var onResult = function (table, msg) {
  if (msg === 'OK') {
    count++;
  } else {
   errors.push(table.trim());
  }
  if (--queriesLeft === 0) {
    connection.end();
    if (errors.length === 0) {
      console.log('check_mysql_table: OK', count, 'table(s) checked');
      process.exit(0);
    } else {
      console.log('check_mysql_table: CRITICAL: erorrs in', errors.join(', '));
      process.exit(2);
    }
  } 
};

tables.forEach(function (table) {
  connection.query('CHECK TABLE ' + table.trim(), function(err, rows, fields) {
    if (!err) {
      onResult(table, rows[0].Msg_text);
    } else {
      console.log('Error while performing Query.', err);
    }
  });
});

