# frozen_string_literal: true

module BCDice
  module GameSystem
    class NegikureNegimaki < Base
      # ゲームシステムの識別子
      ID = "NegikureNegimaki"

      # ゲームシステム名
      NAME = "ネジクレネジマキ"

      # ゲームシステム名の読みがな
      SORT_KEY = "ねしくれねしまき"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 行為判定
        nNNx#y: n個のD6を振り、x以上の出目の個数を成功レベルとして判定する
        n: ダイス数（省略時1）
        x: 難易度（省略時4）
        y: 要求成功レベル（省略時1、0は1として扱う）

        ■ 戦闘判定（アタック判定）
        nNAx#y: n個のD6を振り、x以上を成功とする。y以上の成功は直撃ダメージになる
        n: ダイス数（省略時1）
        x: 難易度（省略時4）
        y: クリティカル値（省略時6、0は1として扱う）
        通常ダメージ = 成功レベル - 直撃ダメージ
        直撃ダメージ = 成功した出目のうち y 以上の個数
        ガッツ減少 = 出目 1 の個数

        ■ ストライクの判定
        nNS: n個のD6を振り、出目 1 の個数だけガッツ減少を算出する
        n: ダイス数（省略時1）
        ガッツ減少が 0 なら成功、1 以上なら失敗
      INFO_MESSAGE_TEXT

      register_prefix('\d*NN\d*(#\d+)?', '\d*NA\d*(#\d+)?', '\d*NS')

      def eval_game_system_specific_command(command)
        return eval_action_command(command) || eval_attack_command(command) || eval_guts_command(command)
      end

      private

      def eval_action_command(command)
        m = /\A(\d+)?NN(\d+)?(?:#(\d+))?\z/i.match(command)
        return nil unless m

        dice_count = m[1]&.to_i || 1
        difficulty = m[2]&.to_i || 4
        required_level = [m[3]&.to_i || 1, 1].max

        return nil if dice_count.zero?

        command_text = "(#{dice_count}NN#{difficulty}##{required_level})"

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        success_level = dice_list.count { |value| value >= difficulty }
        detail_text = "[#{dice_list.join(',')}]"

        return build_result(command_text, detail_text, success_level, required_level)
      end

      def eval_attack_command(command)
        m = /\A(\d+)?NA(\d+)?(?:#(\d+))?\z/i.match(command)
        return nil unless m

        dice_count = m[1]&.to_i || 1
        difficulty = m[2]&.to_i || 4
        critical_value = [m[3]&.to_i || 6, 1].max

        return nil if dice_count.zero?

        command_text = "(#{dice_count}NA#{difficulty}##{critical_value})"

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        success_level = dice_list.count { |value| value >= difficulty }
        direct_damage = dice_list.count { |value| value >= difficulty && value >= critical_value }
        guts_loss = dice_list.count(1)
        detail_text = "[#{dice_list.join(',')}]"

        return build_attack_result(command_text, detail_text, success_level, direct_damage, guts_loss)
      end

      def eval_guts_command(command)
        m = /\A(\d+)?NS\z/i.match(command)
        return nil unless m

        dice_count = m[1]&.to_i || 1
        return nil if dice_count.zero?

        command_text = "(#{dice_count}NS)"
        dice_list = @randomizer.roll_barabara(dice_count, 6)
        guts_loss = dice_list.count(1)
        detail_text = "[#{dice_list.join(',')}]"

        return build_guts_result(command_text, detail_text, guts_loss)
      end

      def build_result(command_text, detail_text, success_level, required_level)
        success = success_level >= required_level
        judge_text = success ? translate('success') : translate('failure')
        result_level_text = translate('NegikureNegimaki.result_level', success_level: success_level, required_level: required_level)
        text = "#{command_text} ＞ #{detail_text} ＞ #{result_level_text} ＞ #{judge_text}"

        if success
          return Result.success(text)
        end

        return Result.failure(text)
      end

      def build_attack_result(command_text, detail_text, success_level, direct_damage, guts_loss)
        normal_damage = [success_level - direct_damage, 0].max
        success = success_level.positive?
        damage_text = translate('NegikureNegimaki.damage', normal_damage: normal_damage, direct_damage: direct_damage)
        damage_text += "/#{translate('NegikureNegimaki.guts_loss', guts_loss: guts_loss)}" if guts_loss.positive?
        text = "#{command_text} ＞ #{detail_text} ＞ #{translate('NegikureNegimaki.success_level', success_level: success_level)} ＞ #{damage_text}"

        if success
          return Result.success(text)
        end

        return Result.failure(text)
      end

      def build_guts_result(command_text, detail_text, guts_loss)
        success = guts_loss.zero?
        text = "#{command_text} ＞ #{detail_text} ＞ #{translate('NegikureNegimaki.guts_loss', guts_loss: guts_loss)}"

        if success
          return Result.success(text)
        end

        return Result.failure(text)
      end
    end
  end
end
