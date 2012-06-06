#--*-coding:utf-8-*--

class DiceBot
  @@bcdice = nil
  
  @@DEFAULT_SEND_MODE = 2;                  # デフォルトの送信形式(0=結果のみ,1=0+式,2=1+ダイス個別)

  
  def initialize
    @sendMode = @@DEFAULT_SEND_MODE #(0=結果のみ,1=0+式,2=1+ダイス個別)
    @sortType = 0;      #ソート設定(1 = ?, 2 = ??, 3 = 1&2　各値の意味が不明です…）
    @sameDiceRerollCount = 0;     #ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
    @sameDiceRerollType = 0;   #ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
    @d66Type = 0;        #d66の差し替え
    @isPrintMaxDice = false;      #最大値表示
    @upplerRollThreshold = 0;      #上方無限
    @unlimitedRollDiceType = 0;    #無限ロールのダイス
    @rerollNumber = 0;      #振り足しする条件
    @defaultSuccessTarget = "";      #目標値が空欄の時の目標値
    @rerollLimitCount = 0;    #振り足し回数上限
    @fractionType = "omit";     #端数の処理 ("omit"=切り捨て, "roundUp"=切り上げ, "roundOff"=四捨五入)
    
    @gameType = 'none'
  end
  
  attr_accessor :rerollLimitCount
  
  attr_reader :sendMode, :sameDiceRerollCount, :sameDiceRerollType, :d66Type
  attr_reader :isPrintMaxDice, :upplerRollThreshold, :unlimitedRollDiceType
  attr_reader :defaultSuccessTarget, :rerollNumber, :fractionType
  
  def gameType
    @gameType
  end
  
  def setGameType(type)
    @gameType = type
  end
  
  def setSendMode(m)
    @sendMode = m
  end
  
  def upplerRollThreshold=(v)
    @upplerRollThreshold = v
  end
  
  def bcdice=(b)
    @@bcdice = b
  end
  
  def bcdice
    @@bcdice
  end
  
  def rand(max)
    @@bcdice.rand(max)
  end
  
  def check_suc(*params)
    @@bcdice.check_suc(*params)
  end
  
  def roll(*args)
    @@bcdice.roll(*args)
  end
  
  def marshalSignOfInequality(*args)
    @@bcdice.marshalSignOfInequality(*args)
  end
  
  def unlimitedRollDiceType
    @@bcdice.unlimitedRollDiceType
  end
  
  def sortType
    @sortType
  end
  
  def setSortType(s)
    @sortType = s
  end
  
  
  def d66(*args)
    @@bcdice.getD66Value(*args)
  end
  
  def rollDiceAddingUp(*arg)
    @@bcdice.rollDiceAddingUp(*arg)
  end
  
  def getHelpMessage
    ''
  end
  
  def parren_killer(string)
    @@bcdice.parren_killer(string)
  end
  
  def changeText(string)
    debug("DiceBot.parren_killer_add called")
    string
  end
  
  def dice_command(string, nick_e)
    output_msg, secret_flg = rollDiceCommandResult(string)
    return output_msg, secret_flg if( output_msg == '1' )
    
    output_msg = "#{nick_e}: #{output_msg}"
    return output_msg, secret_flg
  end
  
  def rollDiceCommandResult(string)
    ['1', false]
  end

  
  def setDiceText(diceText)
    debug("setDiceText diceText", diceText)
    @diceText = diceText
  end
  
  def setDiffText(diffText)
    @diffText = diffText
  end
  
  def dice_command_xRn(string, nick_e)
    ''
  end
  
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)  # ゲーム別成功度判定(2D6)
    ''
  end
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    ''
  end
  
  def check_nD10(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)# ゲーム別成功度判定(nD10)
    ''
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    ''
  end

  def check_1D20(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)     # ゲーム別成功度判定(1d20)
    ''
  end
  
  
  def get_table_by_2d6(table)
    get_table_by_nD6(table, 2)
  end
  
  def get_table_by_1d6(table)
    get_table_by_nD6(table, 1)
  end
  
  def get_table_by_nD6(table, count)
    num, dummy = roll(count, 6);
    
    text = table[num - count]
    
    return '1', 0  if( text.nil? )
    return text, num
  end

  def get_table_by_1d3(table)
    debug("get_table_by_1d3")

    count = 1
    num, dummy = roll(count, 6);
    debug("num", num)
    
    index = ((num - 1)/ 2)
    debug("index", index)
    
    text = table[index]
    
    return '1', 0  if( text.nil? )
    return text, num
  end
  
  
  def get_table_by_d66(table)
    dice1, dummy = roll(1, 6);
    dice2, dummy = roll(1, 6);
    
    num = (dice1 - 1) * 6 + (dice2 - 1);
    
    text = table[num]
    
    indexText = "#{dice1}#{dice2}"
    
    return '1', indexText  if( text.nil? )
    return text, indexText
  end
  
  
  
  #ダイスロールによるポイント等の取得処理用（T&T悪意、ナイトメアハンター・ディープ宿命、特命転校生エクストラパワーポイントなど）
  def getDiceRolledAdditionalText(n1, n_max, dice_max)
    ''
  end
  
  #ダイス目による補正処理（現状ナイトメアハンターディープ専用）
  def getDiceRevision(n_max, dice_max, total_n)
    return '', 0
  end
  
  #ダイス目文字列からダイス値を変更する場合の処理（現状クトゥルフ・テック専用）
  def changeDiceValueByDiceText(dice_now, dice_str, isCheckSuccess, dice_max)
    dice_now
  end
  
  #SW専用
  def setRatingTable(nick_e, tnick, channel_to_list)
    '1'
  end
  
  #振り足し時のダイス読み替え処理用（ダブルクロスはクリティカルでダイス10に読み替える)
  def getJackUpValueOnAddRoll(dice_n)
    0
  end

  #ガンドッグのnD9専用
  def isD9
    false
  end
  
  #シャドウラン4版用グリッチ判定
  def getGrichText(numberSpot1, dice_cnt_total, suc)
    ''
  end
  
  def getDiceList
    getDiceListFromDiceText(@diceText)
  end
  
  def getDiceListFromDiceText(diceText)
    debug("getDiceList diceText", diceText)
    
    diceList = []
    return diceList unless( /\[([\d,]+)\]/ =~ diceText )
    
    diceString = $1;
    diceList = diceString.split(/,/).collect{|i| i.to_i}
    
    debug("diceList", diceList)
    
    return diceList
  end

  
  #** 汎用表サブルーチン
  def get_table_by_number(index, table)
    table.each do |item|
      number = item[0];
      if( number >= index )
        return item[1];
      end
    end
    
    return '1';
  end
  
  
end
