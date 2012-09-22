#--*-coding:utf-8-*--

class TestDummy < DiceBot
  
  def initialize
    super
  end
  def gameName
    'テストボット'
  end
  
  def gameType
    "TestDummy"
  end
  
  def prefixs
     []
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
テストボット！！
INFO_MESSAGE_TEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, nick_e)
    return ': テストですよ。', false
  end
  
end
