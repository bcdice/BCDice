# frozen_string_literal: true

module BCDice
  module GameSystem
    class GundamSentinel < Base
      # ゲームシステムの識別子
      ID = 'GundamSentinel'

      # ゲームシステム名
      NAME = 'ガンダム・センチネルRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かんたむせんちねる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・基本戦闘(BB, BBM)
        　BB[+修正][>回避値]で基本戦闘を判定します。回避値を指定すると、命中・回避も表示します。
        　BBM[+修正][>回避値]でモブ用の基本戦闘を判定します。クリティカルを判定します。回避値を指定すると、命中・回避も表示します。

        　例）BB BBM BB+5>14 BBM+5>15

        ・一般技能(GS)
        　GS[+修正][>目標値]で一般技能を判定します。目標値を指定しない場合は、目標値10で判定します。

        　例）GS GS+5 GS+5>10


        ・各種表
        　敵MSクリティカルヒットチャート　(ECHC)
        　PC用脱出判定チャート　　　　　　(PEJC)
        　艦船追加ダメージ決定チャート　　(ASDC)
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        roll_basic_battle(command) || roll_general_skill(command) || roll_tables(command, TABLES)
      end

      # 基本戦闘ロール
      def roll_basic_battle(command)
        m = /^BB(M)?([-+][-+\d]+)?(>([-+\d]+))?/.match(command)
        return nil unless m

        mob = m[1]
        modify = ArithmeticEvaluator.eval(m[2])
        have_modify = false
        have_modify = true if m[2]
        avoid = ArithmeticEvaluator.eval(m[4])
        have_avoid = false
        have_avoid = true if m[4]

        d60 = @randomizer.roll_once(6)
        d06 = @randomizer.roll_once(6)
        total_d = d60 * 10 + d06
        d60 += (d06 + modify - 1).div(6)
        d06 = (d06 + modify - 1).modulo(6) + 1
        total = d60 * 10 + d06
        total = 11 if total < 11

        success = false
        failure = false
        critical = false

        modify_label = nil
        if have_modify
          if modify >= 0
            modify_label = "#{total_d}+#{modify}"
          else
            modify_label = "#{total_d}#{modify}"
          end
        end

        critical_label = nil
        if mob && (total >= 66)
          critical_label = "クリティカル"
          critical = true
        end

        result = nil
        if have_avoid
          if total > avoid
            result = "命中(+" + count_success(total, avoid).to_s + ")"
            success = true
          else
            result = "回避"
            failure = true
          end
        end

        sequence = [
          "(#{command})",
          modify_label,
          total,
          result,
          critical_label,
        ].compact

        Result.new(sequence.join(" ＞ ")).tap do |r|
          r.success = success
          r.failure = failure
          r.critical = critical
        end
      end

      def count_success(dice, avoid)
        d60 = dice.div(10)
        d06 = dice.modulo(10)
        a60 = avoid.div(10)
        a06 = avoid.modulo(10)

        return ((d60 * 6 + d06) - (a60 * 6 + a06))
      end

      # 一般技能ロール
      def roll_general_skill(command)
        m = /^GS([-+][-+\d]+)?(>([-+\d]+))?/.match(command)
        return nil unless m

        modify = ArithmeticEvaluator.eval(m[1])
        have_modify = false
        have_modify = true if m[1]
        target = ArithmeticEvaluator.eval(m[3])
        target = 10 unless m[3]

        success = false
        failure = false

        dice = @randomizer.roll_sum(2, 6)

        modify_label = nil
        if have_modify
          if modfy >= 0
            modify_label = "#{dice}+#{modify}"
          else
            modify_label = "#{dice}-#{modify}"
          end
        end
        total = dice + modify
        if total > target
          result = "成功"
          success = true
        else
          result = "失敗"
          failure = true
        end

        sequence = [
          "(#{command})",
          modify_label,
          total,
          result,
        ].compact

        Result.new(sequence.join(" ＞ ")).tap do |r|
          r.success = success
          r.failure = failure
        end
      end

      # 各種表

      TABLES = {
        'ECHC' => DiceTable::Table.new(
          '敵MSクリティカルヒットチャート',
          '2D6',
          [
            'コックピット直撃：目標ＭＳは残骸となる。',
            '腕破損：同時に携帯武器も失う。携帯武装の交換も行えない。直ちにモラル判定を－４で行う。',
            '射撃武装破損：目標ＭＳはその時点で使用しているナンバーの若い武装を１つ失う。全ての武装を失った場合、モラル判定を行う。',
            '頭部直撃：目標ＭＳはメインカメラを失い、以後射撃、格闘の命中判定に－６の修正を受ける。頭部に装備されている武装も失われる。',
            'パイロット気絶：目標ＭＳは回復するまで行動不能。',
            '目標ＭＳへのダメージ２倍。',
            '目標ＭＳへのダメージ２倍。',
            '目標ＭＳへのダメージ３倍。',
            '脚破損：目標ＭＳは、以後の回避値に－６の修正を受ける。',
            'コントロール不能：目標ＭＳは１Ｄ６ラウンドの間、行動不能。',
            '熱核ジェネレーター直撃：目標ＭＳは直ちに爆発（耐久力０）する。',
          ]
        ),

        'PEJC' => DiceTable::Table.new(
          'PC用脱出判定チャート',
          '2D6',
          [
            '無傷で脱出',
            '無傷で脱出',
            '無傷で脱出',
            '軽傷で脱出「１Ｄ６ダメージ。」',
            '中傷で脱出「２Ｄ６ダメージ。」',
            '重傷で脱出「３Ｄ６ダメージ。」',
            '重体で脱出「１Ｄ３の耐久力が残る。」',
            '戦死「二階級特進。」',
            '戦死「二階級特進。」',
            '戦死「二階級特進。」',
            '戦死「二階級特進。」',
          ]
        ),

        'ASDC' => DiceTable::Table.new(
          '艦船追加ダメージ決定チャート',
          '2D6',
          [
            'ブリッジ損傷「複数ある艦は、総てのブリッジが損傷すると以後の対空防御は修正を＋５する。」',
            'カタパルト損傷「複数ある艦は、総てのカタパルトが損傷すると、ＭＳの発着艦ができなくなる。」',
            '追加ダメージ「追加２Ｄ６×２ダメージ。」',
            '主砲大破「主砲１門を失う。」',
            '副砲大破「副砲１門を失う。」',
            '追加ダメージ「追加２Ｄ６ダメージ。」',
            '追加ダメージ「追加２Ｄ６ダメージ。」',
            '追加ダメージ「追加２Ｄ６ダメージ。」',
            '１ターン行動不能「１ターンはその艦は何も行動ができない。」',
            '航行不能「その艦はそのヘックスから動けなくなる。」',
            'エンジン誘爆「１Ｄ６×１０％の耐久力を失う。」',
          ]
        ),
      }.freeze

      register_prefix('BB(M)?([-+][-+\d]+)?(>([-+\d]+))?', 'GS([-+][-+\d]+)?(>([-+\d]+))?', TABLES.keys)
    end
  end
end
