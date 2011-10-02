#--*-coding:utf-8-*--

class ZettaiReido < DiceBot
  
  def initialize
    super
    
    # @sendMode = @@DEFAULT_SEND_MODE #(0=結果のみ,1=0+式,2=1+ダイス個別)
    # @sortType = 0;      #ソート設定(1 = ?, 2 = ??, 3 = 1&2　各値の意味が不明です懼�ｦ）
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
    "ZettaiReido"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
m-2DR+n>=x　：m(基本能力),n(修正値),x(目標値) DPの取得の有無も表示されます。
MESSAGETEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, nick_e)
    secret_flg = false
    
    return '1', secret_flg unless( /(^|\s)(S)?(\d+)-2DR([\+\-\d]*)(>=(\d+))?($|\s)/i =~ string )
    
    secretMarker = $2
    
    baseAvility = $3.to_i
    modText = $4
    diffValue = $6
    
    output_msg = roll2DR(baseAvility, modText, diffValue, nick_e)
    
    if( secretMarker )    # 隠しロール
      secret_flg = true if(output_msg != '1')
    end
      
    return output_msg, secret_flg
  end
  
  
  def roll2DR(baseAvility, modText, diffValue, nick_e)
    diceTotal, diceText, darkPoint = roll2DarkDice()
    
    mod, modText = getModInfo(modText)
    diff, diffText = getDiffInfo(diffValue)
    
    output = ""
    output << ": (#{baseAvility}-2DR#{modText}#{diffText})"
    output << " ＞ #{baseAvility}-#{diceTotal}[#{diceText}]#{modText}"
    
    total = baseAvility - diceTotal + mod
    output << " ＞ #{total}"
    
    successText = getSuccessText(diceTotal, total, diff)
    output << successText
    
    darkPointText = getDarkPointResult(total, diff, darkPoint)
    output << darkPointText
    
    return output
  end
  
  
  def roll2DarkDice()
    total, dice_str = roll(2, 6)
    dice1, dice2 = dice_str.split(',').collect{|i|i.to_i}
    
    darkDice1, darkPoint1 = changeDiceToDarkDice(dice1)
    darkDice2, darkPoint2 = changeDiceToDarkDice(dice2)
    
    darkPoint = darkPoint1 + darkPoint2
    if( darkPoint == 2 )
      darkPoint = 4
    end
    
    darkTotal = darkDice1 + darkDice2
    darkDiceText = "#{darkDice1},#{darkDice2}"
    
    return darkTotal, darkDiceText, darkPoint
  end
  
  def changeDiceToDarkDice(dice)
    darkPoint = 0
    darkDice = dice
    if( dice == 6 )
      darkDice = 0
      darkPoint = 1
    end
    
    return darkDice, darkPoint
  end
  
  def getModInfo(modText)
    value = parren_killer("(0#{modText})").to_i
    
    text = ""
    if( value < 0 )
      text = value.to_s
    elsif( value > 0 )
      text = "+" + value.to_s
    end
    
    return value, text
  end
  
  
  def getDiffInfo(diffValue)
    diffText = ""
    
    unless( diffValue.nil? )
      diffValue = diffValue.to_i
      diffText = ">=#{diffValue.to_i}"
    end
    
    return diffValue, diffText
  end
  
  
  def getDarkPointResult(total, diff, darkPoint)
    text = ''
    
    if( darkPoint > 0 ) 
      text = " ＞ #{darkPoint}DP"
    end
    
    return text
  end
  
  
  def getSuccessText(diceTotal, total, diff)
    
    if( diceTotal == 0 )
      return " ＞ クリティカル"
    end
    
    if( diceTotal == 10 )
      return " ＞ ファンブル"
    end
    
    
    if( diff.nil? )
      diff = 0
    end
    
    successLevel = (total - diff)
    if( successLevel >= 0 )
      return " ＞ #{successLevel} 成功"
    end
    
    return ' ＞ 失敗'
  end
  
end
