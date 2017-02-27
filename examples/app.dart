import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'dart:core';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  bot.on('message', (msg) {
    bot.sendMessage(msg['chat']['id'], 'hi');
  });
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
}