# frozen_string_literal: true

module BCDice
  module GameSystem
    class SajinsenkiAGuS < Base
      # ゲームシステムの識別子
      ID = 'SajinsenkiAGuS'

      # ゲームシステム名
      NAME = '砂塵戦機アーガス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'さしんせんきああかす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・一般判定Lv（チャンス出目0→判定0） nAG+x
        　　　nは習得レベル、Lv0の場合nの省略可能。xは判定値修正（数式による修正可）、省略した場合はレベル修正0
        　　　例）AG:習得レベル0の一般技能、1AG+1:習得レベル1・判定値修正+1の技能、AG+2-1：習得レベル0・判定値修正2-1の技能、(1-1)AG：習得レベル1・レベル修正-1の技能

        ・適正距離での命中判定（チャンス出目0→判定0、HR算出）OM+y@z
        　　　yは命中補正値（数式可）、zはクリティカル値。クリティカル値省略時は0
        　　　HRの算出時には、HRが大きくなる場合に出目0を10に読み替えます。
        　　　例）OM+18-6@2:命中補正値+18-6でクリティカル値2、適正距離の判定

        ・非適正距離での命中判定（チャンス出目0→判定0、HR算出）NM+y@z
        　　　yは命中補正値（数式可）、zはクリティカル値。クリティカル値省略時は0
        　　　HRの算出時には、HRが大きくなる場合に出目0を10に読み替えます。
        　　　例）NM+4-3:命中補正値+4-3で非適正距離の判定

        ・クリティカル表 CR

        ※通常の1D10などの10面ダイスにおいて出目10の読み替えはしません。コマンドのみです。

      INFO_MESSAGE_TEXT
      register_prefix('-?\d*AG', 'OM', 'NM', 'CR')

      def eval_game_system_specific_command(command)
        roll_ippan(command) || roll_hit_check(command) || roll_tables(command, TABLES)
      end

      private

      def roll_ippan(command)
        m = /^(-?\d+)?AG((?:[-+]\d+)*)$/.match(command)
        return nil unless m

        level = m[1].to_i
        x = Arithmetic.eval(m[2], @round_type) || 0
        target = level <= 0 ? 7 + x : 10 + level + x

        dice_list = @randomizer.roll_barabara(2, 10).map { |d| d == 10 ? 0 : d }
        total = dice_list.sum
        success_level = 1 + dice_list.count { |val| val <= level }

        return Result.new.tap do |result|
          result.condition = total <= target
          result.rands = dice_list

          sequence = [
            "(2D10<=#{target})",
            "#{total}[#{dice_list.join(',')}]",
            ("チャンス" if dice_list.include?(0)),
            result.success? ? "成功(+#{success_level})" : "失敗"
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end

      # 命中判定＆HR算出
      def roll_hit_check(command)
        parser = Command::Parser.new("OM", "NM", round_type: @round_type).enable_critical
        parsed = parser.parse(command)
        return nil unless parsed

        if parsed.command == "OM"
          return roll_om(parsed)
        elsif parsed.command == "NM"
          return roll_nm(parsed)
        end
      end

      def roll_om(parsed)
        target = parsed.modify_number
        critical = parsed.critical || 0

        dice_list = @randomizer.roll_barabara(2, 10).map { |v| v == 10 ? 0 : v }.sort.reverse

        total = dice_list.sum()
        criticals = dice_list.count { |v| v <= critical }
        hr = calc_hr(target, dice_list)

        return Result.new.tap do |r|
          r.condition = total <= target
          r.rands = dice_list
          r.critical = criticals >= 1
          r.text = [
            "(2D10<=#{target})",
            "#{total}[#{dice_list.join(',')}]",
            ("チャンス" if dice_list.include?(0)),
            r.success? ? "成功（HR=#{hr}、クリティカル#{criticals}）" : "失敗",
          ].compact.join(" ＞ ")
        end
      end

      def roll_nm(parsed)
        target = parsed.modify_number
        critical = parsed.critical || 0

        dice_list = @randomizer.roll_barabara(3, 10).map { |v| v == 10 ? 0 : v }.sort.reverse

        chosen_dice_list = dice_list.take(2)
        total = chosen_dice_list.sum()
        criticals = chosen_dice_list.count { |v| v <= critical }
        hr = calc_hr(target, chosen_dice_list)

        return Result.new.tap do |r|
          r.condition = total <= target
          r.rands = dice_list
          r.critical = criticals >= 1
          r.text = [
            "(3D10<=#{target})",
            "#{total}[#{dice_list[0]},#{dice_list[1]}&#{dice_list[2]}]",
            ("チャンス" if chosen_dice_list.include?(0)),
            r.success? ? "成功（HR=#{hr}、クリティカル#{criticals}）" : "失敗",
          ].compact.join(" ＞ ")
        end
      end

      def calc_hr(target, chosen_dice_list)
        total = chosen_dice_list.sum()
        a = (target - total).abs
        b = (target - total - chosen_dice_list.count(0) * 10).abs
        return [a, b].max
      end

      TABLES = {
        "CR" => DiceTable::Table.new(
          "クリティカル表",
          "1D10",
          [
            "1：「小破」ダメージ+［5］。耐久値-［1］",
            "2：「小破」ダメージ+［5］。耐久値-［1］",
            "3：「小破」ダメージ+［5］。耐久値-［1］",
            "4：「小破」ダメージ+［5］。耐久値-［1］",
            "5：「兵装」損壊を受けるごとに［1D10］を振り、出目に応じた部位の兵装とオプションが《脱落》",
            "6：「上体」攻撃系能力［白兵/ 火器/ 索敵］は各［- 損壊Lv］",
            "7：「脚部」行動系・防御系能力［Iv 値（イニシア値）/ 最大MP/ 回避］は各［- 損壊Lv］",
            "8：「搭乗者」搭乗者の〈最大HP〉および〈HP〉は［-（4 ×損壊Lv）］",
            "9：「搭乗者」搭乗者の〈最大HP〉および〈HP〉は［-（4 ×損壊Lv）］",
            "0：「小破」ダメージ+［5］。耐久値-［1］",
          ]
        )
      }.freeze
    end
  end
end
