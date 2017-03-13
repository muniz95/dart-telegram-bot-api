import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dotenv/dotenv.dart' show load, env;

main() async {
  load();
  Uri uri = Uri.parse("https://api.telegram.org/bot${env['TG_TOKEN']}/sendDocument");
  // Uri uri = Uri.parse("https://madr-muniz95.c9users.io/file");
  var request = new MultipartRequest("POST", uri);
  MultipartFile mpf = new MultipartFile.fromBytes(
    "document",
    new File("${dirname(Platform.script.path)}/file.txt").readAsBytesSync()
  );
  request.fields['chat_id'] = "299327540";
  request.files.add(mpf);
  print(request.contentLength);
  // _send("POST", uri, json: {"chat_id": "299327540", "audio": mpf});
  return request
    .send()
    .then((response) {
      print(response.statusCode);
    })
    .catchError((err) => print(err));
  // print(request.url);
  // print(request.method);
  // print(request.headers);
  // print(request.fields);
  // print(request.files);
}
