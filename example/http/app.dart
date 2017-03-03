import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

main() {
  // var data = {"qs": {"chat_id": 299327540},"formData": {"audio": {"value": {"uri": {"protocol": "https:","slashes": true,"auth": null,"host": "upload.wikimedia.org","port": 443,"hostname": "upload.wikimedia.org","hash": null,"search": null,"query": null,"pathname": "/wikipedia/commons/c/c8/Example.ogg","path": "/wikipedia/commons/c/c8/Example.ogg","href": "https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg"},"method": "GET","headers": {"host": "upload.wikimedia.org"}},"options": {"filename": "Example.ogg","contentType": "audio/ogg"}}}};
  // var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/sendAudio");
  var data = {"offset":"0","timeout":"10","polling":"null","chat_id":"null"};
  var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/getUpdates");
  // var data = {"chat_id": "299327540", "text": "It started!", "offset": "0", "polling": "0", "timeout": "0"};
  // var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/sendMessage");
  // send("POST", url, json: JSON.encode(data))
  //   .then((r) => print(r.content));
  send("POST", url, json: data)
    .then((res) => print(res));
}

Future<dynamic> send(String method, url, {json}) async {
  BaseClient bs = new IOClient();
  var request = new Request(method, url);
  request.headers['Content-Type'] = 'application/json';
  request.body = JSON.encode(json);
  var streamedResponse = await bs.send(request);
  var response = await Response.fromStream(streamedResponse);

  var bodyJson;
  try {
    bodyJson = JSON.decode(response.body);
  } on FormatException {
    var contentType = response.headers['content-type'];
    if (contentType != null && !contentType.contains('application/json')) {
      throw new Exception(
          'Returned value was not JSON. Did the uri end with ".json"?');
    }
    rethrow;
  }

  if (response.statusCode != 200) {
    if (bodyJson is Map) {
      var error = bodyJson['error'];
      if (error != null) {
        // TODO: wrap this in something helpful?
        throw error;
      }
    }
    throw bodyJson;
  }

  print(bodyJson);
}
