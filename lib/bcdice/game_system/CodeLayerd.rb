# frozen_string_literal: true

module BCDice
  module GameSystem
    class CodeLayerd < Base
      # ゲームシステムの識別子
      ID = 'CodeLayerd'

      # ゲームシステム名
      NAME = 'コード：レイヤード'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こおとれいやあと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定（nCL@m[c]+x または nCL+x@m[c]） クリティカル・ファンブル判定あり
          (ダイス数)CL+(修正値)@(判定値)[(クリティカル値)]+(修正値2)

          @m,[c],+xは省略可能。(@6[1]として処理)
          n個のD10でmを判定値、cをクリティカル値とした行為判定を行う。
          nが0以下のときはクリティカルしない1CL判定を行う。(1CL[0]と同一)
          例）
          7CL>=5 ：サイコロ7個で判定値6のロールを行い、目標値5に対して判定
          4CL@7  ：サイコロ4個で判定値7のロールを行い達成値を出す
          4CL+2@7 または 4CL@7+2  ：サイコロ4個で判定値7のロールを行い達成値を出し、修正値2を足す。
          4CL[2] ：サイコロ4個でクリティカル値2のロールを行う。
          0CL : 1CL[0]と同じ判定

          デフォルトダイス：10面
      MESSAGETEXT

      register_prefix('[+-]?\d*CL([+-]\d+)?[@\d]*')

      def initialize(command)
        super(command)

        @sides_implicit_d = 10
      end

      def eval_game_system_specific_command(command)
        debug('eval_game_system_specific_command command', command)

        result = ''

        case command
        when /([+-]?\d+)?CL([+-]\d+)?(@(\d))?(\[(\d+)\])?([+-]\d+)?(>=(\d+))?/i
          m = Regexp.last_match
          base = (m[1] || 1).to_i
          modifier1 = m[2].to_i
          target = (m[4] || 6).to_i
          critical_target = (m[6] || 1).to_i
          modifier2 = m[7].to_i
          diff = m[9].to_i
          result = check_roll(base, target, critical_target, diff, modifier1 + modifier2)
        end

        return nil if result.empty?

        return "#{command} ＞ #{result}"
      end

      def check_roll(base, target, critical_target, diff, modifier)
        if base <= 0 # クリティカルしない1D
          critical_target = 0
          base = 1
        end

        target = 10 if target > 10
        dice_list = @randomizer.roll_barabara(base, 10).sort
        success_count = dice_list.count { |x| x <= target }
        critical_count = dice_list.count { |x| x <= critical_target }
        success_total = success_count + critical_count + modifier

        mod_text = Format.modifier(modifier)

        # (10d10+5)
        result = "(#{base}d10#{mod_text}) ＞ [#{dice_list.join(',')}]#{mod_text} ＞ "
        result += "判定値[#{target}] " unless target == 6
        result += "クリティカル値[#{critical_target}] " unless critical_target == 1
        result += "達成値[#{success_count}]"

        return "#{result} ＞ ファンブル！" if success_count <= 0

        result += "+クリティカル[#{critical_count}]" if critical_count > 0
        result += mod_text
        result += "=[#{success_total}]" if critical_count > 0 || modifier != 0

        success_text =
          if diff == 0
            success_total.to_s
          elsif success_total >= diff
            "成功"
          else
            "失敗"
          end

        return "#{result} ＞ #{success_text}"
      end
    end
  end
end
