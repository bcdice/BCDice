# frozen_string_literal: true

module BCDice
  module GameSystem
    class CastleInGray < Base
      # ゲームシステムの識別子
      ID = "CastleInGray"

      # ゲームシステム名
      NAME = "灰色城綺譚"

      # ゲームシステム名の読みがな
      SORT_KEY = "はいいろしようきたん"

      HELP_MESSAGE = <<~TEXT
        ■ 色占い (BnWm)
        n: 黒
        m: 白
        n, m は1～12の異なる整数

        例) B12W7
        例) B5W12

        ■ 悪意の渦による占い (MALn)
        n: 悪意の渦
        n は1～12の整数

        ■ その他
        ・感情表 ET
        ・暗示表(黒) BIT
        ・暗示表(白) WIT
      TEXT

      TABLES = {
        "ET" => DiceTable::Table.new(
          "感情表",
          "1D12",
          [
            "友情(白)／敵視(黒)",
            "恋慕(白)／嫌悪(黒)",
            "信頼(白)／不信(黒)",
            "同情(白)／憐憫(黒)",
            "憧憬(白)／劣等感(黒)",
            "尊敬(白)／蔑視(黒)",
            "忠誠(白)／執着(黒)",
            "有用(白)／邪魔(黒)",
            "許容(白)／罪悪感(黒)",
            "羨望(白)／嫉妬(黒)",
            "共感(白)／拒絶(黒)",
            "愛情(白)／狂信(黒)"
          ]
        ),
        "BIT" => DiceTable::Table.new(
          "暗示表(黒)",
          "1D12",
          [
            "終わりなき夜に生まれつく者もあり",
            "悪意もて真実を語らば",
            "笑えども笑みはなし",
            "影より抜け出ることあたわじ",
            "心の赴くままに手をとれ",
            "時ならぬ嵐の過ぎ去るを待つ",
            "赦されぬと知るがゆえに",
            "見張りは持ち場を離れる",
            "誰もが盲いたる彷徨い人なり",
            "落ちる日を眺めるがごとく",
            "冷たく雨ぞ降りしきる",
            "今日は笑む花も明日には枯れゆく"
          ]
        ),
        "WIT" => DiceTable::Table.new(
          "暗示表(白)",
          "1D12",
          [
            "無垢なる者のみが真実を得る",
            "げに慈悲深きは沈黙なり",
            "懐かしき日々は去りぬ",
            "束の間に光さす",
            "迷える者に手を差し伸べよ",
            "嵐の前には静けさがある",
            "どうか責めないで",
            "灯した明かりを絶やさぬように",
            "目を開けて見よ",
            "淑やかに訪れる",
            "今こそ泣け、さもなくば二度と泣くな",
            "時が許す間に薔薇を摘め"
          ]
        ),
      }.freeze

      register_prefix('B', 'MAL', TABLES.keys)

      def eval_game_system_specific_command(command)
        return roll_color(command) || roll_mal(command) || roll_tables(command, TABLES)
      end

      def roll_color(command)
        m = /^B(\d{1,2})W(\d{1,2})$/.match(command)
        return nil unless m

        black = m[1].to_i
        white = m[2].to_i
        return nil unless black.between?(1, 12) && white.between?(1, 12)

        value = @randomizer.roll_once(12)

        if black == white
          return color_text(black, white, value, '白と黒は重ねられません')
        end

        if white > black
          return color_text(black, white, value, black <= value && value < white ? '黒' : '白')
        else
          return color_text(black, white, value, white <= value && value < black ? '白' : '黒')
        end
      end

      def color_text(black, white, value, result)
        return "色占い(黒#{black}白#{white}) ＞ [#{value}] ＞ #{result}"
      end

      def roll_mal(command)
        m = /^MAL(\d{1,2})$/i.match(command)
        return nil unless m

        mal = m[1].to_i
        return nil unless mal.between?(1, 12)

        value = @randomizer.roll_once(12)
        result = value <= mal ? '黒' : '白'
        return "悪意の渦(#{mal}) ＞ [#{value}] ＞ #{result}"
      end
    end
  end
end
