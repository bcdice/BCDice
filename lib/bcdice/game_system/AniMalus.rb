# frozen_string_literal: true

module BCDice
  module GameSystem
    class AniMalus < Base
      # ゲームシステムの識別子
      ID = 'AniMalus'

      # ゲームシステム名
      NAME = 'アニマラス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あにまらす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■ステータスのダイス判定　nAM<=t,x        n:能力値 t:成功値 x:必要成功数
        例)3AM<=2,1: ダイスを3個振って、成功値2,必要成功数1で判定。その結果(成功数,成功・失敗)を表示

        ■探索技能のダイス判定　AI<=t,x        t:探索技能レベル x:必要成功数
        例)AI<=3,1: ダイスを3個振って、探索技能レベル3,必要成功数1で判定。その結果(成功数,成功・失敗)を表示

        ■攻撃判定　AA<=t        t:戦闘技能レベル
        例)AA<=3: ダイスを3個振って、戦闘技能レベル3で判定。その結果(成功・失敗,ダメージ,クリティカル,ファンブル)を表示

        ■防御判定　AG=t        t:攻撃技能レベル
        例)AG=2: ダイスを3個振って、攻撃技能レベル2で判定。その結果(成功・失敗,ダメージ,クリティカル,ファンブル)を表示

        ■回避判定　AD=t        t:攻撃技能レベル
        例)AD=3: ダイスを1個振って、攻撃技能レベル3で判定。その結果(成功・失敗)を表示
      INFO_MESSAGETEXT

      register_prefix('\d*A[MIAGD]')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) ||
          resolute_investigation(command) ||
          resolute_attacking(command) ||
          resolute_guarding(command) ||
          resolute_dodging(command)
      end

      private

      # ステータスの判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^(\d+)AM<=(\d+),(\d)$/.match(command)
        return nil unless m

        num_dice = m[1].to_i
        num_target = m[2].to_i
        num_success = m[3].to_i

        dice = @randomizer.roll_barabara(num_dice, 6).sort
        dice_text = dice.join(",")
        success_num = dice.count { |val| val <= num_target }
        output = "(#{num_dice}AM<=#{num_target},#{num_success}) ＞ #{dice_text} ＞ 成功数#{success_num}"
        if success_num >= num_success
          output += " ＞ 成功"
          return Result.success(output)
        else
          output += " ＞ 失敗"
          return Result.failure(output)
        end
      end

      # 探索技能の判定
      # @param [String] command
      # @return [Result]
      def resolute_investigation(command)
        m = /^AI<=(\d+),(\d)$/.match(command)
        return nil unless m

        num_target = m[1].to_i
        num_success = m[2].to_i

        dice = @randomizer.roll_barabara(3, 6).sort
        dice_text = dice.join(",")
        success_num = dice.count { |val| val <= num_target }
        output = "(AI<=#{num_target},#{num_success}) ＞ #{dice_text} ＞ 成功数#{success_num}"
        if success_num >= num_success
          output += " ＞ 成功"
          return Result.success(output)
        else
          output += " ＞ 失敗"
          return Result.failure(output)
        end
      end

      # 攻撃技能の判定
      # @param [String] command
      # @return [Result]
      def resolute_attacking(command)
        m = /^AA<=(\d+)$/.match(command)
        return nil unless m

        num_target = m[1].to_i

        dice = @randomizer.roll_barabara(3, 6).sort
        dice_text = dice.join(",")
        success_num = dice.count { |val| val <= num_target }
        is_critical = dice[0] == 1 && dice[1] == 2 && dice[2] == 3
        is_fumble = dice[0] == 4 && dice[1] == 5 && dice[2] == 6
        damage1 = dice.max
        damage2 = dice.max
        if dice[0] == dice[1] && dice[1] == dice[2] && dice[2] <= num_target
          damage2 += 6
          damage1 = damage2
        elsif dice[0] == dice[1] && dice[1] <= num_target
          damage2 += 3
        elsif dice[1] == dice[2] && dice[2] <= num_target
          damage2 += 3
        end

        return Result.new.tap do |result|
          result.critical = is_critical
          result.fumble = is_fumble
          result.condition = (success_num > 0)

          sequence = [
            "(AA<=#{num_target})",
            dice_text,
            "成功数#{success_num}",
            if result.success?
              "成功"
            else
              "失敗"
            end
          ].compact
          if result.success?
            if damage1 == damage2
              sequence.push("ダメージ(#{damage1})")
            else
              sequence.push("ダメージ(#{damage1}か#{damage2})")
            end
          end
          sequence.push("クリティカル") if result.critical?
          sequence.push("ファンブル") if result.fumble?

          result.text = sequence.join(" ＞ ")
        end
      end

      # 防御技能の判定
      # @param [String] command
      # @return [Result]
      def resolute_guarding(command)
        m = /^AG=(\d+)$/.match(command)
        return nil unless m

        num_target = m[1].to_i

        dice = @randomizer.roll_barabara(3, 6).sort
        dice_text = dice.join(",")
        success_num = dice.count(num_target)
        is_critical = dice[0] == 1 && dice[1] == 2 && dice[2] == 3
        is_fumble = dice[0] == 4 && dice[1] == 5 && dice[2] == 6

        return Result.new.tap do |result|
          result.critical = is_critical
          result.fumble = is_fumble
          result.condition = (success_num > 0)

          sequence = [
            "(AG=#{num_target})",
            dice_text,
            "成功数#{success_num}",
            if result.success?
              "成功 ＞ ダメージ軽減(#{success_num * 2})"
            else
              "失敗"
            end
          ].compact
          sequence.push("クリティカル") if result.critical?
          sequence.push("ファンブル") if result.fumble?

          result.text = sequence.join(" ＞ ")
        end
      end

      # 回避技能の判定
      # @param [String] command
      # @return [Result]
      def resolute_dodging(command)
        m = /^AD=(\d+)$/.match(command)
        return nil unless m

        num_target = m[1].to_i

        dice = @randomizer.roll_barabara(1, 6)
        dice_text = dice.join(",")
        success_num = dice.count(num_target)

        return Result.new.tap do |result|
          result.condition = (success_num > 0)

          sequence = [
            "(AD=#{num_target})",
            dice_text,
            "成功数#{success_num}",
            if result.success?
              "成功(ダメージ無効)"
            else
              "失敗"
            end
          ].compact

          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
