import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'dart:io';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  
  bot.onText(new RegExp("\/remote"), (msg, match) {
    // From file path
    Uri sticker = Uri.parse("https://raw.githubusercontent.com/webmproject/libwebp/master/webp_js/test_webp_js.webp");
    bot.sendSticker(msg['chat']['id'], sticker);
  });
  
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
}
