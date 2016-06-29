# -*- coding: utf-8 -*-

class EclipsePhase < DiceBot
  
  def initialize
    super
  end
  def gameName
    'エクリプス・フェイズ'
  end
  
  def gameType
    "EclipsePhase"
  end
  
  def prefixs
     []
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
1D100<=m 方式の判定で成否、クリティカル・ファンブルを自動判定
INFO_MESSAGE_TEXT
  end
  
  
  def check_1D100(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)    # ゲーム別成功度判定(1d100)
    return '' unless( signOfInequality == '<=' )
    
    diceValue = total_n % 100 #これで１〜１００の値を０〜９９にする。
    dice0 = diceValue / 10 #10の位を代入
    dice1 = diceValue % 10 # 1の位を代入
    
    debug("total_n", total_n)
    debug("dice0, dice1", dice0, dice1)
    
    if( dice0 != dice1 )
      if(total_n <= diff)
        return ' ＞ 成功'
        else
        return ' ＞ 失敗'
      end
    end
    
    if( (dice0 == 0) and (dice1 == 0) )
      return ' ＞ 00 ＞ クリティカル'
    end
    
    if(total_n <= diff)
      return ' ＞ クリティカル'
    else
      return ' ＞ ファンブル'
    end
  end

end
