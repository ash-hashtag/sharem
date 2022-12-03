import 'package:flutter/animation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<VoidCallback> createHttpServer(int port, Future<Response> Function(Request request) handleRequests) async {
  var handler = const Pipeline().addHandler(handleRequests);

  var server = await serve(handler, '0.0.0.0', port);

  print("listening at $port");

  return () => server.close(force: true);
}

// Response handleRequests(Request request) {
//   switch (request.headers['content-type']) {
//     case 'file':
//       return fileHandler(request);
//     case 'files':
//       return filesHandler(request);
//     case 'text':
//       return textHandler(request);
//     default:
//       return Response.badRequest();
//   }
// }

// Response filesHandler(Request request) {
//   return Response.internalServerError();
// }

// Response fileHandler(Request request) {
//   return Response.internalServerError();
// }

// Response textHandler(Request request) {
//   return Response.internalServerError();
// }
