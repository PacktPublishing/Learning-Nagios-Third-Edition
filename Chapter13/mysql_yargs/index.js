var mysql = require('mysql');
var argv = require('yargs')
  .demand(['h', 'u', 'p', 'd', 't'])
  .alias('h', 'hostname')
  .alias('u', 'username')
  .alias('p', 'password')
  .alias('d', 'dbname')
  .alias('t', 'tables')
  .array('t')
  .argv;

var connection = mysql.createConnection({
  host     : argv.hostname,
  user     : argv.username,
  password : argv.password,
  database : argv.dbname
});

var errors = [];
var count = 0;

connection.connect(function (err) {
  if (err) {
    console.log('check_mysql_table: CRITICAL: could not connect');
    process.exit(2);
  }
});
var queriesLeft = argv.tables.length;

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

argv.tables.forEach(function (table) {
  connection.query('CHECK TABLE ' + table, function(err, rows, fields) {
    if (!err) {
      onResult(table, rows[0].Msg_text);
    } else {
      console.log('Error while performing Query.', err);
    }
  });
});

