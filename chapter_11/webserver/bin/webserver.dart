import 'dart:io';

main() {
  print('simple web server');
  HttpServer.bind('127.0.0.1', 8080).then((server) {
    print('server will start listening');
    server.listen((HttpRequest request) {
      print('server listened');
      request.response.write('Learn Dart by Projects, develop in Spirals!');
      request.response.close();
    });
  });
}