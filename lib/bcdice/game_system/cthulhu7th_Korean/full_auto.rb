# frozen_string_literal: true

module BCDice
  module GameSystem
    class Cthulhu7th_Korean < Base
      class FullAuto
        BONUS_DICE_RANGE = (-2..2).freeze

        # 連射処理を止める条件（難易度の閾値）: 연사 처리를 중지하는 조건(난이도 임계값)
        # @return [Hash<String, Integer>]
        #
        # 成功の種類の小文字表記 => 難易度の閾値 : 성공 유형의 소문자 표기 => 난이도 임계값
        ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD = {
          # レギュラー : 보통 성공
          "r" => 0,
          # ハード : 어려운 성공
          "h" => 1,
          # イクストリーム : 극단적 성공
          "e" => 2
        }.freeze

        def self.eval(command, randomizer)
          new.eval(command, randomizer)
        end

        def eval(command, randomizer)
          @randomizer = randomizer
          get_full_auto_result(command)
        end

        private

        include Rollable

        def get_full_auto_result(command)
          m = /^FAR\((-?\d+),(-?\d+),(-?\d+)(?:,(-?\d+)?)?(?:,(-?\w+)?)?(?:,(-?\d+)?)?\)$/i.match(command)
          unless m
            return nil
          end

          bullet_count = m[1].to_i
          diff = m[2].to_i
          broken_number = m[3].to_i
          bonus_dice_count = m[4].to_i
          stop_count = m[5]&.downcase || ""
          bullet_set_count_cap = m[6]&.to_i || diff / 10

          output = ""

          # 最大で（8回*（PC技能値最大値/10））＝72発しか撃てないはずなので上限 : 최대 (8회 * (PC 능력치 최대값 / 10)) = 72발밖에 쏠 수 없으므로 상한선
          bullet_count_limit = 100
          if bullet_count > bullet_count_limit
            output += "탄환이 너무 많습니다. 장전된 탄환을 #{bullet_count_limit}발로 변경합니다.\n"
            bullet_count = bullet_count_limit
          end

          # ボレーの上限の設定がおかしい場合の注意表示 : 연사 상한선 설정이 잘못된 경우의 주의 표시
          if (bullet_set_count_cap > diff / 10) && (diff > 39) && !m[6].nil?
            bullet_set_count_cap = diff / 10
            output += "연사할 탄환 수의 상한은 [기능치÷10(소수점 버림)]발이므로, 그보다 큰 수를 지정할 수 없습니다. 연사할 탄환 수를 #{bullet_set_count_cap}발로 변경합니다.\n"
          elsif (diff <= 39) && (bullet_set_count_cap > 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "기능치가 39 이하일 때 연사할 탄환 수의 상한 및 하한은 3발입니다. 연사할 탄환 수를 #{bullet_set_count_cap}발로 변경합니다.\n"
          end

          # ボレーの下限の設定がおかしい場合の注意表示およびエラー表示 : 연사 하한값 설정이 잘못된 경우의 주의 표시 및 오류 표시
          return "연사할 탄환 수는 양수여야 합니다." if (bullet_set_count_cap <= 0) && !m[6].nil?

          if (bullet_set_count_cap < 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "연사할 탄환 수의 하한은 3발입니다. 연사할 탄환 수를 3발로 변경합니다.\n"
          end

          return "탄환은 양수여야 합니다." if bullet_count <= 0
          return "목표치는 양수여야 합니다." if diff <= 0

          if broken_number < 0
            output += "고장 수치는 양수여야 합니다. 마이너스 부호를 제외합니다.\n"
            broken_number = broken_number.abs
          end

          unless BONUS_DICE_RANGE.include?(bonus_dice_count)
            return "오류. 보너스, 페널티 주사위의 값은 #{BONUS_DICE_RANGE.min}~#{BONUS_DICE_RANGE.max}여야 합니다."
          end

          output += "보너스, 페널티 주사위[#{bonus_dice_count}]"
          output += roll_full_auto(bullet_count, diff, broken_number, bonus_dice_count, stop_count, bullet_set_count_cap)

          return output
        end

        def roll_full_auto(bullet_count, diff, broken_number, dice_num, stop_count, bullet_set_count_cap)
          output = ""
          loop_count = 0

          counts = {
            hit_bullet: 0,
            impale_bullet: 0,
            bullet: bullet_count,
          }

          # 難易度変更用ループ : 난이도 변경용 루프
          4.times do |more_difficulty|
            output += get_next_difficulty_message(more_difficulty)

            # ペナルティダイスを減らしながらロール用ループ : 페널티 주사위를 줄이면서 주사위를 굴리는 루프
            while dice_num >= BONUS_DICE_RANGE.min

              loop_count += 1
              hit_result, total, total_list = get_hit_result_infos(dice_num, diff, more_difficulty)
              output += "\n#{loop_count}번째: ＞ #{total_list.join(', ')} ＞ #{hit_result}"

              if total >= broken_number
                output += "　총알 걸림(고장)"
                return get_hit_result_text(output, counts)
              end

              hit_type = get_hit_type(more_difficulty, hit_result)
              hit_bullet, impale_bullet, lost_bullet = get_bullet_results(counts[:bullet], hit_type, diff, bullet_set_count_cap)

              output += "　（#{hit_bullet}발 명중, #{impale_bullet}발 관통）"

              counts[:hit_bullet] += hit_bullet
              counts[:impale_bullet] += impale_bullet
              counts[:bullet] -= lost_bullet

              return get_hit_result_text(output, counts) if counts[:bullet] <= 0

              dice_num -= 1
            end

            # 指定された難易度となった場合、連射処理を途中で止める : 지정된 난이도에 도달하면 연사 처리를 중단
            if should_stop_roll_full_auto?(stop_count, more_difficulty)
              output += "\n【지정한 난이도가 되었으므로, 처리를 종료합니다.】"
              break
            end

            dice_num += 1
          end

          return get_hit_result_text(output, counts)
        end

        # 連射処理を止めるべきかどうかを返す : 연사 처리를 중지해야 하는지 여부를 반환
        # @param [String] stop_count 成功の種類
        # @param [Integer] difficulty 難易度
        # @return [Boolean]
        def should_stop_roll_full_auto?(stop_count, difficulty)
          difficulty_threshold = ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD[stop_count]
          return difficulty_threshold && difficulty >= difficulty_threshold
        end

        def get_hit_result_infos(dice_num, diff, more_difficulty)
          total, total_list = roll_with_bonus(dice_num)

          fumbleable = get_fumbleable(more_difficulty)
          hit_result = ResultLevel.from_values(total, diff, fumbleable).to_s

          return hit_result, total, total_list
        end

        def get_hit_result_text(output, counts)
          return "#{output}\n＞ #{counts[:hit_bullet]}발 명중, #{counts[:impale_bullet]}발 관통, 남은 탄환 #{counts[:bullet]}발"
        end

        def get_hit_type(more_difficulty, hit_result)
          success_list, impale_bullet_list = get_success_list_impale_bullet_list(more_difficulty)

          return :hit if success_list.include?(hit_result)
          return :impale if impale_bullet_list.include?(hit_result)

          return ""
        end

        def get_bullet_results(bullet_count, hit_type, diff, bullet_set_count_cap)
          bullet_set_count = get_set_of_bullet(diff, bullet_set_count_cap)
          hit_bullet_count_base = get_hit_bullet_count_base(diff, bullet_set_count)
          impale_bullet_count_base = (bullet_set_count / 2.to_f)

          lost_bullet_count = 0
          hit_bullet_count = 0
          impale_bullet_count = 0

          if !last_bullet_turn?(bullet_count, bullet_set_count)

            case hit_type
            when :hit
              hit_bullet_count = hit_bullet_count_base # 通常命中した弾数の計算 : 명중한 탄환 수 계산

            when :impale
              impale_bullet_count = impale_bullet_count_base.floor # 貫通した弾数の計算 : 관통한 탄환 수 계산
              hit_bullet_count = impale_bullet_count_base.ceil
            end

            lost_bullet_count = bullet_set_count

          else

            case hit_type
            when :hit
              hit_bullet_count = get_last_hit_bullet_count(bullet_count)

            when :impale
              impale_bullet_count = get_last_hit_bullet_count(bullet_count)
              hit_bullet_count = bullet_count - impale_bullet_count
            end

            lost_bullet_count = bullet_count
          end

          return hit_bullet_count, impale_bullet_count, lost_bullet_count
        end

        def get_success_list_impale_bullet_list(more_difficulty)
          success_list = []
          impale_bullet_list = []

          case more_difficulty
          when 0
            success_list = ["어려운 성공", "보통 성공"]
            impale_bullet_list = ["대성공", "극단적 성공"]
          when 1
            success_list = ["어려운 성공"]
            impale_bullet_list = ["대성공", "극단적 성공"]
          when 2
            success_list = []
            impale_bullet_list = ["대성공", "극단적 성공"]
          when 3
            success_list = ["대성공"]
            impale_bullet_list = []
          end

          return success_list, impale_bullet_list
        end

        def get_next_difficulty_message(more_difficulty)
          case more_difficulty
          when 1
            return "\n【난이도를 어려운 성공으로 변경】"
          when 2
            return "\n【난이도를 극단적 성공으로 변경】"
          when 3
            return "\n【난이도를 대성공으로 변경】"
          end

          return ""
        end

        def get_set_of_bullet(diff, bullet_set_count_cap)
          bullet_set_count = diff / 10

          if bullet_set_count_cap < bullet_set_count
            bullet_set_count = bullet_set_count_cap
          end

          if (diff >= 1) && (diff < 30)
            bullet_set_count = 3 # 技能値が29以下での最低値保障処理 : 기능치가 29 이하일 때의 최저치 보장 처리
          end

          return bullet_set_count
        end

        def get_hit_bullet_count_base(diff, bullet_set_count)
          hit_bullet_count_base = (bullet_set_count / 2)

          if (diff >= 1) && (diff < 30)
            hit_bullet_count_base = 1 # 技能値29以下での最低値保障 : 기능치 29 이하일 때의 최저치 보장
          end

          return hit_bullet_count_base
        end

        def last_bullet_turn?(bullet_count, bullet_set_count)
          ((bullet_count - bullet_set_count) < 0)
        end

        def get_last_hit_bullet_count(bullet_count)
          # 残弾1での最低値保障処理 : 잔탄 1개일 때의 최저치 보장 처리
          if bullet_count == 1
            return 1
          end

          count = (bullet_count / 2.to_f).floor
          return count
        end

        def get_fumbleable(more_difficulty)
          # 成功が49以下の出目のみとなるため、ファンブル値は上昇 : 성공이 49 이하일 때만 적용되므로, 펌블치 상승
          return (more_difficulty >= 1)
        end
      end
    end
  end
end
