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
        　PC用脱出判定チャート　　　　　　(PEJC[+m] m:修正)
        　艦船追加ダメージ決定チャート　　(ASDC)
        　対空砲結果チャート　　　　　　　(AARC[+m]=t m:修正, t=対空防御力)
        　リハビリ判定チャート　　　　　　(RTJC[+m] m:修正)
        　二次被害判定チャート　　　　　　(SDDC)
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        roll_basic_battle(command) ||
          roll_general_skill(command) ||
          roll_anti_aircraft_gun_result_chart(command) ||
          roll_PC_Escape_Judgment_Chart(command) ||
          roll_Rehabilitation_judgment_chart(command) ||
          roll_tables(command, TABLES)
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
          if modify >= 0
            modify_label = "#{dice}+#{modify}"
          else
            modify_label = "#{dice}#{modify}"
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

      # 対空砲結果チャート
      def index_within_collect_range(range_min, range_max, index_no)
        index_no = range_min if index_no < range_min
        index_no = range_max if index_no > range_max

        return index_no
      end

      def read_GundamSentinel_anti_aircraft_gun_result_chart
        anti_aircraft_gun_result_chart = [
          '*,*,*,*,*,*,*',
          '*,D,D,D,D,D,D',
          '*,H,H,D,D,D,D',
          '*,H,H,H,H,D,D',
          '*,H,H,H,H,H,H',
          '*,10,12,H,H,H,H',
          '*,8,10,12,14,H,H',
          '*,6,9,10,13,14,H',
          '*,5,8,9,12,13,16',
          '*,4,6,7,10,11,14',
          '*,2,5,6,8,9,12',
          '*,1,3,4,6,7,11',
          '*,-,2,3,5,6,8',
          '*,-,-,1,3,4,6'
        ]
        return anti_aircraft_gun_result_chart
      end

      def getNew_anti_aircraft_gun_result_chart(anti_aircraft_gun_result_chart)
        defence_rate0 = []
        defence_rate1 = []
        defence_rate2 = []
        defence_rate3 = []
        defence_rate4 = []
        defence_rate5 = []
        defence_rate6 = []

        anti_aircraft_gun_result_chart.each do |ratetext|
          rate_arr = ratetext.split(/,/)
          defence_rate0.push('*')
          defence_rate1.push(rate_arr[1])
          defence_rate2.push(rate_arr[2])
          defence_rate3.push(rate_arr[3])
          defence_rate4.push(rate_arr[4])
          defence_rate5.push(rate_arr[5])
          defence_rate6.push(rate_arr[6])
        end

        return [defence_rate0, defence_rate1, defence_rate2, defence_rate3, defence_rate4, defence_rate5, defence_rate6]
      end

      def roll_anti_aircraft_gun_result_chart(command)
        m = /^AARC([-+][-+\d]+)?(=(\d))/.match(command)
        return nil unless m

        modify = ArithmeticEvaluator.eval(m[1])
        have_modify = false
        have_modify = true if m[1]
        target = ArithmeticEvaluator.eval(m[3])
        target = index_within_collect_range(1, 6, target)

        dice = @randomizer.roll_sum(2, 6)

        modify_label = nil
        if have_modify
          if modify >= 0
            modify_label = "#{dice}+#{modify}"
          else
            modify_label = "#{dice}#{modify}"
          end
        end
        total = index_within_collect_range(1, 13, dice + modify)
        newChart = getNew_anti_aircraft_gun_result_chart(read_GundamSentinel_anti_aircraft_gun_result_chart)
        result = newChart[target][total]

        sequence = [
          "(#{command})",
          modify_label,
          total,
          "対空砲結果チャート(#{total}vs#{target}):結果「#{result}」",
        ].compact

        Result.new(sequence.join(" ＞ ")).tap do |r|
          begin
            success = true if Float(result)
          rescue StandardError
            success = false
          end
          r.success = success
          r.failure = !success
        end
      end

      # PC用脱出判定チャート
      def getNew_PC_Escape_Judgment_Chart
        [
          '*',
          '*',
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
      end

      def roll_PC_Escape_Judgment_Chart(command)
        m = /^PEJC([-+][-+\d]+)?/.match(command)
        return nil unless m

        modify = ArithmeticEvaluator.eval(m[1])
        have_modify = false
        have_modify = true if m[1]

        dice = @randomizer.roll_sum(2, 6)
        total = index_within_collect_range(2, 12, dice + modify)

        modify_label = nil
        base_label = "PC用脱出判定チャート"
        if have_modify
          if modify >= 0
            modify_label = "#{dice}+#{modify}"
          else
            modify_label = "#{dice}#{modify}"
          end
          base_label += "(#{modify_label}=#{total})"
        else
          base_label += "(#{total})"
        end
        newChart = getNew_PC_Escape_Judgment_Chart
        result = newChart[total]

        sequence = [
          base_label,
          result,
        ].compact

        Result.new(sequence.join(" ＞ "))
      end

      # リハビリ判定チャート
      def getNew_Rehabilitation_judgment_chart
        [
          '*',
          '*',
          'なし',
          '１ヶ月',
          '２ヶ月',
          '３ヶ月',
          '４ヶ月',
          '５ヶ月',
          '６ヶ月',
          '１０ヶ月',
          '１年',
          '１年６ヶ月',
          '１年と、もう一度このチャートで振った結果分を足した期間',
        ]
      end

      def roll_Rehabilitation_judgment_chart(command)
        m = /^RTJC([-+][-+\d]+)?/.match(command)
        return nil unless m

        modify = ArithmeticEvaluator.eval(m[1])
        have_modify = false
        have_modify = true if m[1]

        dice = @randomizer.roll_sum(2, 6)
        total = index_within_collect_range(2, 12, dice + modify)

        modify_label = nil
        base_label = "リハビリ判定チャート"
        if have_modify
          if modify >= 0
            modify_label = "#{dice}+#{modify}"
          else
            modify_label = "#{dice}#{modify}"
          end
          base_label += "(#{modify_label}=#{total})"
        else
          base_label += "(#{total})"
        end
        newChart = getNew_Rehabilitation_judgment_chart
        result = newChart[total]

        sequence = [
          base_label,
          result,
        ].compact

        Result.new(sequence.join(" ＞ "))
      end

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

        'SDDC' => DiceTable::D66GridTable.new(
          '二次被害判定チャート',
          [
            [
              '奇蹟的に無傷「不発！？今回のダメージは0。」',
              'メインカメラ破損「以後、射撃、格闘の命中判定に－３の修正を受ける。」',
              'コクピット破損「以後の追加ダメージ判定に－１の修正を受ける。」',
              '右腕損傷「携帯していた武装も失う。また右腕での武器の使用はできなくなる。」',
              '左腕損傷「携帯していた武装も失う。また左腕での武器の使用はできなくなる。」',
              '気絶「気絶判定の余地無く、必ず気絶する。」',
            ],
            [
              '気絶「気絶判定を－６の修正で行う。」',
              '気絶「気絶判定を－４の修正で行う。」',
              '気絶「気絶判定を－２の修正で行う。」',
              '気絶「気絶判定を行う。」',
              '予備弾倉破損「携帯している予備弾倉かＥパックを１つ失う。」',
              'サブカメラ破損「以後、射撃、格闘の命中判定に－１の修正を受ける。」',
            ],
            [
              '固定武装破損「固定されている武装を１つ失う。」',
              '予備武装破損「携帯している以外の武装を１つ失う。」',
              '頭部破損「メインカメラも失い、以後、射撃、格闘の命中判定に－３の修正を受ける。」',
              '右脚破損「以後、回避値が１Ｄ３低下する。」',
              '左脚破損「以後、回避値が１Ｄ３低下する。」',
              '操縦機構破損「以後、すべての行動は消費行動ポイントを１ポイント余分に消費する。」',
            ],
            [
              '軽傷「パイロットは１Ｄ６のダメージを受ける。また気絶判定を行う。」',
              '中傷「パイロットは２Ｄ６のダメージを受ける。また気絶判定を－６修正で行う。」',
              '重傷「パイロットは３Ｄ６のダメージを受ける。また気絶判定を－９修正で行う。」',
              '操縦伝達部破損「以後すべての射撃、格闘の命中判定と回避値に－１の修正を受ける。」',
              'センサー破損「イニシアティブ決定に－１の修正を受ける。」',
              '脱出機構破損「脱出判定に＋３の修正を受ける。」',
            ],
            [
              '熱核ジェネレーター損傷「行動の「追加移動」が行えなくなる。」',
              '右腕の携帯武装破損「右腕に持っていた武装を１つ失う。」',
              '左腕の携帯武装破損「左腕に持っていた武装を１つ失う。」',
              'サブスラスター破損「回避値が１低下する。」',
              'プロペラントタンク破損「プロペラントタンクを１つ失う。」',
              'バックパック破損「推進剤３Ｄ６ポイント失う。」',
            ],
            [
              'メインスラスター破損「回避値が１Ｄ６低下する。」',
              '動力パイプ破損「以後、行動ポイント決定のダイスに－１の修正を受ける。」',
              '動力伝達機構破損「以後、行動ポイント決定のサイコロに－１Ｄ３の修正を受ける。」',
              'サブスラスター破損「旋回が１２０度までしかできなくなる。」',
              'メインスラスター破損「旋回が６０度までしかできなくなる。」',
              '熱核ジェネレーター直撃「そのＭＳは爆発する。ＰＣは直ちに脱出判定を行う。」',
            ]
          ]
        ),
      }.freeze

      register_prefix('BB(M)?([-+][-+\d]+)?(>([-+\d]+))?', 'GS([-+][-+\d]+)?(>([-+\d]+))?', 'AARC([-+][-+\d]+)?(=(\d))', 'PEJC([-+][-+\d]+)?', 'RTJC([-+][-+\d]+)?', TABLES.keys)
    end
  end
end
