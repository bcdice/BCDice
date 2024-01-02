module BCDice
  module GameSystem
    class ArknightsFan < Base
      # ゲームシステムの識別子
      ID = "ArknightsFan"

      # ゲームシステム名
      NAME = "アークナイツTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "あーくないつTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nD100>=x)
          nD100のダイスロールをして、x 以下であれば成功。
          x が91以上でエラー。
          x が10以下でクリティカル。

        ■ 判定 (nB100>=x)
          nB100のダイスロールをして、
            x 以下であれば成功数+1。
            x が91以上でエラー。成功数+1。
            x が10以下でクリティカル。成功数-1。
          上記による成功数をカウント。

        ■ 判定 (nB100>=x--役職)
          nB100のダイスロールをして、
            x 以下であれば成功数+1。
            x が91以上でエラー。成功数+1。
            x が10以下でクリティカル。成功数-1。
          上記による成功数をカウントした上で、以下の役職による成功数増加効果を適応。
            狙撃 成功数1以上のとき、成功数+1。
          
      TEXT
      
      register_prefix('AD<=\d+', '\d+AD\d+<=\d+', 
                      '\d+AB+<=\d+', '\d+AB\d+<=\d+',
                      '\d+AB+<=\d+--[^\d\s]+', '\d+AB\d+<=\d+--[^\d\s]+'
                      )

      def eval_game_system_specific_command_old(command)
        return roll_b_old(command)
      end

      def eval_game_system_specific_command(command)
        case command
        when /^AD<=(\d+)$/
          return roll_D(command, 1, 100, $1.to_i)
        when /^(\d+)AD(\d+)<=(\d+)$/
          return roll_D(command, $1.to_i, $2.to_i, $3.to_i)
        when /^(\d+)AB<=(\d+)$/
          return roll_B(command, $1.to_i, 100, $2.to_i)
        when /^(\d+)AB(\d+)<=(\d+)$/
          return roll_B(command, $1.to_i, $2.to_i, $3.to_i)
        when /^(\d+)AB<=(\d+)--([^\d\s]+)$/
          return roll_B_withtype(command, $1.to_i, 100, $2.to_i, $3)
        when /^(\d+)AB(\d+)<=(\d+)--([^\d\s]+)$/
          return roll_B_withtype(command, $1.to_i, $2.to_i, $3.to_i, $4)
        end
        
        return "command"
      end

      private

      def roll_D(command, times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides)
        total = dice_list.sum

        success = total <= target

        crierror = 
          if total <= 10
            "Critical"
          elsif total >= 91
            "Error"
          else
            "Neutral"
          end

        result = 
          if success && (crierror == "Critical")
            "クリティカル！"
          elsif success && (crierror == "Neutral")
            "成功"
          elsif success && (crierror == "Error")
            "成功"
          elsif !success && (crierror == "Critical")
            "失敗"
          elsif !success && (crierror == "Neutral")
            "失敗"
          elsif !success && (crierror == "Error")
            "エラー"
          end

        if times == 1
          return "(#{command}) ＞ #{dice_list.join(',')} ＞ #{result}"
        else
          return "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{result}"
        end
      end

      def roll_B(command, times, sides, target)
        result = process_B(times, sides, target)
        dice_list = result[0]
        success_count = result[1]

        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ 成功数#{success_count}"
      end

      def roll_B_withtype(command, times, sides, target, type)
        result = process_B(times, sides, target)
        dice_list = result[0]
        success_count = result[1]

        type_effect = 
          if (type == "SNIPER") && (success_count > 0)
            1
          else
            0
          end
        success_count += type_effect

        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ 役職効果(#{type})+#{type_effect} ＞ 成功数#{success_count}"
      end

      def process_B(times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides)

        success_count = 0
        for num in 1..target do
          success_count += dice_list.count(num)
        end
        
        critical_count = 0
        for num in 1..10 do
          critical_count += dice_list.count(num)
        end

        error_count = 0
        for num in 91..100 do
          error_count += dice_list.count(num)
        end

        success_count += critical_count
        success_count -= error_count

        return [dice_list, success_count, critical_count, error_count]

      end

      def roll_b_type_old(command)
        m = /^(\d+)AN(\d+)<=(\d+)--([^\d\s]+)$/.match(command)
        return nil unless m

        times = m[1].to_i
        sides = m[2].to_i
        target = m[3].to_i
        type = m[4]

        dice_list = @randomizer.roll_barabara(times, sides)

        success_count = 0
        for num in 1..target do
          success_count += dice_list.count(num)
        end
        
        critical_count = 0
        for num in 1..10 do
          critical_count += dice_list.count(num)
        end

        error_count = 0
        for num in 91..100 do
          error_count += dice_list.count(num)
        end

        success_count += critical_count
        success_count -= error_count

        type_effect = 
          if (type == "狙撃") && (success_count > 0)
            1
          else
            0
          end

        success_count += type_effect
        
        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ 役職効果(#{type})+#{type_effect} ＞ 成功数#{success_count}"
      end

      def roll_b_old(command)
        m = /^(\d+)AN(\d+)<=(\d+)$/.match(command)
        return nil unless m

        times = m[1].to_i
        sides = m[2].to_i
        target = m[3].to_i

        dice_list = @randomizer.roll_barabara(times, sides)

        success_count = 0
        for num in 1..target do
          success_count += dice_list.count(num)
        end
        
        critical_count = 0
        for num in 1..10 do
          critical_count += dice_list.count(num)
        end

        error_count = 0
        for num in 91..100 do
          error_count += dice_list.count(num)
        end

        success_count += critical_count
        success_count -= error_count

        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ 成功数#{success_count}"
      end

    end
  end
end