# frozen_string_literal: true

module BCDice
  module GameSystem
    class TrailOfCthulhu < Base
      # ゲームシステムの識別子
      ID = 'TrailOfCthulhu'

      # ゲームシステム名
      NAME = 'トレイル・オブ・クトゥルー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とれいるおふくとうるう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■技能判定　TCb[>=t]   b:消費プール・ポイント t:難易度(省略可能)

        例)TC2>=5:消費プール・ポイント2,難易度5で技能判定し、その結果を表示する。
           TC>=3: 難易度3で技能判定し、その結果を表示する。
           TC:    難易度指定せずに技能判定する。
           TC3:   消費プール・ポイント3,難易度指定せずに技能判定する。

        ■神話的狂気表　MMT[a,b]   a,b:除外する神話的狂気(省略時は全神話的狂気を表示する)

        例)MMT[1,8]: 神話的狂気のうち、1番と8番を除外してロールし、神話的狂気を決定する。
           MMT2,6:   神話的狂気のうち、2番と6番を除外してロールし、神話的狂気を決定する。
           MMT:      神話的狂気を1番から8番まで列挙する。

      INFO_MESSAGETEXT

      register_prefix("TC", "MMT")

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) ||
          roll_mythos_madness_table(command)
      end

      private

      # 技能判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^TC([+\d]*)(>=(\d+))?/.match(command)
        return nil unless m

        bonus =
          if m[1].empty?
            0
          else
            Arithmetic.eval(m[1], @round_type)
          end

        if bonus.nil?
          return nil
        end

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

      # 神話的狂気表
      MITHOS_MADDNESS = [
        "1:強迫性障害",
        "2:恐怖症",
        "3:誇大妄想狂",
        "4:殺人狂",
        "5:恣意的記憶喪失",
        "6:多重人格障害",
        "7:偏執症",
        "8:妄想症",
      ].freeze

      def roll_mythos_madness_table(command)
        m = /^MMT(\[?([1-8],[1-8])\]?)?/.match(command)
        return nil unless m

        sequence = []
        result_text = ""
        if m[1]
          exclusion_number = m[2].split(',')
          return nil unless exclusion_number.length == 2

          sequence = ["(MMT[#{exclusion_number.join(',')}])"]
          is_exclusion_number = true
          while is_exclusion_number
            idx = @randomizer.roll_once(8).to_i
            if idx != exclusion_number[0].to_i && idx != exclusion_number[1].to_i
              result_text = MITHOS_MADDNESS[idx - 1]
              is_exclusion_number = false
            end
          end
        else
          sequence = ["(MMT)"]
          mithos_maddness_all = []
          (1..8).each do |i|
            mithos_maddness_all.push(MITHOS_MADDNESS[i - 1])
          end
          result_text = mithos_maddness_all.join(", ")
        end

        return Result.new.tap do |result|
          sequence.push(result_text)
          result.text = sequence.join(" ＞ ")
        end
      end
    end
  end
end
