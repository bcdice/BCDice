# frozen_string_literal: true

require 'bcdice/game_system/SwordWorld2_0'

module BCDice
  module GameSystem
    class SwordWorld2_0_SimplifiedChinese < SwordWorld2_0
      # ゲームシステムの識別子
      ID = 'SwordWorld2.0:SimplifiedChinese'

      # ゲームシステム名
      NAME = '剑世界2.0'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Simplified Chinese:剑世界2.0'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        自动成功、成功、失败、自动失败会自动判定。

          ・威力表　(Kx)
          　指令为“K威力值+加值”的格式。
          　加值的部分不能是像“K20+K30”这样的威力的写法。
          　另外，加值可以有多个。
          　威力表和骰点一样，可以对其他玩家隐藏。
          　例）K20　　　K10+5　　　k30　　　k10+10　　　Sk10-1　　　k10+5+2

          ・暴击值的设定
          　暴击值通过“[暴击值]”指定。
          　没有指定暴击值时默认为10。
          　如果不需要发生暴击，请设定为13。（例如防御时）
          　另外也可写成结尾的“@暴击值”的形式。
          　例）K20[10]　　　K10+5[9]　　　k30[10]　　　k10[9]+10　　　k10-5@9

          ・威力表的减半 (HKx, KxH+N)
          　在威力表开头或末尾加上“H”，骰威力表的最终结果就会减半。
          　H写在威力表末尾的情况下可以在后面直接跟着修正，会在减半后进行加减运算。
          　这种情况下，多个修正需要用括号括起来（否则会解析失败）
          　没有指定暴击值的情况下，则视为没有暴击值。
          　例）HK20　　K20h　　HK10-5@9　　K10-5@9H　　K20gfH　　K20+8H+2　　K20+8H+(1+1)

          ・骰子出目修正（命运变转或重击光辉用）
          　在指令末尾添加“$修正值”来改变骰子出目。
          　可以使用$+1的格式在骰子出目上+修正，或使用$9的格式把骰子出目替换为固定值。
          　暴击时只有第一次出目应用这个修正。
          　例）K20$+1　　　K10+5$9　　　k10-5@9$+2　　　k10[9]+10$9

          ・威力上升（斩首刀用） r10
          　r后跟上升值，暴击后威力上升r后所填写的上升值点
          　例）K20r10　K30+24@8R10　K40+24@8$12r10

          ・极限命运在末尾加上 gf
          　例）K20gf　K30+24@8GF　K40+24@8$12r5gf

          ・威力表使用1d+固定值对应 暴击后仍继续 sf4
          　例）k10sf4　k0+5sf4@13　k70+26sf3@9

          ・威力表使用1d+固定值对应 暴击后变回使用2d对应 tf3
          　例）k10tf3　k0+5tf4@13　k70+26tf3@9

          ・超越判定用2d6可写成 2d6@10 的格式加上暴击值。
          　例）2D6@10　2D6@10+11>=30

          ・成长　(Gr)
          　在Gr后面加上数字可以进行多次成长。
          　例）Gr3

          ・防御大失败表　(FT)
          　抽取防御大失败表。

          ・缠绕效果表　(TT)
          　抽取缠绕效果表。
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :zh_hans
      end
    end
  end
end
