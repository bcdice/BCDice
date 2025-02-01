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

        例:AB2>=5        （一般技能を活用して難易度5の技能判定。 クリファンなし。）
        例:ABT3>=15      （専門技能を活用して難易度15の技能判定。クリファンあり。）
        例:AB1+2>=8      （一般技能を活用せず難易度8の技能判定。 ボーナスとして+2点の補正あり。  クリファンなし。）
        例:ABT3-3>=10    （専門技能を活用して難易度10の技能判定。ペナルティとして-3点の補正あり。クリファンあり。）
        例:ABT2>=4/8/12  （一般技能を活用して難易度4/8/12の段階的な技能判定。クリファンあり。）
      INFO_MESSAGE_TEXT

      register_prefix('ABT?\d+([\+\-]\d+)?>=\d+(\/\d+)*')

      def eval_game_system_specific_command(command)
        return roll_skills(command)
      end

      def roll_skills(command)
        m = %r{AB(T?)(\d+)([+-]\d+)?>=((\d+)((/\d+)*))}.match(command)
        return nil unless m

        # 値の取得
        use_cf = m[1] != ''
        times = m[2].to_i
        bonus = m[3].to_i
        targets = m[4].split('/').map(&:to_i)
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
        bonus_text = ''
        bonus_result = ''
        if bonus != 0
          if bonus > 0
            bonus_text = "+"
          end
          bonus_text += bonus.to_s
          bonus_result = "#{total} ＞ "
        end

        # Resultクラスに結果を入れる
        Result.new.tap do |r|
          r.text = "(#{command}) ＞ #{dice_total}[#{dice_list.join(',')}]#{bonus_text} ＞ #{bonus_result}#{result}"
          r.critical = has_critical
          r.fumble = has_fumble
          r.success = is_success
          r.failure = !is_success
        end
      end
    end
  end
end
