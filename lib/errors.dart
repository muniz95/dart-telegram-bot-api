class BaseError extends Error {
  dynamic code;
  dynamic response;
  dynamic stack;
  
  BaseError(this.code, message) : super(){
    print('${code}: ${message}');
  }
}

class FatalError extends BaseError {
  /**
   * Fatal Error. Error code is `"EFATAL"`.
   * @class FatalError
   * @constructor
   * @param  {String|Error} data Error object or message
   */
  FatalError(message) : super('EFATAL', message);
}

class ParseError extends BaseError {
  dynamic response;
  /**
   * Error during parsing. Error code is `"EPARSE"`.
   * @class ParseError
   * @constructor
   * @param  {String} message Error message
   * @param  {http.IncomingMessage} response Server response
   */
  ParseError(message, this.response) : super('EPARSE', message);
}


class TelegramError extends BaseError {
  dynamic response;
  /**
   * Error returned from Telegram. Error code is `"ETELEGRAM"`.
   * @class TelegramError
   * @constructor
   * @param  {String} message Error message
   * @param  {http.IncomingMessage} response Server response
   */
  TelegramError(message, this.response) : super('ETELEGRAM', message);
}