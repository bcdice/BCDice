#!/usr/local/bin/ruby -Ku
#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/src_bcdice"

require 'bcdiceCore.rb'

$isDebug = false


class CgiDiceBot
  
  def initialize
    @rollResult = ""
    @isSecret = false
    @rands = nil #テスト以外ではnilで良い。ダイス目操作パラメータ
    @isTest = false
  end
  
  def rollByCgi(cgi)
    @cgi = cgi
    rollByCgiLocal
  end
  
  def rollByCgiDummy()
    @cgi = {
      'message' => 'STG20',
      # 'message' => 'S2d6',
      'gameType' => 'TORG',
      'channel' => '1',
      'state' => 'state',
      'sendto' => 'sendto',
      'color' => '999999',
    }
    
    rollByCgiLocal
  end
  
  def rollByCgiLocal
    message = @cgi['message']
    gameType = @cgi['gameType']
    gameType ||= 'diceBot';
    # $rand_seed = @cgi['randomSeed']
    
    result = ""
    
    result << "##>customBot BEGIN<##"
    result << getDiceBotParamText('channel')
    result << getDiceBotParamText('name')
    result << getDiceBotParamText('state')
    result << getDiceBotParamText('sendto')
    result << getDiceBotParamText('color')
    result << message
    result << roll(message, gameType)
    result << "##>customBot END<##"
    
    return result
  end
  
  def getDiceBotParamText(paramName)
    param = @cgi[paramName]
    param ||= ''
    
    "#{param}\t"
  end
  
  
  def roll(message, gameType)
    executeDiceBot(message, gameType)
    
    rollResult = @rollResult
    @rollResult = ""
    
    result = ""
    
    unless( @isTest )
      result << "##>isSecretDice<##" if( @isSecret )
    end
    
    result << "\n#{gameType} #{rollResult}"
    
    return result
  end
  
  def setTest()
    @isTest = true
  end
  
  def setRandomValues(rands)
    @rands = rands
  end
  
  def executeDiceBot(message, gameType)
    bcdiceMarker = BCDiceMaker.new
    bcdice = bcdiceMarker.newBcDice()
    
    bcdice.setIrcClient(self)
    bcdice.setRandomValues(@rands)
    
    bcdice.setGameByTitle( gameType )
    bcdice.setMessage(message)
    
    channel = ""
    nick_e = ""
    bcdice.setChannel(channel)
    bcdice.recievePublicMessage(nick_e)
  end
  
  def sendMessage(to, message)
    @rollResult << message
  end
  
  def sendMessageToOnlySender(nick_e, message)
    debug("customBot sendMessageToOnlySender")
    @isSecret = true
    @rollResult << message
  end
  
  def sendMessageToChannels(message)
    @rollResult << message
  end
  
end


def logForDiceBot(message)
  message = "nil" if( message.nil? )
  
  open("logForDiceBot.txt", "a+") do |file|
    file.write( message + "\n" )
  end
end


def getCgiDiceRollResult
  result = ""
  begin
    require 'cgi'
    bot = CgiDiceBot.new
    cgi = CGI.new
    
    begin
      result << bot.rollByCgi(cgi)
    rescue => e
      result << e.to_s + $@.join("\n")
    end
    
  rescue => e
    result << "exception + " + e.to_s + $@.join("\n")
  end
  
  header = "Content-Type: text/plain; charset=utf-8\n\n"
  
  return header + result
end


if( $0 === __FILE__ )
  result = getCgiDiceRollResult
  print( result )
end
