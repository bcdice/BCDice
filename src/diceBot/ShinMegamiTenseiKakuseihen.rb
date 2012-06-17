#--*-coding:utf-8-*--

class ShinMegamiTenseiKakuseihen < DiceBot
  
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
    # "真・女神転生TRPG　覚醒編"
    # "ShinMegamiTenseiKakuseihen"
    "SMTKakuseihen"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
MESSAGETEXT
  end
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless(signOfInequality == "<=")
    
    total_n = total_n % 100
    
    dice1, dice2 = getTwoDice
    
    total1 = dice1 * 10 + dice2;
    total2 = dice2 * 10 + dice1;
    
    #ゾロ目
    isRepdigit = ( dice1 == dice2 )
    
    result = " ＞ スワップ"
    result << getCheckResultText(diff, [total1, total2].min, isRepdigit)
    result << "／通常"
    result << getCheckResultText(diff, total_n, isRepdigit)
    result << "／逆スワップ"
    result << getCheckResultText(diff, [total1, total2].max, isRepdigit)
    
    return result
  end
  
  def getTwoDice
    value = getDiceList.first
    value ||= 0
    
    value %= 100
    
    dice1 = value / 10
    dice2 = value % 10
    
    return [dice1, dice2]
  end
  
  def getCheckResultText(diff, total, isRepdigit)
    checkResult = getCheckResult(diff, total, isRepdigit)
    text = sprintf("(%02d)%s", total, checkResult)
    return text
  end
  
  def getCheckResult(diff, total, isRepdigit)
    if( diff >= total )
      return getSuccessResult(isRepdigit)
    end
    
    return getFailResult(isRepdigit)
  end
  
  def getSuccessResult(isRepdigit)
    if( isRepdigit )
      return "絶対成功" 
    end
    
    return "成功"
  end
  
  def getFailResult(isRepdigit)
    if( isRepdigit )
      return "絶対失敗"
    end
    
    return "失敗"
  end
  
  
end
