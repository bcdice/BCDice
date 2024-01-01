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
      
      register_prefix('1D100<=\d+', '\d+D\d+<=\d+', '\d+B\d+<=\d+--[^\d\s]+', '\d+B\d+<=\d+')

      def eval_game_system_specific_command(command)
        return roll_1d100(command) || roll_d(command) || roll_b_type(command) || roll_b(command)
      end

      private

      def roll_1d100(command)
        m = /^1D100<=(\d+)$/.match(command)
        return nil unless m
        
        times = 1
        sides = 100
        target = m[1].to_i

        dice_list = @randomizer.roll_barabara(times, sides)
        total = dice_list[0]

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

        return "(#{command}) ＞ #{dice_list.join(',')} ＞ #{result}"
      end

      def roll_d(command)
        m = /^(\d+)D(\d+)<=(\d+)$/.match(command)
        return nil unless m

        times = m[1].to_i
        sides = m[2].to_i
        target = m[3].to_i

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

        return "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{result}"
      end

      def roll_b_type(command)
        m = /^(\d+)B(\d+)<=(\d+)--([^\d\s]+)$/.match(command)
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

      def roll_b(command)
        m = /^(\d+)B(\d+)<=(\d+)$/.match(command)
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