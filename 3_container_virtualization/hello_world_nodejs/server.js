var http = require('http');
var os = require('os');

http.createServer(function (req, res) {
        var response = "<h1>I'm " + os.hostname() + " </h1>";
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end(response);
}).listen(8888);

