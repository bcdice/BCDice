#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/.."
$LOAD_PATH << File.dirname(__FILE__) + "/../irc"

require 'bcdiceCore.rb'
require 'diceBot/DiceBotLoader'

class TestDiceBot
  
  def initialize
    $isDebug = false
  end
  
  
  def test(arg)
    @testParms = arg
    
    DiceBotLoader.setBcDicePath( FileTest.directory?('../../src_bcdice') ? '../../src_bcdice' : '../../src' )
    
    resultFile = './testData.txt'
    
    buffer = File.read(resultFile).toutf8.gsub(/[\r\n]+/, "\n")
    testDataList = getTestDataList(buffer)
    
#    @testResultFile = open('testResult.txt', 'w+')
    
    targetGameType, targetNumber = getTargetGameTypeAndNumber
    require 'cgiDiceBot'
    @bot = CgiDiceBot.new
    
    errorLog = ""
    testDataList.each do |index, input, good, rands, randsText|
      @testIndex = index
      @input = input
      @good = good.toutf8
      @rands = rands
      @randsText = randsText
      errorLog << executeTest(targetGameType, targetNumber)
    end
    
    if( errorLog.empty? )
      print "\nOK.\n"
    else
      print(errorLog)
    end
    
#    @testResultFile.close
    
  end

  def getMessageAndGameTape
    messages  = @input.split(/\t/)
    gameType = messages.pop
    
    return messages, gameType
  end
  
  def executeCommand()
    messages, gameType = getMessageAndGameTape
    
    @bot.setRandomValues(@rands)
    @bot.setTest()
    
    result = ""
    
    tableDir = '../../extratables'
    messages.each do |message|
      begin
        resultOne, randResults = @bot.roll(message, gameType, tableDir)
        result << resultOne
      end
    end
    
    unless( @rands.empty? )
      result << "\n\tダイス残り：#{@rands.collect do |i| i.join('/') end.join(',')}"
    end
    
    return result
  end
  
  def executeTest(targetGameType, targetNumber)
    message, currentGameType = getMessageAndGameTape
    
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
    
    return RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/ ? log.tosjis : log
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
    rands = randsText.scan(/(\d+)\/(\d+)/)
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

