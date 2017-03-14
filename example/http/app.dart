import 'dart:io';
import 'package:dotenv/dotenv.dart' show load, env;

main() async {
  load();
  Process.run('./post.sh', ["299327540", "/home/ubuntu/workspace/example/audio/audio.mp3", 'https://api.telegram.org/bot${env["TG_TOKEN"]}/sendAudio'])
    .then((ProcessResult results) {
      print(results.stdout);
    });
}
