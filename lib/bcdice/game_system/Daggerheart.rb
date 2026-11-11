# frozen_string_literal: true

module BCDice
  module GameSystem
    class Daggerheart < Base
      # ゲームシステムの識別子
      ID = 'Daggerheart'

      # ゲームシステム名
      NAME = 'Daggerheart'

      # ゲームシステム名の読みがな
      SORT_KEY = 'たかあはあと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 行動ロール≪Action Roll≫
        AR[(h:f)][Ad][+M][>=t]
          h:f：希望ダイス≪Hope Die≫と恐怖ダイス≪Fear Die≫の大きさ。省略した場合は12/12。
          Ad：有利≪Advantage≫（A）または不利≪Disadvantage≫（D）とダイスの大きさ。省略可。大きさを省略した場合はD6。
          M：修正≪Modifier≫とボーナス≪Bonus≫（ダイス式も可）。省略可。
          t：難易度≪Difficulty≫。>=を含めて省略可。
          成功≪Success≫／失敗≪Failure≫、希望≪Hope≫／恐怖≪Fear≫、クリティカル≪Critical≫を自動判定。
          例）AR AR>=10 AR+5>=18 AR-3>=16
            AR+1d4 AR+1d4>=10 AR+5+1d6 AR-3+1d6>=16
            ARa ARa>=10 ARa+3>=18 ARa8-3+1d4>=16
            ARd ARd>=10 ARd+5>=18 ARd12-5+1d6>=16
            AR(20:12) AR(20:12)+5 AR(20:12)-2>=15 AR(20:12)a8+1d4>=18

        ■ 攻撃ロール≪Attack Roll≫
        AT[(h:f)][Ad][+M][>=t]
          行動ロール（AR）と同じ。

        ■ 反応ロール≪Reaction Roll≫
        RR[(h:f)][Ad][+M][>=t]
          要素については行動ロールを参照。
          成功≪Success≫／失敗≪Failure≫、クリティカル≪Critical≫を自動判定。
          例）RR RR>=10 RR+5>=18 RR-3>=16
            RR+1d4 RR+1d4>=10 RR+5+1d6 RR-3+1d6>=16
            RRa RRa>=10 RRa+3>=18 RRa8-3+1d4>=16
            RRd RRd>=10 RRd+5>=18 RRd12-5+1d6>=16
            RR(20:12) RR(20:12)+5 RR(20:12)-2>=15 RR(20:12)a8+1d4>=18

        ■ 敵キャラクターの行動ロール≪Adversary Action Roll≫
        AAR[A][+M][>=t]
          A：有利≪Advantage≫（A）または不利≪Disadvantage≫（D）。省略可。
          M：修正≪Modifier≫とボーナス≪Bonus≫（ダイス式も可）。省略可。
          t：難易度≪Difficulty≫。>=を含めて省略可。
          成功≪Success≫／失敗≪Failure≫を自動判定。
          例）AAR AAR>=10 AAR+5>=18 AAR-3>=16
            AAR+1d4 AAR+1d4>=10 AAR+5+1d6 AAR-3+1d6>=16
            AARa AARa>=10 AARa+3>=18 AARa8-3+1d4>=16
            AARd AARd>=10 AARd+5>=18 AARd12-5+1d6>=16

        ■ 敵キャラクターの攻撃ロール≪Adversary Attack Roll≫
        AAT[A][+M][>=t]
          要素については敵キャラクターの行動ロールを参照。
          成功≪Success≫／失敗≪Failure≫、クリティカル≪Critical≫を自動判定。
          例）AAT、AAT>=10 AAT+5>=18 AAT-3>=16
            AAT+1d4、AAT+1d4>=10 AAT+5+1d6 AAT-3+1d6>=16
            AATa AATa>=10 AATa+3>=18 AATa8-3+1d4>=16
            AATd AATd>=10 AATd+5>=18 AATd12-5+1d6>=16

        ■ 敵キャラクターの反応ロール≪Adversary Reaction Roll≫
        ARR[A][+M][>=t]
          行動ロール（AAR）と同じ。

      INFO_MESSAGE_TEXT

      register_prefix('AR', 'AT', 'RR', 'AAR', 'AAT', 'ARR')

      def initialize(command)
        super(command)

        @round_type = RoundType::CEIL # 端数は切り上げ
        @sort_barabara_dice = false # Bロールでソートしない
      end

      def eval_game_system_specific_command(command)
        action_roll(command) || reaction_roll(command) || adversary_action_roll(command) || adversary_attack_roll(command)
      end

      def number_with_sign_from_int(number)
        if number == 0
          return ""
        elsif number > 0
          return "+#{number}"
        else
          return number.to_s
        end
      end

      # Duality Dice処理（ARとRRの共通処理）
      def duality_roll(command)
        m = %r{^(AR|AT|RR)(\((\d+):(\d+)\))?(([AD])(\d+)?)?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$}.match(command)
        unless m
          return nil
        end

        type = m[1]
        hope_size = 12
        fear_size = 12
        unless m[2].nil?
          hope_size = m[3].to_i
          fear_size = m[4].to_i
        end
        advantage = m[6].to_s
        advantage_die = 6
        unless m[7].nil?
          advantage_die = m[7].to_i
        end
        bonus = m[8].to_s
        difficulty = m[12].to_i

        unless advantage.empty?
          if advantage == "A"
            bonus += "+1D#{advantage_die}"
          else
            bonus += "-1D#{advantage_die}"
          end
        end

        dice_command = "#{type}(#{hope_size}:#{fear_size})"
        dice_command += bonus
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end

        output = [dice_command]

        hope = @randomizer.roll_once(hope_size)
        fear = @randomizer.roll_once(fear_size)
        duality_sum = hope + fear
        duality_str = "#{duality_sum}[#{hope},#{fear}]"
        duality_result =
          if hope == fear
            "critical"
          elsif hope > fear
            "hope"
          else
            "fear"
          end

        bonus_arr = []
        bonus_sum = 0
        bonus_str = ""
        unless bonus.empty?
          bonus_dice_arr = bonus.gsub(/([+-])/, ",\\1").split(',')
          bonus_dice_arr.shift
          bonus_str_arr = []
          bonus_dice_arr.each do |i|
            if i.include?("D")
              bonus_dice = i.split("D")
              dice_number = bonus_dice[0].to_i
              dice_size = bonus_dice[1].to_i
              rolled = @randomizer.roll_barabara(dice_number.abs, dice_size)
              if dice_number.positive?
                bonus_arr.push(rolled.sum())
                bonus_str_arr.push("#{rolled.sum()}[#{rolled.join(',')}]")
              else
                bonus_arr.push(-rolled.sum())
                bonus_str_arr.push("-#{rolled.sum()}[#{rolled.join(',')}]")
              end
            else
              bonus_arr.push(i.to_i)
              bonus_str_arr.push(i.to_i.to_s)
            end
          end
          bonus_sum = bonus_arr.sum()
          if bonus_str_arr.length == 1
            if bonus_str_arr[0][0] == "-"
              bonus_str = bonus_str_arr[0]
            else
              bonus_str = "+#{bonus_str_arr[0]}"
            end
          else
            bonus_str = "#{number_with_sign_from_int(bonus_sum)}[#{bonus_str_arr.join(',')}]"
          end
        end

        output.push("#{duality_str}#{bonus_str}")
        unless bonus.empty?
          output.push((duality_sum + bonus_sum).to_s)
        end

        return duality_result, (duality_sum + bonus_sum), difficulty, output
      end

      # Action Roll
      def action_roll(command)
        m = %r{^(AR|AT)(\((\d+):(\d+)\))?(([AD])(\d+)?)?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$}.match(command)
        unless m
          return nil
        end

        duality_result, total, difficulty, output = duality_roll(command)

        result = Result.new
        if duality_result == "critical"
          result.critical = true
          result.success = true
          output.push(translate("Daggerheart.critical"))
        elsif difficulty > 0
          if total >= difficulty
            result.success = true
            output.push(translate("Daggerheart.success_#{duality_result}"))
          else
            output.push(translate("Daggerheart.failure_#{duality_result}"))
          end
        else
          output.push(translate("Daggerheart.#{duality_result}"))
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")

          if difficulty > 0 || result.critical?
            r.condition = result.success?
          end
          r.critical = result.critical?
        end
      end

      # Reaction Roll
      def reaction_roll(command)
        m = %r{^(RR)(\((\d+):(\d+)\))?(([AD])(\d+)?)?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$}.match(command)
        unless m
          return nil
        end

        duality_result, total, difficulty, output = duality_roll(command)

        result = Result.new
        if duality_result == "critical"
          result.critical = true
          result.success = true
          output.push(translate("Daggerheart.critical"))
        elsif difficulty > 0
          if total >= difficulty
            result.success = true
            output.push(translate("Daggerheart.success"))
          else
            output.push(translate("Daggerheart.failure"))
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")

          if difficulty > 0 || result.critical?
            r.condition = result.success?
          end
          r.critical = result.critical?
        end
      end

      # Adversary Roll処理（AARとAATの共通処理）
      def gm_dice(command)
        m = /^(AAR|AAT|ARR)([AD])?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$/.match(command)
        unless m
          return nil
        end

        type = m[1]
        advantage = m[2].to_s
        bonus = m[3].to_s
        difficulty = m[7].to_i

        dice_command = "#{type}#{advantage}#{bonus}"
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end

        output = [dice_command]

        d20 = 0
        d20_str = ""
        if advantage.empty?
          d20 = @randomizer.roll_once(20)
          d20_str = "#{d20}[#{d20}]"
        else
          dice = @randomizer.roll_barabara(2, 20)
          if advantage == "A"
            d20 = dice.max
          else
            d20 = dice.min
          end
          d20_str = "#{d20}[#{dice.join(',')}]"
        end

        bonus_arr = []
        bonus_sum = 0
        bonus_str = ""
        unless bonus.empty?
          bonus_dice_arr = bonus.gsub(/([+-])/, ",\\1").split(',')
          bonus_dice_arr.shift
          bonus_str_arr = []
          bonus_dice_arr.each do |i|
            if i.include?("D")
              bonus_dice = i.split("D")
              dice_number = bonus_dice[0].to_i
              dice_size = bonus_dice[1].to_i
              rolled = @randomizer.roll_barabara(dice_number.abs, dice_size)
              if dice_number.positive?
                bonus_arr.push(rolled.sum())
                bonus_str_arr.push("#{rolled.sum()}[#{rolled.join(',')}]")
              else
                bonus_arr.push(-rolled.sum())
                bonus_str_arr.push("-#{rolled.sum()}[#{rolled.join(',')}]")
              end
            else
              bonus_arr.push(i.to_i)
              bonus_str_arr.push(i.to_i.to_s)
            end
          end
          bonus_sum = bonus_arr.sum()
          if bonus_str_arr.length == 1
            if bonus_str_arr[0][0] == "-"
              bonus_str = bonus_str_arr[0]
            else
              bonus_str = "+#{bonus_str_arr[0]}"
            end
          else
            bonus_str = "#{number_with_sign_from_int(bonus_sum)}[#{bonus_str_arr.join(',')}]"
          end
        end

        output.push("#{d20_str}#{bonus_str}")
        unless advantage.empty? && bonus.empty?
          output.push((d20 + bonus_sum).to_s)
        end

        return d20, (d20 + bonus_sum), difficulty, output
      end

      # Adversary Action Roll
      def adversary_action_roll(command)
        m = /^(AAR|ARR)([AD])?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$/.match(command)
        unless m
          return nil
        end

        _, total, difficulty, output = gm_dice(command)

        result = Result.new
        if difficulty > 0
          if total >= difficulty
            result.success = true
            output.push(translate("Daggerheart.success"))
          else
            output.push(translate("Daggerheart.failure"))
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")

          if difficulty > 0
            r.condition = result.success?
          end
        end
      end

      # Adversary Attack Roll
      def adversary_attack_roll(command)
        m = /^(AAT)([AD])?(([-+](\d+|\d+D\d+))*)(>=(\d+))?$/.match(command)
        unless m
          return nil
        end

        d20, total, difficulty, output = gm_dice(command)

        result = Result.new
        if d20 == 20
          result.critical = true
          result.success = true
          output.push(translate("Daggerheart.critical"))
        elsif difficulty > 0
          if total >= difficulty
            result.success = true
            output.push(translate("Daggerheart.success"))
          else
            output.push(translate("Daggerheart.failure"))
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")

          if difficulty > 0 || result.critical?
            r.condition = result.success?
          end
          r.critical = result.critical?
        end
      end
    end
  end
end
