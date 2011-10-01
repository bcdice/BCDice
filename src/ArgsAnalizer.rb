#!ruby -Ku
#--*-coding:utf-8-*--

class ArgsAnalizer
  
  def initialize(args)
    @args = args
    @isStartIrc = true
  end
  
  attr :isStartIrc
  
  def analize
    @args.each do |arg|
      analizeArg(arg)
      analizeArgForTest(arg)
    end
  end
  
  def analizeArg(arg)
    return unless( /^-([scngmeir])(.+)$/i =~ arg )
    
    @command = $1.downcase
    @param = $2
    
    case @command
    when "s"
      setServer
    when "c"
      setChannel
    when "n"
      setNick
    when "g"
      setGame
    when "m"
      setMessageSendType
    when "e"
      readExtraCard
    when "i"
      setIrcServerCharacterCode
    end
  end
  
  
  def setServer
    # サーバ設定(Server:Port)
    data = @param.split(/:/)
    $server = data[0];
    $port = data[1] if( data[1] );
  end
  
  def setChannel
    $defaultLoginChannelsText = decode(CHARCODE, @param)
  end
  
  def setNick
    $nick = @param;
  end
  
  def setGame
    $defaultGameType = @param
  end
  
  def setMessageSendType
    $NOTICE_SW = param.to_i
  end
  
  def readExtraCard
    $extraCardFileName = @param
  end
  
  def setIrcServerCharacterCode
    $ircCode = param;
  end
  
  def analizeArgForTest(arg)
    case arg
    when "exerb"
      @isStartIrc = false
    end
  end
  
end
