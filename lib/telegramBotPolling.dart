import 'dart:async';
import 'dart:core';
// import 'dart:io';
import './telegram.dart';

final int ANOTHER_WEB_HOOK_USED = 409;

class TelegramBotPolling {
  TelegramBot bot;
  Map options;
  int limit;
  DateTime _lastUpdate;
  dynamic _lastRequest;
  bool _abort;
  Timer _pollingTimeout; // TO DO: find a way to handle this Future

  TelegramBotPolling(this.bot){

    this.options = (bot.options['polling'] is bool) ? {} : bot.options['polling'];
    this.options['interval'] = (this.options['interval'] is int) ? this.options['interval'] : 300;
    this.options['params'] = (this.options['params'] is Map) ? this.options['params'] : {};
    this.options['params']['offset'] = (this.options['params']['offset'] is int) ? this.options['params']['offset'] : 0;
    this.options['params']['timeout'] = (this.options['params']['timeout'] is int) ? this.options['params']['timeout'] : 10;

    this._lastUpdate = null;
    this._lastRequest = null;
    this._abort = false;
    this._pollingTimeout = null;
  }

  Future start({Map options}) async {
    if (this._lastRequest != null) {
      if (!options['restart']) {
        print('FIX: find a replacement for Promise object');
        // return Promise.resolve();
      }
      return this.stop(options: {
        'cancel': true,
        'reason': 'Polling restart',
      })
      .then((_) {
        return this._polling();
      });
    }
    return this._polling();
  }

  /**
   * Stop polling
   * @param  {Object} [options]
   * @param  {Boolean} [options['cancel']] Cancel current request
   * @param  {String} [options['reason']] Reason for stopping polling
   * @return {Promise}
   */
  Future stop({options}) async {
    if(options == null) options = new Map();
    if (this._lastRequest != null) {
      print('FIX: find a replacement for Promise object');
      // return Promise.resolve();
      return new Future(() => print('No last request'));
    }
    var lastRequest = this._lastRequest;
    this._lastRequest = null;
    // clearTimeout(this._pollingTimeout);
    this._pollingTimeout.cancel();
    if (options['cancel'] != null) {
      var reason = options['reason'] != null ? options['reason'] : 'Polling stop';
      lastRequest.cancel(reason);
      print('FIX: find a replacement for Promise object');
      // return Promise.resolve();
      return new Future(() => print('Cancelled'));
    }
    this._abort = true;
    return lastRequest.whenComplete(() {
      this._abort = false;
    });
  }

  /**
   * Return `true` if is polling. Otherwise, `false`.
   */
  isPolling() {
    return this._lastRequest != null;
  }

  /**
   * Invokes polling (with recursion!)
   * @return {Promise} promise of the current request
   * @private
   */
  _polling() {
    this._lastRequest = this._getUpdates()
      .then((updates) {
        // print('polling data ${updates}');
        this._lastUpdate = new DateTime.now();
        updates.forEach((update) {
          this.options['params']['offset'] = update['update_id'] + 1;
          // print('updated offset: ${this.offset}');
          this.bot.processUpdate(update);
        });
        return null;
      })
      .catchError((err) {
        print("polling error: ${err}");
        return null;
      })
      .whenComplete(() {
        if (this._abort) {
          print('Polling is aborted!');
        } else {
          // print('setTimeout for ${this.interval} miliseconds');
          // this._pollingTimeout = setTimeout(() => this._polling(), this.interval);
          this._pollingTimeout = new Timer(const Duration(milliseconds: 3000), () => this._polling());
          // this._pollingTimeout = new Timer(const Duration(milliseconds: 3000), () => print('executando de novo'));
        }
      });
    return this._lastRequest;
  }

  /**
   * Unset current webhook. Used when we detect that a webhook has been set
   * and we are trying to poll. Polling and WebHook are mutually exclusive.
   * @see https://core.telegram.org/bots/api#getting-updates
   * @private
   */
  _unsetWebHook() {
    print('unsetting webhook');
    return this.bot.unsetWebHook();
  }

  /**
   * Retrieve updates
   */
  _getUpdates() {
    return this.bot.getUpdates(this.options['params'])
      .catchError((err) {
        // print("Erro no _getUpdates() => ${err}");
        // exit(0);
        if (err.response && err.response.statusCode == ANOTHER_WEB_HOOK_USED) {
          return this._unsetWebHook().then(() {
            return this.bot.getUpdates(this.options['params']);
          });
        }
        throw err;
      });
  }
}
