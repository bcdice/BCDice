#--*-coding:utf-8-*--

class KanColle < DiceBot
  
  def initialize
    super
    @sendMode = 2
    @sortType = 3
    @d66Type = 2
  end
  def gameName
    '艦これRPG'
  end
  
  def gameType
    "KanColle"
  end
  
  def getHelpMessage
    info = <<INFO_MESSAGE_TEXT
2D6使った行為判定とD66ダイス(D66S相当=低い方が10の桁になる方)のみ対応。

例) 2D6 ： 単純に2D6した値を出します。
例) 2D6>=7 ： 行為判定。2D6して目標値7以上出れば成功。
例) 2D6+2>=7 ： 行為判定。2D6に修正+2をした上で目標値7以上になれば成功。

2D6での行為判定時は1ゾロでファンブル、6ゾロでスペシャル扱いになります。
天龍ちゃんスペシャルは手動で判定してください。
INFO_MESSAGE_TEXT
  end
  
  
  # ゲーム別成功度判定(2D6)
  def check_2D6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    debug("total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max", total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    return '' unless(signOfInequality == ">=")
    
    output = ''
    if(dice_n <= 2)
      output = " ＞ ファンブル(判定失敗。アクシデント発生)"
    elsif(dice_n >= 12)
      output = " ＞ スペシャル(判定成功)"
    elsif(total_n >= diff)
      output = " ＞ 成功"
    else
      output = " ＞ 失敗"
    end
    
    return output
  end


end
