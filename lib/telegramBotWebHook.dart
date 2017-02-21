class TelegramBotWebHook {
  TelegramBot bot;
  
  TelegramBotWebHook({TelegramBot bot}){
    this.bot = bot;
  }
  
  void open(){
    print('opened');
  }
} 