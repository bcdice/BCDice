# frozen_string_literal: true

module BCDice
  module GameSystem
    class WorldOfDarkness < Base
      # ゲームシステムの識別子
      ID = 'WorldOfDarkness'

      # ゲームシステム名
      NAME = 'ワールド・オブ・ダークネス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'わあるとおふたあくねす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定コマンド(xSTn+y or xSTSn+y or xSTAn+y)
        　(ダイス個数)ST(難易度)+(自動成功)
        　(ダイス個数)STS(難易度)+(自動成功) ※出目10で振り足し、振り足し分の1で打ち消されない
        　(ダイス個数)STB(難易度)+(自動成功) ※出目10で振り足し、振り足し分の1で打ち消される
        　(ダイス個数)STA(難易度)+(自動成功) ※出目10は2成功 [20thルール]

        　難易度=省略時6
        　自動成功=省略時0
      INFO_MESSAGE_TEXT

      register_prefix('\d+ST')

      def eval_game_system_specific_command(command)
        difficulty = 6
        auto_success = 0
        enabled_reroll = false
        enabled_reroll_with_botch = false
        enabled_20th = false

        md = command.match(/\A(\d+)(ST[SAB]?)(\d+)?([+-]\d+)?/)

        dice_pool = md[1].to_i
        case md[2]
        when 'STS'
          enabled_reroll = true
        when 'STA'
          enabled_20th = true
        when 'STB'
          enabled_reroll_with_botch = true
        end
        difficulty = md[3].to_i if md[3]
        auto_success = md[4].to_i if md[4]

        difficulty = 6 if difficulty < 2

        sequence = []
        sequence.push "DicePool=#{dice_pool}, Difficulty=#{difficulty}, AutomaticSuccess=#{auto_success}"

        # 出力では Difficulty=11..12 もあり得る
        difficulty = 10 if difficulty > 10

        total_success = 0
        total_botch = 0
        once_success = false

        dice, ten_success, success, botch = roll_wod(dice_pool, difficulty)
        sequence.push dice.join(',')
        total_success += success
        total_botch += botch

        # 成功がひとつでもあったか覚えておく
        once_success = true if success > 0 || ten_success > 0

        if enabled_20th
          # 20周年記念版なら10の目は2成功扱い
          total_success += ten_success * 2
        else
          # Revised Editionでは10は1成功と数える
          total_success += ten_success

          # 振り足し判定ありなら10が出ただけ振り足しを行う
          if enabled_reroll || enabled_reroll_with_botch
            while ten_success > 0
              dice, ten_success, success, botch = roll_wod(ten_success, difficulty)
              sequence.push dice.join(',')
              total_success += (success + ten_success)

              if enabled_reroll_with_botch
                # 振り足しでのボッチありなら出目1をカウントする
                total_botch += botch
              end
            end
          end
        end

        total_success -= [total_success, total_botch].min

        total_success += auto_success # 意志力による自動成功は打ち消されない

        if total_success > 0
          sequence.push "成功数#{total_success}"
        elsif total_botch > 0 && once_success == false
          # ボッチが存在し、かつ成功がひとつもない場合のみ大失敗
          sequence.push "大失敗"
        else
          sequence.push "失敗"
        end

        output = sequence.join(' ＞ ')
        return output
      end

      # 出目10と1、難易度以上が出た成功の目をカウントする。
      # それぞれの解釈はバージョンによって異なるため、呼び出し元で行う。
      def roll_wod(dice_pool, difficulty)
        # FIXME: まとめて振る
        dice = Array.new(dice_pool) do
          dice_now = @randomizer.roll_once(10)
          dice_now
        end

        dice.sort!

        success = 0
        botch = 0
        ten_success = 0

        dice.each do |d|
          case d
          when 10
            ten_success += 1
          when difficulty...10
            success += 1
          when 1
            botch += 1
          end
        end

        return dice, ten_success, success, botch
      end
    end
  end
end
