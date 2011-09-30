#!/bin/ruby -Ku 
#--*-coding:utf-8-*--

require 'rubygems'
require 'wx'
require 'wx/classes/timer.rb'

require 'bcdiceCore.rb'

$LOAD_PATH << File.dirname(__FILE__) + "/irc"
require 'ircLib.rb'
require 'ircBot.rb'

$isDebug = false

class BCDiceGuiApp < Wx::App
  private

  def on_init
    BCDiceDialog.new.show_modal
    return false
  end
end

$debugText = nil

def debugPrint(text)
  return if( $debugText.nil? ) 
  $debugText.append_text(text)
end


class BCDiceDialog < Wx::Dialog
  
  def initialize
    super(nil, -1, 'B&C Dice')
    
    @allBox = Wx::BoxSizer.new(Wx::VERTICAL)
    
    @serverName = createAddedTextInput( $server, "サーバ名" )
    @portNo = createAddedTextInput( $port.to_s, "ポート番号" )
    @channel = createAddedTextInput( $defaultLoginChannelsText, "ログインチャンネル" )
    @nickName = createAddedTextInput( $nick, "ニックネーム" )
    initGameType
    @extraCardFileText = createAddedTextInput( $extraCardFileName, "拡張カードファイル名" )
    
    @executeButton = createButton('接続')
    evt_button(@executeButton.get_id) {|event| on_execute }
    
    @stopButton = createButton('切断')
    @stopButton.enable(false)
    evt_button(@stopButton.get_id) {|event| on_stop }
    addCtrlOnLine( @executeButton, @stopButton )
    
    
    addTestTextBoxs
    # initDebugTextBox
    
    set_sizer(@allBox)
    @allBox.set_size_hints(self)
    
    argsAnalizer = ArgsAnalizer.new(ARGV)
    argsAnalizer.analize
    
    @ircBot = nil
    unless( argsAnalizer.isStartIrc )
      @ircBot = getInitializedIrcBot()
      setAllGames(@ircBot)
      destroy
    end
  end
  
  def createButton(labelText)
    Wx::Button.new(self, -1, labelText)
  end
  
  def createTextInput(defaultText)
    Wx::TextCtrl.new(self, -1, defaultText)
  end
  
  def createAddedTextInput(defaultText, labelText, *addCtrls)
    textInput = createTextInput(defaultText)
    addCtrl(textInput, labelText, *addCtrls)
    return textInput
  end
  
  def createLabel(labelText)
    Wx::StaticText.new(self, -1, labelText)
  end
  
  def addCtrl(ctrl, labelText = nil, *addCtrls)
    if( labelText.nil? )
      @allBox.add(ctrl, 0, Wx::ALL, 2)
      return ctrl
    end
    
    ctrls = []
    unless( labelText.nil? )
      label = createLabel(labelText)
      ctrls << label
    end
    
    ctrls << ctrl
    ctrls += addCtrls
    
    line = getLineCtrl( ctrls )
    
    @allBox.add(line, 0, Wx::ALL, 2)
    
    return ctrl
  end
  
  def addCtrlOnLine(*ctrls)
    line = getLineCtrl(ctrls)
    @allBox.add(line, 0, Wx::ALL, 2)
    return line
  end
  
  def getLineCtrl(ctrls)
    line = Wx::BoxSizer.new(Wx::HORIZONTAL)
    
    ctrls.each do |ctrl|
      line.add(ctrl, 0, Wx::ALL, 2)
    end
    
    return line
  end
  
  
  def initGameType
    @gameType = Wx::Choice.new(self, -1)
    addCtrl(@gameType, "ゲームタイトル")
    
    gameTypes = getAllGameTypes.sort
    gameTypes.each_with_index do |type, index|
      @gameType.insert( type, index )
    end
    
    @gameType.insert( "NonTitle", 0 )
    
    index = gameTypes.index($defaultGameType)
    index ||= 0
    @gameType.set_selection(index)
    
    evt_choice(@gameType.get_id) { |event| onChoiseGame }
  end
  
  def getAllGameTypes
    return %w{
Arianrhod
ArsMagica
BarnaKronika
ChaosFlare
Chill
Cthulhu
CthulhuTech
DarkBlaze
DemonParasite
DoubleCross
EarthDawn
Elric!
EmbryoMachine
GehennaAn
GunDog
GunDogZero
Hieizan
HuntersMoon
InfiniteFantasia
MagicaLogia
MeikyuDays
MeikyuKingdom
MonotoneMusium
Nechronica
NightWizard
NightmareHunterDeep
ParasiteBlood
Peekaboo
Pendragon
PhantasmAdventure
RokumonSekai2
RoleMaster
RuneQuest
SataSupe
ShadowRun
ShadowRun4
ShinobiGami
SwordWorld
SwordWorld2.0
TORG
TokumeiTenkousei
Tunnels&Trolls
WARPS
WarHammer
ZettaiReido
}
  end
  
  def onChoiseGame
    return if( @ircBot.nil? )
    @ircBot.setGameByTitle( @gameType.get_string_selection )
  end
  
  def addTestTextBoxs
    label = createLabel('動作テスト欄')
    # @testInput = createTextInput( "3d6          " )
    # @testInput.set_default_style( Wx::TextAttr.new(Wx::TE_PROCESS_ENTER) )
    inputSize = Wx::Size.new(250, 25)
    @testInput = Wx::TextCtrl.new(self, -1, "2d6",
                                  :style => Wx::TE_PROCESS_ENTER,
                                  :size => inputSize)
    
    evt_text_enter(@testInput.get_id) { |event| expressTestInput }
    @testButton = createButton('テスト実施')
    evt_button(@testButton.get_id) {|event| expressTestInput }
    
    addCtrlOnLine( label, @testInput, @testButton )
    
    size = Wx::Size.new(400, 150)
    @testOutput = Wx::TextCtrl.new(self, -1, "", 
                                  :style => Wx::TE_MULTILINE,
                                  :size => size)
    addCtrl(@testOutput)
  end
  
  def expressTestInput
    begin
      onEnterTestInputCatched
    rescue => e
      debug("onEnterTestInput error " + e.to_s)
    end
  end
  
  def onEnterTestInputCatched
    debug("onEnterTestInput")
    
    # @testOutput.set_value("")
    
    bcdiceMarker = BCDiceMaker.new
    bcdice = bcdiceMarker.newBcDice()
    bcdice.setIrcClient(self)
    bcdice.setGameByTitle( @gameType.get_string_selection )
    
    arg = @testInput.get_value
    channel = ""
    nick_e = ""
    tnick = ""
    bcdice.setMessage(arg)
    bcdice.setChannel(channel)
    # bcdice.recieveMessage(nick_e, tnick)
    bcdice.recievePublicMessage(nick_e)
  end
  
  def sendMessage(to, message)
    # @testOutput.set_value( message + "\n" )
    unless( @testOutput.get_value().empty? )
      @testOutput.append_text( "\r\n" )
    end
    @testOutput.append_text( message )
  end
  
  def sendMessageToOnlySender(nick_e, message)
    sendMessage(to, message)
  end
  
  def sendMessageToChannels(message)
    sendMessage(to, message)
  end

  
  def initDebugTextBox
    size = Wx::Size.new(600, 200)
    $debugText = Wx::TextCtrl.new(self, -1, "", 
                                  :style => Wx::TE_MULTILINE,
                                  :size => size)
    addCtrl($debugText)
    $isDebug = true
  end
  
  def on_execute
    begin
      setConfig
      startIrcBot
      @executeButton.enable(false)
      @stopButton.enable(true)
    rescue => e
      Wx::message_box(e.to_s)
    end
  end
  
  def setConfig
    $server = @serverName.get_value
    $port = @portNo.get_value.to_i
    $defaultLoginChannelsText = @channel.get_value
    $nick = @nickName.get_value
    $defaultGameType = @gameType.get_string_selection
    $extraCardFileName = @extraCardFileText.get_value
  end
  
  def startIrcBot
    @ircBot = getInitializedIrcBot()
    
    func = Proc.new{destroy}
    @ircBot.setQuitFuction(func)
    
    startIrcBotOnThread
    startThreadTimer
  end
  
  def startIrcBotOnThread
    ircThread = Thread.new do
      begin
        @ircBot.start
      ensure
        @ircBot = nil
      end
    end
  end
  
  #Rubyスレッドの処理が正常に実行されるように、
  #定期的にGUI処理をSleepし、スレッド処理権限を譲渡する
  def startThreadTimer
    Wx::Timer.every(100) do
      sleep 0.05
    end
  end
  
  def on_stop
    return if( @ircBot.nil? )
    
    @ircBot.quit
    
    @executeButton.enable(true)
    @stopButton.enable(false)
  end
  
  def setAllGames(ircBot)
    getAllGameTypes.each do |type|
      @ircBot.setGameByTitle( type )
    end
  end
end


def mainBcDiceGui
 BCDiceGuiApp.new.main_loop
end
