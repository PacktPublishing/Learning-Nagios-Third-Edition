var request = require('request');
var builder = require('xmlbuilder');

var token = 'cu8Eiquasoomeiphahpa';
var url = 'http://zomo.kocjan.org/nrdp/';


var xml = builder.create('root').ele('checkresults').ele('checkresult', {'type': 'service'});
xml.ele('hostname', 'localhost');
xml.ele('servicename', 'HTTP');
xml.ele('state', '1');
xml.ele('output', 'check result output here');

xml = xml.end({ pretty: true});

request.post(
    url,
    {
      form: {
        cmd: 'submitcheck',
        token: token,
        XMLDATA: xml
      }
    },
    function (error, response, body) {
      console.log(response.statusCode);
      console.log(body);
    }
);