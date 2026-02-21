# frozen_string_literal: true

module BCDice
  module GameSystem
    class Aionia < Base
      # ゲームシステムの識別子
      ID = "Aionia"

      # ゲームシステム名
      NAME = "慈悲なきアイオニア"

      # ゲームシステム名の読みがな
      SORT_KEY = "しひなきあいおにあ"

      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        - 技能判定（クリティカル・ファンブルなし）
        AB{n}>={dif} n=10面ダイスの数、dif=難易度
        - 技能判定（クリティカル・ファンブルあり）
        ABT{n}>={dif} n=10面ダイスの数、dif=難易度
        - ダメージチェック
        DMG>={dif} dif=ダメージ難易度

        ※ 技能判定、ダメージチェックともにダイス結果、難易度に対して四則演算（+ - * /）を用いた複数ボーナスを含めることが可能です。計算結果の小数は切り捨てられます。

        例:AB2>=5          （一般技能を活用して難易度5の技能判定。 クリファンなし。）
        例:ABT3>=15        （専門技能を活用して難易度15の技能判定。クリファンあり。）
        例:AB1+1+2>=8      （一般技能を活用せず難易度8の技能判定。 ボーナスとして+1と+2点の補正あり。  クリファンなし。）
        例:ABT3-3>=10+2    （専門技能を活用して難易度10+2の技能判定。ペナルティとして-3点の補正あり。クリファンあり。）
        例:ABT2>=4/8/12    （一般技能を活用して難易度4/8/12の段階的な技能判定。クリファンあり。）
        例:DMG>=50         （難易度50の判定。）
        例:DMG>=20+50      （難易度20+50の判定。）
      INFO_MESSAGE_TEXT

      register_prefix('ABT?', 'DMG')

      def eval_game_system_specific_command(command)
        return roll_skills(command) || roll_damage_check(command)
      end

      def roll_skills(command)
        m = %r{^AB(T?)(\d+)((?:[-+]\d+)*)>=(\d+(?:/\d+)*)((?:[-+]\d+)*)$}.match(command)
        return nil unless m

        # 値の取得
        use_cf = m[1] != ''
        times = m[2].to_i

        # 値の計算
        bonus = m[3] != '' ? Arithmetic.eval(m[3], RoundType::FLOOR) : 0
        return nil unless bonus

        base_targets = m[4].split('/').map(&:to_i)
        target_bonus = m[5] != '' ? Arithmetic.eval(m[5], RoundType::FLOOR) : 0
        return nil unless target_bonus

        targets = base_targets.map { |t| t + target_bonus }
        target = targets[0]
        min_target = targets.min
        max_target = targets.max

        # ダイスロール
        dice_list = @randomizer.roll_barabara(times, 10)
        dice_total = dice_list.sum
        total = dice_total + bonus

        # Result用変数宣言
        is_success = false
        has_critical = false
        has_fumble = false

        # 結果判定
        # 難易度が一つの場合
        if targets.count == 1
          if total >= target
            is_success = true
            if total >= target + 20 && use_cf
              result = 'クリティカル'
              has_critical = true
            elsif target <= times
              result = '自動成功'
            else
              result = '成功'
            end
          else
            is_success = false
            if dice_list.count(1) == times && use_cf
              result = 'ファンブル'
              has_fumble = true
            elsif target > 10 * times
              result = '自動失敗'
            else
              result = '失敗'
            end
          end
        # 段階的な難易度判定の場合
        else
          if total >= min_target
            is_success = true
            if total >= max_target + 20 && use_cf
              result = 'クリティカル'
              has_critical = true
            elsif max_target <= times
              result = '自動成功'
            elsif total >= max_target
              result = '全成功'
            else
              times_suc = targets.count { |x| x <= total }
              result = "#{times_suc}段階成功"
            end
          else
            is_success = false
            if dice_list.count(1) == times && use_cf
              result = 'ファンブル'
              has_fumble = true
            elsif min_target > 10 * times
              result = '自動失敗'
            else
              result = '失敗'
            end
          end
        end

        # ボーナスがある場合の処理
        bonus_text = m[3]
        bonus_result = m[3] == '' ? '' : "#{total} ＞ "

        # Resultクラスに結果を入れる
        Result.new.tap do |r|
          r.text = "(#{command}) ＞ #{dice_total}[#{dice_list.join(',')}]#{bonus_text} ＞ #{bonus_result}#{result}"
          r.critical = has_critical
          r.fumble = has_fumble
          r.success = is_success
          r.failure = !is_success
        end
      end

      def roll_damage_check(command)
        parser = Command::Parser.new("DMG", round_type: BCDice::RoundType::FLOOR)
        parsed = parser.parse(command)
        return nil unless parsed

        # 値の計算
        dif = parsed.target_number
        return nil unless dif

        # ダイスロール
        dice_result = @randomizer.roll_once(100)

        # Result用変数宣言
        is_success = false

        # 結果判定
        if dice_result < (dif / 5)
          is_success = false
          second_result = @randomizer.roll_once(100)
          if second_result >= dif
            result_str = "失敗 > 弱点追加 ＞ #{second_result} ＞ 戦闘不能状態"
          else
            result_str = "失敗 > 弱点追加 ＞ #{second_result} ＞ 死亡状態"
          end
        elsif dice_result < (dif / 2)
          result_str = "失敗 > 弱点追加 > 戦闘不能状態"
          is_success = false
        elsif dice_result < dif
          result_str = "失敗 > 戦闘不能状態"
          is_success = false
        else
          result_str = "成功"
          is_success = true
        end

        Result.new.tap do |r|
          r.text = "(#{command}) ＞ #{dice_result} ＞ #{result_str}"
          r.success = is_success
          r.failure = !is_success
        end
      end
    end
  end
end
