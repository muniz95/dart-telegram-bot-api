import 'dart:io';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:http/http.dart';
import 'package:path/path.dart';

main() {
  load();
  // Process.run('./post.sh', ["299327540", "/home/ubuntu/workspace/example/audio/audio.mp3", 'https://api.telegram.org/bot${env["TG_TOKEN"]}/sendAudio'])
  //   .then((ProcessResult results) {
  //     print(results.stdout);
  //   });
  Uri uri = Uri.parse('https://api.telegram.org/bot${env["TG_TOKEN"]}/sendPhoto');
  var request = new MultipartRequest("POST", uri);
  request.fields['chat_id'] = '299327540';
  request.files.add(new MultipartFile.fromBytes(
    'photo',
    new File('${dirname(Platform.script.path)}/photo.jpg').readAsBytesSync()
  ));
  request
    .send()
    .then((response) => print(response.reasonPhrase));
}
