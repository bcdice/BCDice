# frozen_string_literal: true

module BCDice
  module GameSystem
    class DungeonsAndDragons5 < Base
      # ゲームシステムの識別子
      ID = 'DungeonsAndDragons5'

      # ゲームシステム名
      NAME = 'ダンジョンズ＆ドラゴンズ第5版'

      # ゲームシステム名の読みがな
      SORT_KEY = 'たんしよんすあんととらこんす5'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・攻撃ロール　AT[x][@c][>=t][y][B]
        　x：+-修正。省略可。
        　c:クリティカル値。省略可。
        　t:敵のアーマークラス。>=を含めて省略可。
        　y:有利(A), 不利(D)。省略可。
        　B:ブレスやガイダンス等によるボーナス。省略可。
        　　Bだけを書くと+1d4、B[1D4+1D8]などと書くと[]内のロールをボーナスとしてロールします。
        　ファンブル／失敗／成功／クリティカル を自動判定。
        　例）AT AT>=10 AT+5>=18 AT-3>=16 ATA AT>=10A AT+3>=18A AT-3>=16 ATD AT>=10D AT+5>=18D AT-5>=16D
        　    AT@19 AT+5@18 AT-2@19>=15 AT+3>=18AB AT+3>=18DB[1D6]
        ・能力値判定　AR[x][>=t][y][b]
        　攻撃ロールと同様。失敗／成功を自動判定。
        　例）AR AR>=10 AR+5>=18 AR-3>=16 ARA AR>=10A AR+3>=18A AR-3>=16 ARD AR>=10D AR+5>=18D AR-5>=16D
        　     AR+3>=18AB AR+3>=18DB[1D6]
        ・両手持ちのダメージ　2HnDx[m]
        　n:ダイスの個数
        　x:ダイスの面数
        　m:+-修正。省略可。
        　パラディンとファイターの武器の両手持ちによるダメージダイスの1,2の出目の振り直しを行います。
        　例)2H3D6 2H1D10+3 2H2D8-1
      INFO_MESSAGE_TEXT

      register_prefix('AT', 'AR', '2H')

      def initialize(command)
        super(command)

        @sort_barabara_dice = false # バラバラロール（Bコマンド）でソート無
      end

      def eval_game_system_specific_command(command)
        attack_roll(command) || ability_roll(command) || twohands_damage_roll(command)
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

      # ロール処理
      def exec_roll(command)
        m = /^(AT|AR)([-+\d]+)?(@(\d+))?(>=(\d+))?([AD]?)6?(B(\[(\d+D\d+([-+]\d+D\d+)*)\])?)?/.match(command)
        unless m
          return nil
        end

        modify = 0
        mod_str = ""
        unless m[2].nil?
          if Arithmetic.eval(m[2], @round_type).nil?
            return nil
          else
            modify = Arithmetic.eval(m[2], @round_type)
            mod_str = number_with_sign_from_int(modify).to_s
          end
        end
        critical_no = m[4].to_i
        difficulty = m[6].to_i
        advantage = m[7].to_s
        bonus = m[8].to_s
        bonus_dice = m[10].to_s

        usedie = 0
        bonus_mod = 0
        bonus_str = ""
        bonus_mod_arr = []
        roll_die = ""

        dice_command = "#{m[1]}#{number_with_sign_from_int(modify)}"
        unless critical_no < 1
          dice_command += "@#{critical_no}"
        end
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end
        unless advantage.empty?
          dice_command += advantage
        end
        unless bonus.empty?
          dice_command += bonus
        end

        output = ["(#{dice_command})"]

        if advantage.empty?
          usedie = @randomizer.roll_once(20)
          roll_die = usedie
        else
          dice = @randomizer.roll_barabara(2, 20)
          roll_die = "[" + dice.join(",") + "]"
          if advantage == "A"
            usedie = dice.max
          else
            usedie = dice.min
          end
          roll_die = "#{usedie}#{roll_die}"
        end

        unless bonus.empty?
          if bonus == "B"
            bonus_mod = @randomizer.roll_once(4).to_i
            bonus_str = number_with_sign_from_int(bonus_mod).to_s
          else
            unless bonus_dice.empty?
              bonus_dice_arr = bonus_dice.gsub(/([+-])/, ",\\1").split(',')
              bonus_dice_arr.each do |i|
                now_bonus_dice = i.split("D")
                now_dice_count = now_bonus_dice[0].to_i
                now_dice_number = now_bonus_dice[1].to_i
                dice = @randomizer.roll_barabara(now_dice_count.abs, now_dice_number)
                if now_dice_count.positive?
                  bonus_mod_arr.push(dice.sum())
                else
                  bonus_mod_arr.push(-dice.sum())
                end
              end
              bonus_mod = bonus_mod_arr.sum()
              bonus_str = "#{number_with_sign_from_int(bonus_mod)}[#{bonus_mod_arr.join(',')}]"
            end
          end
        end

        output.push("#{roll_die}#{mod_str}#{bonus_str}")
        unless mod_str.empty? && advantage.empty? && bonus.empty?
          output.push((usedie + modify + bonus_mod).to_s)
        end

        return usedie, (usedie + modify + bonus_mod), difficulty, output
      end

      # 攻撃ロール
      def attack_roll(command)
        m = /^AT([-+\d]+)?(@(\d+))?(>=(\d+))?([AD]?)6?(B(\[(\d+D\d+([-+]\d+D\d+)*)\])?)?/.match(command)
        unless m
          return nil
        end

        critical_no = 20
        unless m[3].nil?
          critical_no = m[3].to_i
        end

        usedie, dice_result, difficulty, output = exec_roll(command)
        if usedie.nil?
          return nil
        end

        result = Result.new
        if usedie >= critical_no
          result.critical = true
          result.success = true
          output.push(translate('critical'))
        elsif usedie == 1
          result.fumble = true
          output.push(translate('fumble'))
        elsif difficulty > 0
          if dice_result >= difficulty
            result.success = true
            output.push(translate('success'))
          else
            output.push(translate('failure'))
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
          if result
            if difficulty > 0 || result.critical? || result.fumble?
              r.condition = result.success?
            end
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end

      # 能力値ロール
      def ability_roll(command)
        m = /^AR([-+\d]+)?(>=(\d+))?([AD]?)6?(B(\[(\d+D\d+([-+]\d+D\d+)*)\])?)?/.match(command)
        unless m
          return nil
        end

        usedie, dice_result, difficulty, output = exec_roll(command)
        if usedie.nil?
          return nil
        end

        result = Result.new
        if difficulty > 0
          if dice_result >= difficulty
            result.success = true
            output.push(translate('success'))
          else
            output.push(translate('failure'))
          end
        end

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
          if result
            if difficulty > 0
              r.condition = result.success?
            end
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end

      # 武器の両手持ちダメージ
      def twohands_damage_roll(command)
        m = /^2H(\d+)D(\d+)([-+\d]+)?/.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        dice_number = m[2].to_i
        modify = m[3] ? Arithmetic.eval(m[3], @round_type) : 0
        mod_str = number_with_sign_from_int(modify)
        output = ["(2H#{dice_count}D#{dice_number}#{mod_str})"]

        dice = @randomizer.roll_barabara(dice_count, dice_number)
        roll_dice = "[" + dice.join(",") + "]"
        output.push("#{roll_dice}#{mod_str}")

        ex_dice = []
        new_dice = []
        sum_dice = 0
        dice.each do |num|
          if num.to_i > 2
            sum_dice += num.to_i
            ex_dice.push(num)
          else
            one_die = @randomizer.roll_once(dice_number)
            sum_dice += one_die.to_i
            new_dice.push(one_die)
          end
        end
        unless new_dice.empty?
          output.push("[" + ex_dice.join(",") + "][" + new_dice.join(",") + "]#{mod_str}")
        end
        output.push((sum_dice + modify).to_s)

        Result.new.tap do |r|
          r.text = output.join(" ＞ ")
        end
      end
    end
  end
end
