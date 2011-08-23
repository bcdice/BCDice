#--*-coding:utf-8-*--

class ShadowRun4 < DiceBot
  
  def initialize
    super
    @sortType = 3
    @rerollNumber = 6;      #振り足しする出目
    @defaultSuccessTarget = ">=5";   #目標値が空欄の時の目標値
  end
  
  def gameType
    "ShadowRun4"
  end
  
  def changeText(string)
    if(string =~ /(\d+)S6/i)
      string = string.gsub(/(\d+)S6/i) {"#{$1}B6"}
    end
    
    return string
  end
  
  #シャドウラン4版用グリッチ判定
  def getGrichText(n1_total, dice_cnt_total, successCount)
    if( n1_total >= (dice_cnt_total / 2) )     # グリッチ！
      if( successCount != 0 ) 
        return ' ＞ グリッチ';
      else
        return ' ＞ クリティカルグリッチ';
      end
    end
    
    return ''
  end
  
end
