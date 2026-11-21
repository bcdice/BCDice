# frozen_string_literal: true

require 'bcdice/game_system/NinjaSlayer2'

module BCDice
  module GameSystem
    class TacticalExorcist < NinjaSlayer2
      # ゲームシステムの識別子
      ID = "TacticalExorcist"

      # ゲームシステム名
      NAME = "タクティカル祓魔師TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "たくていかるふつましTRPG"

      HELP_MESSAGE = <<~TEXT
        --- 成功判定コマンド ---
        通常のダイスの「{ダイス個数}B6>={難易度ごとの目標出目}」を実行するための簡易入力コマンドです。

        - K{x}
        難易度K([K]ids/目標値=2)の成功判定をダイス{x}個で実行します。
        先頭の文字を変えることで、難易度E([E]asy/目標値=3),N([N]ormal/目標値=4),H([H]ard/目標値=5),U([U]ltra-hard/目標値=6)もしくはUH([U]ltra-[H]ard/目標値=6)でも実行可能です。

        - K{x1},N{x2},...,U{xn}
        K{x}の複数ロール版。
        カンマ(,)で区切って複数回入力すると、区切られたセットごとに成功判定を行います。
        2回目以降は難易度指定を省略可能で、省略した場合はひとつ前の難易度を引き継いで判定を行います。
        以下のコマンドについても同様の書式で複数ロールしての同時判定が可能です。

        - K{x1},{x2},...,{xn}@{y1},{y2},...,{yn}
        K{x1},{x2},...,{xn}の判定を行い、出目の中で{y1}から{yn}のいずれかの値と一致した出目を列挙して追加で出力します。(追加判定コマンドの簡易入力版です)

        --- 追加判定コマンド ---
        以下のコマンド群は、成功判定コマンドの後ろに付けて実行してください。

        - [>={y}]
        - [>{y}]
        - [<={y}]
        - [<{y}]
        - [={y}]
        - [!={y}]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[]内で指定された条件で追加判定を行います。
        それぞれ、{y}以上(>=)、{y}より大きい(>)、{y}以下(<=)、{y}未満(<)、{y}のみ(=)、{y}以外(!=)を判定し、
        ロール結果の中で条件を満たしたダイスの個数を「追加判定」というテキストと共に出力します。
        [=5][=6]のように複数記述することで、ひとつのロールに対して複数パターンでの追加判定が可能です。
        ※ 条件は一括でしか指定できないため、ロールごとに異なる条件を指定したい場合はコマンドを分けてください。以下も同様です。。

        - [>={y1}{y2}...{yn}+]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[>={y1}]～[>={yn}]の各条件で追加判定を行います。
        出目の中に条件を満たしたダイスが**全て**含まれていた場合、「追加判定成功！」というテキストを出力します。
        例えば[>=665+]とした場合、出目の中に6以上のダイスが2つと5以上のダイスが1つ含まれていれば成功扱いになります。
      TEXT

      # Base::eval_game_system_specific_commandの実装
      # @param command [String]
      # @return [String, nil]
      def eval_game_system_specific_command(command)
        # @debug = true
        debug("input: #{command}")

        begin
          case command
          when RE_JUDGE_DICEROLL_TE
            # タクティカル祓魔師TRPGで追加されたコマンド
            proc_result = proc_dice_command_with_at(command)

            # 結果は文字列と達成値という形で受け取る
            if proc_result[1] > 0
              return Result.success(proc_result[0])
            else
              return Result.failure(proc_result[0])
            end
          when RE_JUDGE_DICEROLL
            # ソウルワイヤードTRPGフレームワーク2版(ニンジャスレイヤーTRPG第2版)用のダイス判定
            proc_result = proc_dice_2nd(Regexp.last_match)

            # 結果は文字列と達成値という形で受け取る
            if proc_result[1] > 0
              return Result.success(proc_result[0])
            else
              return Result.failure(proc_result[0])
            end
          else
            # ダイスでなければ定型文処理
            return proc_text(command)
          end
        rescue StandardError => e
          # 解析できずにエラーが出たら構文ミスと皆してnilを返す
          debug("#{e.message} \n#{e.backtrace}")
          return nil
        end
      end

      private

      # 難易度判定の成功数を返す。
      # @param dice_array [Array<Integer>]
      # @param difficultys [String]
      # @param cmp_op [String]
      # @return Integer
      def check_difficulty_te(dice_array, difficultys, cmp_op)
        success_dice = []
        diff_array = difficultys.split(",")
        dice_array.each do |dice_value|
          diff_array.each do |diff_value|
            if dice_value.send(Normalize.comparison_operator(cmp_op), diff_value.to_i)
              success_dice.push(dice_value)
            end
          end
        end

        return success_dice
      end

      # 追加判定の処理
      # @param roll_result 判定対象とするロール結果の配列
      # @param ap_commanc 追加判定のコマンド
      # @return String
      def proc_appendix(roll_result, ap_command)
        debug("----- ap_command: #{ap_command}")
        output_text = ''
        case ap_command
        when RE_COUNT_SATZ_BATZ
          diff_condition = Regexp.last_match[1]
          if ap_command.end_with?("+")
            # サツバツ発生チェック
            sb_condition = diff_condition.sub("\+", "").split("/")[0]
            nm_condition = diff_condition.sub("\+", "").split("/")[1]
            debug("sb_condition: #{sb_condition}")
            debug("nm_condition: #{nm_condition}")

            if check_difficulty_new(roll_result.last_dice_list, nm_condition, ">=")
              output_text += ", ナムアミダブツ！[#{ap_command}]"
            elsif check_difficulty_new(roll_result.last_dice_list, sb_condition, ">=")
              output_text += ", サツバツ！[#{ap_command}]"
            end

          else
            # サツバツ数カウント
            diff_result_array = check_difficulty(roll_result.last_dice_list, s_to_i(diff_condition, 6), ">=")
            output_text += ", サツバツ判定[#{ap_command}]:#{diff_result_array.size}"
            unless diff_result_array.empty?
              output_text += "[#{diff_result_array.sort.reverse.join(',')}]"
            end
          end
        when RE_COUNT_CRITICAL
          diff_condition = Regexp.last_match[1]
          if ap_command.end_with?("+")
            # クリティカル発生チェック
            if check_difficulty_new(roll_result.last_dice_list, diff_condition.sub("\+", ""), ">=")
              output_text += ", クリティカル！[#{ap_command}]"
            end
          else
            # クリティカル数カウント
            diff_result_array = check_difficulty(roll_result.last_dice_list, s_to_i(diff_condition, 6), ">=")
            output_text += ", クリティカル判定[#{ap_command}]:#{diff_result_array.size}"
            unless diff_result_array.empty?
              output_text += "[#{diff_result_array.sort.reverse.join(',')}]"
            end
          end
        when RE_COUNT_JUDGE_TE
          diff_type = Regexp.last_match[1]
          diff_condition = Regexp.last_match[2]
          # 追加判定カウント
          diff_result_array = check_difficulty_te(roll_result.last_dice_list, diff_condition, diff_type)
          output_text += ", 追加判定[#{ap_command}]:#{diff_result_array.size}"
          unless diff_result_array.empty?
            output_text += "[#{diff_result_array.sort.reverse.join(',')}]"
          end
        when RE_COUNT_JUDGE
          diff_type = Regexp.last_match[1]
          diff_condition = Regexp.last_match[2]
          debug("#{diff_type} / #{diff_condition}")
          if ap_command.end_with?("+")
            # 追加判定チェック
            if check_difficulty_new(roll_result.last_dice_list, diff_condition.sub("\+", ""), diff_type)
              output_text += ", 追加判定成功！[#{ap_command}]"
            end
          else
            # 追加判定カウント
            diff_result_array = check_difficulty(roll_result.last_dice_list, s_to_i(diff_condition, 6), diff_type)
            output_text += ", 追加判定[#{ap_command}]:#{diff_result_array.size}"
            unless diff_result_array.empty?
              output_text += "[#{diff_result_array.sort.reverse.join(',')}]"
            end
          end
        end
        return output_text
      end

      # @付き追加判定の処理
      # @param at_command String 追加判定のコマンド
      # @return [String, Integer]
      def proc_dice_command_with_at(at_command)
        # コマンドを作り直して
        command = at_command.split("@")[0]
        eq_param = at_command.split("@")[1]
        command += "[=#{eq_param}]"

        # しれっと投げる
        case command
        when RE_JUDGE_DICEROLL
          return proc_dice_2nd(Regexp.last_match)
        else
          return nil
        end
      end

      RE_COUNT_JUDGE_TE = /(=)([1-6](,[1-6])+)/.freeze

      RE_JUDGE_DICEROLL_TE = /^((?:(?:UH|[KENHU])?\d+,?)+)(@[1-6](,[1-6])*)$/i.freeze
      # RE_JUDGE_DICEROLL = %r{^((?:(?:UH|[KENHU])?\d+,?)+)(?:\[((?:(?:S([1-6]|[1-6]+(?:/[1-6]+)?\+)?|C([1-6]*\+?)?|(=|!=|>=|>|<=|<)([1-6]+\+?)|(=)([1-6](,[1-6])+))(?:\]\[)?)+)\])?$}i.freeze
      RE_JUDGE_DICEROLL = /^((?:(?:UH|[KENHU])?\d+,?)+)(?:\[((?:(?:(=|!=|>=|>|<=|<)([1-6]+\+?)|(=)([1-6](,[1-6])+))(?:\]\[)?)+)\])?$/i.freeze

      register_prefix(
        "UH",
        "[KENHU]"
      )
    end
  end
end
