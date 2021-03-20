# frozen_string_literal: true

require "bcdice/game_system/Cthulhu"

module BCDice
  module GameSystem
    class Cthulhu_ChineseTraditional < Cthulhu
      # ゲームシステムの識別子
      ID = 'Cthulhu:ChineseTraditional'

      # ゲームシステム名
      NAME = '克蘇魯神話'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Chinese Traditional:克蘇魯神話'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        c=爆擊率 ／ f=大失敗值 ／ s=特殊

        1d100<=n    c・f・s全關閉（只進行單純數值比較判定）

        ・cfs付註判定指令

        CC	 1d100擲骰 c=1、f=100
        CCB  同上、c=5、f=96

        例：CC<=80  （以技能值80來判定。cf適用於1%規則）
        例：CCB<=55 （以技能值55來判定。cf適用於5%規則）

        ・關於組合骰組

        CBR(x,y)	c=1、f=100
        CBRB(x,y)	c=5、f=96

        ・關於對抗骰
        RES(x-y)	c=1、f=100
        RESB(x-y)	c=5、f=96

        ※故障率判定

        ・CC(x) c=1、f=100
        x=故障率。擲出骰值x以上時、需在大失敗發生同時輸出（參照「大失敗＆故障」）
        沒有大失敗時，無論成功或失敗只需參考[故障]來輸出(並非成功或失敗來輸出，而是覆蓋上去並對其輸出)

        ・CCB(x) c=5、f=96
        同上

      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hant
      end
    end
  end
end
