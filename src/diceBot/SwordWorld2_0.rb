#--*-coding:utf-8-*--

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
    info = <<INFO_MESSAGE_TEXT
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
INFO_MESSAGE_TEXT
  end
  
  def isSW2_0Mode
    true
  end
  
end
