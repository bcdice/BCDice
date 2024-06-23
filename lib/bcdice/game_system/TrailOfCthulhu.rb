# frozen_string_literal: true

module BCDice
  module GameSystem
    class TrailOfCthulhu < Base
      # ゲームシステムの識別子
      ID = 'TrailOfCthulhu'

      # ゲームシステム名
      NAME = 'トレイル・オブ・クトゥルフ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とれいるおふくとうるう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■技能判定　TCb[>=t]   b:消費プール・ポイント t:難易度(省略可能)

        例)TC2>=5:消費プール・ポイント2,難易度5で技能判定し、その結果を表示。
           TC>=3: 難易度3で技能判定する。
           TC:    難易度指定せずに技能判定する。
           TC3:   消費プール・ポイント3,難易度指定せずに技能判定する。

      INFO_MESSAGETEXT

      register_prefix("TC")

      def eval_game_system_specific_command(command)
        resolute_action(command)
      end

      private

      # 技能判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /TC([+\d]*)(>=(\d+))?/.match(command)
        return nil unless m

        bonus = m[1].to_i
        difficulty = m[3].to_i

        dice = @randomizer.roll_once(6)
        total = dice + bonus

        return Result.new.tap do |result|
          if difficulty > 0
            result.condition = (total >= difficulty)

            sequence = [
              "(TC#{bonus}>=#{difficulty})",
              "#{dice}+#{bonus}",
              total.to_s,
              result.success? ? "成功" : "失敗"
            ].compact
          else
            sequence = [
              "(TC#{bonus})",
              "#{dice}+#{bonus}",
              total.to_s,
            ].compact
          end

          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
