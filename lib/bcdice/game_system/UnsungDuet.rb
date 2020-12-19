# frozen_string_literal: true

require "bcdice"

module BCDice
  module GameSystem
    class UnsungDuet < Base
      ID = "UnsungDuet"
      NAME = "アンサング・デュエット"
      SORT_KEY = "あんさんくてゆえつと"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ シフター用判定 (shifter, UDS)
          1D10をダイスロールして判定を行います。
          例） shifter, UDS, shifter>=5, shifter+1>=6

        ■ バインダー用判定 (binder, UDB)
          2D6をダイスロールして判定を行います。
          例） binder, UDB, binder>=5, binder+1>=6

        ■ 変異表
          ・外傷 (HIN, HInjury)
          ・体調の変化 (HPH, HPhysical)
          ・恐怖 (HFE, HFear)
          ・幻想化 (HFA, HFantasy)
          ・精神 (HMI, HMind)
          ・そのほか (HOT, HOther)
      MESSAGETEXT

      ALIAS_1D10 = ["shifter", "UDS"].freeze
      ALIAS_2D6 = ["binder", "UDB"].freeze

      SHIFTER_ALIAS_REG = /^#{ALIAS_1D10.join('|')}/i.freeze
      BINDER_ALIAS_REG = /^#{ALIAS_2D6.join('|')}/i.freeze

      register_prefix(ALIAS_1D10, ALIAS_2D6)

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        roll_replaced_command_if_match(command, SHIFTER_ALIAS_REG, "1D10") ||
          roll_replaced_command_if_match(command, BINDER_ALIAS_REG, "2D6") ||
          roll_tables(command, TABLES)
      end

      def roll_replaced_command_if_match(command, regexp, dist)
        if command.match?(regexp)
          CommonCommand::AddDice.eval(command.sub(regexp, dist), self, @randomizer)
        end
      end

      ALIAS = {
        "HInjury" => "HIN",
        "HPhysical" => "HPH",
        "HFear" => "HFE",
        "HFantasy" => "HFA",
        "HMind" => "HMI",
        "HOther" => "HOT",
      }.transform_keys(&:upcase)

      TABLES = {
        "HIN" => DiceTable::Table.new(
          "変異表：外傷",
          "1D6",
          [
            "顔の傷 → 顔にできた傷。じわりと血がにじむ",
            "大きな怪我 → 早く手当てをしないと命に関わる",
            "痛みのない傷 → 大きな傷なのに、なぜか痛くない",
            "喪失 → 身体のどこかが消えてしまった",
            "文字のような傷跡 → 読めない文字のような傷",
            "模様を描くアザ → 模様のような、身体にできたアザ",
          ]
        ),
        "HPH" => DiceTable::Table.new(
          "変異表：体調の変化",
          "1D6",
          [
            "視界がぼやける → 目の焦点が合わない",
            "耳鳴り → ずっと甲高い音が鳴り続けている気がする",
            "異様な寒気 → 凍えそうなほどに寒く感じる",
            "発汗 → 暑いわけでもないのに、汗がだらだらと",
            "幻覚 → それが本物か幻か、区別がつかない",
            "走馬灯 → 過去のことを次々と思い出してしまう",
          ]
        ),
        "HFE" => DiceTable::Table.new(
          "変異表：恐怖",
          "1D6",
          [
            "不安 → 漠然とした不安が心を蝕む",
            "狭い場所が怖い → 狭い場所に入りたくない",
            "震えが止まらない → どうしても落ち着かない",
            "物音が怖い → ほんの小さな物音にも怯えてしまう",
            "暗い場所が怖い → 灯りのない場所がひどく恐ろしい",
            "誰かがついてくる → 誰かが後ろにいる気がする……",
          ]
        ),
        "HFA" => DiceTable::Table.new(
          "変異表：幻想化",
          "1D6",
          [
            "硝子化 → 身体の一部がガラスのように透明に",
            "羽毛化 → 身体のどこかから羽毛が生えてくる",
            "植物化 → ツタや葉が身体から生えてくる",
            "動物の瞳 → 瞳の形が動物のそれに変わってしまう",
            "有角化 → 額や側頭部から角が生えてくる",
            "陶器化 → 皮膚が陶器のようなものに変わっていく",
          ]
        ),
        "HMI" => DiceTable::Table.new(
          "変異表：精神",
          "1D6",
          [
            "記憶の混乱 → ここはどこ、どうしてこんなところに?",
            "幼少期の記憶 → 口調や態度が幼くなってしまう",
            "素直 → 思ったことを全部言ってしまう",
            "蛮勇 → パートナーを守るために無茶ばかりする",
            "疑心暗鬼 → 何もかもが悪い方向にしか考えられない",
            "食べちゃいたい → パートナーをかじりたくなる",
          ]
        ),
        "HOT" => DiceTable::Table.new(
          "変異表：そのほか",
          "1D6",
          [
            "影絵化 → 身体の一部が影のようになる",
            "水槽化 → 身体の一部が水槽のようなものになる",
            "涙が止まらない → なぜか涙が流れ続ける",
            "鉤爪 → 手や足が、獣のような鉤爪になる",
            "未来視 → 未来が見えてしまう。本当かどうかは不明",
            "帰りたくない → 現実に帰りたくないと微かに思う",
          ]
        ),
      }.freeze

      register_prefix(ALIAS.keys, TABLES.keys)
    end
  end
end
