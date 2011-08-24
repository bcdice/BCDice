#!/perl/bin/ruby -Ku 
#--*-coding:utf-8-*--

require 'config.rb'

$ircNickRegExp = '[A-Za-z\d\-\[\]\\\'^{}_]+';

print("#--*-coding:utf-8-*--\n");


class CardTrader
  
  def initialize
    initValues
    
    @card_channels = {};
    @isShortSpell = true;
    @card_spell = [
                   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z',
                   'a','b','c','d','e','f','g','h','i','j','k','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
                   '0','1','2','3','4','5','6','7','8','9','+','-','*','/',
                  ];  # 64種類の記号
  end
  
  
  # カードをデフォルトに戻す
  def initValues
    @cardTitles = {}
    @card_val = [
                 'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13',
                 'H1','H2','H3','H4','H5','H6','H7','H8','H9','H10','H11','H12','H13',
                 'D1','D2','D3','D4','D5','D6','D7','D8','D9','D10','D11','D12','D13',
                 'C1','C2','C3','C4','C5','C6','C7','C8','C9','C10','C11','C12','C13',
                 'J1',
                ];
    @cardRegExp = '[DHSCJdhscj][\d]+'; #カード指定文字列の正規表現
    @cardRest = @card_val.clone
    @deal_cards = {'card_played' => []};
    
    setCardPlace( 1 )
    setCanTapCard( true )
  end
  
  def setCardPlace(place)
    #カード置き場数。0なら無し。
    @card_place = place
  end
  
  def setCanTapCard(b)
    @canTapCard = b
  end
  
  def set1Deck2Jorker
      @card_val = [
                   'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13',
                   'H1','H2','H3','H4','H5','H6','H7','H8','H9','H10','H11','H12','H13',
                   'D1','D2','D3','D4','D5','D6','D7','D8','D9','D10','D11','D12','D13',
                   'C1','C2','C3','C4','C5','C6','C7','C8','C9','C10','C11','C12','C13',
                   'J1','J0',
                   ];
    @cardRest = @card_val.clone
  end
  def set2Deck2Jorker
      @card_val = [
                   'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13',
                   's1','s2','s3','s4','s5','s6','s7','s8','s9','s10','s11','s12','s13',
                   'H1','H2','H3','H4','H5','H6','H7','H8','H9','H10','H11','H12','H13',
                   'h1','h2','h3','h4','h5','h6','h7','h8','h9','h10','h11','h12','h13',
                   'D1','D2','D3','D4','D5','D6','D7','D8','D9','D10','D11','D12','D13',
                   'd1','d2','d3','d4','d5','d6','d7','d8','d9','d10','d11','d12','d13',
                   'C1','C2','C3','C4','C5','C6','C7','C8','C9','C10','C11','C12','C13',
                   'c1','c2','c3','c4','c5','c6','c7','c8','c9','c10','c11','c12','c13',
                   'J1','J2','J3','J4',
                   ]
    @cardRest = @card_val.clone
  end
  
  def setBcDice(bcDice)
    @bcdice = bcDice
  end
  
  def setNick(nick_e)
    @nick_e = nick_e
  end
  
  def setTnick(t)
    @tnick = t
  end
  
  def printCardHelp()
    sendMessageToOnlySender("・カードを引く　　　　　　　(c-draw[n]) (nは枚数)");
    sendMessageToOnlySender("・オープンでカードを引く　　(c-odraw[n])");
    sendMessageToOnlySender("・カードを選んで引く　　　　(c-pick[c[,c]]) (cはカード。カンマで複数指定可)");
    sendMessageToOnlySender("・捨てたカードを手札に戻す　(c-back[c[,c]])");
    sendMessageToOnlySender("・置いたカードを手札に戻す　(c-back1[c[,c]])");
    sleep 1;
    sendMessageToOnlySender("・手札と場札を見る　　　　　(c-hand) (Talk可)");
    sendMessageToOnlySender("・カードを出す　　　　　　　(c-play[c[,c]]");
    sendMessageToOnlySender("・カードを場に出す　　　　　(c-play1[c[,c]]");
    sendMessageToOnlySender("・カードを捨てる　　　　　　(c-discard[c[,c]]) (Talk可)");
    sendMessageToOnlySender("・場のカードを選んで捨てる　(c-discard1[c[,c]])");
    sendMessageToOnlySender("・山札からめくって捨てる　  (c-milstone[n])");
    sleep 1;
    sendMessageToOnlySender("・カードを相手に一枚渡す　　(c-pass[c]相手) (カード指定が無いときはランダム)");
    sendMessageToOnlySender("・場のカードを相手に渡す　　(c-pass1[c]相手) (カード指定が無いときはランダム)");
    sendMessageToOnlySender("・カードを相手の場に出す　　(c-place[c[,c]]相手)");
    sendMessageToOnlySender("・場のカードを相手の場に出す(c-place1[c[,c]]相手)");
    sleep 1;
    sendMessageToOnlySender("・場のカードをタップする　　(c-tap1[c[,c]]相手)");
    sendMessageToOnlySender("・場のカードをアンタップする(c-untap1[c[,c]]相手)");
    sendMessageToOnlySender("  ---");
    sleep 2;
    sendMessageToOnlySender("・カードを配る　　　　　　　(c-deal[n]相手)");
    sendMessageToOnlySender("・カードを見てから配る　　　(c-vdeal[n]相手)");
    sendMessageToOnlySender("・カードのシャッフル　　　　(c-shuffle)");
    sendMessageToOnlySender("・捨てカードを山に戻す　　　(c-rshuffle)");
    sendMessageToOnlySender("・全員の場のカードを捨てる　(c-clean)");
    sleep 1;
    sendMessageToOnlySender("・相手の手札と場札を見る　　(c-vhand) (Talk不可)");
    sendMessageToOnlySender("・枚数配置を見る　　　　　　(c-check)");
    sendMessageToOnlySender("・復活の呪文　　　　　　　　(c-spell[呪文]) (c-spellで呪文の表示)");
    sendMessageToOnlySender("  -- END ---");
  end
  
  def setCardMode()
    return unless( /(\d+)/  =~ @tnick )
    
    @card_place = $1.to_i
    
    if( @card_place > 0 )
      sendMessageToChannels("カード置き場ありに変更しました")
    else
      sendMessageToChannels("カード置き場無しに変更しました")
    end
  end
  
  
  def readCardSet()
    begin
      readExtraCard(@tnick);
      sendMessageToOnlySender("カードセットの読み込み成功しました");
    rescue => e
      sendMessageToOnlySender(e.to_s)
    end
  end
  
  
  def sendMessage(to, message)
    @bcdice.sendMessage(to, message)
  end
  
  def sendMessageToOnlySender(message)
    @bcdice.sendMessageToOnlySender(message)
  end
  
  def sendMessageToChannels(message)
    @bcdice.sendMessageToChannels(message)
  end
  
  
  ###########################################################################
  #**                        ゲーム設定関連
  ###########################################################################
  
  # 専用カードセットのロード
  def readExtraCard(cardFileName)
    return if(cardFileName.nil?)
    return if(cardFileName.empty?)
    
    debug("Loading Cardset『#{cardFileName}』...\n");
    
    @card_val = [];
    
    begin
      lines = File.readlines(cardFileName)
      
      lines.each do |line|
        next unless(/^(\d+)->(.+)$/ =~ line)  # 番号->タイトル
        
        cardNumber = $1.to_i;
        cardTitle = $2;
        @card_val.push(cardNumber);
        @cardTitles[cardNumber] = cardTitle;
      end
      
      @cardRegExp = '[\d]+';    #カード指定文字列の正規表現
      @cardRest = @card_val.clone
      @deal_cards = {'card_played' => []};
      
      debug("Load Finished...\n");
    rescue => e
      raise ("カードデータを開けません :『#{cardFileName}』" + e.to_s)
    end
  end
  
  
  def executeCard(arg, channel)
    @channel = channel
    
    debug('executeCard arg', arg)
    return unless( /(c-)/ =~ arg )
    
    card_ok = 0
    count = 0
    
    case arg
    when /(c-shuffle|c-sh)($|\s)/
      output_msg = shuffleCards
      sendMessage(@channel, output_msg);
      
    when /c-draw(\[[\d]+\])?($|\s)/
      drawCardByCommandText(arg)
      
    when /(c-odraw|c-opend)(\[[\d]+\])?($|\s)/
      value = $2
      drawCardOpen(value)
      
    when /c-hand($|\s)/
      sendMessageToOnlySender(getHandAndPlaceCardInfoText(arg, @nick_e));
      
    when /c-vhand\s*(#{$ircNickRegExp})($|\s)/
      name = $1
      debug("c-vhand name", name)
      messageText = ("#{name} の手札は" + getHandAndPlaceCardInfoText("c-hand", name) + "です")
      sendMessageToOnlySender(messageText);
      
    when /c-play(\d*)\[#{@cardRegExp}(,#{@cardRegExp})*\]($|\s)/
        playCardByCommandText(arg)
      
    when /(c-rshuffle|c-rsh)($|\s)/
      output_msg = returnCards
      sendMessage(@channel, output_msg);
      
    when /c-clean($|\s)/
      output_msg = clearAllPlaceAllPlayerCards
      sendMessage(@channel, output_msg);
      
    when /c-review($|\s)/
      output_msg = reviewCards
      sendMessageToOnlySender(output_msg);
      
    when /c-check($|\s)/
      out_msg, place_msg = getAllCardLocation
      sendMessage(@channel, out_msg);
      sendMessage(@channel, place_msg);
      
    when /c-pass(\d)*(\[#{@cardRegExp}(,#{@cardRegExp})*\])?\s*(#{$ircNickRegExp})($|\s)/
      sendTo = $4
      transferCardsByCommandText(arg, sendTo)
      
    when /c-pick\[#{@cardRegExp}(,#{@cardRegExp})*\]($|\s)/
        pickupCardCommandText(arg)
            # FIXME
    when /c-back(\d)*\[#{@cardRegExp}(,#{@cardRegExp})*\]($|\s)/
        backCardCommandText(arg)
      
    when /c-deal(\[[\d]+\]|\s)\s*(#{$ircNickRegExp})($|\s)/
      count = $1
      targetNick = $2
      dealCard(count, targetNick)
      
    when /c-vdeal(\[[\d]+\]|\s)\s*(#{$ircNickRegExp})($|\s)/
      count = $1
      targetNick = $2
      lookAndDealCard(count, targetNick)
      
    when /c-(dis|discard)(\d)*\[#{@cardRegExp}(,#{@cardRegExp})*\]($|\s)/
      discardCardCommandText(arg)
      
    when /c-place(\d)*(\[#{@cardRegExp}(,#{@cardRegExp})*\])?\s*(#{$ircNickRegExp})($|\s)/
      targetNick = $4
      sendCardToTargetNickPlaceCommandText(arg, targetNick)
      
    when /c-(un)?tap(\d+)\[#{@cardRegExp}(,#{@cardRegExp})*\]($|\s)/
      tapCardCommandText(arg)
      
    when /c-spell(\[([\s,]*(#{$ircNickRegExp}:)?[A-Za-z0-9\+\-\/\*]+)+\])?($|\s)/
        printCardRestorationSpellResult(arg)
      
    when /(c-mil(stone)?(\[[\d]+\])?)($|\s)/
      commandText = $1
      printMilStoneResult(commandText)
    end
  end
  
  ####################            山札関連           ########################
  
  # デッキと手札の初期化
  def shuffleCards
    @cardRest = @card_val.clone
    @deal_cards = {'card_played' => []};
    return "シャッフルしました";
  end

####################             ドロウ            ########################
  def drawCardByCommandText(arg)
    debug("drawCardByCommandText arg", arg)
    
    cards = drawCard(arg);
    debug("drawCardByCommandText cards", cards)
    
    if(cards.length > 0)
      sendMessageToOnlySender(getCardsTextFromCards(cards));
      sendMessage(@channel, "#{@nick_e}: #{cards.length}枚引きました");
    else
      sendMessage(@channel, "カードが残っていません");
    end
    
    @card_channels[@nick_e] ||= @channel
  end
  
  def drawCardOpen(value)
    cmd = "c-draw";
    cmd += value unless( value.nil? )
    
    cards = drawCard(cmd);
    
    if(cards.length > 0)
      sendMessage(@channel, "#{@nick_e}: " + getCardsTextFromCards(cards) + 'を引きました');
    else
      sendMessage(@channel, "カードが残っていません");
    end
    
    @card_channels[@nick_e] ||= @channel
  end
  
  def drawCard(command, destination = nil)
    destination ||= @nick_e
    destination = destination.upcase
    
    debug("drawCard command, destination", command, destination)
    outputCards = []
    
    debug("@cardRest.length", @cardRest.length)
    if(@cardRest.length <= 0)
      return outputCards
    end
    
    unless(/(c-draw(\[([\d]+)\])?)/ =~ command)
      return outputCards
    end
    
    count = $3
    count ||= 1
    count = count.to_i
    debug("draw count", count)
    
    count.times do |i|
      break if(@cardRest.length <= 0)
      
      card = ejectOneCardRandomFromCards(@cardRest)
      break if( card.nil? )
      
      @deal_cards[ destination ] ||= []
      @deal_cards[ destination ] << card
      
      outputCards << card
    end
    
    return outputCards
  end
  
  def pickupCardCommandText(string)
    debug('pickupCardCommandText string', string)
    
    count, output_msg = pickupCard(string)
    if( count > 0 )
      sendMessage(@channel, "#{@nick_e}: #{count}枚選んで引きました");
    end
    if( output_msg != "" )
      sendMessage(@channel, "[" + getCardsText(output_msg) + "]がありません");
    end
    sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto"));
  end
  
  
  def pickupCard(string)
    okCount = 0
    ngCardList = []
    
    if(/(c-pick\[((,)?#{@cardRegExp})+\])/ =~ string)
      cardName = $1
      okCount, ngCardList = pickupCardByCardName(cardName)
    end
    
    ngCardText = ngCardList.join(",")
    
    return okCount, ngCardText;   # 抜き出せた枚数とデッキに無かったカードを返す
  end
  
  def pickupCardByCardName(cardName)
    okCount = 0
    ngCardList = []
    
    if(/\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ cardName)
      cards = $1.split(/,/)
      okCount, ngCardList = pickupCardByCards(cards)
    end
    
    return okCount, ngCardList
  end
  
  def pickupCardByCards(cards)
    okCount = 0
    ngCardList = []
    
    cards.each do |card|
      string = pickupOneCard(card)
      if(string == $okResult)
        okCount += 1;
      else
        ngCardList << string
      end
    end
    
    return okCount, ngCardList
  end
  
  def pickupOneCard(card)
    if(@cardRest.length <= 0)
      return '山札'
    end
    
    targetCard = card.upcase; # デッキから抜き出すカードの指定
    destination = @nick_e.upcase

    isDelete = @cardRest.delete_if{|card| card == targetCard}
    
    if( isDelete )
      @deal_cards[destination] ||= []
      @deal_cards[destination] << targetCard
      return $okResult;
    else
      return targetCard;   # 無かったカードを返す
    end
  end
  
  
  def backCardCommandText(command)
    count, output_msg = backCard(command);
    
    if(count > 0)
      sendMessage(@channel, "#{@nick_e}: #{count}枚戻しました");
    end
    
    if(output_msg != "")
      sendMessage(@channel, "[#{getCardsText(output_msg)}]がありません");
    else
      sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto"));
    end
  end

  def backCard(command)
    okCount = 0;
    ngCards = []
    
    if(/(c-back(\d*)\[((,)?#{@cardRegExp})+\])/ =~ command)
      commandset = $1;
      place = $2.to_i
      okCount, ngCards = backCardByCommandSetAndPlace(commandset, place)
    end
    
    return okCount, ngCards.join(',')
  end
  
  def backCardByCommandSetAndPlace(commandset, place)
    okCount = 0;
    ngCards = []
    destination = @nick_e.upcase
    
    if( /\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ commandset )
      cards = $1.split(/,/)
      
      cards.each do |card|
        string = backOneCard(card, destination, place);
        if(string == $okResult)
          okCount += 1;
        else
          ngCards << string
        end
      end
    end
    
    return okCount, ngCards;   # 戻せた枚数とNGだったカードを返す
  end
  
  def backOneCard(targetCard, destination, place)
    if(getBurriedCard <= 0)
        return '捨て札';    # 捨て札が無い
    end
    
    
    targetCard = targetCard.upcase
    
    if(@card_place > 0)   # 場があるときのみ処理
      string = transferOneCard(targetCard, "#{place}#{destination}", destination);   # 場から手札への移動
      return $okResult if(string == $okResult);
    end
    
    @deal_cards['card_played'] ||= []
    cards = @deal_cards['card_played']
    isDelete = cards.delete_if{|i| i == targetCard}
    
    if( isDelete )
      @deal_cards[destination] << targetCard
      return $okResult;
    end
    
    return "${targetCard}"; # 戻せるカードが無かったらNGのカードを返す
  end

  
  def dealCard(count, targetNick, isLook = false)
    debug("dealCard count, targetNick", count, targetNick)
    
    cards = drawCard("c-draw#{count}", targetNick);
    if(cards.length > 0)
      sendDealResult(targetNick, count, getCardsTextFromCards(cards), isLook)
    else
      sendMessage(@channel, "カードが残っていません");
    end
    
    @card_channels[targetNick] ||= @channel
    
    return count
  end
  
  def sendDealResult(targetNick, count, output_msg, isLook)
    sendMessage(targetNick, output_msg);
    if( isLook )
      sendMessage(@nick_e, "#{targetNick} に #{output_msg} を配りました")
    end
    sendMessage(@channel, "#{@nick_e}: #{targetNick}に#{count}枚配りました")
  end

  def lookAndDealCard(count, targetNick)
    isLook = true
    dealCard(count, targetNick, isLook)
  end
  
  def discardCardCommandText(commandText)
    count, output_msg, card_ok = discardCards(commandText)
    
    if(count > 0)
      sendMessage(@channel, "#{@nick_e}: #{count}枚捨てました");
      
      unless( @cardTitles.empty? )
        cardText = getCardsText($card_ok)
        sendMessage(@channel, "[#{cardText}]")
      end
    end
    
    if(output_msg != "")
      cardText = getCardsText(output_msg)
      sendMessageToOnlySender("[#{cardText}]がありません");
    else
      sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto"));
    end
  end
  
  
####################             プレイ            ########################
  def playCardByCommandText(arg)
    debug('c-play pattern', arg)
    
    count, output_msg, card_ok = playCard(arg);
    if( count > 0 )
      sendMessage(@channel, "#{@nick_e}: #{count}枚出しました");
      sendMessage(@channel, "[" + getCardsText($card_ok) + "]") unless( @cardTitles.empty? )
    end
    if( output_msg != "")
      debug("output_msg", output_msg)
      sendMessage(@channel, "[" + getCardsText(output_msg) + "]は持っていません");
    end
    sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto", @nick_e));
  end
  
  
  def playCard(cardPlayCommandText)
    debug('playCard cardPlayCommandText', cardPlayCommandText)
    
    okCardCount = 0
    okCardList = []
    ngCardList = []
    
    if(/(c-play(\d*)\[((,)?#{@cardRegExp})+\])/ =~ cardPlayCommandText)
      cardsBlockText = $1
      place = $2.to_i
      debug("cardsBlockText", cardsBlockText)
      debug("place", place)
      okCardList, ngCardList = playCardByCardsBlockTextAndPlaceNo(cardsBlockText, place)
      debug("okCardList", okCardList)
      debug("ngCardList", ngCardList)
      
      okCardCount = okCardList.length
      okCardText = okCardList.join(',')
      ngCardText = ngCardList.join(',')
    end
    
    
    # 出せた枚数、NGだったカード、出せたカード
    return okCardCount, ngCardText, okCardText
  end
  
  
  def playCardByCardsBlockTextAndPlaceNo(cardsBlockText, place)
    okCardList = []
    ngCardList = []
    
    if(/\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ cardsBlockText)
      cardsText = $1
      okCardList, ngCardList = playCardByCardsTextAndPlaceNo(cardsText, place)
    end
    
    return okCardList, ngCardList
  end
  
  def playCardByCardsTextAndPlaceNo(cardsText, place)
    cards = cardsText.split(/,/)
    
    okCardList = []
    ngCardList = []
    
    cards.each do |card|
      okList, ngList = playCardByCardAndPlaceNo(card, place)
      
      okCardList += okList
      ngCardList += ngList
    end
    
    return okCardList, ngCardList
  end
  
  def playCardByCardAndPlaceNo(card, place)
    debug("playCardByCardAndPlaceNo card, place", card, place)
    
    okList = []
    ngList = []
    
    result = playOneCard(card, place)
    debug("playOneCard result", result)
    
    if(result == $okResult)
      okList << card;
    else
      ngList << result
    end
    
    return okList, ngList
  end
  
  def playOneCard(card, place)
    debug("playOneCard card, place", card, place)
    
    destination = @nick_e.upcase
    result = "";
    
    if(place > 0)
      debug("playOneCard place > 0")
      result = transferOneCard(card, destination, "#{place}#{destination}" ); # 場に出す処理
    else
      debug("playOneCard place <= 0")
      result = discardOneCard(card, place, destination);    # 場を使わないときは捨て札扱い
    end
    
    if(result == $okResult)
      return result
    else
      return card
    end
  end
  
  def discardCards(command, destination = nil)
    debug("discardCards command, destination", command, destination)
    
    destination = @nick_e if( destination.nil? )
    destination = destination.upcase
    
    okList = []
    ngList = []
    
    if(/(c-(dis|discard)(\d*)\[((,)?#{@cardRegExp})+\])/ =~ command)
      debug("discardCards reg OK")
      commandSet = $1;
      place = $3.to_i
      okList, ngList = discardCardsByCommandSetAndPlaceAndDestination(commandSet, place, destination)
    end
    
    ngText = ngList.join(',')
    okText = okList.join(',')
    
    return okList.length, ngText, okText
  end
  
  def discardCardsByCommandSetAndPlaceAndDestination(commandSet, place, destination)
    okList = []
    ngList = []
    
    if(/\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ commandSet)
      cards = $1.split(/,/)
      okList, ngList = discardCardsByCardsAndPlace(cards, place, destination)
    end
    
    return okList, ngList
  end

  def discardCardsByCardsAndPlace(cards, place, destination)
    okList = []
    ngList = []
    
    cards.each do |card|
      result = discardOneCard(card, place, destination);
      
      if(result == $okResult)
        okList << card
      else
        ngList << result
      end
    end
    
    return okList, ngList
  end
  

  def discardOneCard(card, place, destination)
    card = card.upcase
    destination = destination.upcase
    destination = getDestinationWhenPlaceIsNotHand(place, destination)
    
    this_cards = []
    rest_cards = []
    
    temp_cards = getCardsFromDealCards(destination)
    
    
    result = temp_cards.reject! {|i| i == card}
    isTargetCardInHand = ( not result.nil? )
    if( isTargetCardInHand )
      this_cards << card
    else
      rest_cards << card
    end
    
    debug("isTargetCardInHand", isTargetCardInHand)
    
    if( isTargetCardInHand )
      debug("isTargetCardInHand OK, so set card info")
      @deal_cards[destination] ||= []
      @deal_cards[destination] += rest_cards
      @deal_cards['card_played'] ||= []
      @deal_cards['card_played'] += this_cards
      debug("@deal_cards", @deal_cards)
      
      return $okResult;
    else
      return card;   # 指定のカードが無いので、無いカードを返す
    end
  end
  
  def getDestinationWhenPlaceIsNotHand(place, destination)
    if(place > 0)
      # 場札から出すときは「出した人」を場札に書き替え
      destination = "#{place}#{destination}"
      return destination
    end
    
    return destination
  end
  
  def getCardsFromDealCards(destination)
    debug('getCardsFromDealCards destination', destination)
    debug('@deal_cards', @deal_cards)
    debug('@deal_cards[destination]', @deal_cards[destination])
    
    if( @deal_cards[destination].nil? )
      debug('getCardsFromDealCards empty')
      return []
    end
    
    cards = @deal_cards[destination]
    debug('getCardsFromDealCards cards', cards)
    return cards
  end
  
####################              パス             ########################
  
  def transferCardsByCommandText(commandText, sendTo)
    debug("transferCardsByCommandText commandText, sendTo", commandText, sendTo)
    count, output_msg = transferCards(commandText);
    
    if( count < 0 )
      sendMessage(@channel, "#{@nick_e}: 相手が登録されていません");
    else
      if( output_msg != "" )
        sendMessage(@channel, "[" + getCardsText(output_msg) + "]がありません");
      end
      if( count > 0 )
        sendMessage(@channel, "#{@nick_e}: #{count}枚渡しました");
        debug('transferCardsByCommandText sendTo', sendTo)
        sendMessage(sendTo, getHandAndPlaceCardInfoText("Auto", sendTo));
      end
    end
    
    sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto"));
  end
  
  def transferCards(command)
    debug('transferCards command', command)
    
    okCount = 0;
    ngCardList = []
    
    if(/(c-pass(\d*)(\[(((,)?#{@cardRegExp})*)\])?)\s*(#{$ircNickRegExp})/ =~ command)
      destination = $7.upcase
      commandset = $1;
      place = $2.to_i
      place ||= 0
      okCount, ngCardList = transferCardsByCommand(commandset, place, destination)
      
      debug('transferCardsByCommand resutl okCount, ngCardList', okCount, ngCardList)
    end
    
    ngCardText = ngCardList.join(",")
    return okCount, ngCardText;  # 渡せた枚数とNGなカードを返す
  end
  
  def transferCardsByCommand(commandset, place, destination)
    debug('transferCardsByCommand commandset, place, destination', commandset, place, destination)
    
    nick_e = @nick_e
    
    if(place > 0);
      nick_e = "#{place}#{nick_e}"
    end
    
    okCount = 0
    ngCardList = []
    debug('LINE', __LINE__)
    
    cards = ['']
    if(/\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ commandset)
      cards = $1.split(/,/) 
    end
    
    debug('transferCardsByCommand cards', cards)
    okCount, ngCardList = transferCardsByCards(cards, destination, nick_e)
    
    debug('LINE', __LINE__)
    
    return okCount, ngCardList
  end
  
  def transferCardsByCards(cards, destination, nick_e)
    okCount = 0
    ngCardList = []
    
    cards.each do |card|
      debug('transferCardsByCards card', card)
      result = transferOneCard(card, nick_e, destination)
      
      debug('transferOneCard result', result)
      
      case result
      when $ngResult
        return -1, ['渡す相手が登録されていません']
      when $okResult
        okCount += 1;
      else
        ngCardList << result
      end
    end
    
    return okCount, ngCardList
  end
  
  def transferOneCard(card, from, toSend);
    debug('transferOneCard card, from, toSend', card, from, toSend)
    
    targetCard = card.upcase
    toSend = toSend.upcase
    from = from.upcase
    
    isTargetCardInHand = false;
    restCards = []
    thisCard = "";
    
    @deal_cards[from] ||= []
    cards = @deal_cards[from]
    debug("from, cards, @deal_cards", from, cards, @deal_cards)
    
    if(targetCard == '')
      debug("カード指定がないのでランダムで一枚渡す")
      thisCard = ejectOneCardRandomFromCards(cards)
      isTargetCardInHand = true
      restCards = @deal_cards[from]
    else
      debug("カード指定あり targetCard", targetCard)
      thisCard, restCards, isTargetCardInHand =
        transferTargetCard(targetCard, cards, toSend, from)
    end
    
    debug("transferOneCard isTargetCardInHand", isTargetCardInHand)
    
    if( not isTargetCardInHand )
      return targetCard;
    end
    
    debug("transferOneCard @deal_cards", @deal_cards)
    debug("transferOneCard toSend", toSend)
    
    if( @deal_cards[toSend] )
      debug('相手は登録済み')
      @deal_cards[toSend] << thisCard
    else
      debug('相手は未登録済み')
      isSuccess = transferTargetCardToNewMember(toSend, thisCard)
      return $ngResult unless( isSuccess )
    end
    
    @deal_cards[from] = restCards
    debug("transferOneCard @deal_cards", @deal_cards)
    
    return $okResult;
  end
  
  
  def ejectOneCardRandomFromCards(cards)
    debug('ejectOneCardRandomFromCards cards.length', cards.length)
    
    return nil if( cards.empty? )
    
    cardNumber, dummy = @bcdice.roll(1, cards.length);
    cardNumber -= 1
    debug("cardNumber", cardNumber)
    
    card = cards.delete_at(cardNumber)
    debug("card", card)
    
    return card
  end
  
  def transferTargetCard(targetCard, cards, toSend, from)
    debug('transferTargetCard(targetCard, cards, toSend, from)', targetCard, cards, toSend, from)
    
    thisCard = ""
    restCards = []
    isTargetCardInHand = false
    
    cards.each do |card|
      if((not isTargetCardInHand) and(card == targetCard))
        isTargetCardInHand = true
        thisCard = card
      else 
        restCards << card
      end
    end
    
    debug("restCards", restCards)
    return thisCard, restCards, isTargetCardInHand
  end
  
  def transferTargetCardToNewMember(destination, thisCard)
    isSuccess = false;
    
    if(@card_place > 0)
      
      if(/^\d+(.+)/ =~ destination)
        #渡すNickが数字で始まっていたら、場に出す処理の最初の一枚目
        placeName = $1
        if( @deal_cards[placeName] )
          #手札は登録されていたら宛先間違いではない
          @deal_cards[destination] ||= []
          @deal_cards[destination] << thisCard
          isSuccess = true;
        end
      end
    end
    
    return isSuccess
  end
  
  

  def sendCardToTargetNickPlaceCommandText(commandText, targetNick)
    debug('sendCardToTargetNickPlaceCommandText commandText, targetNick', commandText, targetNick)
    okCardList, ngCardList = getSendCardToTargetNickPlace(commandText, targetNick)
    debug('getSendCardToTargetNickPlace okCardList, ngCardList', okCardList, ngCardList)

    if(okCardList.length < 0)

      sendMessage(@channel, "#{@nick_e}: 相手が登録されていません");
      return;
    end
    
    unless( ngCardList.empty? )
      ngCardText = getCardsTextFromCards(ngCardList)
      sendMessage(@channel, "[#{ngCardText}]がありません");
      return;
    end
    
    if(okCardList.length > 0)
      printRegistCardResult(targetNick, okCards)
    end
    
    sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto"));
  end
  
  #相手の場にカードを置く
  def getSendCardToTargetNickPlace(commandText, nick_e)
    ngCardList = []
    okCardList = []
    
    debug("commandText", commandText)
    if(/(c-place(\d*)(\[(((,)?#{@cardRegExp})*)\])?)\s*(#{$ircNickRegExp})/ =~ commandText)
      cardset = $1;
      placeNumber = $2.to_i
      destination = $7.upcase
      
      getSendCardToTargetNickPlaceByCardSetAndDestination(cardset, placeNumber, destination)
    end
    
    return okCardList, ngCardList
  end
  
  def getSendCardToTargetNickPlaceByCardSetAndDestination(cardset, placeNumber, destination)
    debug('getSendCardToTargetNickPlaceByCardSetAndDestination cardset, placeNumber, destination', cardset, placeNumber, destination)
    
    debug("今のところ場が１つしかないので相手の場は決めうち")
    toSend = "1#{destination}"
    debug("toSend", toSend)
    
    from = @nick_e
    if( placeNumber > 0 )
      from = "#{placeNumber}#{from}"
    end
    debug("from", from)
    
    if( /\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ cardset )
      cards = $1.split(/,/)
      okCardList, ngCardList = getSendCardToTargetNickPlaceByCards(cards, from, toSend)
    end
    
    return okCardList, ngCardList
  end
    
  def getSendCardToTargetNickPlaceByCards(cards, destination, toSend)
    debug("getSendCardToTargetNickPlaceByCards cards, destination, toSend", destination, toSend)
    okCardList = []
    ngCardList = []
    
    cards.each do |card|
      result = transferOneCard(card, destination, toSend)
      
      case result
      when $ngResult
        return -1, '渡す相手が登録されていません';
      when $okResult
        okCardList << card
      else
        ngCardList << result
      end
    end
    
    return okCardList, ngCardList
  end
  
  
  def printRegistCardResult(targetNick, okCards)
    sendMessage(@channel, "#{@nick_e}: #{ okCards.length }枚場に置きました");
    
    unless( @cardTitles.empty? )
      cardText = getCardsTextFromCards(okCards)
      sendMessage(@channel, "[#{cardText}]")
    end
    
    sendMessage(targetNick, getHandAndPlaceCardInfoText("Auto", targetNick));
  end
  
####################             タップ            ########################
  def tapCardCommandText(commandText)
    debug("tapCardCommandText commandText", commandText)
    
    okList, ngList, isUntap = tapCard(commandText);
    
    if(okList.length > 0)
      tapTypeName = ( isUntap ? 'アンタップ' : 'タップ');
      sendMessage(@channel, "#{@nick_e}: #{okList.length}枚#{tapTypeName}しました");
      sendMessage(@channel, "[#{getCardsTextFromCards(okList)}]") unless( @cardTitles.empty? )
    end
    
    if(ngList.length > 0)
      sendMessage(@channel, "[#{getCardsTextFromCards(ngList)}]は場にありません");
    end
    
    sendMessageToOnlySender(getHandAndPlaceCardInfoText("Auto", @nick_e));
  end
  
  def tapCard(command)
    okCardList = []
    ngCardList = []
    
    unless(@canTapCard and @card_place)
      return okCardList, ngCardList
    end
    
    unless( /(c-(un)?tap(\d+)\[((,)?#{@cardRegExp})+\])/ =~ command )
      return okCardList, ngCardList
    end
    
    place = $3.to_i;
    isUntap = $2
    cardsText = $1
    
    okCardList, ngCardList = tapCardByCardsTextAndPlace(cardsText, place, isUntap)
    return okCardList, ngCardList, isUntap
  end
  
  def tapCardByCardsTextAndPlace(cardsText, place, isUntap)
    okCardList = []
    ngCardList = []
    
    if( /\[(#{@cardRegExp}(,#{@cardRegExp})*)\]/ =~ cardsText)
      cards = $1.split(/,/)
      cards.each do |card|
        okCard, ngCard = tapOneCardByCardAndPlace(card, place, isUntap);
        
        okCardList << okCard unless(okCard.nil?)
        ngCardList << ngCard unless(ngCard.nil?)
      end
    end
    
    return okCardList, ngCardList;
  end
  
  def tapOneCardByCardAndPlace(card, place, isUntap);
    card = card.upcase
    result = ""
    
    # return result unless(@canTapCard > 0)
    # タップ処理をカードの場の移動で扱う(90度タップ、180度タップが将来必要になるかも)
    
    @nick_e = @nick_e.upcase
    
    nick_to = ""
    if( isUntap )
      destination = "#{place * 2 - 1}#{@nick_e}"
      nick_to = "#{place * 2}#{@nick_e}"
    else
      destination = "#{place * 2}#{@nick_e}"
      nick_to = "#{place * 2 - 1}#{@nick_e}"
    end
    
    result = transferOneCard(card, nick_to, destination)
    
    if( result == $okResult )
      return card, nil
    else
      return nil, card
    end
  end

####################            山札関連           ########################
  def printMilStoneResult(commandText)
    count, output_msg = getCardMilstone(commandText)

    if(count > 0)
      sendMessage(@channel, "#{@nick_e}: #{getCardsText(output_msg)}が出ました");
    else
      sendMessage(@channel, "カードが残っていません");
    end
  end
  
  # 山からカードをめくって即座に捨てる
  def getCardMilstone(commandText)
    command = "c-draw";
    count = 0
    if( /\[(\d+)\]/ =~ commandText )
      count = $1.to_i
      command += "[#{count}]"
    end
    
    cards = drawCard(command)
    debug("cards", cards)
    
    text = ""
    
    if(cards.length > 0)
      cardInfo = getCardsTextFromCards(cards)
      okCount, ngCount, text = discardCards("c-discard[#{ cardInfo }]")
      debug("discardCards okCount, ngCount, text", okCount, ngCount, text)
      count = okCount
    else
      count = 0;
    end
    
    debug("count", count)
    debug("cardInfo", cardInfo)
    
    return count, cardInfo;    # めくれた枚数と出たカードを返す
  end
  

  # 全員の場に出たカードを捨てる（手札はそのまま）
  def clearAllPlaceAllPlayerCards
    @deal_cards.each do |place, cards|
      clearAllPlayerCardsWhenPlayedPlace(place, cards)
    end
    
    return '場のカードを捨てました';
  end

  def clearAllPlayerCardsWhenPlayedPlace(place, cards)
    if(place =~ /^\d+/)  # 最初が数値=場に出ているカードなので、カードを全部捨てて場も削除
      clearAllPlayerCards(place, cards)
    end
  end
  
  def clearAllPlayerCards(place, cards)
    cardset = cards.join(',')
    discardCards("c-discard[#{cardset}]", place);
    
    @deal_cards[place] ||= []
    @deal_cards[place].clear
  end
  
  
  # 捨て札をデッキに戻す
  def returnCards
    @deal_cards[ 'card_played' ] ||= []
    cards = @deal_cards[ 'card_played' ]

    while(cards.length > 0)
      @cardRest.push(cards.shift)
    end
    
    return "捨て札を山に戻しました";
  end
  
  def getBurriedCard
    @deal_cards[ 'card_played' ] ||= []
    cards = @deal_cards[ 'card_played' ]
    
    cards.length
  end
  
####################             その他            ########################
  def reviewCards
    @cardRest.join(',')
  end
  
  def getAllCardLocation   # 今のカード配置を見る
    allText = "山札:#{ @cardRest.length }枚 捨札:#{ getBurriedCard }枚";
    allPlaceText = "";
    
    @deal_cards.each do |place, cards|
      next if(place == 'card_played')
      
      text, placeText = getCardLocationOnPlace(place, cards)
      allText += text
      allPlaceText += placeText
    end
    
    return allText, allPlaceText;   # 山札＆捨て札＆各自の手札枚数表示 と 各自の場札表示の配列を返す。(表示レイアウトの関係)
  end
  
  def getCardLocationOnPlace(place, cards)
    text = ""
    placeText = ""
    
    if(place =~ /^(\d+)(#{$ircNickRegExp})/)
      placeNumber = $1;
      cnick = $2;
      placeText = getCardLocationOnNumberdPlace(cards, placeNumber, cnick)
    else
      text = " #{place}:#{cards.length}枚";
    end
    
    return text, placeText
  end
  
  def getCardLocationOnNumberdPlace(cards, placeNumber, cnick)
    cardText = getCardsText(cards)
    if( isTapCardPlace(placeNumber) )
      return " #{cnick}のタップした場札:#{cardText}"
    else
      return " #{cnick}の場札:#{cardText}";
    end
  end
    
  def getHandAndPlaceCardInfoText(str, destination = nil)    # 自分の手札と場札の確認
    debug("getHandAndPlaceCardInfoText(str, destination)", str, destination)
    
    destination = @nick_e if( destination.nil? )
    destination = destination.upcase
    
    hand = getHandCardInfoText(destination)
    debug("hand", hand)
    
    place = getPlaceCardInfoText(destination)
    debug("place", place)
    
    return hand + place
  end
  
  
  def getHandCardInfoText(destination)
    destination = destination.upcase
    debug("getHandCardInfoText destination", destination)
    
    out_msg = getDealCardsText(destination)
    
    if( out_msg.empty? )
      out_msg = "カードを持っていません";
    end
    
    return out_msg
  end
  
  
  def getDealCardsText(destination)
    debug("getDealCardsText destination", destination)
    
    cards = @deal_cards[destination]
    debug("@deal_cards", @deal_cards)
    debug("getDealCardsText cards", cards)
    
    return '' if( cards.nil? )
    
    cardsText = getCardsTextFromCards(cards)
    
    return "[ #{cardsText} ]";
  end

  # ソートサブルーチン
  def compareCard(a, b)
    if(a =~ /[^\d]/)
      compareCardByCardNumber(a, b)
    else
      a <=> b
    end
  end
  
  def compareCardByCardNumber(a, b)
    /([^\d]+)(\d+)/ =~ a
    a1 = $1;
    a2 = $2;
    
    /([^\d]+)(\d+)/ =~ b
    b1 = $1;
    b2 = $2;
    
    result = [a1, a2] <=> [b1, b2]
    
    return result
  end


  def getPlaceCardInfoText(destination)
    destination = destination.upcase
    
    out_msg = "";
    
    unless( @card_place > 0 )
      return out_msg
    end
    
    place_max = @card_place;
    place_max *= 2 if(@canTapCard);
    
    debug("place_max", place_max)
    place_max.times do |i|
      index = i + 1
      
      dealCardsKey = "#{index}#{destination}"
      debug("dealCardsKey", dealCardsKey)
      
      cards = @deal_cards[dealCardsKey]
      cards ||= []
      
      cardsText = getCardsTextFromCards(cards);
      
      if( isTapCardPlace(index) )
        out_msg += " タップした場札:[ #{cardsText} ]";
      else
        out_msg += " 場札:[ #{cardsText} ]";
      end
    end
    
    return out_msg;
  end
  
  def getCardsText(cardsText)    # 汎用カードセット用カードタイトルの表示
    cards = cardsText.split(/,/)
    return getCardsTextFromCards(cards)
  end
  
  def getCardsTextFromCards(cards)
    if( $isHandSort )
      cards = cards.sort{|a, b| compareCard(a, b)}
    end
    
    if( @cardTitles.empty? )
      return cards.join(',')
    end
    
    out_msg = "";
    
    cards.each do |cardNumber|
      out_msg += "," if(out_msg != "");
      title = @cardTitles[cardNumber]
      out_msg += "#{cardNumber}-#{title}"
    end
    
    out_msg = '無し' if(out_msg == "");
  
    return out_msg;
  end
  
  def isTapCardPlace(index)
    return false unless(@canTapCard)
    
    return ((index % 2) == 0)
  end

####################           復活の呪文          ########################
  
  def printCardRestorationSpellResult(commandText)
    output_msg = throwCardRestorationSpell(commandText);
    if(output_msg == "readSpell")
      sendMessage(@channel, "#{@nick_e}: カード配置を復活しました");
    else
      sendMessage(@channel, output_msg);
    end
  end
  
  
  def throwCardRestorationSpell(command)
    output = '0';
    
    unless( /c-spell(\[(([\s,]?(#{$ircNickRegExp}:)?[A-Za-z0-9\+\-\/\*]+)+)\])?/ =~ command)
      return output
    end
    
    spellText = $2
    
    debug("spellText", spellText)
    
    # 呪文の取得
    if( not spellText )
      debug("getNewSpellText")
      output = getNewSpellText()
    else    # 呪文の実行
      debug("setNewSpellText")
      output, dummy = setNewSpellText( spellText )
    end
    
    return output; # 結果を返す
  end
  
  def getNewSpellText
    debug("getNewSpellText begin")
    
    output = ""
    
    @deal_cards.each do |place, cards|
      debug("getNewSpellText place, cards", place, cards)
      next if( cards.length == 0 )   # カードを持っていない人は除外(呪文短縮のため)
      
      cardSpell = getSpellTextFromCards(cards)
      debug("cardSpell", cardSpell)
      
      output += "," unless( output.empty? )
      output += "#{place}:#{cardSpell}"
    end
    
    output = "復活の呪文 ＞ [#{output}]";    # 呪文表示を返す
    
    return output
  end
  
  def getSpellTextFromCards(cards)
    debug("getSpellTextFromCards cards", cards)
    
    #カードが存在するかを @card_val でチェックしたリスト
    exists = getExistsFromCards(cards)
    text = get64DecimalTextFromExists(exists)
    
    debug("getSpellTextFromCards text", text)
    return text
  end
  
  def getExistsFromCards(cards)
    debug("getExistsFromCards cards", cards)
    exists = []
    
    @card_val.each do |card|
      isFind = cards.find{|i| i == card}
      exist = (isFind ? true : false)
      
      exists << exist
    end
    
    debug("getExistsFromCards exists", exists)
    return exists
  end
  
  def get64DecimalTextFromExists(exists)
    #カードの存在是非を64進数の文字(@card_spellで定義)に変換するための処理
    text = ""
    
    #64進数は32bitなのでここで定義
    bits = 6
    
    loopCount = exists.length / bits
    loopCount += 1 if( (exists.length % bits) > 0 )
    
    loopCount.times do |i|
      value = 0
      bits.times do |bitIndex|
        index = i * bits + bitIndex
        exist = exists[index]
        break if( exist.nil? )
        
        debug("exist", exist)
        if( exist )
          pow = (2 ** bitIndex)
          debug("bitIndex, pow", bitIndex, pow)
          value += pow
        end
      end
      
      debug("value", value)
      character = @card_spell[value]
      debug("character", character)
      text << character
    end
    
    debug("get64DecimalTextFromExists end text", text)
    debug("get64DecimalTextFromExists end text.length", text.length)
    
    return text
  end
  
  
  def setNewSpellText(spellText)
    shuffleCards()
    
    output = ''
    spellList = spellText.gsub(/\s/, '').split(',')
    
    spellList.each do |spellText|
      name, spell = spellText.split(":")
      output = readSpell(name, spell)
    end
    
    return output, ""
  end
  
  def readSpell(name, spell)
    debug("readSpell name, spell", name, spell)
    
    exists = getExistsFrom64DecimalText(spell)
    debug("exists.size", exists.size)
    
    cards = getCardsFromCardRestByExists(exists)
    debug("cards.size", cards.size)
    debug("readSpell cards", cards)
    
    @deal_cards[name] = cards
    
    return "readSpell"
  end
  
  def getExistsFrom64DecimalText(text)
    debug("getExistsFrom64DecimalText begin text", text)
    exists = []
    
    #64進数は32bitなのでここで定義
    bits = 6
    
    text.length.times do |textIndex|
      character = text[textIndex, 1]
      value = @card_spell.index(character)
      
      raise "invalid spell text \"#{character}\"" if( value.nil? )
      
      bits.times do |i|
        bit = (value % 2)
        exist = (bit == 1)
        exists << exist
        value = value / 2
      end
    end
    
    debug("getExistsFrom64DecimalText end exists", exists)
    return exists
  end
  
  def getCardsFromCardRestByExists(exists)
    cards = []
    
    exists.each_with_index do |exist, index|
      next unless( exist )
      card = @card_val[index]
      isDelete = @cardRest.delete_if{|i| i == card}
      next unless( isDelete )
      cards << card
    end
    
    return cards
  end
  
  def getNewSpellText_old
    spellCheckArray = getSpellCheckText()
    
    # まずは出たカードと呪文短縮用文字列の取得
    spell, spellCheckArray = makeSpell(@deal_cards['card_played'], spellCheckArray);
    shortSpell, spellCheckArray = getShotSpell(spellCheckArray)
    
    spellText = spell
    unless( shortSpell.empty? )
      spellText = "#{spell},SPELL_SHORTER:#{shortSpell}"
    end
    output = "#{spellText}#{output}"
    
    @deal_cards.each do |place, cards|
      next if(place == 'card_played')
      next if( cards.length == 0 )   # カードを持っていない人は除外(呪文短縮のため)
      
      cardSpell, spellCheckArray = makeSpell(cards, spellCheckArray);
      output += ",#{place}:#{cardSpell}"
    end
    
    output = "復活の呪文 ＞ [#{output}]";    # 呪文表示を返す
  end
  
  def getSpellCheckText
    Array.new(@card_val.length, 0)
  end
  
  def getShotSpell(spellCheckArray)
    return '', spellCheckArray unless(@isShortSpell)
    
    return makeSpell(@cardRest, spellCheckArray);
  end
  
  def makeSpell(cards, spellCheckArray)    # 実際の呪文作成
    debug("makeSpell(cards, spellCheckArray)", cards, spellCheckArray)
    spellCheckArrayOriginal = spellCheckArray.clone
    hitArray = spellCheckArray
    
    dst_arr, hitArray = setCardBit(cards, hitArray)
    
    if(@isShortSpell)  # 呪文を短くするために既出のカードのビットを抜く
      dst_arr = makeSpellInShort(dst_arr, spellCheckArrayOriginal)
      spellCheckArray = hitArray.clone
    end
    
    bitSize = 6
    bitSize.times{ dst_arr.push(0) }
    
    spellText = getSpellTextFrom_dst_arr(dst_arr, bitSize)
    
    debug("makeSpell return spellText, spellCheckArray", spellText, spellCheckArray)
    return spellText, spellCheckArray
  end
  
  
  def setCardBit(cards, hitArray)
    dst_arr = Array.new(@card_val.length, 0)
    
    cards.each do |card|
      i = @card_val.index(card)
      dst_arr[i] = 1;
      hitArray[i] = 1;
    end
    
    return dst_arr, hitArray
  end
  
  def makeSpellInShort(dst_arr, spellCheckArrayOriginal)
    dst_now = []
      
    dst_arr.each_with_index do |dst_arr_item, i|
      next if(spellCheckArrayOriginal[i] == "1")
      dst_now.push(dst_arr_item)
    end

    return dst_now
  end
  
  
  def getSpellTextFrom_dst_arr(dst_arr, bitSize)
    spellText = ''
    
    loopCount = dst_arr.length / bitSize
    
    # 6bitごとに刻んで処理する
    loopCount.times do |i|
      spellCharacterIndex =
        dst_arr[i * 6 + 0]
      + dst_arr[i * 6 + 1] * 2
      + dst_arr[i * 6 + 2] * (2**2)
      + dst_arr[i * 6 + 3] * (2**3)
      + dst_arr[i * 6 + 4] * (2**4)
      + dst_arr[i * 6 + 5] * (2**5);
      
      spellText += @card_spell[ spellCharacterIndex ];
    end
    
    return spellText
  end
  
  
  def setNewSpellText_old(spellText)
    shuffleCards()
    
    spellCheckArray = getSpellCheckText()
    
    output = ''
    spellList = spellText.gsub(/\s/, '').split(',')
    
    spellList.each do |spell|
      output, spellCheckArray = readSpell(spell, spellCheckArray);
    end
    
    return output, spellCheckArray
  end
  
  
=begin
  def readSpell(spell, spellCheckArray)
    
    dst, card = getDstAndCardFromSpell(spell)
    card_src = spellCheckArray.split(/,/)
    card_arr = []
    
    
    my @card_dst = card_src;
    my $out_msg = '0';

    for(my $i=0; $i<length($card); $i++)
        my $word = substr($card, $i, 1);
        my $bit6 = 0;
        for(my $i2=0; $i2 < scalar @card_spell; $i2++)
            if($card_spell[$i2] == $word)
                $bit6 = $i2;
                last;
            end
        end
        my $work = int($bit6 / 2);
        for(my $i2=0; $i2 < 6; $i2++)
            if($bit6-$work*2 >= 1)
              card_arr[$i*6 + $i2] = 1;
            else
              card_arr[$i*6 + $i2] = 0;
            end
            $bit6 = $work;
            $work = int($bit6 / 2);
        end
    end
    if(@isShortSpell)  # 短くなっている呪文を戻す
        my @dst_now;
        for(my $i3=0; $i3 < scalar @card_val; $i3++)
            if(card_src[$i3] != "0")
                push(@dst_now, 0);
            else
                push(@dst_now, shift card_arr);
            end
        end
      card_arr = @dst_now;
    end
    for(my $i = 0; $i < (scalar @card_val); $i++)
        if(card_arr[$i] == 1)
            my $card_no = 0;
            my $card_ok = 0;
            foreach my $card_re (@cardRest)
                if($card_val[$i] == $card_re)
                    $card_ok = 1;
                    $card_dst[$i] = "1";
                    last;
                end
                $card_no+= 1;
            end
            if($card_ok)
                if($dst != 'SPELL_SHORTER')   # 呪文短縮用データはカード配置処理不要
                    $deal_cards{$dst} += "$card_val[$i],";
                    splice @cardRest, $card_no,1;
                end
            else
                $out_msg = '呪文が違います';
            end
        end
    end
    spellCheckArray = join(",", @card_dst) if(@isShortSpell);
    return($out_msg, spellCheckArray);    # 結果と今まで出たカードリストを返す(短縮呪文展開用)
end
=end

  def getDstAndCardFromSpell(spell)
    dst = 'card_played';
    card = spell
    if( spell.include(':') )
      dst, card, *dummy= spell.split(/:/);
    end
    
    return dst, card
  end

end
