#--*-coding:utf-8-*--

class BloodMoon < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 1
    @d66Type = 2
    @fractionType = "roundUp"     # 端数切り上げに設定
  end
  def gameName
    'ブラッド・ムーン'
  end
  
  def gameType
    "BloodMoon"
  end
  
  def prefixs
     []
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
・各種表
　・関係属性表　RAT
　・導入タイプ決定表(ノーマル)　IDT
　・導入タイプ決定表(ハード込み)　ID2T
・D66ダイスあり
INFO_MESSAGE_TEXT
  end
  
  # ゲーム別成功度判定(2D6)
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    return '' unless(signOfInequality == ">=")
    
    if(dice_n <= 2)
      return " ＞ ファンブル(【余裕】が 0 に)"
    elsif(dice_n >= 12)
      return " ＞ スペシャル(【余裕】+3）"
    elsif(total_n >= diff)
      return " ＞ 成功"
    else
      return " ＞ 失敗"
    end
  end
  
  
end
