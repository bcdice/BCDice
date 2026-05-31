# frozen_string_literal: true

require "bcdice/game_system/cthulhu7th_Korean/rollable"
require "bcdice/game_system/cthulhu7th_Korean/full_auto"

module BCDice
  module GameSystem
    class Cthulhu7th_Korean < Base
      # ゲームシステムの識別子
      ID = 'Cthulhu7th:Korean'

      # ゲームシステム名
      NAME = '크툴루의 부름 7판'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:크툴루의 부름 7판'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정　CC(x)<=（목표치）
        　x：보너스, 페널티 주사위 (2~-2). 생략 가능.
        　목표치가 없어도 1D100은 표시됨.
        　대실패 / 실패 / 보통 성공 / 어려운 성공 /
        　극단적 성공 / 대성공 을 자동 판정.
        　예）CC<=30　CC(2)<=50 CC(+2)<=50 CC(-1)<=75 CC-1<=50 CC1<=65 CC+1<=65 CC

        ・기능 판정의 난이도 지정　CC(x)<=(목표치)(난이도)
        　목표치 뒤에 난이도를 지정하여
        　성공 / 실패 / 대성공 / 대실패 를 자동 판정.
        　난이도 지정：
        　　r:보통　h:어려운　e:극단적　c:대성공
        　예）CC<=70r CC1<=60h CC-2<=50e CC2<=99c

        ・대항 판정　(CBR(x,y))
        　목표치 x와 y로 % 판정을 진행하여 성패를 판정.
        　예）CBR(50,20)

        ・자동 사격 무기의 사격 판정(연사)　FAR(w,x,y,z,d,v)
        　w：탄환 수(1~100), x：기능치(1~100), y：고장 수치,
        　z：보너스, 페널티 다이스(-2~2). 생략 가능.
        　d：지정한 난이도에서 연사를 종료（보통：r, 어려운：h, 극단적：e）. 생략 가능.
        　v：연사할 탄환 수를 변경. 생략 가능.
        　명중 수와 관통 수, 남은 탄환 수만 산출. 대미지 산출은 하지 않음.
        예）FAR(25,70,98)　FAR(50,80,98,-1)　far(30,70,99,1,R)
        　　far(25,88,96,2,h,5)　FaR(40,77,100,,e,4)　fAr(20,47,100,,,3)

        ・각종 표
        　【광기 관련】
        　・광기의 발작(실시간)　BMR
        　・광기의 발작(요약)　BMS
        　・공포증의 예 　PH / 집착증의 예　MA

        　【마법 관련】
        　・주문의 강행 판정（Casting Roll）실패 표
        　　비교적 약한 주문의 부작용　FCL／강력한 주문의 부작용　FCM
        　　※실 사용 시 주문의 강행 판정 실패(小)표 / 주문의 강행 판정 실패(大)표 로 출력됩니다.
      INFO_MESSAGE_TEXT

      register_prefix('CC', 'CBR', 'FAR', 'BMR', 'BMS', 'FCL', 'FCM', 'PH', 'MA')

      def eval_game_system_specific_command(command)
        case command
        when /^CC/i
          skill_roll(command)
        when /^CBR/i
          combine_roll(command)
        when /^FAR/i
          getFullAutoResult(command)
        when "BMR" # 狂気の発作（リアルタイム）
          roll_bmr_table()
        when "BMS" # 狂気の発作（サマリー）
          roll_bms_table()
        when "FCL" # キャスティング・ロールのプッシュに失敗した場合（小）
          roll_1d8_table("주문의 강행 판정 실패(小)표", FAILED_CASTING_L_TABLE)
        when "FCM" # キャスティング・ロールのプッシュに失敗した場合（大）
          roll_1d8_table("주문의 강행 판정 실패(大)표", FAILED_CASTING_M_TABLE)
        when "PH" # 恐怖症表
          roll_1d100_table("공포증 표", PHOBIAS_TABLE)
        when "MA" # マニア表
          roll_1d100_table("집착증 표", MANIAS_TABLE)
        end
      end

      class ResultLevel
        LEVEL = [
          :fumble,
          :failure,
          :success,
          :regular_success,
          :hard_success,
          :extreme_success,
          :critical,
        ].freeze

        LEVEL_TO_S = {
          critical: "대성공",
          extreme_success: "극단적 성공",
          hard_success: "어려운 성공",
          regular_success: "보통 성공",
          success: "성공",
          fumble: "대실패",
          failure: "실패",
        }.freeze

        def self.with_difficulty_level(total, difficulty)
          fumble = difficulty < 50 ? 96 : 100

          if total == 1
            ResultLevel.new(:critical)
          elsif total >= fumble
            ResultLevel.new(:fumble)
          elsif total <= difficulty
            ResultLevel.new(:success)
          else
            ResultLevel.new(:failure)
          end
        end

        def self.from_values(total, difficulty, fumbleable = false)
          fumble = difficulty < 50 || fumbleable ? 96 : 100

          if total == 1
            ResultLevel.new(:critical)
          elsif total >= fumble
            ResultLevel.new(:fumble)
          elsif total <= (difficulty / 5)
            ResultLevel.new(:extreme_success)
          elsif total <= (difficulty / 2)
            ResultLevel.new(:hard_success)
          elsif total <= difficulty
            ResultLevel.new(:regular_success)
          else
            ResultLevel.new(:failure)
          end
        end

        def initialize(level)
          @level = level
          @level_index = LEVEL.index(level)
          raise ArgumentError unless @level_index
        end

        def success?
          @level_index >= LEVEL.index(:success)
        end

        def failure?
          @level_index <= LEVEL.index(:failure)
        end

        def critical?
          @level == :critical
        end

        def fumble?
          @level == :fumble
        end

        def to_s
          LEVEL_TO_S[@level]
        end
      end

      private

      include Rollable

      def roll_1d8_table(table_name, table)
        total_n = @randomizer.roll_once(8)
        index = total_n - 1

        text = table[index]

        return "#{table_name}(#{total_n}) ＞ #{text}"
      end

      def roll_1d100_table(table_name, table)
        total_n = @randomizer.roll_once(100)
        index = total_n - 1

        text = table[index]

        return "#{table_name}(#{total_n}) ＞ #{text}"
      end

      def skill_roll(command)
        m = /^CC([-+]?\d+)?(?:<=(\d+)([RHEC])?)?$/.match(command)
        unless m
          return nil
        end

        bonus_dice = m[1].to_i
        difficulty = m[2]&.to_i
        difficulty_level = m[3]

        if difficulty == 0
          difficulty = nil
        elsif difficulty_level == "H"
          difficulty /= 2
        elsif difficulty_level == "E"
          difficulty /= 5
        elsif difficulty_level == "C"
          difficulty = 0
        end

        if bonus_dice == 0 && difficulty.nil?
          dice = @randomizer.roll_once(100)
          return "(1D100) ＞ #{dice}"
        end

        if bonus_dice.abs > 100
          return "보너스, 페널티 주사위의 값은 -100 이상, 100 이하로 지정해 주세요."
        end

        total, total_list = roll_with_bonus(bonus_dice)

        expr = difficulty.nil? ? "1D100" : "1D100<=#{difficulty}"
        result =
          if difficulty_level
            ResultLevel.with_difficulty_level(total, difficulty)
          elsif difficulty
            ResultLevel.from_values(total, difficulty)
          end

        sequence = [
          "(#{expr}) 보너스, 페널티 주사위[#{bonus_dice}]",
          total_list.join(", "),
          total,
          result,
        ].compact

        Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          if result
            r.condition = result.success?
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end

      def getFullAutoResult(command)
        FullAuto.eval(command, @randomizer)
      end

      def combine_roll(command)
        m = /^CBR\((\d+),(\d+)\)$/.match(command)
        return nil unless m

        difficulty_1 = m[1].to_i
        difficulty_2 = m[2].to_i

        total = @randomizer.roll_once(100)

        result_1 = ResultLevel.from_values(total, difficulty_1)
        result_2 = ResultLevel.from_values(total, difficulty_2)

        rank =
          if result_1.success? && result_2.success?
            "성공"
          elsif result_1.success? || result_2.success?
            "일부 성공"
          else
            "실패"
          end

        Result.new.tap do |r|
          r.text = "(1d100<=#{difficulty_1},#{difficulty_2}) ＞ #{total}[#{result_1},#{result_2}] ＞ #{rank}"
          r.success = result_1.success? && result_2.success?
          r.failure = result_1.failure? && result_2.failure?
        end
      end

      # 表一式
      # 即時の恐怖症表
      def roll_bmr_table()
        total_n = @randomizer.roll_once(10)
        text = MADNESS_REAL_TIME_TABLE[total_n - 1]

        time_n = @randomizer.roll_once(10)

        return "광기의 발작(실시간)(#{total_n}) ＞ #{text}(1D10 ＞ #{time_n}라운드)"
      end

      MADNESS_REAL_TIME_TABLE = [
        '기억상실: 마지막으로 안전했던 장소에서 떠난 후로 일어난 일을 전혀 기억하지 못합니다. 조금 전까지 아침 식사를 하고 있었는데 갑자기 괴물 앞에 서 있는 것입니다. 이 증상은 1D10 라운드 동안 계속됩니다.',
        '심신성 장애: 심신증으로 인해 1D10 라운드 동안 눈이 안 보이거나, 소리가 안 들리거나, 사지가 안 움직이게 됩니다.',
        '폭력: 분노에 휩싸여 자제심을 완전히 잃고 1D10 라운드 동안 주변의 적과 아군 모두에게 폭력과 파괴를 가합니다.',
        '편집증: 1D10 라운드 동안 심각한 편집증에 시달립니다. 모든 사람이 자기를 해치려 든다고 생각하고, 아무도 믿지 않습니다. 항상 감시를 당하고 있고, 주변에 배신자가 있으며, 지금 보이는 것이 거짓이라고 생각합니다.',
        '중요한 사람: 탐사자의 백스토리에서 중요한 사람들 항목을 봅니다. 곁에 있는 사람을 자기의 중요한 사람으로 착각하고, 관계에 맞게 행동합니다. 1D10 라운드 동안 지속됩니다.',
        '기절: 기절해서 1D10 라운드 후에 깨어납니다.',
        '필사적인 도주: 가능한 모든 수단을 동원해서 최대한 멀리 도망칩니다. 다른 사람들을 남겨 두고 하나밖에 없는 차를 혼자 몰고 가 버릴 수도 있습니다. 1D10 라운드 동안 계속 도망칩니다.',
        '발작적 행동이나 감정 폭발: 1D10 라운드 동안 웃거나, 울거나, 비명을 지르거나 하느라 다른 행동은 전혀 못 합니다.',
        '공포증: 새로운 공포증이 생깁니다. 【공포증의 예】(수호자 룰북 158p)에서 1D100을 굴리거나 수호자가 적절한 것을 고릅니다. 공포의 대상이 자리에 없어도 탐사자는 1D10 라운드 동안 그 모습을 상상하고 공포에 질립니다.',
        '집착증: 새로운 집착증이 생깁니다. 【집착증의 예】(수호자 룰북 159p)에서 1D100을 굴리거나 수호자가 적절한 것을 고릅니다. 탐사자는 다음 1D10 라운드 동안 새로운 집착증에 몰입합니다.'
      ].freeze

      # 略式の恐怖表
      def roll_bms_table()
        total_n = @randomizer.roll_once(10)
        text = MADNESS_SUMMARY_TABLE[total_n - 1]

        time_n = @randomizer.roll_once(10)

        return "광기의 발작(요약)(#{total_n}) ＞ #{text}(1D10 ＞ #{time_n}시간)"
      end

      MADNESS_SUMMARY_TABLE = [
        '기억상실: 탐사자는 낯선 곳에서 정신을 차리며, 자기가 누구인지도 기억하지 못합니다. 시간이 지나면 기억이 조금씩 돌아옵니다.',
        '도난: 탐사자가 1D10 시간 후에 정신을 차려 보니 도난을 당했습니다. 다친 곳은 없습니다. 소중한 물건 (탐사자 백스토리 참조)을 지니고 있었으면 운 판정을 해서 빼앗겼는지 확인합니다. 그 외의 귀중품은 자동으로 없어집니다.',
        '부상: 탐사자가 1D10 시간 후에 정신을 차려 보니 잔뜩 다쳤습니다. 체력은 광기에 빠지기 전의 절반이 되어 있지만, 그 사이에 중상을 입지는 않았습니다. 강도를 당하지도 않았습니다. 부상을 입은 경위는 수호자가 정합니다.',
        '폭력: 탐사자가 폭력과 파괴 행각을 벌입니다. 정신을 차렸을 때 그 사이의 행동이 기억날 수도 있고 기억나지 않을 수도 있습니다. 탐사자가 무엇을 대상으로 폭력을 휘둘렀는지, 그리고 사람을 죽이거나 다치게 했는지는 수호자가 결정합니다.',
        '사상/신념: 탐사자의 백스토리 항목에서 사상/신념을 확인합니다. 탐사자는 그 중 하나를 극단적이고 괴이한 방법으로 표출합니다. 예를 들어, 신앙심이 깊은 사람은 지하철에서 시끄럽게 설교를 하다가 정신을 차릴 수 있습니다.',
        '중요한 사람들: 탐사자의 백스토리에서 중요한 사람들을 찾아 그 관계가 중요한 이유를 확인합니다. 탐사자는 발작이 지속되는 동안 (1D10 시간 이상) 중요한 사람에게 가까이 가서 관계의 성질에 맞는 행동을 하려고 합니다.',
        '시설 감금: 탐사자가 정신을 차려 보니 정신병원이나 경찰서 유치장에 갇혀 있습니다. 그간의 사정이 조금씩 기억나기 시작할 수도 있습니다.',
        '필사적인 도주: 탐사자가 정신을 차려 보니 먼 곳에 와 있습니다. 황야를 걷고 있을 수도 있고 열차나 장거리 버스에 타고 있을 수도 있습니다.',
        '공포증: 탐사자에게 새로운 공포증이 생깁니다. 【공포증의 예】(수호자 룰북 158p)에서 1D100을 굴리거나 수호자가 적절한 것을 고릅니다. 탐사자는 새로운 공포의 대상을 피하기 위해 온갖 조치를 다 취한 상태로 1D10 시간 후에 정신을 차립니다.',
        '집착증: 탐사자에게 새로운 집착증이 생깁니다. 【집착증의 예】(수호자 룰북 159p)에서 1D100을 굴리거나 수호자가 적절한 것을 고릅니다. 탐사자는 1D10 시간 후에 정신을 차립니다. 이 발작이 지속되는 동안, 탐사자는 새로운 집착증에 완전히 빠집니다. 다른 사람에게도 명확하게 드러나는지는 수호자와 플레이어가 결정합니다.'
      ].freeze

      # キャスティング・ロールのプッシュに失敗した場合（小）
      FAILED_CASTING_L_TABLE = [
        '시야가 흐려지거나 일시적으로 눈이 멉니다.',
        '출처 모를 비명, 음성, 또는 다른 소음이 들립니다.',
        '강풍이 불거나 공기에 다른 변화가 일어납니다.',
        '술자나 현장에 있는 다른 사람, 주변의 물건(예:벽)에서 피가 흐릅니다.',
        '괴이한 환영과 환각이 시작됩니다.',
        '근처에 있는 작은 동물들이 폭발합니다.',
        '고약한 유황 냄새가 납니다.',
        '실수로 신화의 괴물이 소환됩니다.'
      ].freeze

      # キャスティング・ロールのプッシュに失敗した場合（大）
      FAILED_CASTING_M_TABLE = [
        '땅이 울리고 벽이 부서집니다.',
        '천둥과 번개가 요란하게 칩니다.',
        '하늘에서 피가 떨어집니다.',
        '술자의 손이 말라붙어 불탑니다.',
        '술자가 갑자기 늙습니다(+2D10년을 늙고 특성치에 p.32 나이에 나온 조정 사항을 적용).',
        '강력한/수많은 신화의 존재가 나타나서 근처에 있는 사람을 모두 공격합니다. 술자에게 가장 먼저 덤빕니다!',
        '술자와 근처에 있는 모든 사람이 다른 시공간으로 빨려 들어갑니다.',
        '실수로 신화의 신이 소환됩니다.'
      ].freeze

      # 恐怖症表 공포증 표
      PHOBIAS_TABLE = [
        '세척공포증: 씻거나 목욕하는 것에 대한 공포',
        '고소공포증: 높은 곳에 대한 공포',
        '비행공포증: 비행에 대한 공포',
        '광장공포증: 개방적이고 사람이 많은 공공장소에 대한 공포',
        '닭공포증: 닭과 병아리에 대한 공포',
        '마늘공포증: 마늘에 대한 공포',
        '탑승공포증: 탈것 안에 들어가거나 탑승하는 것에 대한 공포',
        '바람공포증: 바람에 대한 공포',
        '남성공포증: 남성에 대한 공포',
        '영국공포증: 영국, 영국 문화 등에 대한 공포',
        '꽃공포증: 꽃에 대한 공포',
        '절단공포증: 절단 또는 신체가 절단된 사람에 대한 공포',
        '거미공포증: 거미에 대한 공포',
        '번개공포증: 번개에 대한 공포',
        '폐허공포증: 폐허에 대한 공포',
        '피리공포증: 피리에 대한 공포',
        '세균공포증: 세균에 대한 공포',
        '탄환공포증: 사격과 탄환에 대한 공포',
        '추락공포증: 추락에 대한 공포',
        '서적공포증: 책에 대한 공포',
        '식물공포증: 식물에 대한 공포',
        '미녀공포증: 미모의 여성에 대한 공포',
        '냉기공포증: 냉기에 대한 공포',
        '시계공포증: 시계에 대한 공포',
        '폐소공포증: 막힌 공간에 대한 공포',
        '광대공포증: 광대에 대한 공포',
        '개공포증: 개에 대한 공포',
        '마귀공포증: 귀신과 악마에 대한 공포',
        '군집공포증: 군중에 대한 공포',
        '치과공포증: 치과의사에 대한 공포',
        '폐기공포증: 물건을 버리는 것에 대한 공포 (호더 증후군)',
        '모피공포증: 모피에 대한 공포',
        '횡단공포증: 길을 건너는 것에 대한 공포',
        '교회공포증: 교회에 대한 공포',
        '거울공포증: 거울에 대한 공포',
        '첨단공포증: 바늘이나 핀에 대한 공포',
        '곤충공포증: 곤충에 대한 공포',
        '고양이공포증: 고양이에 대한 공포',
        '교량공포증: 다리를 건너는 것에 대한 공포',
        '노인공포증: 노인 및 노화에 대한 공포',
        '여성공포증: 여성에 대한 공포',
        '혈액공포증: 피에 대한 공포',
        '죄악공포증: 죄를 저지르는 것에 대한 공포',
        '접촉공포증: 접촉에 대한 공포',
        '파충류공포증: 파충류에 대한 공포',
        '안개공포증: 안개에 대한 공포',
        '총기공포증: 총기에 대한 공포',
        '공수병: 물에 대한 공포',
        '수면공포증: 잠과 최면에 대한 공포',
        '의사공포증: 의사에 대한 공포',
        '어류공포증: 어류에 대한 공포',
        '바퀴벌레공포증: 바퀴벌레에 대한 공포',
        '천둥공포증: 천둥에 대한 공포',
        '채소공포증: 채소에 대한 공포',
        '소음공포증: 시끄러운 소리에 대한 공포',
        '호수공포증: 호수에 대한 공포',
        '기계공포증: 기계에 대한 공포',
        '거대공포증: 큰 것에 대한 공포',
        '결박공포증: 묶이는 것에 대한 공포',
        '유성공포증: 유성과 운석에 대한 공포',
        '고독공포증: 혼자 있는 것에 대한 공포',
        '불결공포증: 더러움이나 오염에 대한 공포',
        '점액공포증: 점액에 대한 공포',
        '시체공포증: 죽은 것들에 대한 공포',
        '8공포증: 8 모양에 대한 공포',
        '치아공포증: 치아에 대한 공포',
        '꿈공포증: 꿈에 대한 공포',
        '단어공포증: 특정 단어를 듣는 것에 대한 공포',
        '뱀공포증: 뱀에 대한 공포',
        '조류공포증: 조류에 대한 공포',
        '기생충공포증: 기생충에 대한 공포',
        '인형공포증: 인형에 대한 공포',
        '공식증: 삼키거나, 먹거나, 먹히는 것에 대한 공포',
        '약물공포증: 약물에 대한 공포',
        '유령공포증: 유령에 대한 공포',
        '일광공포증: 태양빛에 대한 공포',
        '수염공포증: 수염에 대한 공포',
        '하천공포증: 강에 대한 공포',
        '주류공포증: 알코올이나 알코올 음료에 대한 공포',
        '불공포증: 불에 대한 공포',
        '마법공포증: 마법에 대한 공포',
        '어둠공포증: 어둠이나 밤에 대한 공포',
        '달공포증: 달에 대한 공포',
        '열차공포증: 열차 여행에 대한 공포',
        '별공포증: 별에 대한 공포',
        '협소공포증: 좁은 물건이나 장소에 대한 공포',
        '대칭공포증: 대칭에 대한 공포',
        '생매장공포증: 생매장이나 무덤에 대한 공포',
        '황소공포증: 황소에 대한 공포',
        '전화공포증: 전화에 대한 공포',
        '괴물공포증: 괴물에 대한 공포',
        '해양공포증: 바다에 대한 공포',
        '수술공포증: 수술에 대한 공포',
        '13공포증: 숫자 13에 대한 공포',
        'er공포증: 옷에 대한 공포',
        '마녀공포증: 마녀와 주술에 대한 공포',
        '황색공포증: 노란색과「노란색」이라는 말에 대한 공포',
        '외국어공포증: 외국어에 대한 공포',
        '외국인공포증: 낯선 사람과 외국인에 대한 공포',
        '동물공포증: 동물에 대한 공포',
      ].freeze

      # マニア表 집착증 표
      MANIAS_TABLE = [
        '세척광: 자기 몸을 씻어야겠다는 강박',
        '무위광: 병적인 우유부단',
        '어둠애호증: 어둠을 광적으로 좋아하는 증상',
        '고도광: 높은 곳에 오르려는 강박',
        '친절광: 병적인 친절',
        '전원광: 트인 곳에 있으려는 강렬한 욕망',
        '첨단집착증: 날카롭고 뾰족한 물체에 대한 집착',
        '고양이애호증: 고양이를 광적으로 좋아하는 증상',
        '고통광: 고통에 대한 집착',
        '마늘광: 마늘에 대한 집착',
        '탑승광: 탈것 안에 있으려는 집착',
        '쾌활증: 병적인 쾌활함',
        '꽃애호증: 꽃에 대한 집착',
        '숫자광: 숫자에 과도하게 몰두',
        '낭비벽: 충동적이거나 병적인 소비',
        '고독광: 고독을 광적으로 좋아하는 증상',
        '발레광: 발레를 광적으로 좋아하는 증상',
        '책절도광: 책을 도둑질하려는 강박',
        '서적광: 책과 독서에 대한 집착',
        '이갈이광: 이를 가는 행동에 대한 강박',
        '빙의광: 자기가 악령에 씌었다는 병적인 믿음',
        '자기미인망상광: 자신의 미모에 대한 집착',
        '지도광: 모든 곳의 지도를 보려고 하는 자제할 수 없는 강박',
        '낙하광: 높은 곳에서 뛰어내리려는 집착',
        '냉기광: 냉기나 차가운 것들에 대한 비정상적인 욕망',
        '무도광: 춤애호증 또는 자제할 수 없는 광란',
        '침대광: 침대를 벗어나지 않으려는 과도한 욕망 (수면만족/수면벽)',
        '묘지광: 묘지에 대한 집착',
        '색채광: 특정한 색채에 대한 집착',
        '광대애호증: 광대에 대한 집착',
        '공포광: 공포스러운 상황을 겪고자 하는 강박',
        '살해광: 살해에 관한 집착',
        '악마광: 자기가 악마에 씌었다는 병적인 믿음',
        '박피광: 피부를 뜯으려는 강박',
        '정의광: 정의 실현을 보려는 집착',
        '음주광: 알코올에 비정상적으로 탐닉하는 증상',
        '모피광: 모피를 소유하려는 집착',
        '선물광: 선물을 주려는 집착',
        '탈출광: 도망치려는 강박',
        '방랑벽: 방랑을 하려는 강박',
        '자아광: 불합리한 자기중심적 태도, 자아도취',
        '공직광: 공직에 대한 자제할 수 없는 욕망',
        '죄악광: 자기가 죄를 지었다는 병적인 믿음',
        '지식광: 지식을 얻으려는 집착',
        '정적광: 정적에 대한 강박',
        '에테르광: 에테르에 대한 열망',
        '이상청혼광: 괴이하게 청혼하겠다는 집착',
        '폭소증: 소리내어 웃으려는 자제할 수 없는 강박',
        '마녀광: 마녀와 주술에 관한 집착',
        '서광: 무엇이든 써서 남기겠다는 집착',
        '나체광: 나체에 대한 강박',
        '낙천광: 사실을 무시하고 비정상적으로 즐거운 망상을 만들어 내려는 경향',
        '벌레애호증: 벌레를 광적으로 좋아함',
        '총기광: 총기에 대한 집착',
        '수갈증: 물에 대한 불합리한 열망',
        '어류광: 어류에 대한 집착',
        '초상광: 아이콘이나 초상화에 대한 집착',
        '우상광: 우상에 대한 집착 또는 헌신',
        '정보광: 사실 정보를 축적하려는 과도한 노력',
        '고함벽: 고함을 지르려는 불합리한 충동',
        '도벽: 도둑질을 하려는 불합리한 충동',
        '비명광: 크거나 날카로운 소리를 내려는 자제할 수 없는 강박',
        '현애호증: 끈에 대한 집착',
        '추첨광: 추첨에 참여하려는 극단적인 열망',
        '울증: 깊은 우울에 잠기려는 비정상적인 경향',
        '거석광: 서 있는 거석이나 원형으로 둘러싼 거석이 있을 때 괴이한 생각에 휩싸이는 비정상적인 경향',
        '음악광: 음악이나 특정한 곡조에 대한 집착',
        '작시광: 시를 지으려는 끝없는 욕망',
        '혐오증: 모든 것에 대한 증오, 특정 대상이나 단체에 대한 증오에 집착',
        '편집광: 한 가지 생각이나 아이디어에 대한 비정상적인 집착',
        '허언증: 비정상적인 수준의 거짓말이나 과장',
        '질환망상증: 상상의 질병으로 고통받는 망상',
        '기록광: 모든 것을 사진 등으로 기록하려는 강박',
        '명칭광: 이름에 대한 집착 (사람, 장소, 물건)',
        '단어광: 특정 단어를 반복하려는 자제할 수 없는 열망',
        '조갑박리광: 손톱을 강박적으로 잡아 뜯으려는 강박',
        '미식광: 한 가지 음식에 대한 비정상적인 애호',
        '불평광: 불평에서 비정상적인 쾌락을 느낌',
        '가면광: 가면을 쓰려는 강박',
        '유령광: 유령에 대한 집착',
        '살인광: 병적인 살인 경향',
        '조명광: 빛에 대한 병적인 열망',
        '일탈광: 사회 규범을 어기려는 비정상적인 열망',
        '배금광: 부에 대한 열망 and 집착',
        '습관성 거짓말: 거짓말을 하려는 불합리한 강박',
        '방화광: 불을 지르려는 강박',
        '질문광: 질문을 하려는 강박',
        '습관성 코파기: 코파기에 대한 강박',
        '낙서광: 낙서에 대한 집착',
        '열차광: 열차와 철도 여행에 대한 강렬한 집착',
        '현자망상증: 자기가 대단한 지능을 소유하고 있다는 망상',
        '기술광: 새로운 기술에 대한 집착',
        '자멸광: 자기가 죽음의 저주에 걸렸다는 믿음',
        '신광증: 자기가 신이라는 믿음',
        '소양광: 자기 몸을 긁으려는 강박',
        '수술광: 수술을 불합리할 정도로 좋아하는 경향',
        '발모증: 자신의 체모를 뽑으려는 열망',
        '심신성맹증: 심신증으로 인해 눈이 보이지 않음',
        '외국광: 외국의 것에 대한 집착',
        '동물광: 동물을 광적으로 좋아하는 증상',
      ].freeze
    end
  end
end
