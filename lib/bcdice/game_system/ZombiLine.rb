# frozen_string_literal: true

module BCDice
  module GameSystem
    class ZombiLine < Base
      # ゲームシステムの識別子
      ID = "ZombiLine"

      # ゲームシステム名
      NAME = "ゾンビライン"

      # ゲームシステム名の読みがな
      SORT_KEY = "そんひらいん"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (xZL<=y)
        　x：ダイス数(省略時は1)
        　y：成功率

        ■ 各種表
        　ストレス症状表 SST
        　食材表 IT
      TEXT

      def initialize(command)
        super(command)
        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        return check_action(command) || roll_tables(command, TABLES)
      end

      def check_action(command)
        parser = Command::Parser.new("ZL", round_type: @round_type)
                                .enable_prefix_number
                                .disable_modifier
                                .restrict_cmp_op_to(:<=)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_count = parsed.prefix_number || 1
        target_num = parsed.target_number

        debug(dice_count)

        dice_list = @randomizer.roll_barabara(dice_count, 100).sort
        is_success = dice_list.any? { |i| i <= target_num }
        is_critical = dice_list.any? { |i| i <= 5 }
        is_fumble = dice_list.any? { |i| i >= 96 && i > target_num }
        if is_critical && is_fumble
          is_critical = false
          is_fumble = false
        end

        success_message =
          if is_success && is_critical
            "成功(クリティカル)"
          elsif is_success && is_fumble
            "成功(ファンブル)"
          elsif is_success
            "成功"
          elsif is_fumble
            "失敗(ファンブル)"
          else
            "失敗"
          end
        sequence = [
          "(#{parsed})",
          "[#{dice_list.join(',')}]",
          success_message
        ]

        Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          r.condition = is_success
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end

      TABLES = {
        'SST' => DiceTable::Table.new(
          'ストレス症状表',
          '1D10',
          [
            '憤怒：一番近い敵を攻撃（成功率+20%）しにいきます。近くに敵がいない場合、誰かのストレスを＋１させます。　頭に血が上り、誰かに怒りをぶつけます。',
            '逃避：落下してでも敵から逃げるように移動します。周囲に敵が居ない場合、現実逃避します。　耐えられなくなり、逃げ出します。',
            '幻覚：戦闘中は、「行動放棄（全AP）」します。戦闘以外なら、幻覚を見て笑います。　自分が望む幻覚が見えます。',
            '絶叫：戦闘中は、「注目を集める（2AP）」をします。戦闘以外なら、無意味に叫びます。　思わず叫んでしまいます。',
            '自傷：自ら【怪我】を負います。戦闘中は「自傷行為（1AP）」をして自分が【怪我】します。　思わず自分を傷つけます。',
            '不安：誰かのストレスを１上げます。近くに誰も居ない場合、泣き出します。　不安にかられて余計なことを言います。',
            '忌避：その場から一番近い対象に「石（1AP）」を投げます。それができない場合、【転倒】してうずくまります。　嫌悪感から全てを拒みます。',
            '暴走：一番近い敵を攻撃しにいきます。近くに敵がいない場合、周りの意見も聞かずに安直な行動をします。　冷静でいられなくなり、直情的になります。',
            '混乱：近くにいるランダムな対象に格闘で攻撃しにいきます。それができない場合、「行動放棄（全 AP）」します。　世界全てが敵に見えて攻撃します。',
            '開眼：ストレスは0まで下がります。あなたは教祖となって教義をひとつつくって「布教」できます。次の症状が出るまで効果は続きます。　ゾンビだらけの世界の真理を見つけます。',
          ]
        ),
        'IT' => DiceTable::RangeTable.new(
          '食材表',
          '1d100',
          [
            [1..50, '生モノ食材'],
            [51..80, '怪しい食材'],
            [81..100, '危ない食材']
          ]
        )
      }.freeze

      register_prefix('\d*ZL', TABLES.keys)
    end
  end
end
