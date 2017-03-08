import 'package:dart_telegram_bot_api/telegram.dart';
import 'package:dotenv/dotenv.dart' show load, env;
import 'dart:core';

main() {
  load();
  Map options = {'polling': {'autoStart': true}, 'onlyFirstMatch': true};
  TelegramBot bot = new TelegramBot(env['TG_TOKEN'], options: options);
  // bot.on('message', (msg) {
  //   bot.sendMessage(msg['chat']['id'], 'hi');
  // });
  bot.onText(new RegExp(r"\/start"), (msg, match) {
    bot.sendMessage(msg['chat']['id'], "It started!");
  });
  bot.onText(new RegExp(r"\/me"), (msg, match) async {
    Map r = await bot.getMe();
    bot.sendMessage(msg['chat']['id'], r.toString());
  });
  bot.onText(new RegExp(r"\/typing"), (msg, match) {
    bot.sendChatAction(msg['chat']['id'], "typing");
  });
  bot.onText(new RegExp(r"\/upload"), (msg, match) {
    bot.sendChatAction(msg['chat']['id'], "upload_photo");
  });
  bot.onText(new RegExp(r"\/record"), (msg, match) {
    bot.sendChatAction(msg['chat']['id'], "record_audio");
  });
  bot.onText(new RegExp(r"\/location"), (msg, match) {
    bot.sendChatAction(msg['chat']['id'], "find_location");
  });
  bot.onText(new RegExp(r"\/user"), (msg, match) {
    bot.getUserProfilePhotos(msg['from']['id']);
  });
  bot.onText(new RegExp(r"\/map"), (msg, match) {
    bot.sendLocation(msg['chat']['id'], -25.413863, -49.250175);
  });
  bot.onText(new RegExp(r"\/venue"), (msg, match) {
    bot.sendVenue(msg['chat']['id'], -25.413863, -49.250175, "ICI", "Rua São Pedro, 910, Cabral, Curitiba, PR");
  });
  bot.onText(new RegExp(r"\/contact"), (msg, match) {
    bot.sendContact(msg['chat']['id'], 554133333333, "Rádio Taxi Sereia");
  });
  bot.onText(new RegExp(r"\/chat"), (msg, match) {
    bot.getChat(msg['chat']['id']).then((chat) => print(chat));
  });
  bot.onText(new RegExp(r"\/admins"), (msg, match) {
    bot.getChatAdministrators(msg['chat']['id']).then((admins) => print(admins));
  });
  bot.onText(new RegExp(r"\/count"), (msg, match) {
    bot.getChatMembersCount(msg['chat']['id']).then((count) => print(count));
  });
}