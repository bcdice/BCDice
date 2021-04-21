# frozen_string_literal: true

module BCDice
  module GameSystem
    class SamsaraBallad < Base
      # ゲームシステムの識別子
      ID = 'SamsaraBallad'

      # ゲームシステム名
      NAME = 'サンサーラ・バラッド'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'さんさあらはらつと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        SB	 通常のD100ロールを行う
        SBS	 スワップロールでD100ロールを行う
        SB#x@y	 F値をx、C値をyとして通常のD100ロールを行う
        SBS#x@y	 F値をx、C値をyとしてスワップロールでD100ロールを行う

        例：
        SB<=85 通常の技能で成功率85%の判定
        SBS<=70 習熟を得た技能で成功率70%の判定
        SBS#3@7<=80 習熟を得た技能で、F値3、C値7で成功率80%の攻撃判定
        SB<57 通常の技能で、能動側の達成値が57の受動判定
        SBS<70 習熟を得た技能で、能動側の達成値が70の受動判定
      MESSAGETEXT

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('SBS?')

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command Begin")

        parser = Command::Parser.new('SBS', 'SB', round_type: round_type)
                                .enable_critical
                                .enable_fumble
                                .restrict_cmp_op_to(nil, :<=, :<)
        cmd = parser.parse(command)

        unless cmd
          return nil
        end

        if cmd.command == 'SB'
          places_text = nil
          total = @randomizer.roll_once(100)
        else
          a = @randomizer.roll_once(10)
          b = @randomizer.roll_once(10)
          places_text = "#{a},#{b}"
          places = [a, b].map { |n| n == 10 ? 0 : n }.sort

          total = places[0] * 10 + places[1]
          total = 100 if total == 0
        end

        result = compare(total, cmd)

        result_str =
          if result.failure?
            "失敗"
          elsif result.success?
            "成功"
          end

        additional_str =
          if result.fumble?
            "ファンブル"
          elsif result.critical?
            "クリティカル"
          end

        sequence = [
          "(D100#{cmd.cmp_op}#{cmd.target_number})",
          places_text,
          total.to_s,
          result_str,
          additional_str,
        ].compact

        result.text = sequence.join(" ＞ ")

        return result
      end

      private

      # @return [Result]
      def compare(total, cmd)
        if [:<=, :<].include?(cmd.cmp_op)
          if !total.send(cmd.cmp_op, cmd.target_number)
            Result.failure(nil)
          elsif fumble_?(total, cmd.fumble)
            Result.new.tap do |r|
              r.success = true
              r.fumble = true
            end
          elsif critical_?(total, cmd.critical)
            Result.critical(nil)
          else
            Result.success(nil)
          end
        elsif fumble_?(total, cmd.fumble)
          # ファンブル優先
          Result.new.tap do |r|
            r.fumble = true
          end
        elsif critical_?(total, cmd.critical)
          Result.new.tap do |r|
            r.critical = true
          end
        else
          Result.new
        end
      end

      # @param total [Integer]
      # @param fumble [Integer, nil]
      # @return [Boolean]
      def fumble_?(total, fumble)
        fumble && (total % 10 <= fumble)
      end

      # @param total [Integer]
      # @param critical [Integer, nil]
      # @return [Boolean]
      def critical_?(total, critical)
        critical && (total % 10 >= critical)
      end
    end
  end
end
