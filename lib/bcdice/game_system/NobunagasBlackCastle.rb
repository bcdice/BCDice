# frozen_string_literal: true

require 'bcdice/dice_table/table'

module BCDice
  module GameSystem
    class NobunagasBlackCastle < Base
      # ゲームシステムの識別子
      ID = 'NobunagasBlackCastle'

      # ゲームシステム名
      NAME = '信長の黒い城'

      # ゲームシステム名の読みがな
      SORT_KEY = 'のふなかのくろいしろ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　sDRt        s: 能力値 t:目標値

        例)+3DR12: 能力値+3、DR12で1d20を振って、その結果を表示(クリティカル・ファンブルも表示)

        ■イニシアティヴ　INS

        例)INS: 1d6を振って、イニシアティヴの結果を表示(PC先行を成功として表示)

        ■NPC能力値作成　NPCST

        例)NPCST: 3d6を4回振って、各能力値とHPを表示


        ■各種表

        ・遭遇反応表(ERT)
        ・武器表(SWT)/その他の奇妙な武器表(OSWT)
        ・鎧表(ART)

      INFO_MESSAGETEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_initiative(command) || roll_tables(command, TABLES) || make_npc_status(command)
      end

      private

      def result_dr(total, dice_total, target)
        if dice_total <= 1
          Result.fumble("ファンブル")
        elsif dice_total >= 20
          Result.critical("クリティカル")
        elsif total >= target
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end

      # DR判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /^([+-]?\d*)DR(\d+)$/.match(command)
        return nil unless m

        num_status = m[1].to_i
        num_target = m[2].to_i

        total = @randomizer.roll_once(20)
        total_status = total.to_s + with_symbol(num_status)
        result = result_dr(total + num_status, total, num_target)

        sequence = [
          "(#{command})",
          total_status,
          total + num_status,
          result.text,
        ]

        result.text = sequence.join(" ＞ ")
        return result
      end

      def with_symbol(number)
        if number == 0
          return "+0"
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # イニシアティヴ判定
      # @param [String] command
      # @return [Result]
      def resolute_initiative(command)
        unless command == "INS"
          return nil
        end

        total = @randomizer.roll_once(6)
        result =
          if total >= 4
            Result.success("PC先行")
          else
            Result.failure("敵先行")
          end

        result.text = "(#{command}) ＞ #{total} ＞ #{result.text}"
        return result
      end

      # NPC能力値作成
      # @param [String] command
      # @return [String]
      def make_npc_status(command)
        unless command == "NPCST"
          return nil
        end

        pre = @randomizer.roll_sum(3, 6)
        agi = @randomizer.roll_sum(3, 6)
        str = @randomizer.roll_sum(3, 6)
        tgh = @randomizer.roll_sum(3, 6)
        hpd = @randomizer.roll_once(8)
        hp  = hpd + calc_status(tgh)
        hp = 1 if hp < 1

        text = [
          "心#{with_symbol(calc_status(pre))}(#{pre})",
          "技#{with_symbol(calc_status(agi))}(#{agi})",
          "体#{with_symbol(calc_status(str))}(#{str})",
          "耐久#{with_symbol(calc_status(tgh))}(#{tgh})",
          "HP#{hp}(#{hpd})",
        ].join(", ")

        return "(#{command}) ＞ #{text}"
      end

      def calc_status(st)
        if st <= 4
          return -3
        elsif st <= 6
          return -2
        elsif st <= 8
          return -1
        elsif st <= 12
          return 0
        elsif st <= 14
          return 1
        elsif st <= 16
          return 2
        elsif st <= 20
          return 3
        end
      end

      # 各種表

      TABLES = {
        'OSWT' => DiceTable::Table.new(
          'その他の奇妙な武器表',
          '1D10',
          [
            '六尺棒（D4）',
            '手槍（D4）',
            '弓矢（D6）',
            '鉄扇（D4）',
            '大鉞（D8）',
            '吹き矢（D2）＋感染',
            '鞭（D3）',
            '熊手（D4）',
            '石つぶて（D3）',
            '丸太（D4）',
          ]
        ),
        'SWT' => DiceTable::Table.new(
          '武器表',
          '1D12',
          [
            '尖らせた骨の杭（D3）',
            '竹槍（D4）',
            '百姓から奪った鍬（D4）',
            '脇差し（D4）',
            '手裏剣　D6本（D4）',
            '刀（D6）',
            '鎖鎌（D6）',
            '太刀（D8）',
            '種子島銃（2D6）　弾丸（心+5）発',
            '大槍（D8）',
            '爆裂弾（D4）　心+3発',
            '斬馬刀（D10）',
          ]
        ),
        'ART' => DiceTable::Table.new(
          '鎧表',
          '1D6',
          [
            '防具は、何もない',
            '防具は、何もない',
            '部分鎧（腹巻き）　-D2ダメージ',
            'お貸し具足　-D3ダメージ',
            '武者鎧　-D4ダメージ',
            '大鎧　-D6ダメージ',
          ]
        ),
        # 無理に高度なことをしなくても、表は展開して実装しても動く
        'ERT' => DiceTable::Table.new(
          '遭遇反応表',
          '2D6',
          [
            'お前ら、殺す！',
            'お前ら、殺す！',
            '憎悪の視線で睨んでくる。すきを見せれば、攻撃してくる。',
            '憎悪の視線で睨んでくる。すきを見せれば、攻撃してくる。',
            '憎悪の視線で睨んでくる。すきを見せれば、攻撃してくる。',
            '警戒はしているが、特に、戦闘は望んでいない。怒らせなければ、自分たちの目的に沿って動く。',
            '警戒はしているが、特に、戦闘は望んでいない。怒らせなければ、自分たちの目的に沿って動く。',
            '中立。何かを与えたり、取引の材料を提示したりできれば、交渉できそうだ。',
            '中立。何かを与えたり、取引の材料を提示したりできれば、交渉できそうだ。',
            '好意的に会話できそうだ。向こうも取引したがっている。',
            '好意的に会話できそうだ。向こうも取引したがっている。',
          ]
        ),
      }.freeze

      register_prefix('[+-]?\d*DR[\d]+', 'INS', 'NPCST', TABLES.keys)
    end
  end
end
