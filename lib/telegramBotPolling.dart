class TelegramBotPolling {
  TelegramBot bot;
  
  TelegramBotPolling({TelegramBot bot}){
    this.bot = bot;
  }
  
  void start(TelegramBot bot){
    print('started');
  }
}