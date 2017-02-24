# dart-telegram-bot-api
My attempt to create an interface to the Telegram Bot API

This project is a port of the [Yagop's node-telegram-bot-api](https://github.com/yagop/node-telegram-bot-api/), with almost all methods and features, but built entirely in Dart.

Currently, it is able to answer a message sent to the bot setted, but it answers you in an endless loop. Because of that, I am stopping the project for a while to find or develop a library similar to the [primus' eventemitter3](https://github.com/primus/eventemitter3), or even port it. If I find a way to make this bot work without event emitters it would be way better.
