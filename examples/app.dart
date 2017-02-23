import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dart_telegram_bot_api/telegramBotOptions.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'dart:core';

main() {
  load();
  TelegramBotOptions options = new TelegramBotOptions(polling: {'autoStart': true}, webHook: {'autoOpen': true});
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  bot.onText(new RegExp(r"\/start"), (msg) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
  bot.onText(new RegExp(r"\/select"), (msg) {
    bot.sendMessage(msg['chat']['id'], 'It selected!');
  });
}