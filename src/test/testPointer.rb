#!/perl/bin/ruby -Ku 
#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__) + "/.."
require 'test/unit'
require 'Kconv'
require 'log'
require 'BCDice_forTest'

$isDebug = false


class TestSecretDice < Test::Unit::TestCase
  
  def setup
    $isDebug = false
    $isRollVoidDiceAtAnyRecive = false
    
    @nick = "test_nick"
    @channel = "test_channel"
    
    maker = BCDiceMaker_forTest.new
    @bcdice = maker.newBcDice()
  end
  
  def trace
    $isDebug = true
  end
  
  def execute(text, channel = nil, nick = nil)
    @bcdice.setMessage(text)
    
    channel ||= @channel
    @bcdice.setChannel( channel )
    
    nick ||= @nick
    @bcdice.recievePublicMessage( nick )
  end
  
  def test_setPoinChangePoinAndOpen
    execute("#HP12")
    assert_equal( "sendMessage\nto:test_channel\ntest_nick: (HP) 12\n", @bcdice.getResult() )
    
    execute("#OPEN!HP")
    assert_equal( "sendMessage\nto:test_channel\nHP TEST_NICK(12)\n", @bcdice.getResult() )
    
    execute("#HP9", nil, "nick2")
    assert_equal( "sendMessage\nto:test_channel\nnick2: (HP) 9\n", @bcdice.getResult() )
    
    execute("#OPEN!HP")
    assert_equal( "sendMessage\nto:test_channel\nHP NICK2(9) TEST_NICK(12)\n", @bcdice.getResult() )
    
    execute("#OPEN!HP")
    assert_equal( "sendMessage\nto:test_channel\nHP NICK2(9) TEST_NICK(12)\n", @bcdice.getResult() )
    
    execute("#HP-5")
    assert_equal( "sendMessage\nto:test_channel\ntest_nick: (HP) 12 -> 7\n", @bcdice.getResult() )
    
    execute("#OPEN!HP")
    assert_equal( "sendMessage\nto:test_channel\nHP NICK2(9) TEST_NICK(7)\n", @bcdice.getResult() )
  end
  
  def _test_XXXXXXXX
    execute(text)
    assert_equal( "", @bcdice.getResult())
  end
  
end


