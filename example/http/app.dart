import 'dart:convert';
import 'dart:io';
import 'package:simple_requests/simple_requests.dart';

main() {
  // var data = {"qs": {"chat_id": 299327540},"formData": {"audio": {"value": {"uri": {"protocol": "https:","slashes": true,"auth": null,"host": "upload.wikimedia.org","port": 443,"hostname": "upload.wikimedia.org","hash": null,"search": null,"query": null,"pathname": "/wikipedia/commons/c/c8/Example.ogg","path": "/wikipedia/commons/c/c8/Example.ogg","href": "https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg"},"method": "GET","headers": {"host": "upload.wikimedia.org"}},"options": {"filename": "Example.ogg","contentType": "audio/ogg"}}}};
  // var data = {"offset":"0","timeout":"10","polling":"null","chat_id":"null"};
  var data = {"chat_id": "299327540", "text": "It started!", "offset": null, "polling": null, "timeout": null};
  // var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/sendAudio");
  // var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/getUpdates");
  var url = Uri.parse("https://api.telegram.org/bot275274798:AAF-dv1Xxh57QGIFzsMEuoA_jFK5RI0BT4Q/sendMessage");
  request(url, payload: data)
    .then((r) => print(r.content));
}