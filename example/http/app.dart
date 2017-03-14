import 'dart:io';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:http/http.dart';

main() {
  load();
  // Process.run('./post.sh', ["299327540", "/home/ubuntu/workspace/example/audio/audio.mp3", 'https://api.telegram.org/bot${env["TG_TOKEN"]}/sendAudio'])
  //   .then((ProcessResult results) {
  //     print(results.stdout);
  //   });
  String url = 'https://api.telegram.org/bot${env["TG_TOKEN"]}/sendAudio';
  Map options = {
    "chat_id": "299327540",
    "audio": "http://www.noiseaddicts.com/samples_1w72b820/3717.mp3"
  };
  post(url, body: options)
    .then((response) {
      print(response.body);
    });
}
