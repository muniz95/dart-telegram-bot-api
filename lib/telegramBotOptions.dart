class TelegramBotOptions {
  Map polling;
  String webHook;
  String baseApiUrl;
  String filePath;
  Boolean restart;
  
  TelegramBotOptions({Map polling, String webHook, String baseApiUrl, String filePath, Boolean restart}){
    this.polling = polling;
    this.webHook = webHook;
    this.baseApiUrl = baseApiUrl;
    this.filePath = filePath;
    this.restart = restart;
  }
}