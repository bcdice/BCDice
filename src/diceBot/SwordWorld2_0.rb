# -*- coding: utf-8 -*-

require 'diceBot/SwordWorld'

class SwordWorld2_0 < SwordWorld
  
  def initialize
    rating_table = 2
    super()
    @rating_table = rating_table;
  end
  def gameName
    'ソードワールド2.0'
  end
  
  def gameType
    return "SwordWorld2.0"
  end
  
  def prefixs
     ['K\d+.*']
  end
  
  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
自動的成功、成功、失敗、自動的失敗の自動判定を行います。

・レーティング表　(Kx)
　"Kキーナンバー+ボーナス"の形で記入します。
　ボーナスの部分に「K20+K30」のようにレーティングを取ることは出来ません。
　また、ボーナスは複数取ることが出来ます。
　レーティング表もダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
　例）K20　　　K10+5　　　k30　　　k10+10　　　Sk10-1　　　k10+5+2

・クリティカル値の設定
　クリティカル値は"[クリティカル値]"で指定します。
　指定しない場合はクリティカル値10とします。
　クリティカル処理が必要ないときは13などとしてください。(防御時などの対応)
　またタイプの軽減化のために末尾に「@クリティカル値」でも処理するようにしました。
　例）K20[10]　　　K10+5[9]　　　k30[10]　　　k10[9]+10　　　k10-5@9

・ダイス目の修正（運命変転やクリティカルレイ用）
　末尾に「$修正値」でダイス目に修正がかかります。
　$＋１と修正表記ならダイス目に＋修正、＄９のように固定値ならダイス目をその出目に差し替え。
　クリティカルした場合でも固定値や修正値の適用は最初の一回だけです。
　例）K20$+1　　　K10+5$9　　　k10-5@9$+2　　　k10[9]+10$9

・首切り刀用レーティング上昇 r10
　例）K20r10　K30+24@8R10　K40+24@8$12r10

・グレイテストフォーチュンは末尾に gt
　例）K20gf　K30+24@8GF　K40+24@8$12r10gf

・超越判定用に2d6ロールに 2D6@10 書式でクリティカル値付与が可能に。
　例）2D6@10　2D6@10+11>=30
INFO_MESSAGE_TEXT
  end
  
  def isSW2_0Mode
    true
  end
  
  
  def is2dCritical
    true
  end
  
  
  # SW2.0 の超成功用
  def check2dCritical(critical, dice_new, dice_arry, loop_count)
    return if( critical <= 2 )
    
    if( loop_count == 0 )
      return if( dice_new == 12 )
      return if( dice_new == 2 )
    end
    
    if( dice_new >= critical )
      dice_arry.push( 2 )
    end
  end
  
  
  def check_nD6(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max) # ゲーム別成功度判定(nD6)
    
    debug("check_nD6")
    result = super(total_n, dice_n, signOfInequality, diff, dice_cnt, dice_max, n1, n_max)
    
    return result unless( result == "" )
    
    string = @@bcdice.getOriginalMessage
    
    superSuccessValue = 41
    
    if( /@(\d+)/ === string )
      critical = $1.to_i
      if( dice_n >= critical ) 
        if( total_n >= superSuccessValue )
          return " ＞ 超成功"
        end
      end
    end
    
    return result
  end
  
end
