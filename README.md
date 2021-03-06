# dart-telegram-bot-api
My attempt to create an interface to the Telegram Bot API

This project is a port of the [Yagop's node-telegram-bot-api](https://github.com/yagop/node-telegram-bot-api/), with almost all methods and features, but built entirely in Dart.

## Things it can do:

- [x] Answer messages and commands
- [ ] Send audio
  - [x] Via URL
  - [ ] By file uploading
- [ ] Send video
  - [x] Via URL
  - [ ] By file uploading
- [ ] Send documents
  - [x] Via URL (only .zip, .gif and .pdf, as explained in the [Bot's API documentation](https://core.telegram.org/bots/api#sending-files))
  - [ ] By file uploading
- [ ] Send images
  - [x] Via URL
  - [ ] By file uploading
- [ ] Send voice (any .ogg equal or smaller than 1MB)
  - [x] Via URL
  - [ ] By file uploading
- [ ] Send stickers
  - [x] Via URL
  - [ ] By file uploading
- [x] Reply messages (quote a message)
- [x] Send custom keyboards
- [x] Send location
- [x] Send venues
- [x] Send contacts
- [ ] Run with WebHooks
- [x] Run with polling
