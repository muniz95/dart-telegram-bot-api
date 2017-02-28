import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'dart:core';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  bot.onText(new RegExp("\/audio"), (msg, match) {
    // From file path
    String audio = "${dirname(Platform.script.toString())}/audio.mp3";
    bot.sendAudio(msg['chat']['id'], audio);
  });
}
