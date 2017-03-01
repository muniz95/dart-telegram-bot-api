import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:core';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  
  bot.onText(new RegExp("\/stream"), (msg, match) {
    // From file path
    Stream audio = new File("${dirname(Platform.script.path)}/audio.mp3").openRead();
    bot.sendAudio(msg['chat']['id'], audio);
  });
  
  bot.onText(new RegExp("\/local"), (msg, match) {
    // From file path
    String audio = "${dirname(Platform.script.path)}/audio.mp3";
    bot.sendAudio(msg['chat']['id'], audio);
  });
  
  bot.onText(new RegExp("\/remote"), (msg, match) {
    // From file path
    String url = "https://archive.org/download/testmp3testfile/mpthreetest.mp3";
    http.get(url)
      .then((audio) => bot.sendAudio(msg['chat']['id'], audio));
  });
}
