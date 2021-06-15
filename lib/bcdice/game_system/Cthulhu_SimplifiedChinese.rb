# frozen_string_literal: true

require "bcdice/game_system/Cthulhu"

module BCDice
  module GameSystem
    class Cthulhu_SimplifiedChinese < Cthulhu
      # ゲームシステムの識別子
      ID = 'Cthulhu:SimplifiedChinese'

      # ゲームシステム名
      NAME = '克苏鲁的呼唤 第六版'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Simplified Chinese:克苏鲁的呼唤 第六版'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        c=大成功值 ／ f=大失败值 ／ s=极难成功

        1d100<=n    c・f・s全部关闭（只进行数值比较判定）

        ・带cfs判定的判定指令

        CC	 掷1d100骰 c=1、f=100
        CCB  同上，c=5、f=96

        例：CC<=80  （以80技能値进行行为判定。并以1%的标准使用cf的值）
        例：CCB<=55 （以55技能値进行行为判定。并以5%的标准使用cf的值）

        ・关于组合骰

        CBR(x,y)	c=1、f=100
        CBRB(x,y)	c=5、f=96

        ・关于对抗骰
        RES(x-y)	c=1、f=100
        RESB(x-y)	c=5、f=96

        ※故障值判定

        ・CC(x) c=1、f=100
        x=故障值。骰点在x以上并且发生大失败时，会和大失败一起显示（文本为「大失败＆故障」）
        没有发生大失败时，与成功或失败无关，文斗都会显示为「故障」（不显示成功或失败的情况下进行覆盖显示）

        ・CCB(x) c=5、f=96
        同上

      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hans
      end
    end
  end
end
