# frozen_string_literal: true

module BCDice
  module GameSystem
    class JekyllAndHyde < Base
      # ゲームシステムの識別子
      ID = "JekyllAndHyde"

      # ゲームシステム名
      NAME = "ジキルとハイドとグリトグラ"

      # ゲームシステム名の読みがな
      SORT_KEY = "*しきるとはいととくりとくら"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ・難易度算出コマンド　DDC
        ・判定コマンド　RCx　or　RCx+y　or　RCx-y（x＝難易度、y=修正値（省略可能））
        ・目標決定表　GOALT
        ジキルとハイドとグリトグラ　byかむらい
      HELP

      TABLES = {
        "GOALT" => DiceTable::Table.new("目標決定表", "1D6", [
          "「主人格の目的達成」",
          "「主人格の目的阻害」",
          "「主人格のハッピーエンド（目的達成しなくてもよい）」",
          "「主人格のバッドエンド（目的達成していてもよい）」",
          "「自分の人格が目的を決定できる」",
          "「主人格の目的達成」「主人格の目的阻害」「主人格のハッピーエンド（目的達成しなくてもよい）」「主人格のバッドエンド（目的達成していてもよい）」「自分の人格が目的を決定できる」のどれかを自由に選べる"
        ])
      }.freeze

      register_prefix('(RC\d+|DDC|GOALT).*')

      def initialize(command)
        super(command)
        @sortType = true
        @d66Type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command begin string", command)

        result = checkRoll(command)
        return result unless result.empty?

        debug("各種表として処理")
        return rollTableCommand(command)
      end

      def checkRoll(string)
        debug("checkRoll begin string", string)

        return "" unless /^RC(\d+)(([+]|-)(\d+))?$/i =~ string

        target = Regexp.last_match(1).to_i
        operator = Regexp.last_match(3)
        value = Regexp.last_match(4).to_i
        modify = 0

        result = "判定　難易度：#{target}　"

        unless operator.nil?
          modify = value if operator == "+"
          modify = value * -1 if operator == "-"
          result += "修正値：#{modify}　"
        end

        d1, d2 = @randomizer.roll_barabara(2, 6)

        result += "＞　出目：#{d1}、#{d2}　＞　"

        if d1 == d2
          result += "ゾロ目！【Ｃｒｉｔｉｃａｌ】"
        elsif d1 + d2 == 7
          result += "ダイスの出目が表裏！【Ｆｕｍｂｌｅ】"
        elsif d1 + d2 + modify >= target
          result += "#{d1 + d2 + modify}、難易度以上！【Ｓｕｃｃｅｓｓ】"
        else
          result += "#{d1 + d2 + modify}、難易度未満！【Ｍｉｓｓ】"
        end

        return result
      end

      ####################
      # 各種表

      def rollTableCommand(command)
        command = command.upcase

        debug("rollDiceCommand command", command)

        if command == "DDC"
          return choiceddcTable()
        end

        roll_tables(command, TABLES)
      end

      # ##呼び出し＋α

      def choiceddcTable
        name = "難易度決定"
        text = "#{name}："

        d1, d2 = @randomizer.roll_barabara(2, 6)
        text += "　出目：#{d1}、#{d2}　＞　"

        if d1 >= d2
          text += "#{d1}－#{d2}＝#{d1 - d2}　＞　難易度#{5 + (d1 - d2)}"
        else
          text += "#{d2}－#{d1}＝#{d2 - d1}　＞　難易度#{5 + (d2 - d1)}"
        end

        return text
      end
    end
  end
end
