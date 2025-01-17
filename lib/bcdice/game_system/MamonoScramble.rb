# frozen_string_literal: true

module BCDice
  module GameSystem
    class MamonoScramble < Base
      # ゲームシステムの識別子
      ID = 'MamonoScramble'

      # ゲームシステム名
      NAME = 'マモノスクランブル'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まものすくらんふる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定 xMS<=t
        　[判定]を行う。成否と[マリョク]の上昇量を表示する。
        　x: ダイス数
        　t: 能力値（目標値）

        ・アクシデント表 ACC
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sides_implicit_d = 12
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        roll_ability(command) || roll_tables(command, TABLES)
      end

      private

      def roll_ability(command)
        parser = Command::Parser.new("MS", round_type: @round_type)
                                .has_prefix_number
                                .disable_modifier
                                .restrict_cmp_op_to(:<=)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_list = @randomizer.roll_barabara(parsed.prefix_number, 12).sort
        count_success = dice_list.count { |value| value <= parsed.target_number }
        count_one = dice_list.count(1)
        is_critical = count_one > 0
        has_twelve = dice_list.include?(12)

        maryoku =
          if has_twelve && !is_critical
            0
          else
            count_success + count_one
          end

        sequence = [
          "(#{parsed})",
          "[#{dice_list.join(',')}]",
          count_success > 0 ? "成功, [マリョク]が#{maryoku}上がる" : "失敗"
        ]

        return Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          r.condition = count_success > 0
          r.critical = r.success? && is_critical
        end
      end

      TABLES = {
        "ACC" => DiceTable::Table.new(
          "アクシデント表",
          "1D12",
          [
            "思わぬ対立：[判定]で10〜12の出目を1個でも出した場合、【耐久値】を2点減らす。",
            "都市の迷宮化：[判定]に【社会】を使用できない。",
            "不穏な天気：特別な効果は発生しない。",
            "突然の雷雨：エリアの[特性]に[雨]や[水たまり]などを足してもいい。",
            "関係ない危機：[判定]に失敗したPCの【耐久値】を2点減らす。",
            "からりと晴天：エリアの[特性]に[強い日光]や[日だまり]などを足してもいい。",
            "謎のお祭り：[判定]で1〜3の出目を1個でも出した場合、【耐久値】を2点回復する。",
            "すごい人ごみ：エリアの[特性]に[野次馬]や[観光客]などを足してもいい。",
            "マリョク乱気流：[判定]に【異質】を使用できない。",
            "魔術テロ事件：GMが1Dをロールする。出目が1〜3なら【身体】、出目が4〜6なら【異質】、出目が7〜9なら【社会】が[判定]で使えない。10〜12は何も起きない。",
            "マリョク低気圧：[判定]に【身体】を使用できない。",
            "平穏な時間：特別な効果は発生しない。",
          ]
        )
      }.freeze

      register_prefix('\d+MS', TABLES.keys)
    end
  end
end
