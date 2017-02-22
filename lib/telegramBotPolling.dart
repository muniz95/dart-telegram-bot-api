import 'dart:async';
import 'dart:core';
import 'dart:io';

final int ANOTHER_WEB_HOOK_USED = 409;

class TelegramBotPolling {
  TelegramBot bot;
  int interval;
  int offset;
  int timeout;
  int limit;
  DateTime _lastUpdate;
  dynamic _lastRequest;
  Boolean _abort;
  Future _pollingTimeout; // TO DO: find a way to handle this Future
  
  TelegramBotPolling({this.bot, this.interval, this.offset, this.timeout}){
    this._lastUpdate = 0;
    this._lastRequest = null;
    this._abort = false;
    this._pollingTimeout = null;
  }
  
  Future start({Map options}) async {
    print('It needs to be implemented: started');
    if (this._lastRequest) {
      if (!options['restart']) {
        return Promise.resolve();
      }
      return this.stop({
        cancel: true,
        reason: 'Polling restart',
      }).then((_) {
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
  Future stop({options}) {
    if(options == null) options = new Map();
    if (!this._lastRequest) {
      return Promise.resolve();
    }
    var lastRequest = this._lastRequest;
    this._lastRequest = null;
    clearTimeout(this._pollingTimeout);
    if (options['cancel']) {
      const reason = options['reason'] || 'Polling stop';
      lastRequest.cancel(reason);
      return Promise.resolve();
    }
    this._abort = true;
    return lastRequest.whenComplete(() => {
      this._abort = false;
    });
  }

  /**
   * Return `true` if is polling. Otherwise, `false`.
   */
  isPolling() {
    return !!this._lastRequest;
  }

  /**
   * Invokes polling (with recursion!)
   * @return {Promise} promise of the current request
   * @private
   */
  _polling() {
    this._lastRequest = this._getUpdates()
      .then((updates) {
        if(updates != null){
          // print('polling data ${updates}');
          this._lastUpdate = new DateTime.now();
          updates.forEach((update) {
            this.offset = update['update_id'] + 1;
            // print('updated offset: ${this.offset}');
            this.bot.processUpdate(update);
          });
        }
        return null;
      })
      .catchError((err) {
        print(err);
        // print("polling error: ${err['message']}");
        // if (this.bot.listeners('polling_error').length) {
        //   this.bot.emit('polling_error', err);
        // } else {
        //   console.error(err);
        // }
        return null;
      })
      .whenComplete(() {
        if (this._abort) {
          print('Polling is aborted!');
        } else {
          // print('setTimeout for ${this.interval} miliseconds');
          // this._pollingTimeout = setTimeout(() => this._polling(), this.interval);
          this._pollingTimeout = new Future.delayed(const Duration(milliseconds: 3000), () => this._polling());
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
    return this.bot._request('setWebHook');
  }

  /**
   * Retrieve updates
   */
  _getUpdates() {
    return this.bot.getUpdates(timeout: this.timeout, limit: this.limit, offset: this.offset)
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