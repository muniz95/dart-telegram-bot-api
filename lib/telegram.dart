import 'package:eventable/eventable.dart';
import './errors.dart' as errors;
import './telegramBotWebHook.dart';
import './telegramBotPolling.dart';
// const debug = require('debug')('node-telegram-bot-api');
// const EventEmitter = require('eventemitter3');
// const fileType = require('file-type');
// const Promise = require('bluebird');
// const request = require('request-promise');
// const streamedRequest = require('request');
// const qs = require('querystring');
// const stream = require('stream');
// const mime = require('mime');
// const path = require('path');
// const URL = require('url');
// const fs = require('fs');
// const pump = require('pump');
// const deprecate = require('depd')('node-telegram-bot-api');

final Array _messageTypes = [
  'text', 'audio', 'document', 'photo', 'sticker', 'video', 'voice', 'contact',
  'location', 'new_chat_participant', 'left_chat_participant', 'new_chat_title',
  'new_chat_photo', 'delete_chat_photo', 'group_chat_created'
];

class TelegramBot extends EventEmitter {
  String token;
  Object options;
  Array _textRegexpCallbacks;
  int _replyListenerId;
  Array _replyListeners;
  dynamic _polling;
  dynamic _webHook;
  
  static BaseError errors() {
    return errors;
  }

  static Array messageTypes() {
    return _messageTypes;
  }
  
  TelegramBot(String token, {polling}) {
    // super();
    this.token = token;
    this.options = options;
    if (this.options != null){
      this.options.polling = (options.polling == null) ? false : options.polling;
      this.options.webHook = (options.webHook == null) ? false : options.webHook;
      this.options.baseApiUrl = options.baseApiUrl || 'https://api.telegram.org';
      this.options.filepath = (options.filepath == null) ? true : options.filepath;
    }
    this._textRegexpCallbacks = [];
    this._replyListenerId = 0;
    this._replyListeners = [];
    this._polling = null;
    this._webHook = null;

    // if (options.polling) {
    //   var autoStart = options.polling.autoStart;
    //   if (typeof autoStart === 'undefined' || autoStart === true) {
    //     this.startPolling();
    //   }
    // }

    // if (options.webHook) {
    //   const autoOpen = options.webHook.autoOpen;
    //   if (typeof autoOpen === 'undefined' || autoOpen === true) {
    //     this.openWebHook();
    //   }
    // }
  }
}