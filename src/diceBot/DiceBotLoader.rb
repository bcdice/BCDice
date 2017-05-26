
class DiceBotLoader
  
  @@bcDicePath = FileTest.directory?('./diceBot') ? '.' : (FileTest.directory?('./src_bcdice') ? './src_bcdice' : './src')
  
  def self.setBcDicePath(path)
    @@bcDicePath = path
  end
  
  @@knownGameTypes = []
  
  def self.setKnownGameType(list)
    @@knownGameTypes = list
  end
  
  def initialize
  end
  
  def loadUnknownGame(gameTitle)
    debug("loadUnknownGame gameTitle", gameTitle)
    
    diceBotBaseFileName = gameTitle.gsub(/(\.\.|\/|:|-)/, '_')
    
    botFile = "diceBot/#{diceBotBaseFileName}.rb"
    fileName = "#{@@bcDicePath}/#{botFile}"
    fileName.untaint
    
    debug("botFile", botFile)
    debug("fileName", fileName)
    debug("botFile exist", File.exist?( fileName ))
    debug("pwd", Dir.pwd)
    
    diceBot = nil
    
    isKnownGameType = @@knownGameTypes.include?( gameTitle )
    unless( isKnownGameType )
      return diceBot unless( File.exist?(fileName) )
    end
    
    begin
      require "#{botFile}"
      diceBot = Module.const_get(diceBotBaseFileName).new
    rescue => e
      debug("DiceBot load ERROR!!!", e.to_s)
    end
    
    return diceBot
  end
  
end
