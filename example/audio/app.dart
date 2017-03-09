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

  bot.onText(new RegExp("\/existing"), (msg, match) {
    // From file path
    List<int> audio = new File("${dirname(Platform.script.path)}/audio.mp3").readAsBytesSync();
    bot.sendAudio(msg['chat']['id'], audio);
  });

  bot.onText(new RegExp("\/local"), (msg, match) {
    // From file path
    String audio = "${dirname(Platform.script.path)}/audio.mp3";
    bot.sendAudio(msg['chat']['id'], audio);
  });

  bot.onText(new RegExp("\/remote"), (msg, match) {
    // From file path
    Uri audio = Uri.parse("https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg");
    bot.sendAudio(msg['chat']['id'], audio);
  });
  
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
}
