# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'

require 'bcdice/game_system/SwordWorld'
require 'bcdice/game_system/sword_world/transcendent_test'

module BCDice
  module GameSystem
    class SwordWorld2_0 < SwordWorld
      # ゲームシステムの識別子
      ID = 'SwordWorld2.0'

      # ゲームシステム名
      NAME = 'ソード・ワールド2.0'

      # ゲームシステム名の読みがな
      SORT_KEY = 'そおとわあると2.0'

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
        　例）HK20　　K20h　　HK10-5@9　　K10-5@9H　　K20gfH　　K20+8H+2　　K20+8H(1+1)

        ・ダイス目の修正（運命変転やクリティカルレイ用）
        　末尾に「$修正値」でダイス目に修正がかかります。
        　$＋１と修正表記ならダイス目に＋修正、＄９のように固定値ならダイス目をその出目に差し替え。
        　クリティカルした場合でも固定値や修正値の適用は最初の一回だけです。
        　例）K20$+1　　　K10+5$9　　　k10-5@9$+2　　　k10[9]+10$9

        ・首切り刀用レーティング上昇 r10
        　例）K20r10　K30+24@8R10　K40+24@8$12r10

        ・グレイテストフォーチュンは末尾に gf
        　例）K20gf　K30+24@8GF　K40+24@8$12r10gf

        ・威力表を1d+sfで参照 クリティカル後も継続 sf4
        　例）k10sf4　k0+5SF4@13　k70+26sf3@9

        ・威力表を1d+tfで参照 クリティカル後は2dで参照 tf3
        　例）k10tf3　k0+5TF4@13　k70+26tf3@9

        ・超越判定用に2d6ロールに 2D6@10 書式でクリティカル値付与が可能に。
        　例）2D6@10　2D6@10+11>=30

        ・成長　(Gr)
        　末尾に数字を付加することで、複数回の成長をまとめて行えます。
        　例）Gr3

        ・防御ファンブル表　(FT)
        　防御ファンブル表を出すことができます。

        ・絡み効果表　(TT)
        　絡み効果表を出すことができます。
      INFO_MESSAGE_TEXT

      register_prefix('H?K', 'Gr', '2D6?@\d+', 'FT', 'TT')

      def initialize(command)
        super(command)
        @rating_table = 2
      end

      def eval_game_system_specific_command(command)
        case command
        when /^Gr(\d+)?$/i
          if command =~ /^Gr(\d+)/i
            growth(Regexp.last_match(1).to_i)
          else
            growth
          end
        when /^2D6?@\d+/i
          transcendent_parser = Command::Parser.new(/2D6?/i, round_type: BCDice::RoundType::CEIL)
                                               .enable_critical
                                               .restrict_cmp_op_to(nil, :>=, :>)
          cmd = transcendent_parser.parse(command)

          unless cmd
            return nil
          end

          node = TranscendentTest.new(cmd.critical, cmd.modify_number, cmd.cmp_op, cmd.target_number, @locale)
          node.execute(@randomizer)
        when 'FT'
          get_fumble_table
        when 'TT'
          get_tangle_table
        else
          super(command)
        end
      end

      def rating_parser
        return RatingParser.new(version: :v2_0)
      end

      def rollDice(command, round)
        if command.semi_fixed_val > 0
          # 常に片方の出目を固定
          dice = @randomizer.roll_once(6)
          return dice + command.semi_fixed_val, "#{dice},#{command.semi_fixed_val}"
        elsif round == 0 && command.tmp_fixed_val > 0
          # 回転前だけ片方の出目を固定
          dice = @randomizer.roll_once(6)
          return dice + command.tmp_fixed_val, "#{dice},#{command.tmp_fixed_val}"
        elsif command.greatest_fortune
          # グレイテスト・フォーチュン
          dice = @randomizer.roll_once(6)
          return dice * 2, "#{dice},#{dice}"
        else
          return super(command, round)
        end
      end

      def growth(count = 1)
        ((1..count).map { growth_step }).join " | "
      end

      def growth_step
        table = DiceTable::Table.from_i18n("SwordWorld2_0.GrowthTable", @locale)
        r1 = table.roll(@randomizer)
        r2 = table.roll(@randomizer)

        return r1.value != r2.value ? "[#{r1.value},#{r2.value}]->(#{r1.body} or #{r2.body})" : "[#{r1.value},#{r2.value}]->(#{r1.body})"
      end

      def get_fumble_table()
        table = DiceTable::Table.from_i18n("SwordWorld2_0.FumbleTable", @locale)
        return table.roll(@randomizer)
      end

      def get_tangle_table()
        table = DiceTable::Table.from_i18n("SwordWorld2_0.TangleTable", @locale)
        return table.roll(@randomizer)
      end
    end
  end
end
