# frozen_string_literal: true

module BCDice
  module GameSystem
    class Cthulhu7th_ChineseTraditional < Base
      class FullAuto
        BONUS_DICE_RANGE = (-2..2).freeze

        # 停止連射的條件（難度閾值）
        # @return [Hash<String, Integer>]
        #
        # 成功類型的小寫表記 => 難度的閾值
        ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD = {
          # 一般
          "r" => 0,
          # 困難
          "h" => 1,
          # 極限
          "e" => 2
        }.freeze

        def self.eval(command, randomizer)
          new.eval(command, randomizer)
        end

        def eval(command, randomizer)
          @randomizer = randomizer
          getFullAutoResult(command)
        end

        private

        include Rollable

        def getFullAutoResult(command)
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

          # 最大（8次 * （PC技能值最大值 / 10））= 72發，因此設置上限
          bullet_count_limit = 100
          if bullet_count > bullet_count_limit
            output += "彈藥數量過多。將裝填的彈藥數量更改為#{bullet_count_limit}發。\n"
            bullet_count = bullet_count_limit
          end

          # 如果設置的連射上限不合理則顯示注意
          if (bullet_set_count_cap > diff / 10) && (diff > 39) && !m[6].nil?
            bullet_set_count_cap = diff / 10
            output += "連射的彈藥數量上限為\[技能值÷10（取整）\]發，因此無法指定更高的數量。連射的彈藥數量更改為#{bullet_set_count_cap}發。\n"
          elsif (diff <= 39) && (bullet_set_count_cap > 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "技能值在39以下時，連射的彈藥數量上限和下限均為3發。連射的彈藥數量更改為#{bullet_set_count_cap}發。\n"
          end

          # 如果設置的連射下限不合理則顯示注意或錯誤
          return "連射的彈藥數量必須為正數。" if (bullet_set_count_cap <= 0) && !m[6].nil?

          if (bullet_set_count_cap < 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "連射的彈藥數量下限為3發。連射的彈藥數量更改為3發。\n"
          end

          return "彈藥數量必須為正數。" if bullet_count <= 0
          return "目標值必須為正數。" if diff <= 0

          if broken_number < 0
            output += "故障值必須為正數。去掉負號。\n"
            broken_number = broken_number.abs
          end

          unless BONUS_DICE_RANGE.include?(bonus_dice_count)
            return "錯誤。獎勵・懲罰骰的值必須在#{BONUS_DICE_RANGE.min}～#{BONUS_DICE_RANGE.max}之間。"
          end

          output += "獎勵・懲罰骰[#{bonus_dice_count}]"
          output += rollFullAuto(bullet_count, diff, broken_number, bonus_dice_count, stop_count, bullet_set_count_cap)

          return output
        end

        def rollFullAuto(bullet_count, diff, broken_number, dice_num, stop_count, bullet_set_count_cap)
          output = ""
          loopCount = 0

          counts = {
            hit_bullet: 0,
            impale_bullet: 0,
            bullet: bullet_count,
          }

          # 難度變更用循環
          4.times do |more_difficulty|
            output += getNextDifficultyMessage(more_difficulty)

            # 隨著懲罰骰的減少進行擲骰循環
            while dice_num >= BONUS_DICE_RANGE.min
              loopCount += 1
              hit_result, total, total_list = getHitResultInfos(dice_num, diff, more_difficulty)
              output += "\n#{loopCount}次: ＞ #{total_list.join(', ')} ＞ #{hit_result}"

              if total >= broken_number
                output += "　卡彈"
                return getHitResultText(output, counts)
              end

              hit_type = getHitType(more_difficulty, hit_result)
              hit_bullet, impale_bullet, lost_bullet = getBulletResults(counts[:bullet], hit_type, diff, bullet_set_count_cap)

              output += "　（#{hit_bullet}發命中，#{impale_bullet}發貫穿）"

              counts[:hit_bullet] += hit_bullet
              counts[:impale_bullet] += impale_bullet
              counts[:bullet] -= lost_bullet

              return getHitResultText(output, counts) if counts[:bullet] <= 0

              dice_num -= 1
            end

            # 當達到指定的難度時，停止連射處理
            if shouldStopRollFullAuto?(stop_count, more_difficulty)
              output += "\n【因達到指定難度，處理結束。】"
              break
            end

            dice_num += 1
          end

          return getHitResultText(output, counts)
        end

        # 判斷是否應該停止連射處理
        # @param [String] stop_count 成功的類型
        # @param [Integer] difficulty 難度
        # @return [Boolean]
        def shouldStopRollFullAuto?(stop_count, difficulty)
          difficulty_threshold = ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD[stop_count]
          return difficulty_threshold && difficulty >= difficulty_threshold
        end

        def getHitResultInfos(dice_num, diff, more_difficulty)
          total, total_list = roll_with_bonus(dice_num)

          fumbleable = getFumbleable(more_difficulty)
          hit_result = ResultLevel.from_values(total, diff, fumbleable).to_s

          return hit_result, total, total_list
        end

        def getHitResultText(output, counts)
          return "#{output}\n＞ #{counts[:hit_bullet]}發一般命中，#{counts[:impale_bullet]}發貫穿，剩餘彈藥#{counts[:bullet]}發"
        end

        def getHitType(more_difficulty, hit_result)
          successList, impaleBulletList = getSuccessListImpaleBulletList(more_difficulty)

          return :hit if successList.include?(hit_result)
          return :impale if impaleBulletList.include?(hit_result)

          return ""
        end

        def getBulletResults(bullet_count, hit_type, diff, bullet_set_count_cap)
          bullet_set_count = getSetOfBullet(diff, bullet_set_count_cap)
          hit_bullet_count_base = getHitBulletCountBase(diff, bullet_set_count)
          impale_bullet_count_base = (bullet_set_count / 2.to_f)

          lost_bullet_count = 0
          hit_bullet_count = 0
          impale_bullet_count = 0

          if !isLastBulletTurn(bullet_count, bullet_set_count)

            case hit_type
            when :hit
              hit_bullet_count = hit_bullet_count_base # 計算一般命中的彈數

            when :impale
              impale_bullet_count = impale_bullet_count_base.floor # 計算貫穿的彈數
              hit_bullet_count = impale_bullet_count_base.ceil
            end

            lost_bullet_count = bullet_set_count

          else

            case hit_type
            when :hit
              hit_bullet_count = getLastHitBulletCount(bullet_count)

            when :impale
              impale_bullet_count = getLastHitBulletCount(bullet_count)
              hit_bullet_count = bullet_count - impale_bullet_count
            end

            lost_bullet_count = bullet_count
          end

          return hit_bullet_count, impale_bullet_count, lost_bullet_count
        end

        def getSuccessListImpaleBulletList(more_difficulty)
          successList = []
          impaleBulletList = []

          case more_difficulty
          when 0
            successList = ["困難成功", "一般成功"]
            impaleBulletList = ["大成功", "極限成功"]
          when 1
            successList = ["困難成功"]
            impaleBulletList = ["大成功", "極限成功"]
          when 2
            successList = []
            impaleBulletList = ["大成功", "極限成功"]
          when 3
            successList = ["大成功"]
            impaleBulletList = []
          end

          return successList, impaleBulletList
        end

        def getNextDifficultyMessage(more_difficulty)
          case more_difficulty
          when 1
            return "\n【難度已更改為困難】"
          when 2
            return "\n【難度已更改為極限】"
          when 3
            return "\n【難度已更改為大成功】"
          end

          return ""
        end

        def getSetOfBullet(diff, bullet_set_count_cap)
          bullet_set_count = diff / 10

          if bullet_set_count_cap < bullet_set_count
            bullet_set_count = bullet_set_count_cap
          end

          if (diff >= 1) && (diff < 30)
            bullet_set_count = 3 # 技能值在29以下的最低值保障處理
          end

          return bullet_set_count
        end

        def getHitBulletCountBase(diff, bullet_set_count)
          hit_bullet_count_base = (bullet_set_count / 2)

          if (diff >= 1) && (diff < 30)
            hit_bullet_count_base = 1 # 技能值在29以下的最低值保障
          end

          return hit_bullet_count_base
        end

        def isLastBulletTurn(bullet_count, bullet_set_count)
          ((bullet_count - bullet_set_count) < 0)
        end

        def getLastHitBulletCount(bullet_count)
          # 剩餘1發的最低值保障處理
          if bullet_count == 1
            return 1
          end

          count = (bullet_count / 2.to_f).floor
          return count
        end

        def getFumbleable(more_difficulty)
          # 因為成功的出目必須在49以下，因此失誤值上升
          return (more_difficulty >= 1)
        end
      end
    end
  end
end