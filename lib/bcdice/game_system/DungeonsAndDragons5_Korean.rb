# frozen_string_literal: true

module BCDice
  module GameSystem
    class DungeonsAndDragons5_Korean < DungeonsAndDragons5
      # ゲームシステムの識別子
      ID = 'DungeonsAndDragons5:Korean'

      # ゲームシステム名
      NAME = '던전 앤 드래곤 5판'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:던전 앤 드래곤 5판'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・명중 굴림　AT[x][@c][>=t][y]
        　x: +- 수정치 (생략 가능)
        　c: 크리티컬 수치 (생략 가능)
        　t: 목표 AC (>= 포함, 생략 가능)
        　y: 유리(A), 불리(D) (생략 가능)
        　펌블／실패／성공／크리티컬을 자동으로 판정합니다.
        　예시）AT AT>=10 AT+5>=18 AT-3>=16 ATA AT>=10A AT+3>=18A AT-3>=16 ATD AT>=10D AT+5>=18D AT-5>=16D
        　    AT@19 AT+5@18 AT-2@19>=15
        ・능력 판정　AR[x][>=t][y]
        　명중 굴림과 동일. 실패／성공을 자동 판정합니다.
        　예시）AR AR>=10 AR+5>=18 AR-3>=16 ARA AR>=10A AR+3>=18A AR-3>=16 ARD AR>=10D AR+5>=18D AR-5>=16D
        ・대형 무기 전투술 대미지 계산(베이직 룰북 32p)　2HnDx[m]
        　n: 주사위 개수
        　x: 주사위 면수(1d6의 6, 1d8의 8 등)
        　m: +- 수정치 (생략 가능)
        　팔라딘과 파이터의 무기를 양손으로 사용할 경우, 대미지 주사위에서 1 또는 2가 나오면 다시 굴립니다.
        　예시)2H3D6 2H1D10+3 2H2D8-1
      INFO_MESSAGE_TEXT

      register_prefix('AT([+-]\d+)?(@\d+)?(>=\d+)?[AD]?', 'AR([+-]\d+)?(>=\d+)?[AD]?', '2H(\d+)D(\d+)([+-]\d+)?')

      def initialize(command)
        super(command)

        @locale = :ko_kr # i18n ko_kr 참조
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

      # 攻撃ロール 명중 굴림
      def attack_roll(command)
        m = /^AT([-+]\d+)?(@(\d+))?(>=(\d+))?([AD]?)/.match(command)
        unless m
          return nil
        end

        modify = m[1].to_i
        critical_no = m[3].to_i
        difficulty = m[5].to_i
        advantage = m[6]

        usedie = 0
        roll_die = ""

        dice_command = "AT#{number_with_sign_from_int(modify)}"
        if critical_no > 0
          dice_command += "@#{critical_no}"
        else
          critical_no = 20
        end
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end
        unless advantage.empty?
          dice_command += advantage.to_s
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
        end

        if modify != 0
          output.push("#{roll_die}#{number_with_sign_from_int(modify)}")
          output.push((usedie + modify).to_s)
        else
          unless advantage.empty?
            output.push(roll_die)
          end
          output.push(usedie.to_s)
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
          if usedie + modify >= difficulty
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

      # 能力値ロール 능력 판정
      def ability_roll(command)
        m = /^AR([-+]\d+)?(>=(\d+))?([AD]?)/.match(command)
        unless m
          return nil
        end

        modify = m[1].to_i
        difficulty = m[3].to_i
        advantage = m[4]

        usedie = 0
        roll_die = ""

        dice_command = "AR#{number_with_sign_from_int(modify)}"
        if difficulty > 0
          dice_command += ">=#{difficulty}"
        end
        unless advantage.empty?
          dice_command += advantage.to_s
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
        end

        if modify != 0
          output.push("#{roll_die}#{number_with_sign_from_int(modify)}")
          output.push((usedie + modify).to_s)
        else
          unless advantage.empty?
            output.push(roll_die)
          end
          output.push(usedie.to_s)
        end

        result = Result.new
        if difficulty > 0
          if usedie + modify >= difficulty
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

      # 武器の両手持ちダメージ 대형 무기 전투술 대미지 계산
      def twohands_damage_roll(command)
        m = /^2H(\d+)D(\d+)([+-]\d+)?/.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        dice_number = m[2].to_i
        modify = m[3].to_i
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
