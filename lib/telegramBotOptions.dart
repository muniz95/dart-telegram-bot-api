class TelegramBotOptions {
  Map polling;
  String webHook;
  String baseApiUrl;
  String filePath;
  bool restart;
  bool onlyFirstMatch;
  
  TelegramBotOptions({this.polling, this.webHook, this.baseApiUrl, this.filePath, this.restart, this.onlyFirstMatch});
}