# frozen_string_literal: true

require 'bcdice/game_system/SwordWorld2_0'

module BCDice
  module GameSystem
    class SwordWorld2_5 < SwordWorld2_0
      # ゲームシステムの識別子
      ID = 'SwordWorld2.5'

      # ゲームシステム名
      NAME = 'ソード・ワールド2.5'

      # ゲームシステム名の読みがな
      SORT_KEY = 'そおとわあると2.5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
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

        ・レーティング表の半減 (HKx, KxH+N)
        　レーティング表の先頭または末尾に"H"をつけると、レーティング表を振って最終結果を半減させます。
        　末尾につけた場合、直後に修正ををつけることで、半減後の加減算を行うことができます。
        　この際、複数の項による修正にはカッコで囲うことが必要です（カッコがないとパースに失敗します）
        　クリティカル値を指定しない場合、クリティカルなしと扱われます。
        　例）HK20　　K20h　　HK10-5@9　　K10-5@9H　　K20gfH　　K20+8H+2　　K20+8H+(1+1)

        ・レーティング表の1.5倍 (OHKx, KxOH+N)
        　レーティング表の先頭または末尾に"OH"をつけると、レーティング表を振って最終結果を1.5倍します。
        　末尾につけた場合、直後に修正ををつけることで、1.5倍後の加減算を行うことができます。
        　この際、複数の項による修正にはカッコで囲うことが必要です（カッコがないとパースに失敗します）
        　クリティカル値を指定しない場合、クリティカルなしと扱われます。
        　例）OHK20　　K20oh　　OHK10-5@9　　K20+8OH+2　　K20+8OH+(1+1)

        ・ダイス目の修正（運命変転やクリティカルレイ、魔女の火用）
        　末尾に「$修正値」でダイス目に修正がかかります。
        　$＋１と修正表記ならダイス目に＋修正、＄９のように固定値ならダイス目をその出目に差し替え。
        　$~＋１とチルダを追加して記述することで、出目10以下の場合のみダイス目に＋修正（魔女の火用）
        　クリティカルした場合でも固定値や修正値の適用は最初の一回だけです。
        　例）K20$+1　　　K10+5$9　　　k10-5@9$+2　　　k10[9]+10$9　　　k20+6$~+1

        ・ダイス目の修正（必殺攻撃用）
        　「＃修正値」でダイス目に修正がかかります。
        　クリティカルした場合でも修正値の適用は継続されます。
        　例）K20#1　　　k10-5@9#2

        ・首切り刀用レーティング上昇 r5
        　例）K20r5　K30+24@8R5　K40+24@8$12r5

        ・グレイテストフォーチュンは末尾に gf
        　例）K20gf　K30+24@8GF　K40+24@8$12r5gf

        ・威力表を1d+sfで参照 クリティカル後も継続 sf4
        　例）k10sf4　k0+5sf4@13　k70+26sf3@9

        ・威力表を1d+tfで参照 クリティカル後は2dで参照 tf3
        　例）k10tf3　k0+5tf4@13　k70+26tf3@9

        ・超越判定用に2d6ロールに 2D6@10 書式でクリティカル値付与が可能に。
        　例）2D6@10　2D6@10+11>=30

        ・成長　(Gr)
        　末尾に数字を付加することで、複数回の成長をまとめて行えます。
        　例）Gr3

        ・防御ファンブル表　(FT)
        　防御ファンブル表を出すことができます。

        ・絡み効果表　(TT)
        　絡み効果表を出すことができます。

        ・ドルイドの物理魔法用表　(Dru[2-6の値,7-9の値,10-12の値])
        　例）Dru[0,3,6]+10-3

        ・アビスカース表　(ABT)
        　アビスカース表を出すことができます。
      INFO_MESSAGE_TEXT

      register_prefix('H?K', 'OHK', 'Gr', '2D6?@\d+', 'FT', 'TT', 'Dru', 'ABT')

      def eval_game_system_specific_command(command)
        case command
        when /^dru\[(\d+),(\d+),(\d+)\]/i
          power_list = Regexp.last_match.captures.map(&:to_i)
          druid_parser = Command::Parser.new(/dru\[\d+,\d+,\d+\]/i, round_type: BCDice::RoundType::CEIL)

          cmd = druid_parser.parse(command)
          unless cmd
            return nil
          end

          druid_dice(cmd, power_list)
        when 'ABT'
          get_abyss_curse_table
        else
          super(command)
        end
      end

      def rating_parser
        return RatingParser.new(version: :v2_5)
      end

      def druid_dice(command, power_list)
        dice_list = @randomizer.roll_barabara(2, 6)
        dice_total = dice_list.sum()
        offset =
          case dice_total
          when 2..6
            0
          when 7..9
            1
          when 10..12
            2
          end
        power = power_list[offset]
        total = power + command.modify_number
        sequence = [
          "(#{command.command.capitalize}#{Format.modifier(command.modify_number)})",
          "2D[#{dice_list.join(',')}]=#{dice_total}",
          "#{power}#{Format.modifier(command.modify_number)}",
          total
        ]

        return sequence.join(" ＞ ")
      end

      def get_abyss_curse_table
        table_result = DiceTable::D66GridTable.from_i18n('SwordWorld2_5.AbyssCurseTable', @locale).roll(@randomizer)
        additional =
          case table_result.value
          when 14  # 「差別の」における分類決定表
            DiceTable::D66ParityTable.from_i18n('SwordWorld2_5.AbyssCurseCategoryTable', @locale).roll(@randomizer).to_s
          when 25  # 「過敏な」における属性決定表
            DiceTable::D66ParityTable.from_i18n('SwordWorld2_5.AbyssCurseAttrTable', @locale).roll(@randomizer).to_s
          end
        final_result = [
          table_result.to_s,
          additional,
        ].compact

        return final_result.join("\n")
      end
    end
  end
end
