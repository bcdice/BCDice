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

        ・威力表を1d+sfで参照 回転後も継続 sf4
        　例）k10sf4

        ・威力表を1d+tfで参照 回転後は2dで判定 tf3
        　例）k10tf3

        ・グレイテストフォーチュンは末尾に gf
        　例）K20gf　K30+24@8GF　K40+24@8$12r10gf

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
        when /^Gr(\d+)?/i
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

          node = TranscendentTest.new(cmd.critical, cmd.modify_number, cmd.cmp_op, cmd.target_number)
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
          dice = @randomizer.roll_once(6)
          return dice + command.semi_fixed_val, "#{dice},#{command.semi_fixed_val}"
        end
        if round == 0 && command.tmp_fixed_val > 0
          dice = @randomizer.roll_once(6)
          return dice + command.tmp_fixed_val, "#{dice},#{command.tmp_fixed_val}"
        end
        unless command.greatest_fortune
          return super(command, round)
        end

        if command.greatest_fortune
          dice = @randomizer.roll_once(6)
          return dice * 2, "#{dice},#{dice}"
        end
      end

      def growth(count = 1)
        ((1..count).map { growth_step }).join " | "
      end

      def growth_step
        d1 = @randomizer.roll_once(6)
        d2 = @randomizer.roll_once(6)

        a1 = get_ability_by_dice(d1)
        a2 = get_ability_by_dice(d2)

        return a1 != a2 ? "[#{d1},#{d2}]->(#{a1} or #{a2})" : "[#{d1},#{d2}]->(#{a1})"
      end

      def get_ability_by_dice(dice)
        ['器用度', '敏捷度', '筋力', '生命力', '知力', '精神力'][dice - 1]
      end

      def get_fumble_table()
        table = [
          'この表を2回振り、その両方を適用する。（同じ出目による影響は累積しない）。この自動失敗により得られる経験点は、+50点される',
          'ダメージに、攻撃者を強化している「剣のかけら」の数が追加される',
          'ダメージに、攻撃者の「レベル」が追加される',
          'ダメージ決定を2回行い、より高い方を採用する',
          '合算ダメージを2倍する',
          '防護点無効'
        ]
        text, num = get_table_by_1d6(table)
        return "防御ファンブル表(#{num}) → #{text}"
      end

      def get_tangle_table()
        table = [
          '頭や顔：牙や噛みつきなどにおける命中力判定及び、魔法の行使やブレスに-2のペナルティ修正を受ける',
          '武器や盾：武器の使用不可、又は盾の回避力修正及び防護点を無効化する',
          '腕や手：武器や爪などにおける命中力判定に-2のペナルティ修正、盾を持つ腕方の腕ならその盾の回避力修正及び防護点を無効化する',
          '脚や足：移動不可、更に回避力判定に-2のペナルティ修正を受ける ※両足に絡んでも累積しない',
          '胴体：生命・精神抵抗力を基準値に用いる判定を除き、あらゆる行為判定に-1のペナルティ修正を受ける',
          '特殊：尻尾や翼などに命中。絡められた部位を使用する判定において-2のペナルティ修正、またはそこが使えていたことによるボーナス修正を失う ※存在しない場合は決め直し'
        ]
        text, num = get_table_by_1d6(table)
        return "絡み効果表(#{num}) → #{text}"
      end
    end
  end
end
