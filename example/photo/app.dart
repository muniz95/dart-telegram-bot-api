import 'dart:async';
import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:core';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);

  bot.onText(new RegExp("\/photo"), (msg, match) {
    // From file path
    File file = new File("${dirname(Platform.script.path)}/photo.jpg");
    List<int> photo = file.readAsBytesSync();
    bot.sendPhoto(msg['chat']['id'], photo);
  });
  
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
}
