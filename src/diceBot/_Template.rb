#--*-coding:utf-8-*--

class _Template < DiceBot
  
  def initialize
    super
    
    # @sendMode = @@DEFAULT_SEND_MODE #(0=結果のみ,1=0+式,2=1+ダイス個別)
    # @sortType = 0;      #ソート設定(1 = ?, 2 = ??, 3 = 1&2　各値の意味が不明です…）
    # @sameDiceRerollCount = 0;     #ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
    # @sameDiceRerollType = 0;   #ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
    # @d66Type = 0;        #d66の差し替え
    # @isPrintMaxDice = false;      #最大値表示
    # @upplerRollThreshold = 0;      #上方無限
    # @unlimitedRollDiceType = 0;    #無限ロールのダイス
    # @rerollNumber = 0;      #振り足しする条件
    # @defaultSuccessTarget = "";      #目標値が空欄の時の目標値
    # @rerollLimitCount = 0;    #振り足し回数上限
    # @fractionType = "omit";     #端数の処理 ("omit"=切り捨て, "roundUp"=切り上げ, "roundOff"=四捨五入)
  end
  
  def gameType
    "_Template"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
MESSAGETEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, nick_e)
    ['1', false]
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
  
  
  #以下のメソッドはテーブルの参照用に便利
  #get_table_by_2d6(table)
  #get_table_by_1d6(table)
  #get_table_by_nD6(table, 1)
  #get_table_by_nD6(table, count)
  #get_table_by_1d3(table)
  #get_table_by_number(index, table)
  
  
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
  
  #振り足し時のダイス読み替え処理用（ダブルクロスはクリティカルでダイス10に読み替える)
  def getJackUpValueOnAddRoll(dice_n)
    0
  end
  
  #ダイス目が知りたくなったら getDiceList を呼び出すこと(DiceBot.rbにて定義)
end
