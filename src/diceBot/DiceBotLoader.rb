
class DiceBotLoader
  
  @@bcDicePath = './src_bcdice'
  
  def self.setBcDicePath(path)
    @@bcDicePath = path
  end
  
  def initialize
  end
  
  def loadUnknownGame(gameTitle)
    debug("loadUnknownGame gameTitle", gameTitle)
    
    gameTitle = gameTitle.gsub(/(\.\.|\/)/, '_')
    
    botFile = "diceBot/#{gameTitle}.rb"
    fileName = "#{@@bcDicePath}/#{botFile}"
    fileName.untaint
    
    debug("botFile", botFile)
    debug("fileName", fileName)
    debug("botFile exist", File.exist?( fileName ))
    debug("pwd", Dir.pwd)
    
    diceBot = nil
    
    return diceBot unless( File.exist?(fileName) )
    
    begin
      require "#{botFile}"
      diceBot = Module.const_get(gameTitle).new
    rescue
    end
    
    return diceBot
  end
  
end
