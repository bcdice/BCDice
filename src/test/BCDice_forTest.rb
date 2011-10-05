$LOAD_PATH << File.dirname(__FILE__) + "/.."
require 'bcdiceCore'

class BCDiceMaker_forTest < BCDiceMaker
  
  def newBcDice
    bcdice = BCDice_forTest.new(self, @cardTrader, @diceBot, @counterInfos)
    
    return bcdice
  end
  
end


class BCDice_forTest < BCDice
  
  def initialize(parent, diceBot, cardTrader, counterInfos)
    super
    init
  end
  
  attr_accessor :cardTrader
  
  def init
    @buffer = ""
    @rands = []
  end
  
  def sendMessage(to, message)
    writeResult("sendMessage", message, to)
  end
  
  def sendMessageToOnlySender(message)
    writeResult("sendMessageToOnlySender", message)
  end
  
  def sendMessageToChannels(message)
    writeResult("sendMessageToChannels", message)
  end
  
  
  def writeResult(method, message, to = nil)
    @buffer << "#{method}\nto:#{to}\n#{message}\n"
  end
  
  
  def getResult()
    result = @buffer
    debug("== getResult result ==============>", "\n", result, "\n<=================================")
    @buffer = ""
    
    return result
  end
  
  def rand(max)
    debug('rand called @rands', @rands)
    
    if( @rands.nil? )
      #debug('randNomal(max)')
      return randNomal(max)
    end
    
    #debug('randFromRands(max)')
    return randFromRands(max)
  end
  
  def randNomal(max)
    Kernel.rand(max)
  end
  
  def randFromRands(targetMax)
    nextRand = @rands.shift
    
    if( nextRand.nil? )
      #return randNomal(targetMax)
      raise "nextRand is nil, so @rands is empty!! @rands:#{@rands.inspect}"
    end
    
    value, max = nextRand
    
    if( max != targetMax )
      #return randNomal(targetMax)
      raise "invalid max value! max, targetMax: #{value}, #{max}, #{targetMax}"
    end
    
    return (value - 1)
  end
  
  
  def setRandomValues(rands)
    @rands = rands
  end
  
end


