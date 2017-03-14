import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'dart:io';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  
  bot.onText(new RegExp("\/remote"), (msg, match) {
    // From file path
    Uri video = Uri.parse("https://archive.org/download/Pbtestfilemp4videotestmp4/video_test.mp4");
    bot.sendVideo(msg['chat']['id'], video);
  });
  
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
}
