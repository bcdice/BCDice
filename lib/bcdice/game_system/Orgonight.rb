# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'
require 'bcdice/dice_table/d66_table'

module BCDice
  module GameSystem
    class Orgonight < Base
      # ゲームシステムの識別子
      ID = "Orgonight"

      # ゲームシステム名
      NAME = "オルガナイト"

      # ゲームシステム名の読みがな
      SORT_KEY = "おるかないと"

      HELP_MESSAGE = <<~TEXT
        ・判定コマンド nOR+z@x#y$g%t/w>=m
        　　n=ダイス数（省略不能）　m=修正値（省略時0）　s=スペシャル値（省略時20）　f=ファンブル値（省略時1）　g=GB判定値（省略可、目標値省略時は影響なし）　t=自動判定値（省略可）　w=[判定値÷X]のXの部分、端数切り上げ（省略可）　T=目標値（省略可）
        　　$と%は数値を記入せずに使用可能です。$のみ使用時は判定値と10差でGBが発生し、%のみ使用時は出目8として自動判定が行われます。
        　　@、#はデフォルトに対する加減算でスペシャル値とファンブル値を計算できます。
        　　$を入れた判定で失敗した時も、判定値が目標値よりg以上低ければGBが発生します。

        例：
        1OR　デフォルトのスペシャル値（以降S値）・ファンブル値（以降F値）の判定を行う
        5OR　ダイス数を5個にし、デフォルトのS値・F値の判定を行う
        1OR+5　デフォルトのS値・F値で修正値5の判定を行う
        1OR@17　S値17、デフォルトのF値の判定を行う
        1OR#+5　デフォルトのS値とF値6(1+5)の判定を行う
        1OR>=12　デフォルトのS値・F値で目標値12の判定を行う
        1OR$>=8　デフォルトのS値・F値で目標値8の判定を行う。この際判定値が目標値より10以上大きいか小さい場合、GBを表示する
        1OR%　デフォルトのS値・F値の判定を行う。ただし、出目は8に固定される
        1OR/2　デフォルトのS値・F値の判定を行う。ただし、判定値は1/2（端数切り上げ）される

        (1+1)or+3+4@-3#+(0+2)$>=12+2　ダイス数を2個にし、S値17、F値3で修正値7、目標値14の判定を行う。この際判定値が目標値より10以上大きいか小さい場合、GBを表示する
        2or+10@17#7%　ダイス数を2個にし、S値17、F値7で修正値10の判定を行う。ただし、出目は8に固定される
        2or+10@17#7%9　ダイス数を2個にし、S値17、F値7で修正値10の判定を行う。ただし、出目は9に固定される
        2or+7@17#3$%/3　ダイス数を2個にし、S値17、F値3で修正値7の判定を行う。ただし、出目は8に固定され、判定値は1/3（端数切り上げ）になる

      TEXT

      # 登録するコマンド。今回は「数字+OR」のみに反応するようにします
      register_prefix('\d+OR')

      def eval_game_system_specific_command(command)
        return roll_or(command)
      end

      private

      def eval_math(expr)
        return 0 if expr.nil? || expr.strip.empty?

        ArithmeticEvaluator.eval(expr)
      end

      def roll_or(command)
        m = %r{^([-+*/0-9()]+)OR(.*?)$}i.match(command)
        return nil unless m

        dice_count = eval_math(m[1])
        return nil if dice_count <= 0

        opts = parse_options(m[2])
        dice_list = @randomizer.roll_barabara(dice_count, 20)
        sorted_dice = dice_list.sort
        adopted = opts[:fixed] || sorted_dice.last

        achieve = adopted + opts[:mod]
        achieve = (achieve.to_f / opts[:div]).ceil if opts[:div]

        result_str, has_gb = judge_success(adopted, achieve, opts)
        result_str += "、GB(ギャップボーナス)" if has_gb

        build_output(dice_count, sorted_dice, adopted, achieve, opts, result_str)
      end

      def parse_options(modifiers)
        strict = '([+-]?\d+|[+-]?\([^)]+\))'
        loose = '([-+*\/0-9()]+)'
        opts = {sp: 20, fu: 1, gb: 10, mod: 0, gb_en: false}

        if (m = /(>=|>)#{loose}/.match(modifiers))
          opts[:cmp] = m[1]
          opts[:tgt] = eval_math(m[2])
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = %r{/#{strict}?}.match(modifiers))
          opts[:div_emp] = m[1].nil? || m[1].empty?
          opts[:div] = opts[:div_emp] ? 2 : eval_math(m[1])
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = /\$#{strict}?/.match(modifiers))
          opts[:gb_en] = true
          opts[:gb_emp] = m[1].nil? || m[1].empty?
          opts[:gb] = opts[:gb_emp] ? 10 : eval_math(m[1])
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = /%#{strict}?/.match(modifiers))
          opts[:fix_emp] = m[1].nil? || m[1].empty?
          opts[:fixed] = opts[:fix_emp] ? 8 : eval_math(m[1])
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = /@#{strict}/.match(modifiers))
          val = eval_math(m[1])
          opts[:sp] = m[1].start_with?('+', '-') ? 20 + val : val
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = /##{strict}/.match(modifiers))
          val = eval_math(m[1])
          opts[:fu] = m[1].start_with?('+', '-') ? 1 + val : val
          modifiers = modifiers.sub(m[0], '')
        end
        if (m = /#{loose}/.match(modifiers)) && m[1].match?(/\d/)
          opts[:mod] = eval_math(m[1])
        end
        opts
      end

      def judge_success(adopted, achieve, opts)
        is_fu = (adopted <= opts[:fu])
        is_sp = !is_fu && (adopted >= opts[:sp])
        is_suc = opts[:tgt] && (opts[:cmp] == ">=" ? (achieve >= opts[:tgt]) : (achieve > opts[:tgt]))

        res = ""
        has_gb = false

        if is_fu
          res = "ファンブル"
          has_gb = opts[:gb_en] && opts[:tgt] && ((opts[:tgt] - achieve) >= opts[:gb])
        elsif is_sp
          res = "スペシャル"
          has_gb = opts[:gb_en] && opts[:tgt] && ((achieve - opts[:tgt]) >= opts[:gb])
        elsif opts[:tgt]
          res = is_suc ? "成功" : "失敗"
          has_gb = opts[:gb_en] && (is_suc ? ((achieve - opts[:tgt]) >= opts[:gb]) : ((opts[:tgt] - achieve) >= opts[:gb]))
        end

        return res, has_gb
      end

      def build_output(count, dice, adopted, achieve, opts, result_str)
        c_text = "#{count}OR"
        c_text += (opts[:mod] > 0 ? "+#{opts[:mod]}" : opts[:mod].to_s) if opts[:mod] != 0
        c_text += "@#{opts[:sp]}" if opts[:sp] != 20
        c_text += "##{opts[:fu]}" if opts[:fu] != 1
        c_text += (opts[:gb_emp] ? "$" : "$#{opts[:gb]}") if opts[:gb_en]
        c_text += (opts[:fix_emp] ? "%" : "%#{opts[:fixed]}") if opts[:fixed]
        c_text += (opts[:div_emp] ? "/" : "/#{opts[:div]}") if opts[:div]
        c_text += "#{opts[:cmp]}#{opts[:tgt]}" if opts[:tgt]

        secs = [c_text]
        secs << "[#{dice.join(',')}]" if count > 1
        secs << "[#{opts[:fixed]}]" if opts[:fixed]

        if opts[:mod] != 0 || opts[:div]
          if opts[:mod] != 0
            secs << "#{adopted}#{opts[:mod] > 0 ? "+#{opts[:mod]}" : opts[:mod]}"
          end
          secs << "#{adopted + opts[:mod]}/#{opts[:div]}" if opts[:div]
        end
        secs << achieve.to_s
        secs << result_str unless result_str.empty?

        secs.join(" ＞ ")
      end
    end
  end
end
