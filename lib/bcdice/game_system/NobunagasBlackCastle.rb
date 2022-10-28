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

      # コマンドを追加するときは、ここにコマンドを登録すること
      register_prefix('[+-]?\d*DR[\d]+', 'INS', 'NPCST', 'O?SWT', 'ERT', 'ART')

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_initiative(command) || roll_tables(command, TABLES) || make_npc_status(command)
      end

      private

      def result_DR(total, dice_total, target)
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
        m = /([+-]?\d*)DR(\d+)/.match(command)
        return nil unless m

        num_status = m[1].to_i
        num_target = m[2].to_i

        total = @randomizer.roll_once(20)
        total_status = total.to_s + with_symbol(num_status)
        result = result_DR(total + num_status, total, num_target)

        sequence = [
          "(#{command})",
          total_status,
          total + num_status,
          result&.text,
        ].compact

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
        m = /INS/.match(command)
        return nil unless m

        total = @randomizer.roll_once(6)
        result =
          if total >= 4
            Result.success("PC先行")
          else
            Result.failure("敵先行")
          end
        sequence = [
          "(#{command})",
          total,
          result&.text,
        ].compact

        result.text = sequence.join(" ＞ ")
        return result
      end

      # NPC能力値作成
      # @param [String] command
      # @return [String]
      def make_npc_status(command)
        m = /NPCST/.match(command)
        return nil unless m

        pre = @randomizer.roll_barabara(3, 6).sum()
        agi = @randomizer.roll_barabara(3, 6).sum()
        str = @randomizer.roll_barabara(3, 6).sum()
        tgh = @randomizer.roll_barabara(3, 6).sum()
        hpd = @randomizer.roll_once(8).to_i
        hp  = hpd + calc_status(tgh)
        hp = 1 if hp < 1

        text  =   "心"  + with_symbol(calc_status(pre)) + "(#{pre})"
        text += ", 技"  + with_symbol(calc_status(agi)) + "(#{agi})"
        text += ", 体"  + with_symbol(calc_status(str)) + "(#{str})"
        text += ", 耐久" + with_symbol(calc_status(tgh)) + "(#{tgh})"
        text += ", HP" + hp.to_s + "(#{hpd})"

        sequence = [
          "(#{command})",
          text,
        ].compact
        sequence.join(" ＞ ")
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
            '六尺棒（Ｄ４）',
            '手槍（Ｄ４）',
            '弓矢（Ｄ６）',
            '鉄扇（Ｄ４）',
            '大鉞（Ｄ８）',
            '吹き矢（Ｄ２）＋感染',
            '鞭（Ｄ３）',
            '熊手（Ｄ４）',
            '石つぶて（Ｄ３）',
            '丸太（Ｄ４）',
          ]
        ),
        'SWT' => DiceTable::Table.new(
          '武器表',
          '1D12',
          [
            '尖らせた骨の杭（Ｄ３）',
            '竹槍（Ｄ４）',
            '百姓から奪った鍬（Ｄ４）',
            '脇差し（Ｄ４）',
            '手裏剣　Ｄ６本（Ｄ４）',
            '刀（Ｄ６）',
            '鎖鎌（Ｄ６）',
            '太刀（Ｄ８）',
            '種子島銃（２Ｄ６）　弾丸（心＋５）発',
            '大槍（Ｄ８）',
            '爆裂弾（Ｄ４）　心＋３発',
            '斬馬刀（Ｄ１０）',
          ]
        ),
        'ART' => DiceTable::Table.new(
          '鎧表',
          '1D6',
          [
            '防具は、何もない',
            '防具は、何もない',
            '部分鎧（腹巻き）　－Ｄ２ダメージ',
            'お貸し具足　－Ｄ３ダメージ',
            '武者鎧　－Ｄ４ダメージ',
            '大鎧　－Ｄ６ダメージ',
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
    end
  end
end
