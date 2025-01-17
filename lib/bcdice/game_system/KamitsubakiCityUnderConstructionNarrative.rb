# frozen_string_literal: true

module BCDice
  module GameSystem
    class KamitsubakiCityUnderConstructionNarrative < Base
      # ゲームシステムの識別子
      ID = 'KamitsubakiCityUnderConstructionNarrative'

      # ゲームシステム名
      NAME = '神椿市建設中。NARRATIVE'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かみつはきしけんせつちゆうならていふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・可組（KA）
        　KA6 行動判定
        　KA8 技能ロール
        　KA10 特技ロール
        　KA12 Aロール

        ・裏組（RI）
        　RI6 行動判定
        　RI8 技能ロール
        　RI10 特技ロール
        　RI12 Aロール

        ・羽組（HA）
        　HA6 行動判定
        　HA8 技能ロール
        　HA10 特技ロール
        　HA12 Aロール

        ・星組（SE）
        　SE6 行動判定
        　SE8 技能ロール
        　SE10 特技ロール
        　SE12 Aロール

        ・狐組（CO）
        　CO6 行動判定
        　CO8 技能ロール
        　CO10 特技ロール
        　CO12 Aロール

        ・GM用
        　GM6 （成否判定なし）
        　GM8 技能ロール
        　GM10 特技ロール
        　Q12 Qロール

        ・存在証明 EXI<=x
        　存在証明の判定を行う
        　x: 存在値
      INFO_MESSAGE_TEXT

      def eval_game_system_specific_command(command)
        roll_kumi(command) || roll_existence(command)
      end

      private

      def roll_kumi(command)
        table = TABLES[command]
        unless table
          return nil
        end

        return table.roll(@randomizer)
      end

      class KumiDice
        def initialize(items)
          @items = items.freeze
        end

        CRITICAL = "M"
        FUMBLE = "Q"

        def roll(randomizer)
          dice = randomizer.roll_once(@items.length)
          chosen = @items[dice - 1]

          fumble = chosen == FUMBLE
          critical = chosen == CRITICAL

          result_tail =
            if fumble
              "ファンブル"
            elsif critical
              "マジック"
            elsif !chosen.empty?
              "成功"
            else
              "失敗"
            end

          Result.new.tap do |r|
            r.critical = critical
            r.fumble = fumble
            r.condition = !chosen.empty? && !r.fumble?
            r.text = [
              "(D#{@items.length})",
              dice,
              chosen.empty? ? nil : chosen,
              result_tail
            ].compact.join(" ＞ ")
          end
        end
      end

      class KumiD6
        def initialize(success_symbol)
          @success_symbol = success_symbol
        end

        TABLE = ["裏", "羽", "星", "狐", "可", "Q"].freeze

        def roll(randomizer)
          dice = randomizer.roll_once(6)
          chosen = TABLE[dice - 1]

          Result.new.tap do |r|
            unless @success_symbol.nil?
              r.fumble = chosen == "Q"
              r.condition = chosen == @success_symbol
            end

            result_tail =
              if r.fumble?
                "ファンブル"
              elsif r.success?
                "成功"
              elsif r.failure?
                "失敗"
              end

            r.text = [
              "(D6)",
              dice,
              chosen,
              result_tail
            ].compact.join(" ＞ ")
          end
        end
      end

      class QDice
        def initialize(items)
          @items = items.freeze
        end

        CRITICAL = "M"

        def roll(randomizer)
          dice = randomizer.roll_once(@items.length)
          chosen = @items[dice - 1]

          critical = chosen == CRITICAL

          result_tail =
            if critical
              "マジック"
            elsif !chosen.empty?
              "成功"
            else
              "失敗"
            end

          Result.new.tap do |r|
            r.critical = critical
            r.condition = !chosen.empty?
            r.text = [
              "(D#{@items.length})",
              dice.to_s,
              chosen.empty? ? nil : chosen,
              result_tail,
            ].compact.join(" ＞ ")
          end
        end
      end

      def roll_existence(command)
        m = /^EXI<=(\d+)$/.match(command)
        unless m
          return nil
        end

        target = m[1].to_i
        dice = @randomizer.roll_once(20)
        Result.new.tap do |r|
          r.critical = dice == 1
          r.fumble = dice == 20
          r.condition = (dice <= target && !r.fumble?) || r.critical?

          result_tail =
            if r.critical?
              "M ＞ マジック"
            elsif r.fumble?
              "Q ＞ ファンブル"
            elsif r.success?
              "成功"
            else
              "失敗"
            end

          r.text = [
            "(D20<=#{target})",
            dice,
            result_tail
          ].join(" ＞ ")
        end
      end

      TABLES = {
        "KA6" => KumiD6.new("可"),
        "KA8" => KumiDice.new(["Q", "", "", "", "可", "可", "可", "M"]),
        "KA10" => KumiDice.new(["Q", "", "", "可", "可", "可", "可", "可", "M", "M"]),
        "KA12" => KumiDice.new(["Q", "", "", "可", "可", "可", "可", "可", "可", "可", "M", "M"]),

        "RI6" => KumiD6.new("裏"),
        "RI8" => KumiDice.new(["Q", "", "", "", "裏", "裏", "裏", "M"]),
        "RI10" => KumiDice.new(["Q", "", "", "裏", "裏", "裏", "裏", "裏", "M", "M"]),
        "RI12" => KumiDice.new(["M", "M", "裏", "裏", "裏", "裏", "裏", "裏", "裏", "", "", "Q"]),

        "HA6" => KumiD6.new("羽"),
        "HA8" => KumiDice.new(["Q", "", "", "", "羽", "羽", "羽", "M"]),
        "HA10" => KumiDice.new(["Q", "", "", "羽", "羽", "羽", "羽", "羽", "M", "M"]),
        "HA12" => KumiDice.new(["Q", "Q", "羽", "羽", "羽", "", "", "", "M", "M", "M", "M"]),

        "SE6" => KumiD6.new("星"),
        "SE8" => KumiDice.new(["Q", "", "", "", "星", "星", "星", "M"]),
        "SE10" => KumiDice.new(["Q", "", "", "星", "星", "星", "星", "星", "M", "M"]),
        "SE12" => KumiDice.new(["星", "", "星", "星", "M", "Q", "M", "星", "星", "星", "", "星"]),

        "CO6" => KumiD6.new("狐"),
        "CO8" => KumiDice.new(["Q", "", "", "", "狐", "狐", "狐", "M"]),
        "CO10" => KumiDice.new(["Q", "", "", "狐", "狐", "狐", "狐", "狐", "M", "M"]),
        "CO12" => KumiDice.new(["Q", "", "", "狐狐狐", "狐狐", "狐", "狐狐狐", "狐狐", "狐", "狐", "M", "M"]),

        "GM6" => KumiD6.new(nil),
        "GM8" => KumiDice.new(["Q", "", "", "", "W", "W", "W", "M"]),
        "GM10" => KumiDice.new(["Q", "", "", "W", "W", "W", "W", "W", "M", "M"]),
        "Q12" => QDice.new(["", "", "", "Q", "Q", "Q", "Q", "Q", "Q", "Q", "M", "M"])
      }.freeze

      register_prefix("EXI", TABLES.keys)
    end
  end
end
