import 'package:mime/mime.dart';
import 'package:events/events.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:core';
import 'dart:io';
import './errors.dart';
import './telegramBotWebHook.dart';
import './telegramBotPolling.dart';
import './telegramBotObjects.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
// import './telegramBotOptions.dart';
// const debug = require('debug')('node-telegram-bot-api');
// const fileType = require('file-type');
// const request = require('request-promise');
// const streamedRequest = require('request');
// const qs = require('querystring');
// const stream = require('stream');
// const path = require('path');
// const URL = require('url');
// const fs = require('fs');
// const pump = require('pump');
// const deprecate = require('depd')('node-telegram-bot-api');

final List _messageTypes = [
  'text', 'audio', 'document', 'photo', 'sticker', 'video', 'voice', 'contact',
  'location', 'new_chat_participant', 'left_chat_participant', 'new_chat_title',
  'new_chat_photo', 'delete_chat_photo', 'group_chat_created'
];

class TelegramBot extends Events {
  String token;
  Map options;
  List _textRegexpCallbacks;
  int _replyListenerId;
  List _replyListeners;
  dynamic _polling;
  dynamic _webHook;

  // static BaseError errors() {
  //   return new BaseError();
  // }

  static List messageTypes() {
    return _messageTypes;
  }

  TelegramBot(String token, {Map options}) : super() {
    this.token = token;
    this.options = options;
    if (this.options != null) {
      this.options['polling'] = options['polling'];
      this.options['webHook'] = options['webHook'];
      this.options['onlyFirstMatch'] = (options['onlyFirstMatch'] == null) ? false : options['onlyFirstMatch'];
      this.options['baseApiUrl'] = "https://api.telegram.org";
      ///////////////////////////////Arrumo depois////////////////////////////////////////////////////////////
      ////////////////////////////////////////////////////////////////////////////////////////////////////////
      // this.options.baseApiUrl = options.baseApiUrl != '' ? options.baseApiUrl : "https://api.telegram.org";
      ////////////////////////////////////////////////////////////////////////////////////////////////////////
      this.options['filePath'] = (options['filePath'] == null) ? true : options['filePath'];

      if (options['polling'] != null) {
        var autoStart = options['polling']['autoStart'];
        if (autoStart != null) {
          this.startPolling();
        }
      }

      if (options['webHook'] != null) {
        var autoOpen = options['webHook']['autoOpen'];
        if (autoOpen != null) {
          this.openWebHook();
        }
      }
    }

    this._textRegexpCallbacks = [];
    this._replyListenerId = 0;
    this._replyListeners = [];
    this._polling = null;
    this._webHook = null;
  }

  // /**
  //  * Generates url with bot token and provided path/method you want to be got/executed by bot
  //  * @param  {String} path
  //  * @return {String} url
  //  * @private
  //  * @see https://core.telegram.org/bots/api#making-requests
  //  */
  String _buildURL(_path) {
    return "${this.options['baseApiUrl']}/bot${this.token}/${_path}";
  }
  //
  // /**
  //  * Fix 'reply_markup' parameter by making it JSON-serialized, as
  //  * required by the Telegram Bot API
  //  * @param {Object} obj Object; either 'form' or 'qs'
  //  * @private
  //  * @see https://core.telegram.org/bots/api#sendmessage
  //  */
  void _fixReplyMarkup(obj) {
    var replyMarkup = obj['reply_markup'];
    if (replyMarkup != null) {
      obj['reply_markup'] = JSON.encode(replyMarkup);
    }
  }

  Future<dynamic> _send(String method, url, {json}) async {
    BaseClient bs = new IOClient();
    var request = new Request(method, url);
    request.headers['Content-Type'] = 'multipart/form-data';
    request.body = JSON.encode(json);
    var streamedResponse = await bs.send(request);
    var response = await Response.fromStream(streamedResponse);

    var bodyJson;
    try {
      bodyJson = JSON.decode(response.body);
    } on FormatException {
      var contentType = response.headers['content-type'];
      if (contentType != null && !contentType.contains('application/json')) {
        throw new Exception(
            'Returned value was not JSON. Did the uri end with ".json"?');
      }
      rethrow;
    }

    if (response.statusCode != 200) {
      if (bodyJson is Map) {
        var error = bodyJson['error'];
        if (error != null) {
          throw error;
        }
      }
      throw bodyJson;
    }

    return bodyJson;
  }

  //
  // /**
  //  * Make request against the API
  //  * @param  {String} _path API endpoint
  //  * @param  {Object} [options]
  //  * @private
  //  * @return {Promise}
  //  */
  _request(_path, {options}) {
    if(options == null) options = {};
    if (this.token == null) {
      return new Future.error(new FatalError('Telegram Bot Token not provided!'));
    }

    String _url = this._buildURL(_path);

    options['polling'] = options['polling'].toString();
    options['chat_id'] = options['chat_id'].toString();
    options['timeout'] = options['timeout'].toString();
    options['offset'] = options['offset'].toString();
    
    // print(options);
    
    return http.post(_url, body: options)
      .then((resp) {
        var data;
        try {
          data = JSON.decode(resp.body);
        }
        catch(err) {
          throw new ParseError("Error parsing Telegram response: ${resp.body}", resp);
        }
        
        if(data["ok"]){
          return data["result"];
        }
        
        throw new TelegramError("${data['error_code']} ${data['description']}", resp);
      })
      .catchError((err) {
        print('deu m.... ${err}');
      });
  }

  //
  // /**
  //  * Format data to be uploaded; handles file paths, streams and buffers
  //  * @param  {String} type
  //  * @param  {String|stream.Stream|Buffer} data
  //  * @return {Array} formatted
  //  * @return {Object} formatted[0] formData
  //  * @return {String} formatted[1] fileId
  //  * @throws Error if Buffer file type is not supported.
  //  * @see https://npmjs.com/package/file-type
  //  * @private
  //  */
  _formatSendData(type, data) async {
    var formData;
    var fileName;
    var fileId;
    
    // // This is a remote file
    // // FIX: find a proper replacement for the stream.Stream type
    // //
    if (data is List) {
      // // Will be 'null' if could not be parsed. Default to 'filename'.
      // // For example, 'data.path' === '/?id=123' from 'request("https://example.com/?id=123")'
      fileName = data[0];
      Stream value = data[1];
      formData = {};
      formData[type] = {
        'value': value,
        'options': {
          'filename': fileName,
          'contentType': lookupMimeType(fileName)
        }
      };
    }

    // // This is a Stream file
    // FIX: find a replacement for fileType() method
    //
    else if (data is Stream || data is http.MultipartFile) {
      print('É um stream de arquivo');
      // exit(0);
      var filetype = {'ext': 'mp3', 'mime': 'audio/mpeg'};
      if (filetype == null) {
        throw new FatalError('Unsupported Buffer file type');
      }
      formData = {};
      formData[type] = {
        'value': data,
        'options': {
          'filename': "data.${filetype['ext']}",
          'contentType': filetype['mime']
        }
      };
    }
    else if (this.options['filePath'] == null) {
      /**
        * When the constructor option 'filePath' is set to
        * 'false', we do not support passing file-paths.
        */
      fileId = data;
    }
    // // This is the reference for the file path
    // // FIX: find a replacement for the fs object
    // //
    // else if (fs.existsSync(data)) {
    else if (await new File(data).exists()) {
      fileName = data.toString().split("/").last;
      formData = {};
      formData[type] = {
        "value": new File(data).openRead(),
        "options": {
          "filename": fileName,
          "contentType": "audio/mpeg"
        }
      };
    }
    else {
      fileId = data;
    }
    return [formData, fileId];
  }
  //
  // /**
  //  * Start polling.
  //  * Rejects returned promise if a WebHook is being used by this instance.
  //  * @param  {Object} [options]
  //  * @param  {Boolean} [options.restart=true] Consecutive calls to this method causes polling to be restarted
  //  * @return {Promise}
  //  */
  startPolling({Map options}) async {
    if(options == null) options = new Map();
    if (this.hasOpenWebHook()) {
      print('FIX: find a replacement for Promise object');
      // return Promise.reject(new FatalError('Polling and WebHook are mutually exclusive'));
    }
    options['restart'] = options['restart'] == null ? true : options['restart'];
    if (!this._polling) {
      this._polling = new TelegramBotPolling(this);
    }
    return await this._polling.start(options: options);
  }
  //
  // /**
  //  * Alias of "TelegramBot#startPolling()". This is **deprecated**.
  //  * @param  {Object} [options]
  //  * @return {Promise}
  //  * @deprecated
  //  */
  initPolling() {
    return this.startPolling();
  }
  //
  // /**
  //  * Stops polling after the last polling request resolves.
  //  * Multiple invocations do nothing if polling is already stopped.
  //  * Returning the promise of the last polling request is **deprecated**.
  //  * @return {Promise}
  //  */
  stopPolling() {
    if (!this._polling) {
      print('FIX: find a replacement for Promise object');
      // return Promise.resolve();
    }
    return this._polling.stop();
  }
  //
  // /**
  //  * Return true if polling. Otherwise, false.
  //  * @return {Boolean}
  //  */
  isPolling() {
    return this._polling ? this._polling.isPolling() : false;
  }
  //
  // /**
  //  * Open webhook.
  //  * Multiple invocations do nothing if webhook is already open.
  //  * Rejects returned promise if Polling is being used by this instance.
  //  * @return {Promise}
  //  */
  openWebHook() {
    if (this.isPolling()) {
      print('FIX: find a replacement for Promise object');
      // return Promise.reject(new FatalError('WebHook and Polling are mutually exclusive'));
    }
    if (!this._webHook) {
      this._webHook = new TelegramBotWebHook(bot: this);
    }
    return this._webHook.open();
  }
  //
  // /**
  //  * Close webhook after closing all current connections.
  //  * Multiple invocations do nothing if webhook is already closed.
  //  * @return {Promise} promise
  //  */
  closeWebHook() {
    if (!this._webHook) {
      print('FIX: find a replacement for Promise object');
      // return Promise.resolve();
    }
    return this._webHook.close();
  }
  //
  // /**
  //  * Return true if using webhook and it is open i.e. accepts connections.
  //  * Otherwise, false.
  //  * @return {Boolean}
  //  */
  hasOpenWebHook() {
    return this._webHook != null ? this._webHook.isOpen() : false;
  }
  //
  // /**
  //  * Returns basic information about the bot in form of a "User" object.
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getme
  //  */
  getMe() {
    String _path = 'getMe';
    return this._request(_path);
  }
  //
  // /**
  //  * Specify an url to receive incoming updates via an outgoing webHook.
  //  * This method has an [older, compatible signature][setWebHook-v0.25.0]
  //  * that is being deprecated.
  //  *
  //  * @param  {String} url URL where Telegram will make HTTP Post. Leave empty to
  //  * delete webHook.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @param  {String|stream.Stream} [options.certificate] PEM certificate key (public).
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#setwebhook
  //  */
  setWebHook(url, {options}) {
    /* The older method signature was setWebHook(url, cert).
      * We need to ensure backwards-compatibility while maintaining
      * consistency of the method signatures throughout the library */
    if(options == null) options = {};
    var cert = options.certificate;

    Map opts = {
      'qs': options
    };
    opts['qs']['url'] = url;

    if (cert != null) {
      try {
        var sendData = this._formatSendData('certificate', cert);
        opts['formData'] = sendData[0];
        opts['qs']['certificate'] = sendData[1];
      }
      catch (ex) {
        print('FIX: find a replacement for Promise object');
        // return Promise.reject(ex);
      }
    }

    return this._request('setWebHook', options: opts);
  }
  //
  // /**
  //  * Use this method to remove webhook integration if you decide to
  //  * switch back to getUpdates. Returns True on success.
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#deletewebhook
  //  */
  deleteWebHook() {
    return this._request('deleteWebhook');
  }

  unsetWebHook() {
    return this._request('setWebHook');
  }
  //
  // /**
  //  * Use this method to get current webhook status.
  //  * On success, returns a [WebhookInfo](https://core.telegram.org/bots/api#webhookinfo) object.
  //  * If the bot is using getUpdates, will return an object with the
  //  * url field empty.
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getwebhookinfo
  //  */
  getWebHookInfo() {
    return this._request('getWebhookInfo');
  }
  //
  // /**
  //  * Use this method to receive incoming updates using long polling.
  //  * This method has an [older, compatible signature][getUpdates-v0.25.0]
  //  * that is being deprecated.
  //  *
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getupdates
  //  */
  getUpdates(options) async {
    return this._request('getUpdates', options: options);
  }
  //
  // /**
  //  * Process an update; emitting the proper events and executing regexp
  //  * callbacks. This method is useful should you be using a different
  //  * way to fetch updates, other than those provided by TelegramBot.
  //  * @param  {Object} update
  //  * @see https://core.telegram.org/bots/api#update
  //  */
  processUpdate(update) {
    var message = update['message'];
    var editedMessage = update['edited_message'];
    var channelPost = update['channel_post'];
    var editedChannelPost = update['edited_channel_post'];
    var inlineQuery = update['inline_query'];
    var chosenInlineResult = update['chosen_inline_result'];
    var callbackQuery = update['callback_query'];

    if (message != null) {
      this.emit('message', message);
      var processMessageType = (messageType) {
        if (message[messageType] != null) {
          this.emit(messageType, message);
        }
      };
      messageTypes().forEach(processMessageType);
      if (message['text'] != null) {
        this._textRegexpCallbacks.forEach((reg) {
          // var result = reg.regexp.exec(message['text']);
          var result = reg['regexp'].allMatches(message['text']);
          if (result.length == 0) {
            return false;
          }
          reg['callback'](message, result);
          // returning truthy value exits .some
          // return this.options.onlyFirstMatch;
          return this.options['onlyFirstMatch'];
        });
      }
      if (message['reply_to_message'] != null) {
        // Only callbacks waiting for this message
        this._replyListeners.forEach((reply) {
          // Message from the same chat
          if (reply['chatId'] == message['chat']['id']) {
            // Responding to that message
            if (reply['messageId'] == message['reply_to_message']['message_id']) {
              // Resolve the promise
              reply['callback'](message);
            }
          }
        });
      }
    }
    else if (editedMessage != null) {
      this.emit('edited_message', editedMessage);
      if (editedMessage['text'] != null) {
        this.emit('edited_message_text', editedMessage);
      }
      if (editedMessage['caption'] != null) {
        this.emit('edited_message_caption', editedMessage);
      }
    }
    else if (channelPost != null) {
      this.emit('channel_post', channelPost);
    }
    else if (editedChannelPost != null) {
      this.emit('edited_channel_post', editedChannelPost);
      if (editedChannelPost['text']) {
        this.emit('edited_channel_post_text', editedChannelPost);
      }
      if (editedChannelPost.caption) {
        this.emit('edited_channel_post_caption', editedChannelPost);
      }
    }
    else if (inlineQuery != null) {
      this.emit('inline_query', inlineQuery);
    }
    else if (chosenInlineResult != null) {
      this.emit('chosen_inline_result', chosenInlineResult);
    }
    else if (callbackQuery != null) {
      this.emit('callback_query', callbackQuery);
    }
  }
  //
  // /**
  //  * Send text message.
  //  * @param  {Number|String} chatId Unique identifier for the message recipient
  //  * @param  {String} text Text of the message to be sent
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendmessage
  //  */
  sendMessage(chatId, text, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['text'] = text;
    return this._request('sendMessage', options: options);
  }
  //
  // /**
  //  * Send answers to an inline query.
  //  * @param  {String} inlineQueryId Unique identifier of the query
  //  * @param  {InlineQueryResult[]} results An array of results for the inline query
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#answerinlinequery
  //  */
  answerInlineQuery(inlineQueryId, results, {options}) {
    if(options == null) options = {};
    options['inline_query_id'] = inlineQueryId;
    print('FIX: find a replacement for stringify() method');
    // options['results'] = JSON.stringify(results);
    return this._request('answerInlineQuery', options: options);
  }
  //
  // /**
  //  * Forward messages of any kind.
  //  * @param  {Number|String} chatId     Unique identifier for the message recipient
  //  * @param  {Number|String} fromChatId Unique identifier for the chat where the
  //  * original message was sent
  //  * @param  {Number|String} messageId  Unique message identifier
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  */
  forwardMessage(chatId, fromChatId, messageId, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['from_chat_id'] = fromChatId;
    options['message_id'] = messageId;
    return this._request('forwardMessage', options: options);
  }
  //
  // /**
  //  * Send photo
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} photo A file path or a Stream. Can
  //  * also be a "file_id" previously uploaded
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendphoto
  //  */
  sendPhoto(chatId, photo, {options}) {
    if(options == null) options = {};
    // A file can be sent as an URL, so it can be downloaded and handled by the API
    if(photo is Uri){
      options["chat_id"] = chatId;
      options["photo"] = photo.toString();
      return this._request("sendPhoto", options: options);
    }
    // A file can also be sent as a byte array
    else if(photo is List) {
      throw new Exception("Needs to be implemented");
    }
  }
  //
  // /**
  //  * Send audio
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} audio A file path, Stream or Buffer.
  //  * Can also be a "file_id" previously uploaded.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendaudio
  //  */
  sendAudio(chatId, audio, [options]) {
    if(options == null) options = {};
    // A file can be sent as an URL, so it can be downloaded and handled by the API
    if(audio is Uri){
      options["chat_id"] = chatId;
      options["audio"] = audio.toString();
      return this._request("sendAudio", options: options);
    }
    // A file can also be sent as a byte array
    else if(audio is List) {
      throw new Exception("Needs to be implemented");
    }
  }
  //
  // /**
  //  * Send Document
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} doc A file path, Stream or Buffer.
  //  * Can also be a "file_id" previously uploaded.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @param  {Object} [fileOpts] Optional file related meta-data
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendDocument
  //  */
  sendDocument(chatId, document, [options, fileOpts, replyToMessageId, dynamic replyMarkup]) {
    if(options == null) options = {};
    // A file can be sent as an URL, so it can be downloaded and handled by the API
    if(document is Uri){
      options["chat_id"] = chatId;
      options["document"] = document.toString();
      return this._request("sendDocument", options: options);
    }
    // A file can also be sent as a byte array
    else if(document is List) {
      throw new Exception("Needs to be implemented");
    }
  }
  //
  // /**
  //  * Send .webp stickers.
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} sticker A file path, Stream or Buffer.
  //  * Can also be a "file_id" previously uploaded. Stickers are WebP format files.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendsticker
  //  */
  sendSticker(chatId, sticker, {options}) {
    throw new Exception("Needs to be implemented");
  }
  //
  // /**
  //  * Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as Document).
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} video A file path or Stream.
  //  * Can also be a "file_id" previously uploaded.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendvideo
  //  */
  sendVideo(chatId, video, {options}) {
    throw new Exception("Needs to be implemented");
  }
  //
  // /**
  //  * Send voice
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String|stream.Stream|Buffer} voice A file path, Stream or Buffer.
  //  * Can also be a "file_id" previously uploaded.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendvoice
  //  */
  sendVoice(chatId, voice, {options}) {
    throw new Exception("Needs to be implemented");
  }
  //
  //
  // /**
  //  * Send chat action.
  //  * "typing" for text messages,
  //  * "upload_photo" for photos, "record_video" or "upload_video" for videos,
  //  * "record_audio" or "upload_audio" for audio files, "upload_document" for general files,
  //  * "find_location" for location data.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String} action Type of action to broadcast.
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendchataction
  //  */
  sendChatAction(chatId, action) {
    Map options = {
      'action': action,
      'chat_id': chatId
    };
    return this._request('sendChatAction', options: options);
  }
  //
  // /**
  //  * Use this method to kick a user from a group or a supergroup.
  //  * In the case of supergroups, the user will not be able to return
  //  * to the group on their own using invite links, etc., unless unbanned
  //  * first. The bot must be an administrator in the group for this to work.
  //  * Returns True on success.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the target group or username of the target supergroup
  //  * @param  {String} userId  Unique identifier of the target user
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#kickchatmember
  //  */
  kickChatMember(chatId, userId) {
    Map options = {
      'chat_id': chatId,
      'user_id': userId
    };
    return this._request('kickChatMember', options: options);
  }
  //
  // /**
  //  * Use this method to unban a previously kicked user in a supergroup.
  //  * The user will not return to the group automatically, but will be
  //  * able to join via link, etc. The bot must be an administrator in
  //  * the group for this to work. Returns True on success.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the target group or username of the target supergroup
  //  * @param  {String} userId  Unique identifier of the target user
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#unbanchatmember
  //  */
  unbanChatMember(chatId, userId) {
    Map options = {
      'chat_id': chatId,
      'user_id': userId
    };
    return this._request('unbanChatMember', options: options);
  }
  //
  // /**
  //  * Use this method to send answers to callback queries sent from
  //  * inline keyboards. The answer will be displayed to the user as
  //  * a notification at the top of the chat screen or as an alert.
  //  * On success, True is returned.
  //  *
  //  * @param  {Number|String} callbackQueryId  Unique identifier for the query to be answered
  //  * @param  {String} text  Text of the notification. If not specified, nothing will be shown to the user
  //  * @param  {Boolean} showAlert  Whether to show an alert or a notification at the top of the screen
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#answercallbackquery
  //  */
  answerCallbackQuery(callbackQueryId, text, showAlert, {options}) {
    if(options == null) options = {};
    options['callback_query_id'] = callbackQueryId;
    options['text'] = text;
    options['show_alert'] = showAlert;
    return this._request('answerCallbackQuery', options: options);
  }
  //
  // /**
  //  * Use this method to edit text messages sent by the bot or via
  //  * the bot (for inline bots). On success, the edited Message is
  //  * returned.
  //  *
  //  * Note that you must provide one of chat_id, message_id, or
  //  * inline_message_id in your request.
  //  *
  //  * @param  {String} text  New text of the message
  //  * @param  {Object} [options] Additional Telegram query options (provide either one of chat_id, message_id, or inline_message_id here)
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#editmessagetext
  //  */
  editMessageText(text, {options}) {
    if(options == null) options = {};
    options['text'] = text;
    return this._request('editMessageText', options: options);
  }
  //
  // /**
  //  * Use this method to edit captions of messages sent by the
  //  * bot or via the bot (for inline bots). On success, the
  //  * edited Message is returned.
  //  *
  //  * Note that you must provide one of chat_id, message_id, or
  //  * inline_message_id in your request.
  //  *
  //  * @param  {String} caption  New caption of the message
  //  * @param  {Object} [options] Additional Telegram query options (provide either one of chat_id, message_id, or inline_message_id here)
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#editmessagecaption
  //  */
  editMessageCaption(caption, {options}) {
    if(options == null) options = {};
    options['caption'] = caption;
    return this._request('editMessageCaption', options: options);
  }
  //
  // /**
  //  * Use this method to edit only the reply markup of messages
  //  * sent by the bot or via the bot (for inline bots).
  //  * On success, the edited Message is returned.
  //  *
  //  * Note that you must provide one of chat_id, message_id, or
  //  * inline_message_id in your request.
  //  *
  //  * @param  {Object} replyMarkup  A JSON-serialized object for an inline keyboard.
  //  * @param  {Object} [options] Additional Telegram query options (provide either one of chat_id, message_id, or inline_message_id here)
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#editmessagetext
  //  */
  editMessageReplyMarkup(replyMarkup, {options}) {
    if(options == null) options = {};
    options['reply_markup'] = replyMarkup;
    return this._request('editMessageReplyMarkup', options: options);
  }
  //
  // /**
  //  * Use this method to get a list of profile pictures for a user.
  //  * Returns a [UserProfilePhotos](https://core.telegram.org/bots/api#userprofilephotos) object.
  //  * This method has an [older, compatible signature][getUserProfilePhotos-v0.25.0]
  //  * that is being deprecated.
  //  *
  //  * @param  {Number|String} userId  Unique identifier of the target user
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getuserprofilephotos
  //  */
  getUserProfilePhotos(userId, {options}) {
    if(options == null) options = {};
    options['user_id'] = userId.toString();
    return this._request('getUserProfilePhotos', options: options);
  }
  //
  // /**
  //  * Send location.
  //  * Use this method to send point on the map.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {Float} latitude Latitude of location
  //  * @param  {Float} longitude Longitude of location
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendlocation
  //  */
  sendLocation(chatId, latitude, longitude, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['latitude'] = latitude.toString();
    options['longitude'] = longitude.toString();
    return this._request('sendLocation', options: options);
  }
  //
  // /**
  //  * Send venue.
  //  * Use this method to send information about a venue.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {Float} latitude Latitude of location
  //  * @param  {Float} longitude Longitude of location
  //  * @param  {String} title Name of the venue
  //  * @param  {String} address Address of the venue
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendvenue
  //  */
  sendVenue(chatId, latitude, longitude, title, address, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['latitude'] = latitude.toString();
    options['longitude'] = longitude.toString();
    options['title'] = title;
    options['address'] = address;
    return this._request('sendVenue', options: options);
  }
  //
  // /**
  //  * Send contact.
  //  * Use this method to send phone contacts.
  //  *
  //  * @param  {Number|String} chatId  Unique identifier for the message recipient
  //  * @param  {String} phoneNumber Contact's phone number
  //  * @param  {String} firstName Contact's first name
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendcontact
  //  */
  sendContact(chatId, phoneNumber, firstName, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['phone_number'] = phoneNumber.toString();
    options['first_name'] = firstName;
    return this._request('sendContact', options: options);
  }
  //
  //
  // /**
  //  * Get file.
  //  * Use this method to get basic info about a file and prepare it for downloading.
  //  * Attention: link will be valid for 1 hour.
  //  *
  //  * @param  {String} fileId  File identifier to get info about
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getfile
  //  */
  getFile(fileId) {
    Map options = { 'file_id': fileId };
    return this._request('getFile', options: options);
  }
  //
  // /**
  //  * Get link for file.
  //  * Use this method to get link for file for subsequent use.
  //  * Attention: link will be valid for 1 hour.
  //  *
  //  * This method is a sugar extension of the (getFile)[#getfilefileid] method,
  //  * which returns just path to file on remote server (you will have to manually build full uri after that).
  //  *
  //  * @param  {String} fileId  File identifier to get info about
  //  * @return {Promise} promise Promise which will have *fileURI* in resolve callback
  //  * @see https://core.telegram.org/bots/api#getfile
  //  */
  getFileLink(fileId) {
    return this.getFile(fileId)
      .then((resp) => "${this.options['baseApiUrl']}/file/bot${this.token}/${resp['file_path']}");
  }
  //
  // /**
  //  * Downloads file in the specified folder.
  //  * This is just a sugar for (getFile)[#getfilefiled] method
  //  *
  //  * @param  {String} fileId  File identifier to get info about
  //  * @param  {String} downloadDir Absolute path to the folder in which file will be saved
  //  * @return {Promise} promise Promise, which will have *filePath* of downloaded file in resolve callback
  //  */
  downloadFile(fileId, downloadDir) {
    return this
      .getFileLink(fileId)
      .then((fileURI) {
        String fileName = fileURI.slice(fileURI.lastIndexOf('/') + 1);
        // TODO: Ensure fileName doesn't contains slashes
        String filePath = "${downloadDir}/${fileName}";

        // FIX
        // // properly handles errors and closes all streams
        // return Promise
        //   .fromCallback((next) {
        //     pump(streamedRequest({ uri: fileURI }), fs.createWriteStream(filePath), next);
        //   }).return(filePath);
      });
  }
  //
  // /**
  //  * Register a RegExp to test against an incomming text message.
  //  * @param  {RegExp}   regexp       RegExp to be executed with "exec".
  //  * @param  {Function} callback     Callback will be called with 2 parameters,
  //  * the "msg" and the result of executing "regexp.exec" on message text.
  //  */
  onText(regexp, callback) {
    this._textRegexpCallbacks.add({ 'regexp': regexp, 'callback': callback });
  }
  //
  // /**
  //  * Register a reply to wait for a message response.
  //  * @param  {Number|String}   chatId       The chat id where the message cames from.
  //  * @param  {Number|String}   messageId    The message id to be replied.
  //  * @param  {Function} callback     Callback will be called with the reply
  //  *  message.
  //  * @return {Number} id                    The ID of the inserted reply listener.
  //  */
  onReplyToMessage(chatId, messageId, callback) {
    var id = ++this._replyListenerId;
    this._replyListeners.add({
      'id': id,
      'chatId': chatId,
      'messageId': messageId,
      'callback': callback
    });
    return id;
  }
  //
  // /**
  //  * Removes a reply that has been prev. registered for a message response.
  //  * @param   {Number} replyListenerId      The ID of the reply listener.
  //  * @return  {Object} deletedListener      The removed reply listener if
  //  *   found. This object has "id", "chatId", "messageId" and "callback"
  //  *   properties. If not found, returns "null".
  //  */
  removeReplyListener(replyListenerId) {
    print('FIX: find a replacement for findIndex() method');
    // var index = this._replyListeners.findIndex((replyListener) {
    //   return replyListener['id'] == replyListenerId;
    // });
    // if (!index) {
    //   return null;
    // }
    print('FIX: find a replacement for splice() method');
    // return this._replyListeners.splice(index, 1)[0];
  }
  //
  // /**
  //  * Use this method to get up to date information about the chat
  //  * (current name of the user for one-on-one conversations, current
  //  * username of a user, group or channel, etc.).
  //  * @param  {Number|String} chatId Unique identifier for the target chat or username of the target supergroup or channel
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getchat
  //  */
  getChat(chatId) {
    Map options = {
      'chat_id': chatId
    };
    return this._request('getChat', options: options);
  }
  //
  // /**
  //  * Returns the administrators in a chat in form of an Array of "ChatMember" objects.
  //  * @param  {Number|String} chatId  Unique identifier for the target group or username of the target supergroup
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getchatadministrators
  //  */
  getChatAdministrators(chatId) {
    Map options = {
      'chat_id': chatId
    };
    return this._request('getChatAdministrators', options: options);
  }
  //
  // /**
  //  * Use this method to get the number of members in a chat.
  //  * @param  {Number|String} chatId  Unique identifier for the target group or username of the target supergroup
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getchatmemberscount
  //  */
  getChatMembersCount(chatId) {
    Map options = {
      'chat_id': chatId
    };
    return this._request('getChatMembersCount', options: options);
  }
  //
  // /**
  //  * Use this method to get information about a member of a chat.
  //  * @param  {Number|String} chatId  Unique identifier for the target group or username of the target supergroup
  //  * @param  {String} userId  Unique identifier of the target user
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getchatmember
  //  */
  getChatMember(chatId, userId) {
    Map options = {
      'chat_id': chatId,
      'user_id': userId
    };
    return this._request('getChatMember', options: options);
  }
  //
  // /**
  //  * Leave a group, supergroup or channel.
  //  * @param  {Number|String} chatId Unique identifier for the target group or username of the target supergroup (in the format @supergroupusername)
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#leavechat
  //  */
  leaveChat(chatId) {
    Map options = {
      'chat_id': chatId
    };
    return this._request('leaveChat', options: options);
  }
  //
  // /**
  //  * Use this method to send a game.
  //  * @param  {Number|String} chatId Unique identifier for the message recipient
  //  * @param  {String} gameShortName name of the game to be sent.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#sendgame
  //  */
  sendGame(chatId, gameShortName, {options}) {
    if(options == null) options = {};
    options['chat_id'] = chatId;
    options['game_short_name'] = gameShortName;
    return this._request('sendGame', options: options);
  }
  //
  // /**
  //  * Use this method to set the score of the specified user in a game.
  //  * @param  {String} userId  Unique identifier of the target user
  //  * @param  {Number} score New score value.
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#setgamescore
  //  */
  setGameScore(userId, score, {options}) {
    if(options == null) options = {};
    options['user_id'] = userId;
    options['score'] = score;
    return this._request('setGameScore', options: options);
  }
  //
  // /**
  //  * Use this method to get data for high score table.
  //  * @param  {String} userId  Unique identifier of the target user
  //  * @param  {Object} [options] Additional Telegram query options
  //  * @return {Promise}
  //  * @see https://core.telegram.org/bots/api#getgamehighscores
  //  */
  getGameHighScores(userId, {options}) {
    if(options == null) options = {};
    options['user_id'] = userId;
    return this._request('getGameHighScores', options: options);
  }
  
  void _forceType(object, List<Type> types) {
    if (!types.any((Type T) => object.runtimeType == T)) {
      throw new TypeError();
    }
  }
}
