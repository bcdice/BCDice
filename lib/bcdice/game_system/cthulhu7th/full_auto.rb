# frozen_string_literal: true

module BCDice
  module GameSystem
    class Cthulhu7th < Base
      class FullAuto
        BONUS_DICE_RANGE = (-2..2).freeze

        # 連射処理を止める条件（難易度の閾値）
        # @return [Hash<String, Integer>]
        #
        # 成功の種類の小文字表記 => 難易度の閾値
        ROLL_FULL_AUTO_DIFFICULTY_THRESHOLD = {
          # レギュラー
          "r" => 0,
          # ハード
          "h" => 1,
          # イクストリーム
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

          # 最大で（8回*（PC技能値最大値/10））＝72発しか撃てないはずなので上限
          bullet_count_limit = 100
          if bullet_count > bullet_count_limit
            output += "弾薬が多すぎます。装填された弾薬を#{bullet_count_limit}発に変更します。\n"
            bullet_count = bullet_count_limit
          end

          # ボレーの上限の設定がおかしい場合の注意表示
          if (bullet_set_count_cap > diff / 10) && (diff > 39) && !m[6].nil?
            bullet_set_count_cap = diff / 10
            output += "ボレーの弾丸の数の上限は\[技能値÷10（切り捨て）\]発なので、それより高い数を指定できません。ボレーの弾丸の数を#{bullet_set_count_cap}発に変更します。\n"
          elsif (diff <= 39) && (bullet_set_count_cap > 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "技能値が39以下ではボレーの弾丸の数の上限および下限は3発です。ボレーの弾丸の数を#{bullet_set_count_cap}発に変更します。\n"
          end

          # ボレーの下限の設定がおかしい場合の注意表示およびエラー表示
          return "ボレーの弾丸の数は正の数です。" if (bullet_set_count_cap <= 0) && !m[6].nil?

          if (bullet_set_count_cap < 3) && !m[6].nil?
            bullet_set_count_cap = 3
            output += "ボレーの弾丸の数の下限は3発です。ボレーの弾丸の数を3発に変更します。\n"
          end

          return "弾薬は正の数です。" if bullet_count <= 0
          return "目標値は正の数です。" if diff <= 0

          if broken_number < 0
            output += "故障ナンバーは正の数です。マイナス記号を外します。\n"
            broken_number = broken_number.abs
          end

          unless BONUS_DICE_RANGE.include?(bonus_dice_count)
            return "エラー。ボーナス・ペナルティダイスの値は#{BONUS_DICE_RANGE.min}～#{BONUS_DICE_RANGE.max}です。"
          end

          output += "ボーナス・ペナルティダイス[#{bonus_dice_count}]"
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

          # 難易度変更用ループ
          4.times do |more_difficulty|
            output += getNextDifficultyMessage(more_difficulty)

            # ペナルティダイスを減らしながらロール用ループ
            while dice_num >= BONUS_DICE_RANGE.min

              loopCount += 1
              hit_result, total, total_list = getHitResultInfos(dice_num, diff, more_difficulty)
              output += "\n#{loopCount}回目: ＞ #{total_list.join(', ')} ＞ #{hit_result}"

              if total >= broken_number
                output += "　ジャム"
                return getHitResultText(output, counts)
              end

              hit_type = getHitType(more_difficulty, hit_result)
              hit_bullet, impale_bullet, lost_bullet = getBulletResults(counts[:bullet], hit_type, diff, bullet_set_count_cap)

              output += "　（#{hit_bullet}発が命中、#{impale_bullet}発が貫通）"

              counts[:hit_bullet] += hit_bullet
              counts[:impale_bullet] += impale_bullet
              counts[:bullet] -= lost_bullet

              return getHitResultText(output, counts) if counts[:bullet] <= 0

              dice_num -= 1
            end

            # 指定された難易度となった場合、連射処理を途中で止める
            if shouldStopRollFullAuto?(stop_count, more_difficulty)
              output += "\n【指定の難易度となったので、処理を終了します。】"
              break
            end

            dice_num += 1
          end

          return getHitResultText(output, counts)
        end

        # 連射処理を止めるべきかどうかを返す
        # @param [String] stop_count 成功の種類
        # @param [Integer] difficulty 難易度
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
          return "#{output}\n＞ #{counts[:hit_bullet]}発が通常命中、#{counts[:impale_bullet]}発が貫通、残弾#{counts[:bullet]}発"
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
              hit_bullet_count = hit_bullet_count_base # 通常命中した弾数の計算

            when :impale
              impale_bullet_count = impale_bullet_count_base.floor # 貫通した弾数の計算
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
            successList = ["ハード成功", "レギュラー成功"]
            impaleBulletList = ["クリティカル", "イクストリーム成功"]
          when 1
            successList = ["ハード成功"]
            impaleBulletList = ["クリティカル", "イクストリーム成功"]
          when 2
            successList = []
            impaleBulletList = ["クリティカル", "イクストリーム成功"]
          when 3
            successList = ["クリティカル"]
            impaleBulletList = []
          end

          return successList, impaleBulletList
        end

        def getNextDifficultyMessage(more_difficulty)
          case more_difficulty
          when 1
            return "\n【難易度がハードに変更】"
          when 2
            return "\n【難易度がイクストリームに変更】"
          when 3
            return "\n【難易度がクリティカルに変更】"
          end

          return ""
        end

        def getSetOfBullet(diff, bullet_set_count_cap)
          bullet_set_count = diff / 10

          if bullet_set_count_cap < bullet_set_count
            bullet_set_count = bullet_set_count_cap
          end

          if (diff >= 1) && (diff < 30)
            bullet_set_count = 3 # 技能値が29以下での最低値保障処理
          end

          return bullet_set_count
        end

        def getHitBulletCountBase(diff, bullet_set_count)
          hit_bullet_count_base = (bullet_set_count / 2)

          if (diff >= 1) && (diff < 30)
            hit_bullet_count_base = 1 # 技能値29以下での最低値保障
          end

          return hit_bullet_count_base
        end

        def isLastBulletTurn(bullet_count, bullet_set_count)
          ((bullet_count - bullet_set_count) < 0)
        end

        def getLastHitBulletCount(bullet_count)
          # 残弾1での最低値保障処理
          if bullet_count == 1
            return 1
          end

          count = (bullet_count / 2.to_f).floor
          return count
        end

        def getFumbleable(more_difficulty)
          # 成功が49以下の出目のみとなるため、ファンブル値は上昇
          return (more_difficulty >= 1)
        end
      end
    end
  end
end
