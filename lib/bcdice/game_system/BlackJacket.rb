# frozen_string_literal: true

require 'bcdice/dice_table/range_table'

module BCDice
  module GameSystem
    class BlackJacket < Base
      # ゲームシステムの識別子
      ID = 'BlackJacket'

      # ゲームシステム名
      NAME = 'ブラックジャケットRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふらつくしあけつとRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定（BJx）
        　x：成功率
        　例）BJ80
        　クリティカル、ファンブルの自動的判定を行います。
        　「BJ50+20-30」のように加減算記述も可能。
        　成功率は上限100％、下限０％
        ・デスチャート(DCxY)
        　x：チャートの種類。肉体：DCL、精神：DCS、環境：DCC
        　Y=マイナス値
        　例）DCL5：ライフが -5 の判定
        　　　DCS3：サニティーが -3 の判定
        　　　DCC0：クレジット 0 の判定
        ・チャレンジ・ペナルティ・チャート（CPC）
        ・サイドトラック・チャート（STC）
      INFO_MESSAGE_TEXT

      def eval_game_system_specific_command(command)
        resolute_action(command) || roll_death_chart(command) || roll_tables(command, TABLES)
      end

      private

      def resolute_action(command)
        m = /^BJ(\d+([+-]\d+)*)$/.match(command)
        unless m
          return nil
        end

        success_rate = ArithmeticEvaluator.eval(m[1])

        roll_result, dice10, dice01 = roll_d100
        roll_result_text = format('%02d', roll_result)

        result = action_result(roll_result, dice10, dice01, success_rate)

        sequence = [
          "行為判定(成功率:#{success_rate}％)",
          "1D100[#{dice10},#{dice01}]=#{roll_result_text}",
          roll_result_text.to_s,
          result.text
        ]

        result.text = sequence.join(" ＞ ")
        result
      end

      SUCCESS_STR = "成功"
      FAILURE_STR = "失敗"
      CRITICAL_STR = (SUCCESS_STR + " ＞ クリティカル！ パワーの代償１／２").freeze
      FUMBLE_STR = (FAILURE_STR + " ＞ ファンブル！ パワーの代償２倍＆振り直し不可").freeze
      MISERY_STR = (FAILURE_STR + " ＞ ミザリー！ パワーの代償２倍＆振り直し不可").freeze

      def action_result(total, tens, ones, success_rate)
        if total == 100
          Result.fumble(MISERY_STR)
        elsif success_rate <= 0
          Result.fumble(FUMBLE_STR)
        elsif total <= success_rate - 100
          Result.critical(CRITICAL_STR)
        elsif tens == ones
          if total <= success_rate
            Result.critical(CRITICAL_STR)
          else
            Result.fumble(FUMBLE_STR)
          end
        elsif total <= success_rate
          Result.success(SUCCESS_STR)
        else
          Result.failure(FAILURE_STR)
        end
      end

      def roll_d100
        dice10 = @randomizer.roll_once(10)
        dice10 = 0 if dice10 == 10
        dice01 = @randomizer.roll_once(10)
        dice01 = 0 if dice01 == 10

        roll_result = dice10 * 10 + dice01
        roll_result = 100 if roll_result == 0

        return roll_result, dice10, dice01
      end

      class DeathChart
        def initialize(name, chart)
          @name = name
          @chart = chart.freeze

          if @chart.size != 11
            raise ArgumentError, "unexpected chart size #{name.inspect} (given #{@chart.size}, expected 11)"
          end
        end

        # @param randomizer [Randomizer]
        # @param minus_score [Integer]
        # @return [String]
        def roll(randomizer, minus_score)
          dice = randomizer.roll_once(10)
          key_number = dice + minus_score

          key_text, chosen = at(key_number)

          return "デスチャート（#{@name}）[マイナス値:#{minus_score} + 1D10(->#{dice}) = #{key_number}] ＞ #{key_text} ： #{chosen}"
        end

        private

        # key_numberの10から20がindexの0から10に対応する
        def at(key_number)
          if key_number < 10
            ["10以下", @chart.first]
          elsif key_number > 20
            ["20以上", @chart.last]
          else
            [key_number.to_s, @chart[key_number - 10]]
          end
        end
      end

      def roll_death_chart(command)
        m = /^DC([LSC])(\d+)$/i.match(command)
        unless m
          return m
        end

        chart = DEATH_CHARTS[m[1]]
        minus_score = m[2].to_i

        return chart.roll(@randomizer, minus_score)
      end

      DEATH_CHARTS = {
        'L' => DeathChart.new(
          '肉体',
          [
            "何も無し。キミは奇跡的に一命を取り留めた。闘いは続く。",
            "激痛が走る。以後、イベント終了時まで、全ての判定の成功率－10％。",
            "もう、体が動かない……。キミは［硬直２］を受ける。",
            "渾身の一撃!!　キミは〈生存〉判定を行なう。失敗した場合、［死亡］する。",
            "突然、目の前が真っ暗になった。キミは［気絶２］を受ける。",
            "以後、イベント終了時まで、全ての判定の成功率－20％。",
            "記録的一撃!!　キミは〈生存〉－20％の判定を行なう。失敗した場合、［死亡］する。",
            "生きているのか死んでいるのか。キミは［瀕死２］を受ける。",
            "叙事詩的一撃!!　キミは〈生存〉－30％の判定を行なう。失敗した場合、［死亡］する。",
            "以後、イベント終了時まで、全ての判定の成功率－30％。",
            "神話的一撃!!　キミは宙を舞って三回転ほどした後、地面に叩きつけられる。見るも無惨な姿。肉体は原型を留めていない（キミは［死亡］した）。",
          ]
        ),
        'S' => DeathChart.new(
          '精神',
          [
            "何も無し。キミは歯を食いしばってストレスに耐えた。",
            "以後、イベント終了時まで、全ての判定の成功率－10％。",
            "云い知れぬ恐怖がキミを襲う。キミは［恐怖２］を受ける。",
            "とても傷ついた。キミは〈意思〉判定を行なう。失敗した場合、［絶望］してNPCとなる。",
            "キミは意識を失った。キミは［気絶２］を受ける。",
            "以後、イベント終了時まで、全ての判定の成功率－20％。",
            "信じる者にだまされたような痛み。キミは〈意思〉－20％の判定を行なう。失敗した場合、［絶望］してＮＰＣとなる。",
            "仲間に裏切られたのかも知れない。キミは［混乱２］を受ける。",
            "あまりに残酷な現実。キミは〈意思〉－30％の判定を行なう。失敗した場合、［絶望］してＮＰＣとなる。",
            "以後、イベント終了時まで、全ての判定の成功率－30％。",
            "宇宙開闢の理に触れるも、それは人類の認識限界を超える何かであった。キミは［絶望］し、以後ＮＰＣとなる。",
          ]
        ),
        'C' => DeathChart.new(
          '環境',
          [
            "何も無し。キミは黒い噂を握りつぶした。",
            "以後、イベント終了時まで、全ての判定の成功率－10％。",
            "ピンチ！　以後、ラウンド終了時まで、キミはカルマを使用できない。",
            "悪い噂が流れる。キミは〈交渉〉判定を行なう。失敗した場合、キミは仲間からの信頼を失って［無縁］され、ＮＰＣとなる。",
            "以後、イベント終了時まで、代償にクレジットを消費するパワーを使用できない。",
            "キミの悪評が世間に知れ渡る。協力者からの支援が打ち切られる。以後、シナリオ終了時まで、全ての判定の成功率－20％。",
            "裏切り!!　キミは〈経済〉－20％の判定を行なう。失敗した場合、キミは周囲からの信頼を失い、［無縁］され、ＮＰＣとなる。",
            "以後、シナリオ終了時まで、【環境】系の技能のレベルがすべて０となる。",
            "捏造報道？　身に覚えのない背信行為がスクープとして報道される。キミは〈心理〉－30％の判定を行なう。失敗した場合、キミは人としての尊厳を失い、［無縁］を受ける。",
            "以後、イベント終了時まで、全ての判定の成功率－30％。",
            "キミの名は史上最悪の汚点として歴史に刻まれる。もはらキミを信じる仲間はなく、キミを助ける社会もない。キミは［無縁］され、以後ＮＰＣとなる。",
          ]
        )
      }.freeze

      TABLES = {
        "CPC" => DiceTable::Table.new(
          "チャレンジ・ペナルティ・チャート",
          "1D10",
          [
            "逝去\n助けるべきＮＰＣ（ヒロインなど）が死亡する。",
            "黒星\n敵が目的を成就し、事件はPCの敗北で終了する。そのまま余韻フェイズへ。",
            "活性\n敵のボスのライフを２倍にしたうえで決戦フェイズを開始する。",
            "攻勢\n敵ボスの与ダメージに＋２D6の修正を与えたうえで決戦フェイズを開始する。",
            "大挙\n敵の数（ボス以外）を２倍にしたうえで決戦フェイズを開始する。",
            "暗黒\nすべてのエリアを［暗闇］にしたうえで決戦フェイズを開始する。",
            "猛火\n２つの戦場エリアを［ダメージゾーン２］にして、決戦フェイズを開始する。",
            "伏兵\n敵の半分をエリア１とエリア２に移動させた状態で決戦フェイズを開始する。",
            "満腹\nボス以外の敵のライフをすべて２倍にしたうえで決戦フェイズを開始する。",
            "封印\n決戦フェイズの間、PCはカルマを使用できない。決戦フェイズを開始する。"
          ]
        ),
        "STC" => DiceTable::Table.new(
          "サイドトラック・チャート",
          "1D10",
          [
            "邂逅\n偶然、ＮＰＣと出会う。どのＮＰＣが現れるかはGMが決定すること。",
            "事故\n交通事故に出くわす。周囲ではパニックが起きているかも知れない。",
            "午睡\n強烈な睡魔に襲われる。まさか、新手のヴィランの能力か？",
            "告白\nＮＰＣのひとりから、今まで秘めていた思いを吐露される。",
            "設定\n新たな設定が明かされる。実はＮＰＣの父だったとか、生来目が見えん、とか。",
            "刺客\n何者かから攻撃を受ける。第３勢力か？",
            "会敵\n偶然、仇敵のひとりと出くわす。追うべきか？　無視すべきか？",
            "不審\n怪しい人物を見かける。追うべきか？　無視すべきか？",
            "遭遇\nシナリオと関係のないヴィラン組織と遭遇する。",
            "平和\n特に何も起きなかった。",
          ]
        ),
      }.freeze

      register_prefix(
        'BJ',
        'DC[LSC]',
        TABLES.keys
      )
    end
  end
end
