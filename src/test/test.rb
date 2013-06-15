#!/perl/bin/ruby -Ku 
#--*-coding:utf-8-*--
$KCODE = 'UTF8'

$LOAD_PATH << File.dirname(__FILE__) + "/.."
$LOAD_PATH << File.dirname(__FILE__) + "/../irc"

require 'Kconv'
require 'bcdiceCore.rb'
require 'diceBot/DiceBotLoader'

class TestDiceBot
  
  def initialize
    $isDebug = false
  end
  
  
  def test(arg)
    @testParms = arg
    
    DiceBotLoader.setBcDicePath( '../../src_bcdice' )
    
    resultFile = './testData.txt'
    
    buffer = File.readlines(resultFile).join.toutf8
    testDataList = getTestDataList(buffer)
    
#    @testResultFile = open('testResult.txt', 'w+')
    
    errorLog = ""
    testDataList.each do |index, input, good, rands, randsText|
      @testIndex = index
      @input = input
      @good = good.toutf8
      @rands = rands
      @randsText = randsText
      errorLog << executeTest()
    end
    
    if( errorLog.empty? )
      print "\nOK.\n"
    else
      print(errorLog)
    end
    
#    @testResultFile.close
    
  end

  def getMessageAndGameTape
    message, gameType, *dummy = @input.split(/\t/)
    return message, gameType
  end
  
  def executeCommand()
    message, gameType = getMessageAndGameTape
    
    require 'cgiDiceBot'
    bot = CgiDiceBot.new
    bot.setRandomValues(@rands)
    bot.setTest()
    result, randResults = bot.roll(message, gameType)
    
    unless( @rands.empty? )
      result << "\n\tダイス残り：#{@rands.collect do |i| i.join('/') end.join(',')}"
    end
    
    return result
  end
  
  def executeTest()
    message, currentGameType = getMessageAndGameTape
    targetGameType, targetNumber = getTargetGameTypeAndNumber
    
    
    return "" unless( isTargetGameType(targetGameType, currentGameType) )
    return "" unless( isTargetNumber(targetNumber, @testIndex) )
    
    unless( targetNumber.nil? )
      $isDebug = true
    end
    
    errorLog = ""
    begin
      result = executeCommand()
      return "" if( result == nil )
      
      result = result.toutf8
      return "" if( /お好み焼き/ =~ result )
      return "" if( /英雄で指示して/ =~ result )
      
      if( result != @good )
        errorLog << getLogText(result)
      end
    rescue => exception
      errorLog << getLogText(result, exception)
    end
    
    if( errorLog.empty? )
      print '.'
    else
      print 'x'
    end
    
    return errorLog
  end
  
  def getLogText(result, exception = nil)
    log = "\n===========================\n"
    
    unless( exception.nil? )
      log << "index:#{@testIndex}\nExceptin:#{exception.inspect}\n#{$@.join("\n")}\ninput:#{@input}\ngood  :#{@good}\nrandsText:#{@randsText}\n"
    else
      log << "index:#{@testIndex}\ninput:#{@input}\nresult:#{result}\ngood  :#{@good}\nrandsText:#{@randsText}\n"
    end
    
    return log.tosjis
  end
  
  def getTestDataList(buffer)
    testDataList = buffer.split("============================\n")
    testDataList.shift
    
    result = []
    testDataList.each_with_index do |testData, index|
      unless(/input:(.+)\noutput:(.+)rand:(.*)\n/m =~ testData)
        raise "invalid data \n#{testData}"
      end
      
      input = $1
      good = $2.toutf8.chomp
      randsText = $3
      rands = getRands(randsText)
      
      result << [index, input, good, rands, randsText]
    end
    
    return result
  end

  def getTargetGameTypeAndNumber
    targetGameType = nil
    number = nil
    
    case @testParms
    when /^\d+$/
      number = @testParms.to_i
    when nil, ''
      #pass
    else
      targetGameType = @testParms
    end
    
    return targetGameType, number
  end
  
  def getRands(randsText)
    randsSet = randsText.split(/,/)
    
    rands = randsSet.collect do |pair|
      value, max = pair.split('/')
      [value.to_i, max.to_i]
    end
    
    return rands
  end


  def isTargetGameType(targetGameType, currentGameType)
    return true if( targetGameType.nil? )
    return ( targetGameType == currentGameType )
  end

  def isTargetNumber(targetNumber, currentNumber)
    return true if( targetNumber.nil? )
    return ( targetNumber == currentNumber )
  end

end

if($0 === __FILE__)
  arg = ARGV[0]
  
  tester = TestDiceBot.new
  tester.test(arg)
end

