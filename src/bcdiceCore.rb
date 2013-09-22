#!/bin/ruby -Ku 
#--*-coding:utf-8-*--

#require 'Kconv'

require 'log'
require 'configBcDice.rb'
require 'CountHolder.rb'
require 'kconv'

#============================== 起動法 ==============================
# 上記設定をしてダブルクリック、
# もしくはコマンドラインで
#
# ruby bcdice.rb
#
# とタイプして起動します。
#
# このとき起動オプションを指定することで、ソースを書き換えずに設定を変更出来ます。
#
# -s サーバ設定      「-s(サーバ):(ポート番号)」     (ex. -sirc.trpg.net:6667)
# -c チャンネル設定  「-c(チャンネル名)」            (ex. -c#CoCtest)
# -n Nick設定        「-n(Nick)」                    (ex. -nDicebot)
# -g ゲーム設定      「-g(ゲーム指定文字列)」        (ex. -gCthulhu)
# -m メッセージ設定  「-m(Notice_flgの番号)」        (ex. -m0)
# -e エクストラカード「-e(カードセットのファイル名)」(ex. -eTORG_SET.txt)
# -i IRC文字コード   「-i(文字コード名称)」          (ex. -iISO-2022-JP)
#
# ex. ruby bcdice.rb -sirc.trpg.net:6667 -c#CoCtest -gCthulhu
#
# プレイ環境ごとにバッチファイルを作っておくと便利です。
#
# 終了時はボットにTalkで「お疲れ様」と発言します。($quitCommandで変更出来ます。)
#====================================================================

def decode(code, str)
  return str.kconv(code)
end

def encode(code, str)
  return Kconv.kconv(str, code)
end


$secretRollMembersHolder = {};
$secretDiceResultHolder = {};
$plotPrintChannels = {};
$point_counter = {};


require 'CardTrader'
require 'TableFileData'
require 'diceBot/DiceBot'
require 'dice/AddDice'
require 'dice/UpperDice'
require 'dice/RerollDice'


class BCDiceMaker
  
  def initialize
    @diceBot = DiceBot.new
    @cardTrader = CardTrader.new
    @cardTrader.initValues;
    
    @counterInfos = {};
    @tableFileData = TableFileData.new
    
    @master = "";
    @quitFunction = nil
  end
  
  attr_accessor :master
  attr_accessor :quitFunction
  attr_accessor :diceBot
  attr_accessor :diceBotPath
  
  def newBcDice
    bcdice = BCDice.new(self, @cardTrader, @diceBot, @counterInfos, @tableFileData)
    
    return bcdice
  end
  
end


class BCDice
  
  def initialize(parent, cardTrader, diceBot, counterInfos, tableFileData)
    @parent = parent
    
    setDiceBot(diceBot)
    
    @cardTrader = cardTrader
    @cardTrader.setBcDice(self)
    @counterInfos = counterInfos
    @tableFileData = tableFileData
    
    @nick_e = ""
    @tnick = ""
    @isMessagePrinted = false
    @rands = nil
    @isKeepSecretDice = true
    @randResults = nil
  end
  
  def setDir(dir, prefix)
    @tableFileData.setDir(dir, prefix)
  end
  
  def isKeepSecretDice(b)
    @isKeepSecretDice = b
  end
  
  def getGameType
    @diceBot.gameType
  end
  
  def setDiceBot(diceBot)
    return if( diceBot.nil? )
    
    @diceBot = diceBot
    @diceBot.bcdice = self
    @parent.diceBot = @diceBot
  end
  
  attr_reader :nick_e
  
  def readExtraCard(cardFileName)
    @cardTrader.readExtraCard(cardFileName)
  end
  
  def setIrcClient(client)
    @ircClient = client
  end
  
  def setMessage(message)
    @messageOriginal = parren_killer(message)
    @message = @messageOriginal.upcase
    debug("@message", @message)
  end
  
  def getOriginalMessage
    @messageOriginal
  end
  
  #直接TALKでは大文字小文字を考慮したいのでここでオリジナルの文字列に変更
  def changeMessageOriginal
    @message = @messageOriginal
  end
  
  def recieveMessage(nick_e, tnick)
    begin
      recieveMessageCatched(nick_e, tnick)
    rescue => e
      printErrorMessage(e)
    end
  end
  
  def printErrorMessage(e)
    sendMessageToOnlySender("error " + e.to_s + $@.join("\n"))
  end
  
  def recieveMessageCatched(nick_e, tnick)
    debug('recieveMessage nick_e, tnick', nick_e, tnick)
    
    @nick_e = nick_e
    @cardTrader.setTnick( @nick_e )
    
    @tnick = tnick
    @cardTrader.setTnick( @tnick )
    
    debug("@nick_e, @tnick", @nick_e, @tnick)
    
    # ===== 設定関係 ========
    if( /^set[\s]/i =~ @message )
      setCommand(@message)
    end
    
    # ポイントカウンター関係
    executePointCounter
    
    # プロット入力処理
    addPlot(@messageOriginal.clone)
    
    
    # ボット終了命令
    case @message
    when $quitCommand
      quit
      
    when /^mode$/i
      # モード確認
      checkMode()
      
    when /^help$/i
      # 簡易オンラインヘルプ
      printHelp()
      
    when /^c-help$/i
      @cardTrader.printCardHelp()
      
    end
  end
  
  def quit
    @ircClient.quit
    
    if( @parent.quitFunction.nil? )
      sleep( 3 );
      exit( 0 );
    else
      @parent.quitFunction.call()
    end
  end
  
  def setQuitFuction(func)
    @parent.quitFunction = func
  end
  
  def setCommand(arg)
    debug('setCommand arg', arg)
    
    case arg
    when (/^set[\s]+master$/i)
      # マスター登録
      setMaster()
      
    when (/^set[\s]+game$/i)
      # ゲーム設定
      setGame()
      
    when (/^set[\s]+v(iew[\s]*)?mode$/i)
      # 表示モード設定
      setDisplayMode()
      
    when (/^set[\s]+upper$/i)
      # 上方無限ロール閾値設定 0=Clear
      setUpplerRollThreshold()
      
    when (/^set[\s]+reroll$/i)
      # 個数振り足しロール回数制限設定 0=無限
      setRerollLimit()
      
    when (/^set[\s]+s(end[\s]*)?mode$/i)
      # データ送信モード設定
      setDataSendMode()
      
    when (/^set[\s]+r(ating[\s]*)?t(able)?$/i)
      # レーティング表設定
      setRatingTable()
      
    when (/^set[\s]+sort$/i)
      # ソートモード設定
      setSortMode()
      
    when (/^set[\s]+(cardplace|CP)$/i)
      # カードモード設定
      setCardMode()
      
    when (/^set[\s]+(shortspell|SS)$/i)
      # 呪文モード設定
      setSpellMode()
      
    when (/^set[\s]+tap$/i)
      # タップモード設定
      setTapMode()
      
    when (/^set[\s]+(cardset|CS)$/i)
      # カード読み込み
      readCardSet()
    else
    end
  end
  
  
  def setMaster()
    if( @parent.master != "" )
      setMasterWhenMasterAlreadySet()
    else
      setMasterWhenMasterYetSet()
    end
  end
  
  def setMasterWhenMasterAlreadySet()
    if( @nick_e == @parent.master )
      setMasterByCurrentMasterOwnself()
    else
      sendMessageToOnlySender("Masterは#{@parent.master}さんになっています");
    end
  end
  
  def setMasterByCurrentMasterOwnself()
    if( @tnick != "" )
      @parent.master = @tnick;
      sendMessageToChannels("#{@parent.master}さんをMasterに設定しました");
    else
      @parent.master = "";
      sendMessageToChannels("Master設定を解除しました");
    end
  end
  
  
  def setMasterWhenMasterYetSet()
    if( @tnick != "" )
      @parent.master = @tnick;
    else
      @parent.master = @nick_e;
    end
    sendMessageToChannels("#{@parent.master}さんをMasterに設定しました");
  end
  
  
  def setGame()
    messages = setGameByTitle(@tnick)
    sendMessageToChannels(messages);
  end
  
  
  def isMaster()
    return ((@nick_e == @parent.master) or (@parent.master == ""))
  end
  
  
  def setDisplayMode()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    
    mode = $1.to_i
    @diceBot.setSendMode(mode)
    
    sendMessageToChannels("ViewMode#{@diceBot.sendMode}に変更しました");
  end
  
  
  def setUpplerRollThreshold()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    @diceBot.upplerRollThreshold = $1.to_i;
    
    if( @diceBot.upplerRollThreshold > 0 )
      sendMessageToChannels("上方無限ロールを#{@diceBot.upplerRollThreshold}以上に設定しました");
    else
      sendMessageToChannels("上方無限ロールの閾値設定を解除しました");
    end
  end
  
  def setRerollLimit()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    @diceBot.rerollLimitCount = $1.to_i;
    
    if(@diceBot.rerollLimitCount > 0)
      sendMessageToChannels("個数振り足しロール回数を#{@diceBot.rerollLimitCount}以下に設定しました");
    else
      sendMessageToChannels("個数振り足しロールの回数を無限に設定しました");
    end
  end
  
  
  def setDataSendMode()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    $NOTICE_SW = $1.to_i;
    
    $mode_str = ( ($NOTICE_SW != 0) ? "notice-mode" : "msg-mode" );
    
    sendMessageToChannels("SendModeを#{$mode_str}に変更しました");
  end
  
  def setRatingTable()
    return unless( isMaster() )
    
    output = @diceBot.setRatingTable(@tnick)
    return if( output == '1' )
    
    sendMessageToChannels(output)
  end
  
  
  def setSortMode()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    sortType = $1.to_i
    @diceBot.setSortType(sortType)
    
    if( @diceBot.sortType != 0 )
      sendMessageToChannels("ソート有りに変更しました")
    else
      sendMessageToChannels("ソート無しに変更しました")
    end
  end
  
  def setCardMode()
    return unless( isMaster() )
    
    @cardTrader.setCardMode()
  end
  
  
  def setSpellMode()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    @isShortSpell = ($1.to_i != 0 );
    
    if( @isShortSpell )
      sendMessageToChannels("短い呪文モードに変更しました")
    else
      sendMessageToChannels("通常呪文モードに変更しました")
    end
  end
  
  def setTapMode()
    return unless( isMaster() )
    
    return unless( /(\d+)/  =~ @tnick )
    @canTapCard = ($1.to_i != 0);
    
    if( @canTapCard )
      sendMessageToChannels("タップ可能モードに変更しました")
    else
      sendMessageToChannels("タップ不可モードに変更しました")
    end
  end
  
  
  def readCardSet()
    return unless( isMaster() )
    
    @cardTrader.readCardSet()
  end
  
  
  def executePointCounter
    arg = @messages
    debug("executePointCounter arg", arg)
    
    unless(arg =~ /^#/)
      debug("executePointCounter is NOT matched")
      return
    end
    
    channel = getPrintPlotChannel(@nick_e);
    debug("getPrintPlotChannel get channel", channel)
    
    if( channel == "1")
      sendMessageToOnlySender("表示チャンネルが登録されていません");
      return
    end
    
    
    arg << "->#{@tnick}" unless( @tnick.empty? );
    
    pointerMode = :sameNick
    output_msg, pointerMode = countHolder.executeCommand(arg, @nick_e, channel, pointerMode);
    debug("point_counter_command called, line", __LINE__)
    debug("output_msg", output_msg)
    debug("pointerMode", pointerMode)
    
    if( output_msg == "1" )
      debug("executePointCounter point_counter_command output_msg is \"1\"")
      return
    end
    
    case pointerMode
    when :sameNick
      debug("executePointCounter:Talkで返事")
      sendMessageToOnlySender(output_msg);
    when :sameChannel
      debug("executePointCounter:publicで返事")
      sendMessage(channel, output_msg);
    end
    
    debug("executePointCounter end")
  end
  
  def addPlot(arg)
    debug("addPlot begin arg", arg)
    
    unless(/#{$ADD_PLOT}[:：](.+)/i =~ arg)
      debug("addPlot exit")
      return
    end
    plot = $1;
    
    channel = getPrintPlotChannel(@nick_e);
    
    debug('addPlot channel', channel)
    
    if( channel.nil? )
      debug('channel.nil?')
      sendMessageToOnlySender("プロット出力先が登録されていません");
    else
      debug('addToSecretDiceResult calling...')
      addToSecretDiceResult(plot, channel, 1);
      sendMessage(channel, "#{@nick_e} さんがプロットしました");
    end
    
  end
  
  
  def getPrintPlotChannel(nick)
    nick = getNick(nick)
    return  $plotPrintChannels[nick]
  end
  
  
  def checkMode()
    return unless( isMaster() )
    
    output_msg = "GameType = " + @diceBot.gameType + ", ViewMode = " + @diceBot.sendMode + ", Sort = " + @diceBot.sortType;
    sendMessageToOnlySender(output_msg);
  end
  
  
  def printHelp()
    
    sendMessageToOnlySender("・加算ロール　　　　　　　　(xDn) (n面体ダイスをx個)");
    sendMessageToOnlySender("・バラバラロール　　　　　　(xBn)");
    sendMessageToOnlySender("・個数振り足しロール　　　　(xRn[振り足し値])");
    sendMessageToOnlySender("・上方無限ロール　　　　　　(xUn[境界値])");
    sendMessageToOnlySender("・シークレットロール　　　　(Sダイスコマンド)");
    sendMessageToOnlySender("・シークレットをオープンする(#{$OPEN_DICE})");
    sendMessageToOnlySender("・四則計算(端数切捨て)　　　(C(式))");
    
    sleep 2;
    
    @diceBot.getHelpMessage().each do |i|
      sendMessageToOnlySender(i);
      if( (i % 5) == 0 )
        sleep 1
      end
    end
    
    sendMessageToOnlySender("  ---");
    sleep 1;
    sendMessageToOnlySender("・プロット表示　　　　　　　　(#{$OPEN_PLOT})");
    sendMessageToOnlySender("・プロット記録　　　　　　　　(Talkで #{$ADD_PLOT}:プロット)");
    sendMessageToOnlySender("  ---");
    sleep 2;
    sendMessageToOnlySender("・ポイントカウンタ値登録　　　(#[名前:]タグn[/m]) (識別名、最大値省略可,Talk可)");
    sendMessageToOnlySender("・カウンタ値操作　　　　　　　(#[名前:]タグ+n) (もちろん-nもOK,Talk可)");
    sendMessageToOnlySender("・識別名変更　　　　　　　　　(#RENAME!名前1->名前2) (Talk可)");
    sleep 1;
    sendMessageToOnlySender("・同一タグのカウンタ値一覧　　(#OPEN!タグ)");
    sendMessageToOnlySender("・自キャラのカウンタ値一覧　　(Talkで#OPEN![タグ]) (全カウンタ表示時、タグ省略)");
    sendMessageToOnlySender("・自キャラのカウンタ削除　　　(#[名前:]DIED!) (デフォルト時、識別名省略)");
    sendMessageToOnlySender("・全自キャラのカウンタ削除　　(#ALL!:DIED!)");
    sendMessageToOnlySender("・カウンタ表示チャンネル登録　(#{$READY_CMD})");
    sendMessageToOnlySender("  ---");
    sleep 2;
    sendMessageToOnlySender("・カード機能ヘルプ　　　　　　(c-help)");
    sendMessageToOnlySender("  -- END ---");
  end
  
  def setChannel(channel)
    debug("setChannel called channel", channel)
    @channel = channel
  end
  
  def recievePublicMessage(nick_e)
    begin
      recievePublicMessageCatched(nick_e)
    rescue => e
      printErrorMessage(e)
    end
  end
  
  def recievePublicMessageCatched(nick_e)
    debug("recievePublicMessageCatched begin nick_e", nick_e)
    debug("recievePublicMessageCatched @channel", @channel)
    debug("recievePublicMessageCatched @message", @message)
    
    @nick_e = nick_e
    
    mynick = ''#self.nick;
    secret_flg = false
    
    if(/(^|\s+)#{$OPEN_PLOT}(\s+|$)/i =~ @message)
      #プロットの表示
      printPlot()
    end
    
    if(/(^|\s+)#{$OPEN_DICE}(\s+|$)/i =~ @message)
      # シークレットロールの表示
      printSecretRoll()
    end
    
    # ポイントカウンター関係
    executePointCounterPublic
    
    # ダイスロールの処理
    executeDiceRoll
    
    # 四則計算代行
    if(/(^|\s)C([-\d]+)\s*$/i =~ @message)
      output_msg = $2;
      if( output_msg != "" )
        sendMessage(@channel, "#{@nick_e}: 計算結果 ＞ #{output_msg}");
      end
    end
    
    #ここから大文字・小文字を考慮するようにメッセージを変更
    changeMessageOriginal
    
    # カード処理
    executeCard
    
    unless( @isMessagePrinted ) # ダイスロール以外の発言では捨てダイス処理を
      # rand 100 if($isRollVoidDiceAtAnyRecive);
    end
    
    debug("\non_public end")
  end
  
  
  def printPlot
    debug("printPlot begin")
    messageList = openSecretRoll(@channel, 1);
    debug("messageList", messageList)
    
    messageList.each do |message|
      if( message.empty?)
        debug("message is empty")
        setPrintPlotChannel
      else
        debug("message", message)
        sendMessage(@channel, message)
        sleep 1;
      end
    end
    
    setPrintPlotChannelIfChannelUndefine
  end
  
  def setPrintPlotChannelIfChannelUndefine
    return if( isTalkChannel )
    
    channel = getPrintPlotChannel(@nick_e);
    if( channel.nil? )
      setPrintPlotChannel
    end
  end
  
  
  def isTalkChannel
    (not (/^#/ === @channel))
  end
  
  def printSecretRoll
    output_msgs = openSecretRoll(@channel, 0);
    
    output_msgs.each do |diceResult|
      next if( diceResult.empty?)
      
      sendMessage(@channel, diceResult)
      sleep 1;
    end
  end
  
  def executePointCounterPublic
    debug("executePointCounterPublic begin")
    
    if(/^#{$READY_CMD}(\s+|$)/i =~ @message)
      setPrintPlotChannel
      sendMessageToOnlySender("表示チャンネルを設定しました");
      return
    end
    
    unless( /^#/ =~ @message)
      debug("executePointCounterPublic NOT match")
      return
    end
    
    pointerMode = :sameChannel
    countHolder = CountHolder.new(self, @counterInfos)
    output_msg, isSecret = countHolder.executeCommand(@message, @nick_e, @channel, pointerMode);
    debug("executePointCounterPublic output_msg, isSecret", output_msg, isSecret)
    
    if( isSecret )
      debug("is secret")
      sendMessageToOnlySender(output_msg) if(output_msg != "1");
    else
      debug("is NOT secret")
      sendMessage(@channel, output_msg) if(output_msg != "1");
    end
  end
  
  def executeDiceRoll
    debug("executeDiceRoll begin")
    debug("channel", @channel)
    
    output_msg, secret_flg = dice_command
    
    unless( secret_flg )
      debug("executeDiceRoll @channel", @channel)
      sendMessage(@channel,  output_msg) if(output_msg != "1");
      return;
    end
    
    # 隠しロール
    return if( output_msg == "1" )
    
    if( @isTest )
      output_msg << "###secret dice###"
    end
    
    broadmsg(output_msg, @nick_e);
    
    if( @isKeepSecretDice )
      addToSecretDiceResult(output_msg, @channel, 0);
    end
  end
  
  def setTest(isTest)
    @isTest = isTest
  end
  
  def executeCard
    debug('executeCard begin')
    @cardTrader.setNick( @nick_e )
    @cardTrader.setTnick( @tnick )
    @cardTrader.executeCard(@message, @channel)
    debug('executeCard end')
  end
  
  ###########################################################################
  #**                         各種コマンド処理
  ###########################################################################
  
  #=========================================================================
  #**                           コマンド分岐
  #=========================================================================
  def dice_command   # ダイスコマンドの分岐処理
    arg = @message.upcase
    output_msg = '1';
    secret_flg = false;
    
    output_msg, secret_flg = @diceBot.dice_command(@message, @nick_e)
    return output_msg, secret_flg if( output_msg != '1' )
    
    debug('dice_command arg', arg)
    
    case arg
      
    when /^D66/i
      debug("match D66 roll")
      
      if(@diceBot.d66Type != 0)
        output_msg, secret_flg_tmp = d66dice(arg)
        if(output_msg != '1');
          secret_flg = secret_flg_tmp
        end
      end
      
    when /[-\d]+D[\d\+\*\-D]+([<>=]+[?\-\d]+)?($|\s)/i
      debug("match add roll")
      
      dice = AddDice.new(self, @diceBot)
      output_msg = dice.rollDice(arg)
      if( /S[-\d]+D[\d+-]+/ =~ arg )     # 隠しロール
        secret_flg = true if(output_msg != '1');
      end
      
    when /[\d]+B[\d]+([<>=]+[\d]+)?($|\s)/i
      debug("match barabara roll")
      
      output_msg = bdice(arg)
      if(/S[\d]+B[\d]+/i =~ arg )   # 隠しロール
        secret_flg = true if(output_msg != '1');
      end
      
    when /(S)?[\d]+R[\d]+/i
      debug('match xRn roll')
      debug('xRn input arg', arg)
      
      secretMarker = $1
      output_msg = @diceBot.dice_command_xRn(arg, @nick_e)
      
      if( output_msg.empty? )
        dice = RerollDice.new(self, @diceBot)
        output_msg = dice.rollDice(arg)
      end
      
      debug('xRn output_msg', output_msg)
      
      if( secretMarker )
        secret_flg = true if(output_msg != '1');
      end
      
    when /[\d]+U[\d]+/
      debug("match upper roll")
      
      dice = UpperDice.new(self, @diceBot)
      output_msg = dice.rollDice(arg)
      if( /S[\d]+U[\d]+/ =~ arg )   # 隠しロール
        secret_flg = true if(output_msg != '1');
      end
      
    when /((^|\s)(S)?choice\[[^,]+(,[^,]+)+\]($|\s))/i
      debug("match choice command")
      
      secretMarker = $3
      output_msg = choice_random($1)
      if( secretMarker )   # 隠しロール
        secret_flg = true if(output_msg != '1');
      end
    else
      debug("match none...")
      output_msg, secret_flg = getTableDataResult(arg)
      return output_msg, secret_flg if(output_msg != '1');
    end
    
    debug("arg", arg)
    
    return output_msg, secret_flg;
  end
  
  
  def getTableDataResult(arg)
    debug("getTableDataResult Begin")
    
    output_msg = '1'
    secret_flg = false
    
    dice, title, table, secret_flg = @tableFileData.getTableData(arg, @diceBot.gameType)
    debug("dice", dice)
    
    if( table.nil? )
      debug("table is null")
      return output_msg, secret_flg
    end
    
    value = 0
    
    case dice
    when /D66/i
      value = getD66Value(0)
    when /(\d+)D(\d+)/i
      diceCount = $1
      diceMax = $2
      value, = roll(diceCount, diceMax)
    else
      table = []
    end
    
    debug("value", value)
    
    key, result_msg = table.find{|i| i.first === value}
    
    if( result_msg.nil? )
      return output_msg, secret_flg
    end
    
    output_msg = "#{nick_e}:#{title}(#{value}) ＞ #{result_msg}"
    
    return output_msg, secret_flg
  end
  
  
  #=========================================================================
  #**                           ランダマイザ
  #=========================================================================
  # ダイスロール
  def roll(dice_cnt, dice_max, dice_sort = 0, dice_add = 0 , dice_ul = '' , dice_diff = 0 , dice_re = nil)
    dice_cnt = dice_cnt.to_i
    dice_max = dice_max.to_i
    dice_re = dice_re.to_i
    
    total = 0;
    dice_str = "";
    numberSpot1 = 0;
    cnt_max = 0;
    n_max = 0;
    cnt_suc = 0;
    d9_on = false;
    rerollCount = 0;
    dice_result = []
    
    #dice_add = 0 if( ! dice_add );
    
    if( (@diceBot.d66Type != 0) and (dice_max == 66) )
      dice_sort = 0;
      dice_cnt = 2;
      dice_max = 6;
    end
    
    if( @diceBot.isD9 and (dice_max == 9))
      d9_on = true
      dice_max += 1
    end
    
    unless( (dice_cnt <= $DICE_MAXCNT) and (dice_max <= $DICE_MAXNUM) )
      return total, dice_str, numberSpot1, cnt_max, n_max, cnt_suc, rerollCount;
    end
    
    dice_cnt.times do |i|
      i += 1
      dice_now = 0;
      dice_n = 0;
      dice_st_n = "";
      round = 0;
      
      begin
        if( round >= 1 )
          # 振り足し時のダイス読み替え処理用（ダブルクロスはクリティカルでダイス10に読み替える)
          dice_now += @diceBot.getJackUpValueOnAddRoll(dice_n)
        end
        
        dice_n = rand(dice_max).to_i + 1;
        dice_n -=1 if( d9_on );
        
        dice_now += dice_n;
        
        debug('@diceBot.sendMode', @diceBot.sendMode)
        if( @diceBot.sendMode >= 2 )
          dice_st_n += "," unless( dice_st_n.empty? );
          dice_st_n += "#{dice_n}";
        end
        round += 1
        
      end while( (dice_add > 1) and (dice_n >= dice_add) );
      
      total +=  dice_now;
      
      if( dice_ul != '' )
        suc = check_hit(dice_now, dice_ul, dice_diff);
        cnt_suc += suc;
      end
      
      if( dice_re )
        rerollCount += 1 if(dice_now >= dice_re);
      end
      
      if( (@diceBot.sendMode >= 2) and (round >= 2) )
        dice_result.push( "#{dice_now}[#{dice_st_n}]" );
      else
        dice_result.push( dice_now )
      end
        
      numberSpot1 += 1 if( dice_now == 1 );
      cnt_max += 1 if( dice_now == dice_max );
      n_max = dice_now if( dice_now > n_max);
    end
    
    if( dice_sort != 0 )
      dice_str = dice_result.sort_by{|a| dice_num(a)}.join(",")
    else
      dice_str = dice_result.join(",");
    end
    
    return total, dice_str, numberSpot1, cnt_max, n_max, cnt_suc, rerollCount;
  end
  
  def setRandomValues(rands)
    @rands = rands
  end
  
  def rand(max)
    debug('rand called @rands', @rands)
    
    value = 0 
    if( @rands.nil? )
      value = randNomal(max)
    else
      value = randFromRands(max)
    end
    
    unless( @randResults.nil? ) 
      @randResults << [(value + 1), max]
    end
    
    return value
  end
  
  
  def setCollectRandResult(b)
    if( b )
      @randResults = []
    else
      @randResults = nil
    end
  end
  
  def getRandResults
    @randResults
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
      raise "invalid max value! value, max, targetMax: #{value}, #{max}, #{targetMax}"
    end
    
    return (value - 1)
  end
  
  def dice_num(dice_str)
    dice_str = dice_str.to_s
    return dice_str.sub(/\[[\d,]+\]/, '').to_i
  end
  
  #==========================================================================
  #**                            ダイスコマンド処理
  #==========================================================================
  
  ####################         バラバラダイス       ########################
  def bdice(string) # 個数判定型ダイスロール
    total_n = 0;
    suc = 0;
    signOfInequality = "";
    diff = 0;
    output = "";
    
    string = string.gsub(/-[\d]+B[\d]+/, '');   # バラバラダイスを引き算しようとしているのを除去
    
    unless( /(^|\s)S?(([\d]+B[\d]+(\+[\d]+B[\d]+)*)(([<>=]+)([\d]+))?)($|\s)/ =~ string )
      output = '1';
      return output;
    end
    
    string = $2;
    if( $5 )
      signOfInequality = marshalSignOfInequality( $6 )
      diff = $7.to_i
      string = $3
    elsif( /([<>=]+)(\d+)/ =~ @diceBot.defaultSuccessTarget )
      signOfInequality = marshalSignOfInequality($1);
      diff = $2.to_i;
    end
    
    dice_a = string.split(/\+/)
    dice_cnt_total = 0;
    numberSpot1 = 0;
    
    dice_a.each do |dice_o|
      dice_cnt, dice_max, = dice_o.split(/[bB]/)
      dice_cnt = dice_cnt.to_i
      dice_max = dice_max.to_i
      
      dice_dat = roll(dice_cnt, dice_max, (@diceBot.sortType & 2), 0, signOfInequality, diff);
      suc += dice_dat[5];
      output += "," if(output != "");
      output += dice_dat[1];
      numberSpot1 += dice_dat[2];
      dice_cnt_total += dice_cnt;
    end
    
    if(signOfInequality != "")
      string += "#{signOfInequality}#{diff}";
      output = "#{output} ＞ 成功数#{suc}";
      output += @diceBot.getGrichText(numberSpot1, dice_cnt_total, suc)
    end
    output = "#{@nick_e}: (#{string}) ＞ #{output}";
    
    return output;
  end
  
  def isReRollAgain(dice_cnt, round)
    debug("isReRollAgain dice_cnt, round", dice_cnt, round)
    ( (dice_cnt > 0) and ((round < @diceBot.rerollLimitCount) or (@diceBot.rerollLimitCount == 0)) )
  end
  
  ####################             D66ダイス        ########################
  def d66dice(string)
    string = string.upcase
    secret_flg = false
    output = '1';
    count = 1;
    
    if(string =~ /(^|\s)(S)?((\d+)?D66)(\s|$)/i)
      string = $3
      secret_flg = (not $2.nil?)
      count = $4.to_i if($4)
      debug('d66dice count', count)
      
      d66List = []
      count.times do |i|
        d66List << getD66Value( @diceBot.d66Type )
      end
      d66Text = d66List.join(',')
      debug('d66Text', d66Text)
      
      output = "#{@nick_e}: (#{string}) ＞ #{d66Text}"
    end
    
    return output, secret_flg
  end
  
  def getD66Value(mode = nil)
    mode ||= @diceBot.d66Type
    
    isSwap = ( mode > 1)
    getD66(isSwap)
  end
  
  def getD66(isSwap)
    output = 0
    
    dice_a = rand(6) + 1
    dice_b = rand(6) + 1
    debug("dice_a", dice_a)
    debug("dice_b", dice_b)
    
    if( isSwap and (dice_a > dice_b))
      # 大小でスワップするタイプ
      output = dice_a + dice_b * 10
    else
      # 出目そのまま
      output = dice_a * 10 + dice_b
    end
    
    debug("output", output)
    
    return output
  end
  
  
  ####################        その他ダイス関係      ########################
  def openSecretRoll(channel, mode)
    debug("openSecretRoll begin")
    channel = channel.upcase
    
    messages = []
    
    memberKey = getSecretRollMembersHolderKey(channel, mode)
    members = $secretRollMembersHolder[memberKey]
    
    if( members.nil? )
      debug("openSecretRoll members is nil. messages", messages)
      return messages
    end
    
    members.each do |member|
      diceResultKey = getSecretDiceResultHolderKey(channel, mode, member)
      debug("openSecretRoll diceResulyKey", diceResultKey)
      
      diceResult = $secretDiceResultHolder[diceResultKey]
      debug("openSecretRoll diceResult", diceResult)
      
      if( diceResult )
        messages.push( diceResult )
        $secretDiceResultHolder.delete(diceResultKey)
      end
    end
    
    if(mode <= 0)  # 記録しておいたデータを削除
      debug("delete recorde data")
      $secretRollMembersHolder.delete(channel)
    end
    
    debug("openSecretRoll result messages", messages)
    
    return messages;
  end
  
  def getNick(nick = nil)
    nick ||= @nick_e
    nick = nick.upcase
    
    /[_\d]*(.+)[_\d]*/ =~ nick
    nick = $1;   # Nick端の数字はカウンター変わりに使われることが多いので除去
    
    return nick
  end
  
  def addToSecretDiceResult(diceResult, channel, mode)
    nick = getNick()
    channel = channel.upcase
    
    # まずはチャンネルごとの管理リストに追加
    addToSecretRollMembersHolder(channel, mode)
    
    # 次にダイスの出力結果を保存
    saveSecretDiceResult(diceResult, channel, mode)
    
    @isMessagePrinted = true
  end
  
  def addToSecretRollMembersHolder(channel, mode)
    key = getSecretRollMembersHolderKey(channel, mode)
    
    $secretRollMembersHolder[key] ||= []
    members = $secretRollMembersHolder[key]
    
    nick = getNick()
    
    unless( members.include?(nick) )
      members.push(nick)
    end
  end
  
  def getSecretRollMembersHolderKey(channel, mode)
    "#{mode},#{channel}"
  end
  
  def saveSecretDiceResult(diceResult, channel, mode)
    nick = getNick()
    
    if( mode != 0 )
      diceResult = "#{nick}: #{diceResult}" # プロットにNickを追加
    end
    
    key = getSecretDiceResultHolderKey(channel, mode, nick)
    $secretDiceResultHolder[key] = diceResult;    # 複数チャンネルも一応想定
    
    debug("key", key)
    debug("secretDiceResultHolder", $secretDiceResultHolder)
  end
  
  def getSecretDiceResultHolderKey(channel, mode, nick)
    key = "#{mode},#{channel},#{nick}"
    return key
  end
  
  def setPrintPlotChannel
    nick = getNick()
    $plotPrintChannels[nick] = @channel;
  end
  
  
  #==========================================================================
  #**                            その他の機能
  #==========================================================================
  def choice_random(string)
    output = "1";
    
    unless(/(^|\s)((S)?choice\[([^,]+(,[^,]+)+)\])($|\s)/i =~ string)
      return output
    end
    
    string = $2;
    targetList = $4
    
    unless(targetList)
      return output
    end
    
    targets = targetList.split(/,/)
    index = rand(targets.length)
    target = targets[ index ]
    output = "#{@nick_e}: (#{string}) ＞ #{target}"
    
    return output;
  end
  
  #==========================================================================
  #**                            結果判定関連
  #==========================================================================
  def getMarshaledSignOfInequality(text)
    return "" if( text.nil? )
    return marshalSignOfInequality(text)
  end
  
  def marshalSignOfInequality(signOfInequality)  # 不等号の整列
    case signOfInequality
    when /(<=|=<)/
      return "<=";
    when /(>=|=>)/
      return ">=";
    when /(<>)/
      return "<>";
    when /[<]+/
      return "<";
    when /[>]+/
      return ">";
    when /[=]+/
      return "=";
    end
    
    return signOfInequality;
  end
  
  def check_hit(dice_now, signOfInequality, diff) # 成功数判定用
    suc = 0;
    
    if( diff.is_a?(String) )
      unless( /\d/ =~ diff )
        return suc
      end
      diff = diff.to_i
    end
    
    case signOfInequality
    when /(<=|=<)/
      if( dice_now <= diff)
        suc += 1
      end
    when /(>=|=>)/
      if( dice_now >=  diff)
        suc += 1;
      end
    when /(<>)/
      if(dice_now != diff)
        suc += 1;
      end
    when /[<]+/
      if(dice_now < diff)
        suc += 1;
      end
    when /[>]+/
      if(dice_now > diff)
        suc += 1;
      end
    when /[=]+/
      if(dice_now == diff)
        suc += 1;
      end
    end
    
    return suc;
  end
  
  
  ####################       ゲーム別成功度判定      ########################
  def check_suc(*check_param)
    
    total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max = *check_param
    
    debug('check params : total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max',
          total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    return "" unless(/([\d]+)[)]?$/ =~ total_n.to_s)
    
    total_n = $1.to_i;
    diff = diff.to_i
    
    check_paramNew = [total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max]
    
    text = getSuccessText(*check_paramNew)
    
    if( text.empty? )
      if( signOfInequality != "" )
        debug('どれでもないけど判定するとき')
        return check_nDx(*check_param);
      end
    end
    
    return text
  end
  
  
  def getSuccessText(*check_param)
    debug('getSuccessText begin')
    
    total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max = *check_param
    
    debug("dice_max, dice_cnt", dice_max, dice_cnt)
    
    if((dice_max == 100) and (dice_cnt == 1))
      debug('1D100判定')
      return @diceBot.check_1D100(*check_param);
    end
    
    if((dice_max == 20) and (dice_cnt == 1))
      debug('1d20判定')
      return @diceBot.check_1D20(*check_param);
    end
    
    if(dice_max == 10)
      debug('d10ベース判定')
      return @diceBot.check_nD10(*check_param);
    end
    
    if(dice_max == 6)
      if(dice_cnt == 2)
        debug('2d6判定')
        return @diceBot.check_2D6(*check_param);
      end
      
      debug('xD6判定')
      return @diceBot.check_nD6(*check_param);
    end
    
    return ""
  end
  
  def check_nDx(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(ダイスごちゃ混ぜ系)
    debug('check_nDx begin diff', diff)
    success = check_hit(total_n, signOfInequality, diff);
    debug('check_nDx success', success)
    
    if(success >= 1)
      return " ＞ 成功";
    end
    
    return " ＞ 失敗";
  end
  
  ###########################################################################
  #**                              出力関連
  ###########################################################################
  
  def broadmsg(output_msg, nick)
    debug("broadmsg output_msg, nick", output_msg, nick)
    debug("@nick_e", @nick_e)
    
    if(output_msg == "1")
      return
    end
    
    if( nick == @nick_e )
      sendMessageToOnlySender(output_msg); #encode($ircCode, output_msg));
    else
      sendMessage(nick, output_msg);
    end
  end
  
  def sendMessage(to, message)
    debug("sendMessage to, message", to, message)
    @ircClient.sendMessage(to, message)
    @isMessagePrinted = true
  end
  
  def sendMessageToOnlySender(message)
    debug("sendMessageToOnlySender message", message)
    debug("@nick_e", @nick_e)
    @ircClient.sendMessageToOnlySender(@nick_e, message)
    @isMessagePrinted = true
  end
  
  def sendMessageToChannels(message)
    @ircClient.sendMessageToChannels(message)
    @isMessagePrinted = true
  end
  
  
  ####################         テキスト前処理        ########################
  def parren_killer(string)
    debug("parren_killer input", string)
    
    while( /^(.*?)\[(\d+[Dd]\d+)\](.*)/ =~ string )
      str_before = "";
      str_after = "";
      dice_cmd = $2;
      str_before = $1 if($1);
      str_after = $3 if($3);
      rolled, dmy = rollDiceAddingUp(dice_cmd);
      string = "#{str_before}#{rolled}#{str_after}";
    end
    
    string = changeRangeTextToNumberText(string)
    
    while(/^(.*?)(\([\d\/*+-]+?\))(.*)/ =~ string)
      
      str_a = $3
      str_a ||= ""
      
      str_b = $1
      str_b ||= ""
      
      par_i = $2;
      
      debug(par_i)
      par_o = paren_k(par_i);
      debug(par_o)
      
      if(par_o != 0)
        if(par_o < 0)
          if(/(.+?)(\+)$/ =~ str_b)
            str_b = $1;
          elsif(/(.+?)(-)$/ =~ $str_b)
            str_b = "$1+";
            par_o =~ /([\d]+)/;
            par_o = $1;
          end
        end
        string = "#{str_b}#{par_o}#{str_a}";
      else
        if(/^([DBRUdbru][\d]+)(.*)/ =~ $str_a)
          str_a = $2;
        end
        string = "#{str_b}0#{str_a}";
      end
    end
    
    debug("diceBot.changeText(string) begin", string)
    string = @diceBot.changeText(string)
    debug("diceBot.changeText(string) end", string)
    
    string = string.gsub(/([\d]+[dD])([^\d\w]|$)/) {"#{$1}6#{$2}"}
    
    debug("parren_killer output", string)
    
    return string
  end
  
  def rollDiceAddingUp(*arg)
    dice = AddDice.new(self, @diceBot)
    dice.rollDiceAddingUp(*arg)
  end
  
  # [1...4]D[2...7] -> 2D7 のように[n...m]をランダムな数値へ変換
  def changeRangeTextToNumberText(string)
    debug('[st...ed] before string', string)
    
    while(/^(.*?)\[(\d+)[.]{3}(\d+)\](.*)/ =~ string )
      beforeText = $1
      beforeText ||= "";
      
      rangeBegin = $2.to_i;
      rangeEnd = $3.to_i;
      
      afterText = $4
      afterText ||= "";
      
      if(rangeBegin < rangeEnd)
        range = (rangeEnd - rangeBegin + 1)
        debug('range', range)
        
        rolledNumber, = roll(1, range);
        resultNumber = rangeBegin - 1 + rolledNumber
        string = "#{beforeText}#{resultNumber}#{afterText}";
      end
    end
    
    debug('[st...ed] after string', string)
    
    return string
  end
  
  def paren_k(string)
    kazu_o = 0;
    
    unless (/([\d\/*+-]+)/ =~ string)
      return kazu_o
    end
    
    string = $1;
    
    kazu_p = string.split(/\+/)
    
    kazu_p.each do |kazu_a|
      dec_p = "";
      
      if(/(.*?)(-)(.*)/ =~ kazu_a)
        kazu_a = $1;
        dec_p = $3;
      end
      
      mul = 1;
      dev = 1;
      
      while(/(.*?)(\*[\d]+)(.*)/ =~ kazu_a)
        par_b = $1;
        par_a = $3;
        par_c = $2;
        kazu_a = "#{par_b}#{par_a}";
        if(/([\d]+)/ =~ par_c)
          mul = mul * $1.to_i;
        end
      end
      
      while(/(.*?)(\/[\d]+)(.*)/ =~ kazu_a)
        par_b = $1;
        par_a = $3;
        par_c = $2;
        kazu_a = "#{par_b}#{par_a}";
        if(/([\d]+)/ =~ par_c)
          dev = dev * $1.to_i;
        end
      end
      
      work = 0;
      if(/([\d]+)/ =~ kazu_a)
        work = ($1.to_i) * mul;
        
        if( dev != 0 )
          case @diceBot.fractionType
          when "roundUp"  # 端数切り上げ
            kazu_o += (work / dev + 0.999).to_i
          when "roundOff" # 四捨五入
            kazu_o += (work / dev + 0.5).to_i
          else #切り捨て
            kazu_o += (work / dev).to_i
          end
        end
      end
      
      next if( dec_p == "" )
      
      kazu_m = dec_p.split(/-/)
      kazu_m.each do |kazu_s|
        mul = 1;
        dev = 1;
        while(/(.*?)(\*[\d]+)(.*)/ =~ kazu_s)
          par_b = $1;
          par_a = $3;
          par_c = $2;
          kazu_s = "#{par_b}#{par_a}";
          if(/([\d]+)/ =~ par_c)
            mul = mul * $1.to_i;
          end
        end
        while(/(.*?)(\/[\d]+)(.*)/ =~ kazu_s)
          par_b = $1;
          par_a = $3;
          par_c = $2;
          kazu_s = "#{par_b}#{par_a}";
          if(/([\d]+)/ =~ par_c)
            dev = dev * $1.to_i;
          end
        end
        
        if( /([\d]+)/ =~ kazu_s )
          work = ($1.to_i) * mul;
          
          if( dev != 0 )
            case @diceBot.fractionType
            when "roundUp"     # 端数切り上げに設定
              kazu_o -= (work / dev + 0.999).to_i
            when "roundOff"    # 四捨五入
              kazu_o -= (work / dev + 0.5).to_i
            else #切り捨て
              kazu_o -= (work / dev).to_i
            end
          end
        end
      end
    end
    
    return kazu_o
    
  end
  
  
  def setGameByTitle(gameTitle)  # 各種ゲームモードの設定
    debug('setGameByTitle gameTitle', gameTitle)
    
    @cardTrader.initValues;
    
    diceBot = nil
    
    case gameTitle
    when /(^|\s)((Cthulhu)|(COC))$/i
      require 'diceBot/Cthulhu'
      diceBot = Cthulhu.new
    when /(^|\s)((Hieizan)|(COCH))$/i
      require 'diceBot/Hieizan'
      diceBot = Hieizan.new
    when /(^|\s)((Elric!)|(EL))$/i
      require 'diceBot/Elric'
      diceBot = Elric.new
    when /(^|\s)((RuneQuest)|(RQ))$/i
      require 'diceBot/RuneQuest'
      diceBot = RuneQuest.new
    when /(^|\s)((Chill)|(CH))$/i
      require 'diceBot/Chill'
      diceBot = Chill.new
    when /(^|\s)((RoleMaster)|(RM))$/i
      require 'diceBot/RoleMaster'
      diceBot = RoleMaster.new
    when /(^|\s)((ShadowRun)|(SR))$/i
      require 'diceBot/ShadowRun'
      diceBot = ShadowRun.new
    when /(^|\s)((ShadowRun4)|(SR4))$/i
      require 'diceBot/ShadowRun4'
      diceBot = ShadowRun4.new
    when /(^|\s)((Pendragon)|(PD))$/i
      require 'diceBot/Pendragon'
      diceBot = Pendragon.new
    when /(^|\s)(SwordWorld\s*2\.0|SW\s*2\.0)$/i
      require 'diceBot/SwordWorld'
      require 'diceBot/SwordWorld2_0'
      diceBot = SwordWorld2_0.new
    when /(^|\s)((SwordWorld)|(SW))$/i
      require 'diceBot/SwordWorld'
      diceBot = SwordWorld.new
    when /(^|\s)((Arianrhod)|(AR))$/i
      require 'diceBot/Arianrhod'
      diceBot = Arianrhod.new
    when /(^|\s)((Infinite[\s]*Fantasia)|(IF))$/i
      require 'diceBot/InfiniteFantasia'
      diceBot = InfiniteFantasia.new
    when /(^|\s)(WARPS)$/i
      require 'diceBot/WARPS'
      diceBot = WARPS.new
    when /(^|\s)((Demon[\s]*Parasite)|(DP))$/i
      require 'diceBot/DemonParasite'
      diceBot = DemonParasite.new
    when /(^|\s)((Parasite\s*Blood)|(PB))$/i
      require 'diceBot/DemonParasite'
      require 'diceBot/ParasiteBlood'
      diceBot = ParasiteBlood.new
    when /(^|\s)((Gun[\s]*Dog)|(GD))$/i
      require 'diceBot/Gundog'
      diceBot = Gundog.new
    when /(^|\s)((Gun[\s]*Dog[\s]*Zero)|(GDZ))$/i
      require 'diceBot/Gundog'
      require 'diceBot/GundogZero'
      diceBot = GundogZero.new
    when /(^|\s)((Tunnels[\s]*&[\s]*Trolls)|(TuT))$/i
      require 'diceBot/TunnelsAndTrolls'
      diceBot = TunnelsAndTrolls.new
    when /(^|\s)((Nightmare[\s]*Hunter[=\s]*Deep)|(NHD))$/i
      require 'diceBot/NightmareHunterDeep'
      diceBot = NightmareHunterDeep.new
    when /(^|\s)((War[\s]*Hammer(FRP)?)|(WH))$/i
      require 'diceBot/Warhammer'
      diceBot = Warhammer.new
    when /(^|\s)((Phantasm[\s]*Adventure)|(PA))$/i
      require 'diceBot/PhantasmAdventure'
      diceBot = PhantasmAdventure.new
    when /(^|\s)((Chaos[\s]*Flare)|(CF))$/i
      require 'diceBot/ChaosFlare'
      diceBot = ChaosFlare.new
      
      @cardTrader.set2Deck2Jorker
      @cardTrader.setCardPlace(0)#手札の他のカード置き場
      @cardTrader.setCanTapCard(false)#場札のタップ処理の必要があるか？
      
    when /(^|\s)((Cthulhu[\s]*Tech)|(CT))$/i
      require 'diceBot/CthulhuTech'
      diceBot = CthulhuTech.new
    when /(^|\s)((Tokumei[\s]*Tenkousei)|(ToT))$/i
      require 'diceBot/TokumeiTenkousei'
      diceBot = TokumeiTenkousei.new
    when /(^|\s)((Shinobi[\s]*Gami)|(SG))$/i
      require 'diceBot/ShinobiGami'
      diceBot = ShinobiGami.new
    when /(^|\s)((Double[\s]*Cross)|(DX))$/i
      require 'diceBot/DoubleCross'
      diceBot = DoubleCross.new
    when /(^|\s)((Sata[\s]*Supe)|(SS))$/i
      require 'diceBot/Satasupe'
      diceBot = Satasupe.new
    when /(^|\s)((Ars[\s]*Magica)|(AM))$/i
      require 'diceBot/ArsMagica'
      diceBot = ArsMagica.new
    when /(^|\s)((Dark[\s]*Blaze)|(DB))$/i
      require 'diceBot/DarkBlaze'
      diceBot = DarkBlaze.new
    when /(^|\s)((Night[\s]*Wizard)|(NW))$/i
      require 'diceBot/NightWizard'
      diceBot = NightWizard.new
    when /(^|\s)TORG$/i
      require 'diceBot/Torg'
      diceBot = Torg.new
    when /(^|\s)(hunters\s*moon|HM)$/i
      require 'diceBot/HuntersMoon'
      diceBot = HuntersMoon.new
    when /(^|\s)(Blood\s*Crusade|BC)$/i
      require 'diceBot/BloodCrusade'
      diceBot = BloodCrusade.new
    when /(^|\s)(Meikyu\s*Kingdom|MK)$/i
      require 'diceBot/MeikyuKingdom'
      diceBot = MeikyuKingdom.new
    when /(^|\s)(Earth\s*Dawn|ED)$/i
      require 'diceBot/EarthDawn'
      diceBot = EarthDawn.new
    when /(^|\s)(Embryo\s*Machine|EM)$/i
      require 'diceBot/EmbryoMachine'
      diceBot = EmbryoMachine.new
    when /(^|\s)(Gehenna\s*An|GA)$/i
      require 'diceBot/GehennaAn'
      diceBot = GehennaAn.new
    when /(^|\s)((Magica[\s]*Logia)|(ML))$/i
      require 'diceBot/MagicaLogia'
      diceBot = MagicaLogia.new
    when /(^|\s)((Nechronica)|(NC))$/i
      require 'diceBot/Nechronica'
      diceBot = Nechronica.new
    when /(^|\s)(Meikyu\s*Days|MD)$/i
      require 'diceBot/MeikyuDays'
      diceBot = MeikyuDays.new
    when /(^|\s)(Peekaboo|PK)$/i
      require 'diceBot/Peekaboo'
      diceBot = Peekaboo.new
    when /(^|\s)(Barna\s*Kronika|BK)$/i
      require 'diceBot/BarnaKronika'
      diceBot = BarnaKronika.new
      
      @cardTrader.set1Deck2Jorker
      @cardTrader.setCardPlace(0)#手札の他のカード置き場
      @cardTrader.setCanTapCard(false)#場札のタップ処理の必要があるか？
      
    when /(^|\s)(RokumonSekai2|RS2)$/i
      require 'diceBot/RokumonSekai2'
      diceBot = RokumonSekai2.new
    when /(^|\s)(Monotone(\s*)Musium|MM)$/i
      require 'diceBot/MonotoneMusium'
      diceBot = MonotoneMusium.new
    when /(^|\s)Zettai\s*Reido$/i
      require 'diceBot/ZettaiReido'
      diceBot = ZettaiReido.new
    when /(^|\s)Eclipse\s*Phase$/i
      require 'diceBot/EclipsePhase'
      diceBot = EclipsePhase.new
    when /(^|\s)NJSLYRBATTLE$/i
      require 'diceBot/NjslyrBattle'
      diceBot = NjslyrBattle.new
    when /(^|\s)ShinMegamiTenseiKakuseihen$/i, /(^|\s)SMTKakuseihen$/i
      require 'diceBot/ShinMegamiTenseiKakuseihen'
      diceBot = ShinMegamiTenseiKakuseihen.new
    when /(^|\s)Ryutama$/i
      require 'diceBot/Ryutama'
      diceBot = Ryutama.new
    when /(^|\s)CardRanker$/i
      require 'diceBot/CardRanker'
      diceBot = CardRanker.new
    when /(^|\s)ShinkuuGakuen$/i
      require 'diceBot/ShinkuuGakuen'
      diceBot = ShinkuuGakuen.new
    when /(^|\s)CrashWorld$/i
      require 'diceBot/CrashWorld'
      diceBot = CrashWorld.new
    when /(^|\s)WitchQuest$/i
      require 'diceBot/WitchQuest'
      diceBot = WitchQuest.new
    when /(^|\s)BattleTech$/i
      require 'diceBot/BattleTech'
      diceBot = BattleTech.new
    when /(^|\s)Elysion$/i
      require 'diceBot/Elysion'
      diceBot = Elysion.new
    when /(^|\s)GeishaGirlwithKatana$/i
      require 'diceBot/GeishaGirlwithKatana'
      diceBot = GeishaGirlwithKatana.new
    when /(^|\s)GURPS$/i
      require 'diceBot/Gurps'
      diceBot = Gurps.new
    when /(^|\s)HarnMaster$/i
      require 'diceBot/HarnMaster'
      diceBot = HarnMaster.new
    when /(^|\s)Insane$/i
      require 'diceBot/Insane'
      diceBot = Insane.new
    when /(^|\s)KillDeathBusiness$/i
      require 'diceBot/KillDeathBusiness'
      diceBot = KillDeathBusiness.new
    when /(^|\s)Kamigakari$/i
      require 'diceBot/Kamigakari'
      diceBot = Kamigakari.new
    when /(^|\s)None$/i, ""
      diceBot = DiceBot.new
    else
      require 'diceBot/DiceBotLoader'
      loader = DiceBotLoader.new
      diceBot = loader.loadUnknownGame(gameTitle)
    end
    
    if( diceBot.nil? )
      diceBot = DiceBot.new
    end
    
    setDiceBot(diceBot)
    
    message = "Game設定を#{diceBot.gameName}に設定しました"
    debug( 'setGameByTitle message', message )
    
    return message
  end
  
end


