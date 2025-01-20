# frozen_string_literal: true

require 'bcdice/dice_table/range_table'

module BCDice
  module GameSystem
    class BlackJacket_Korean < BlackJacket
      # ゲームシステムの識別子
      ID = 'BlackJacket:Korean'

      # ゲームシステム名
      NAME = '블랙재킷RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:블랙재킷RPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・행위 판정（BJx）
        　x：성공률
        　예）BJ80
        　크리티컬,펌블 여부는 자동으로 판정합니다.
        　「BJ50+20-30」처럼 값을 가감하여 기재할 수 있습니다.
        　성공률의 상한은 100％、하한은 ０％ 입니다.
        ・데스 차트 (DCxY)
        　x：차트 종류. 육체：DCL, 정신：DCS, 환경：DCC
        　Y=마이너스 값
        　예）DCL5：라이프 마이너스 값 5 + 1D10 판정
        　　　DCS3：새니티 마이너스 값 3 + 1D10 판정
        　　　DCC0：크레딧 마이너스 값 0 + 1D10 판정
        ・챌린지・패널티 차트（CPC）
        ・사이드 트랙 차트（STC）
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
          "행위판정(성공률:#{success_rate}％)",
          "1D100[#{dice10},#{dice01}]=#{roll_result_text}",
          roll_result_text.to_s,
          result.text
        ]

        result.text = sequence.join(" ＞ ")
        result
      end

      SUCCESS_STR = "성공"
      FAILURE_STR = "실패"
      CRITICAL_STR = (SUCCESS_STR + " ＞ 크리티컬! 파워의 대가(코스트) 절반으로 감소").freeze
      FUMBLE_STR = (FAILURE_STR + " ＞ 펌블! 파워의 대가(코스트) 2배 & 재굴림 불가").freeze
      MISERY_STR = (FAILURE_STR + " ＞ 미저리! 파워의 대가(코스트) 2배 & 재굴림 불가").freeze

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

          return "데스 차트（#{@name}）[마이너스 값:#{minus_score} + 1D10(->#{dice}) = #{key_number}] ＞ #{key_text} ： #{chosen}"
        end

        private

        # key_numberの10から20がindexの0から10に対応する
        def at(key_number)
          if key_number < 10
            ["10이하", @chart.first]
          elsif key_number > 20
            ["20이상", @chart.last]
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
          '육체',
          [
            "효과 없음. 당신은 기적적으로 목숨을 건졌다. 싸움은 계속된다.",
            "격한 통증을 느낀다. 이후 이벤트가 끝날 때까지 모든 판정의 성공률에 -10%.",
            "더이상 몸이 움직이지 않는다…… 당신은 [경직 2]를 받는다.",
            "혼신의 일격!! 당신은 〈생존〉 판정을 한다. 실패할 경우 [사망]한다.",
            "갑자기 눈앞이 캄캄해진다. 당신은 [기절 2]를 받는다.",
            "이후, 이벤트 종료까지 모든 판정의 성공률 -20%.",
            "기록적인 일격!! 당신은 〈생존〉 -20% 으로 판정한다. 실패할 경우 [사망]한다.",
            "사느냐 죽느냐. 당신은 [빈사 2]를 받는다.",
            "역사에 한 획을 그을 일격!! 당신은 <생존> -30% 으로 판정한다. 실패할 경우 [사망]한다.",
            "이후, 이벤트 종료 시까지 모든 판정의 성공률 -30%.",
            "신화적 일격!! 공중에서 세 바퀴 정도 회전한 후 땅바닥에 내동댕이쳐진다. 보기에도 끔찍한 모습. 육체는 원형을 유지하지 못했다. 당신은 [사망]한다.",
          ]
        ),
        'S' => DeathChart.new(
          '정신',
          [
            "효과 없음. 당신은 이를 악물고 스트레스를 견뎌냈다.",
            "이후, 이벤트 종료 시까지 모든 판정의 성공률 -10%.",
            "말할 수 없는 공포가 당신을 엄습한다. 당신은 [공포 2]를 받는다.",
            "상처를 많이 받았다. 당신은 〈의지〉 판정을 한다. 실패할 경우 [절망] 상태가 되어서 NPC가 된다.",
            "의식을 잃었다. 당신은 [기절 2]를 받는다.",
            "이후, 이벤트 종료 시까지 모든 판정의 성공률 -20%.",
            "신뢰했던 자에게 속은 아픔. 당신은 〈의지〉 -20% 으로 판정한다. 실패할 경우, [절망] 상태가 되어서 NPC가 된다.",
            "동료에게 배신 당한 것일지도 모른다. 당신은 [혼란 2]를 받는다.",
            "너무나 참혹한 현실. 당신은 〈의지〉 -30% 으로 판정한다. 실패할 경우 [절망] 상태가 되어서 NPC가 된다.",
            "이후, 이벤트 종료 시까지 모든 판정의 성공률 -30%.",
            "천지개벽의 이치 그 이상. 그것은 인류의 인식한계를 뛰어넘는 무언가였다. 당신은 [절망] 상태가 된 후 NPC가 된다.",
          ]
        ),
        'C' => DeathChart.new(
          '환경',
          [
            "효과 없음. 당신은 뒤숭숭한 소문을 무시했다.",
            "이후, 이벤트 종료 시까지 모든 판정의 성공률 -10%.",
            "위험한 상태! 이후, 라운드 종료 시까지 당신은 카르마를 사용할 수 없다.",
            "나쁜 소문이 돈다. 당신은 〈교섭〉 판정을 한다. 실패할 경우 당신은 동료들의 신뢰를 잃고 [무연고] 상태가 된 후 NPC가 된다.",
            "이후, 시나리오 종료 시까지 대가(코스트)에 크레딧을 소비하는 파워를 사용할 수 없다.",
            "당신의 악평이 세상에 널리 알려진다. 협력자로부터의 지원이 중단된다. 이후 시나리오 종료 시까지 모든 판정의 성공률 -20%.",
            "배신!! 당신은 〈경제〉 -20% 으로 판정한다. 실패할 경우 당신은 주위로부터 신용을 잃고, [무연고] 상태가 되어 NPC가 된다.",
            "이후, 시나리오 종료 시까지 【환경】 계열의 기능 레벨이 모두 0이 된다.",
            "날조 보도? 기억나지 않는 배신 행위가 특종으로 보도된다. 당신은 〈심리〉 -30% 으로 판정한다. 실패할 경우 당신은 인간으로서의 존엄성을 잃고, [무연고]가 된다.",
            "이후, 이벤트 종료 시까지 모든 판정 성공률 -30%.",
            "당신의 이름은 사상 최악의 오점으로 영원히 역사에 새겨진다. 이제 당신을 믿는 동료는 없고 당신을 돕는 사회도 없다. 당신은 [무연고] 상태가 된 후 NPC가 된다.",
          ]
        )
      }.freeze

      TABLES = {
        "CPC" => DiceTable::Table.new(
          "챌린지・패널티 차트",
          "1D10",
          [
            "사망\n도와야 할 NPC (히로인 등)가 사망한다.",
            "검은 별\n적이 목적을 성취하고, 사건은 PC의 패배로 끝난다. 그대로 여운 페이즈로 넘어갈 것.",
            "활성\n적 보스의 라이프를 2배로 한 다음 결전 페이즈를 개시한다.",
            "공세\n적 보스의 대미지에 +2D6의 수정을 준 후 결전 페이즈를 개시한다.",
            "대거\n적의 수(보스 제외)를 2배로 한 후 결전 페이즈를 개시한다.",
            "암흑\n모든 에리어(구역)을 [어둠]으로 만든 다음 결전 페이즈를 개시한다.",
            "맹화\n전투 에리어(구역) 2개를 [대미지 존 2]로 취급한 후, 결전 페이즈를 개시한다.",
            "복병\n적의 절반을 에리어(구역) 1과 에리어(구역) 2로 이동시킨 후, 결전 페이즈를 개시한다.",
            "만복\n보스 이외의 적의 라이프를 모두 2배로 한 다음, 결전 페이즈를 개시한다.",
            "봉인\nPC는 결전 페이즈 동안 카르마를 사용할 수 없다. 결전 페이즈를 개시한다."
          ]
        ),
        "STC" => DiceTable::Table.new(
          "사이드 트랙 차트",
          "1D10",
          [
            "해후\n우연히 NPC와 만난다. 어떤 NPC가 나타날지는 GM이 결정한다.",
            "사고\교통사고를 당한다. 주변에서 패닉이 일어나고 있을지도 모른다.",
            "낮잠\n지독한 졸음이 몰려온다. 설마, 신참 빌런의 능력인가?",
            "고백\nNPC 한 명이 지금까지 간직하고 있던 마음을 당신에게 고백한다.",
            "설정\n새로운 설정이 밝혀진다. 사실은 NPC의 아버지였다든가, 선천적으로 눈이 보이지 않는다든가.",
            "자객\n누군가로부터 공격을 받는다. 제3세력인가?",
            "불청객\n우연히 원수 한 명과 마주친다. 상황에 따라서 바로 전투가 발생할지도 모른다.",
            "의심\n수상한 사람을 눈치챘다. 따라가야 하나? 무시해야 하나?",
            "조우\n시나리오와 관계없는 빌런 조직과 조우한다.",
            "평화\n별일 없었다.",
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
