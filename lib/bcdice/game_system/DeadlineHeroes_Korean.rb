# frozen_string_literal: true

module BCDice
  module GameSystem
    class DeadlineHeroes_Korean < Base
      ID = "DeadlineHeroes:Korean"
      NAME = "데드라인 히어로즈 RPG"
      SORT_KEY = "国際化:Korean:데드라인 히어로즈 RPG"

      HELP_MESSAGE = <<~TEXT
        ・행위판정（DLHx）
          x：성공률 (%)
          예) DLH80
          크리티컬, 펌블을 자동으로 판정합니다.
          「DLH50+20-30」처럼 가산, 감산 기재도 가능.
          성공률은 상한 100%, 하한 0%

        ・데스차트（DCxY）
          x：L=육체 / S=정신 / C=환경
          Y：수치
          예)
            DCL-5 → 라이프 -5로 판정
            DCS-3 → 새니티 -3으로 판정
            DCC0  → 크레딧 0으로 판정

        ・히어로 네임 차트（HNC）

        ・리얼 네임 차트:일본（RNCJ） / 해외（RNCO）

      TEXT

      register_prefix('DLH', 'DCL', 'DCS', 'DCC', 'HNC', 'RNCO', 'RNCJ')

      def eval_game_system_specific_command(command)
        roll_check(command) ||
          death_chart(command) ||
          hero_name_chart(command) ||
          real_name_chart_overseas(command) ||
          real_name_chart_jp(command)
      end

      def roll_check(command)
        # 1. /i 를 추가해 대소문자 무시
        m = /^DLH([0-9+-]+)$/i.match(command)
        return nil unless m

        expr = m[1]
        parts = expr.scan(/[+-]?\d+/)
        target = parts.map(&:to_i).sum
        target = [[target, 0].max, 100].min

        roll = @randomizer.roll_once(100)
        roll_str = format("%02d", roll)
        is_double = roll_str[0] == roll_str[1]

        # 2. 문자열을 먼저 조합
        text = "성공률#{target}% ＞ #{roll_str}"

        # 3. 문자열이 아닌 Result 객체를 반환
        if is_double && roll <= target
          return Result.critical("#{text} ＞ 크리티컬")
        elsif is_double && roll > target
          return Result.fumble("#{text} ＞ 펌블")
        elsif roll <= target
          return Result.success("#{text} ＞ 성공")
        else
          return Result.failure("#{text} ＞ 실패")
        end
      end

      def death_chart(command)
        m = /^DC([LSC])([+-]?\d+)$/i.match(command)
        return nil unless m

        type = m[1]
        base_value = m[2].to_i
        base_value = -base_value
        roll = @randomizer.roll_once(10)
        total = base_value + roll
        total = [total, 20].min # 21 이상은 20으로 보정

        table =
          case type
          when "L"
            [
              "",
              "",
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 2
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 3
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 4
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 5
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 6
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 7
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 8
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 9
              "아무 일도 일어나지 않는다. 당신은 기적적으로 목숨을 부지했다. 싸움은 계속된다.", # 10
              "격통이 인다. 이후 이벤트 종료 시까지 모든 판정 성공률 -10%.", # 11
              "당신은 [경직] 포인트 2점을 얻는다. [경직] 포인트를 소지하는 동안, 당신은 모든 파워를 사용할 수 없으며 자신의 턴도 얻을 수 없다. 각 라운드 종료 시, 당신이 소지한 [경직] 포인트를 1점 줄여도 좋다.", # 12
              "혼신의 일격!! 당신은 <생존> 판정을 한다. 실패한 경우 [사망] 한다.", # 13
              "당신은 [기절] 포인트를 2점 얻는다. [기절] 포인트를 소지하는 동안, 당신은 모든 파워를 사용할 수 없으며 자신의 턴도 얻을 수 없다. 각 라운드 종료 시, 당신이 소지한 [기절] 포인트를 1점 줄여도 좋다.", # 14
              "이후 이벤트 종료 시까지 모든 판정의 성공률 -20%.", # 15
              "기록적 일격!! 당신은 <생존>-20% 판정을 한다. 실패한 경우 [사망] 한다.", # 16
              "당신은 [빈사] 포인트 2점을 얻는다. [빈사] 포인트를 소지하는 동안, 당신은 모든 파워를 사용할 수 없으며 자신의 턴도 얻을 수 없다. 각 라운드 종료 시, 당신이 소지한 [빈사] 포인트를 1점 잃는다. 모든 [빈사] 포인트를 잃기 전에 전투가 끝나지 않았을 경우, 당신은 [사망] 한다.", # 17
              "서사시적 일격!! 당신은 <생존>-30% 판정을 한다. 실패한 경우 [사망] 한다.", # 18
              "이후 이벤트 종료 시까지 모든 판정의 성공률 -30%.", # 19
              "신화적 일격!! 당신은 하늘을 날아 3회전 정도 한 뒤, 지면에 내리꽂힌다. 눈뜨고 볼 수 없는 무참한 모습. 육체는 원형을 유지하지 못하고, 당신은 [사망] 했다." # 20
            ]
          when "S"
            ["", "",
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 2
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 3
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 4
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 5
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 6
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 7
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 8
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 9
             "아무 일도 일어나지 않는다. 당신은 이를 악물고 스트레스를 버텼다.", # 10
             "이후 이벤트 종료 시까지 모든 판정 성공률 -10%.", # 11
             "당신은 [공포] 포인트 2점을 얻는다. [공포] 포인트를 소지하는 동안, 당신은 [속성:공격]인 파워를 사용할 수 없다. 각 라운드 종료 시, 당신이 소지한 [공포] 포인트를 1점 줄여도 좋다.", # 12
             "매우 상처입었다. 당신은 <의지> 판정을 한다. 실패한 경우 [절망]해 NPC가 된다.", # 13
             "당신은 [기절] 포인트를 2점 얻는다. [기절] 포인트를 소지하는 동안, 당신은 모든 파워를 사용할 수 없으며 자신의 턴도 얻을 수 없다. 각 라운드 종료 시, 당신이 소지한 [기절] 포인트를 1점 줄여도 좋다.", # 14
             "이후 이벤트 종료 시까지 모든 판정의 성공률 -20%.", # 15
             "믿고 있던 사람에게 배신당한 듯한 아픔. 당신은 <의지>-20% 판정을 한다. 실패한 경우 [절망]해 NPC가 된다.", # 16
             "당신은 [혼란] 포인트 2점을 얻는다. [혼란] 포인트를 소지하는 동안, 당신은 원래 동료였던 캐릭터에게, 가능한 한 최대의 피해를 입히도록 행동을 계속한다. 각 라운드 종료 시, 당신이 소지한 [혼란] 포인트를 1점 줄여도 좋다.", # 17
             "너무나도 잔혹한 현실. 당신은 <의지>-30% 판정을 한다. 실패한 경우 [절망]해 NPC가 된다.", # 18
             "이후 이벤트 종료 시까지 모든 판정의 성공률 -30%.", # 19
             "우주의 섭리를 마주하나, 그것은 인류의 인식 한계를 뛰어넘는 무언가였다. 당신은 [절망]해 이후 NPC가 된다."] # 20
          when "C"
            ["", "",
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 2
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 3
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 4
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 5
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 6
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 7
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 8
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 9
             "아무 일도 일어나지 않는다. 당신은 수상한 소문을 불식시켰다.", # 10
             "이후 이벤트 종료 시까지 모든 판정 성공률 -10%.", # 11
             "핀치! 이후 이벤트 종료 시까지 당신은 《지원》을 사용할 수 없다.", # 12
             "배신!! 당신은 <경제> 판정을 한다. 실패한 경우 당신은 히어로로서의 명성을 잃고 [오명]을 뒤집어쓴다.", # 13
             "이후 시나리오 종료 시까지 대가로 크레딧을 소비하는 파워를 사용할 수 없다.", # 14
             "당신의 악평이 상당한 모양이다. 이후 시나리오 종료 시까지 모든 판정의 성공률 -20%.", # 15
             "신뢰의 실추!! 당신은 <경제>-20% 판정을 한다. 실패한 경우 당신은 히어로로서의 명성을 잃고 [오명]을 뒤집어쓴다.", # 16
             "이후 시나리오 종료 시까지 【환경】계열 기능의 레벨이 모두 0이 된다.", # 17
             "날조 보도!! 저지른 적 없는 범죄에 대한 가담이 특종으로 보도된다. 당신은 <경제>-30% 판정을 한다. 실패한 경우 당신은 히어로로서의 명성을 잃고 [오명]을 뒤집어쓴다.", # 18
             "이후 이벤트 종료 시까지 모든 판정의 성공률 -30%.", # 19
             "당신의 이름은 사상 최악의 오점으로 영원히 역사에 기록된다. 더이상 당신을 믿는 동료는 없으며, 당신을 도와줄 사회도 없다. 당신은 [오명]을 뒤집어쓴다."] # 20
          end
        result_text = table[total] || "(결과 없음)"

        "(#{type} 데스차트 ＞ #{result_text}"
      end

      def hero_name_chart(command)
        return nil unless command == "HNC"

        combo_roll = @randomizer.roll_once(9)
        combo_pattern = [
          "베이스A+베이스B", "베이스B", "베이스B×2회", "베이스B+베이스C",
          "베이스A+베이스B+베이스C", "베이스A+베이스B×2회",
          "베이스B×2회+베이스C", "베이스B·오브·베이스B", "베이스B·더·베이스B"
        ][combo_roll - 1]
        base_a = get_from_table(:A)
        base_b1 = get_from_table(:B)
        base_b2 = get_from_table(:B)
        base_c = get_from_table(:C)
        result_name = case combo_roll
                      when 1 then "#{base_a}#{base_b1}"
                      when 2 then base_b1
                      when 3 then "#{base_b1}#{base_b2}"
                      when 4 then "#{base_b1}#{base_c}"
                      when 5 then "#{base_a}#{base_b1}#{base_c}"
                      when 6 then "#{base_a}#{base_b1}#{base_b2}"
                      when 7 then "#{base_b1}#{base_b2}#{base_c}"
                      when 8 then "#{base_b1}·오브·#{base_b2}"
                      when 9 then "#{base_b1}·더·#{base_b2}"
                      end
        "히어로 네임 차트 ＞ 조합식: #{combo_pattern} ＞ 결과: #{result_name}"
      end

      # ========== [베이스 및 세부표] ==========
      def get_from_table(type)
        case type
        when :A
          roll = @randomizer.roll_once(10)
          case roll
          when 1 then "더·"
          when 2 then "캡틴·"
          when 3 then sample(["미스터·", "미스·", "미세스·"])
          when 4 then sample(["닥터·", "프로페서·"])
          when 5 then sample(["로드·", "바론·", "제네럴·"])
          when 6 then "맨·오브·"
          when 7 then get_from_table(:STR)
          when 8 then get_from_table(:COLOR)
          when 9 then sample(["마담·", "미들·"])
          when 10 then @randomizer.roll_once(10).to_s
          end

        when :B
          roll = @randomizer.roll_once(10)
          case roll
          when 1 then get_from_table(:MYTH)
          when 2 then get_from_table(:WEAPON)
          when 3 then get_from_table(:ANIMAL)
          when 4 then get_from_table(:BIRD)
          when 5 then get_from_table(:BUG)
          when 6 then get_from_table(:BODY)
          when 7 then get_from_table(:LIGHT)
          when 8 then get_from_table(:ATTACK)
          when 9 then get_from_table(:ETC)
          when 10 then @randomizer.roll_once(10).to_s
          end

        when :C
          roll = @randomizer.roll_once(10)
          case roll
          when 1 then sample(["맨", "우먼"])
          when 2 then sample(["보이", "걸"])
          when 3 then sample(["마스크", "후드"])
          when 4 then "라이더"
          when 5 then "마스터"
          when 6 then sample(["파이터", "솔저"])
          when 7 then sample(["킹", "퀸"])
          when 8 then get_from_table(:COLOR)
          when 9 then sample(["히어로", "스페셜"])
          when 10 then @randomizer.roll_once(10).to_s
          end

        when :COLOR then sample(['블랙', '그린', '블루', '옐로', '레드', '바이올렛', '실버', '골드', '화이트', '클리어'])
        when :WEAPON then sample(['나이브스', '소드', '해머', '건', '스틸', '터스크', '뉴', '애로', '소', '레이저'])
        when :BODY then sample(['하트', '페이스', '암', '숄더', '헤드', '아이', '피스트', '핸드', '클로', '본'])
        when :ATTACK then sample(['스트로크', '크래시', '블로', '히트', '펀치', '킥', '슬래시', '베네트레이트', '샷', '킬'])
        when :MYTH then sample(['아포칼립스', '워', '이터널', '엔젤', '데블', '이모탈', '데스', '드림', '고스트', '데드'])
        when :ANIMAL then sample(['버니', '타이거', '샤크', '캣', '콩', '도그', '폭스', '팬서', '애스', '배트'])
        when :LIGHT then sample(['라이트', '섀도우', '파이어', '다크', '나이트', '팬텀', '토치', '플래시', '랜턴', '선'])
        when :BIRD then sample(['호크', '팔콘', '캐너리', '로빈', '이글', '아울', '레이븐', '덕', '펭귄', '피닉스'])
        when :ETC then sample(['휴먼', '에이전트', '부스터', '아이언', '선더', '워처', '풀', '머신', '콜드', '사이드'])
        when :STR then sample(['슈퍼', '원더', '얼티밋', '판타스틱', '마이티', '인크레더블', '어메이징', '와일드', '그레이티스트', '마벨러스'])
        when :BUG then sample(['비틀', '버터플라이', '스네이크', '엘리게이터', '로커스트', '리자드', '터틀', '스파이더', '앤트', '맨티스'])
        end
      end

      def sample(array)
        index = @randomizer.roll_once(array.size) - 1
        array[index]
      end

      def real_name_chart_overseas(command)
        return nil unless command == "RNCO"
        return "무명(모종의 이유로 이름이 없다. 혹은 잃었다)" if @randomizer.roll_once(10) == 1

        first_male = sample(['알버스', '크리스', '사뮤엘', '시드니', '스파이크', '데미안', '딕', '덴젤', '돈', '니콜라스', '네빌', '발리', '빌리', '브루스', '마브', '라이언'])
        first_female = sample(['아이리스', '올리브', '카라', '킬스틴', '그웬', '사만사', '저스티나', '타바사', '나딘', '노엘', '할린', '마르셀라', '라나', '린디', '로잘리', '원더'])
        last_name = sample(['알렌', '워큰', '울프먼', '오르센', '카터', '캐러딘', '지겔', '존스', '파커', '프리먼', '머피', '밀러', '무어', '리브', '레이놀즈', '워드'])

        "이름(남):#{first_male}\n이름(여):#{first_female}\n성:#{last_name}"
      end

      def real_name_chart_jp(command)
        return nil unless command == "RNCJ"
        return "무명(모종의 이유로 이름이 없다. 혹은 잃었다)" if @randomizer.roll_once(10) == 1

        last_name = sample(['아이카와', '아마미야', '이부키', '오가미', '카이', '사카키', '시시도', '타치바나', '츠부라야', '하야카와', '하라다', '후지카와', '호시', '미조구치', '야시다', '유우키'])
        first_male = sample(['아키라', '에이지', '카즈키', '긴가', '켄이치로', '고우', '지로', '타케시', '츠바사', '테츠', '히데오', '마사무네', '야마토', '류세이', '레츠', '렌'])
        first_female = sample(['안', '이노리', '에마', '카논', '사라', '시즈쿠', '치즈루', '나오미', '하루', '히카루', '베니', '마치', '미아', '유리코', '루이', '레나'])

        "성:#{last_name}\n이름(남):#{first_male}\n이름(여):#{first_female}"
      end
    end
  end
end
