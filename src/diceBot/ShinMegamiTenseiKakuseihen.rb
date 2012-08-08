#--*-coding:utf-8-*--

class ShinMegamiTenseiKakuseihen < DiceBot
  
  def initialize
    super
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
