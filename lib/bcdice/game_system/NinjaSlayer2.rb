# frozen_string_literal: true

module BCDice
  module GameSystem
    class NinjaSlayer2 < Base
      # ゲームシステムの識別子
      ID = "NinjaSlayer2"

      # ゲームシステム名
      NAME = "ニンジャスレイヤーTRPG 2版"

      # ゲームシステム名の読みがな
      SORT_KEY = "にんしやすれいやあTRPG2"

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

        - [S{y}]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[>={y}]と同等の追加判定を行います。
        条件を満たしたダイスの個数を「サツバツ判定」というテキストと共に出力します。
        ※ {y}は省略可能、省略した場合は固定値6で処理します。

        - [S{y1}{y2}...{yn}+]
        - [S{y1}{y2}...{yn}/{z1}{z2}...{zn}+]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[>={y1}{y2}...{yn}+]と[>={z1}{z2}...{zn}+]と同等の追加判定を行います。
        {z1}～{zn}で条件を満たした場合、「ナムアミダブツ！」というテキストを出力します。
        {z1}～{zn}の条件を満たせず、{y1}～{yn}で条件を満たした場合、「サツバツ！」というテキストを出力します。
        ※ {z1}～{zn}を省略した場合は、「サツバツ！」の判定のみを行ないます。

        - [C{y}]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[>={y}]と同等の追加判定を行います。
        条件を満たしたダイスの個数を「クリティカル判定」というテキストと共に出力します。
        ※ {y}は省略可能、省略した場合は固定値6で処理します。

        - [C{y1}{y2}...{yx}+]
        成功判定コマンドでカンマ区切りで指定した各ロール結果に対して、[>={y1}{y2}...{yn}+]と同等の追加判定を行います。
        条件を条件を満たした場合、「クリティカル！」というテキストを出力します。

        --- 定型文コマンド ---
        以下のコマンド群はそれぞれ単体で使用してください。

        - SB or SB@{x}
        {x}(1-6/省略時はd6)に対応したサツバツ([S]atz-[B]atz)・クリティカル表の内容を返します。

        - WS{x}
        {x}(1-12/省略不可)に対応する[W]as[s]hoi!判定(2d6<={x})を行います

        - WSE or WSE@{x}
        {x}(1-6/省略時はd6)に対応する死神のエントリー決定表([W]as[s]hoi! [E]ntry)の内容を返します。

        - NRS_E{x} or NRS_E{x}@{y} or NRS@{y}
        ダイス{x}個で難易度[E]asy(>=3)のNRS判定({x}省略時はスキップ)を行い、失敗した場合は{y}(1～7/省略時は難易度に応じたダイス目)に対応するNRS発狂表を返します。
        「_E」部分を変更することで、難易度N,H,U,UHでも利用可能です。(Kはありません)
      TEXT

      # Base::eval_game_system_specific_commandの実装
      # @param command [String]
      # @return [String, nil]
      def eval_game_system_specific_command(command)
        # @debug = true
        debug("input: #{command}")

        begin
          case command
          when RE_JUDGE_DICEROLL
            # 2版用のダイス判定
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

      # 文字列stringを数値化する。nilの場合はdefaultで指定された値を返す
      # @param string [String]
      # @param default [Integer]
      # @return [Integer]
      def s_to_i(string, default)
        return string.nil? || string.empty? ? default : string.to_i
      end

      # 難易度判定の成功数を返す。
      # @param dice_array [Array<Integer>]
      # @param difficulty [Integer]
      # @param cmp_op [String]
      # @return Integer
      def check_difficulty(dice_array, difficulty, cmp_op)
        success_dice = []
        dice_array.each do |dice_value|
          if dice_value.send(Normalize.comparison_operator(cmp_op), difficulty)
            success_dice.push(dice_value)
          end
        end

        return success_dice
      end

      # 難易度判定結果を返す。
      # @param dice_array [Array<Integer>]
      # @param difficulty [Integer]
      # @param cmp_op [String]
      # @return [boolean]
      def check_difficulty_new(dice_array, difficulty, cmp_op)
        if difficulty.nil? || dice_array.empty?
          return false
        end

        # 難易度とダイスを昇順ソート
        sorted_dice_array = dice_array.min(dice_array.size)
        sorted_difficulty = difficulty.chars.min(difficulty.length)
        debug("sorted_difficulty #{sorted_difficulty}")
        debug("sorted_dice_array #{sorted_dice_array}")

        # 出目が低い順に難易度を越えているかチェック
        check_index = 0
        sorted_dice_array.each do |dice_value|
          if dice_value.send(Normalize.comparison_operator(cmp_op), sorted_difficulty[check_index].to_i)
            check_index += 1
          end
        end

        # 全難易度を突破していたら成功を返す
        return check_index >= sorted_difficulty.size
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

      # ダイス処理(2版用)
      # @param command [String]
      # @return [String, Integer]
      def proc_dice_2nd(match)
        output_text = ''
        total_success_num = 0

        command = match[1]
        appendix = match[2]
        difficulty = 0

        command.split(",").each do |sub_command|
          /^(UH|[KENHU])?(\d+)$/i.match(sub_command)
          unless Regexp.last_match[1].nil?
            difficulty = DIFFICULTY_SYMBOL_TO_INTEGER.fetch(Regexp.last_match[1])
          end
          dice_num = Regexp.last_match[2].to_i

          # D6バラバラロール
          roll_command = "#{dice_num}B6>=#{difficulty}"
          roll_result = BCDice::CommonCommand::BarabaraDice.eval(roll_command, self, @randomizer)

          output_text += "(#{roll_command}) ＞ #{roll_result.last_dice_list.join(',')} ＞ 成功数:#{roll_result.success_num}"
          success_num = roll_result.success_num

          # Appendix部分の処理
          unless appendix.nil?
            debug("---- appendix: [#{appendix}]")
            ap_command_array = appendix.split("\]\[")
            ap_command_array.each do |ap_command|
              output_text += proc_appendix(roll_result, ap_command)
            end
          end
          output_text += " \n"

          total_success_num += success_num
        end

        return output_text, total_success_num
      end

      # サツバツ！の処理を実行する
      # @param type [Integer]
      # @return [Result]
      def proc_satz_batz(type)
        # サツバツ判定(d6)
        if type > 0
          return "サツバツ!!(#{type}) ＞ #{translate('NinjaSlayer2.table.SATSUBATSU.items')[type - 1]}"
        else
          return DiceTable::Table.from_i18n("NinjaSlayer2.table.SATSUBATSU", @locale).roll(@randomizer)
        end
      end

      # Wasshoi！判定の処理を実行する
      # @param dkk [Integer]
      # @return [Result]
      def proc_wasshoi(dkk)
        dice_array = @randomizer.roll_barabara(2, 6)
        output_text = "Wasshoi!判定(2D6) ＞ (#{dice_array.join('+')}) ＞ #{dice_array.sum()}"

        if dice_array.sum() > dkk
          output_text += "(>#{dkk}) 判定失敗"
          return Result.success(output_text)
        else
          output_text += "(<=#{dkk}) 判定成功!! \nニンジャスレイヤー=サンのエントリーだ!!"
          return Result.failure(output_text)
        end
      end

      # Wasshoi！の処理を実行する
      # @param type [Integer]
      # @return [Result]
      def proc_wasshoi_entry(type)
        # Wasshoi!判定
        output_text = ""
        if type > 0
          output_text += "ニンジャスレイヤー=サンのエントリー!!(#{type}) ＞ #{translate('NinjaSlayer2.table.WASSHOI.items')[type - 1]}"
        else
          # DKKの指定無し、もしくはロール結果がDKKを超えたら死神のエントリー決定表(d6)
          table = DiceTable::Table.from_i18n("NinjaSlayer2.table.WASSHOI", @locale)
          output_text += table.roll(@randomizer).to_s
        end
        return output_text
      end

      # NRS判定の処理を実行する
      # @param dice_num [Integer]
      # @param dificulty_s [String]
      # @param type [Integer]
      # @return [Result]
      def proc_nrs(dice_num, dificulty_s, type)
        # 難易度も乱数表の番号も指定が無ければコマンドミス
        dificulty_i = dificulty_s.nil? ? 0 : DIFFICULTY_SYMBOL_TO_INTEGER.fetch(dificulty_s)
        if dificulty_i == 0 && type == 0
          return nil
        end

        # NRS判定
        output_text = ""
        if dificulty_i > 0
          roll_command = "#{dice_num}B6>=#{dificulty_i}"
          roll_result = BCDice::CommonCommand::BarabaraDice.eval(roll_command, self, @randomizer)
          output_text += "NRS判定(#{roll_command}) ＞ #{roll_result.last_dice_list.join(',')} ＞ 成功数:#{roll_result.success_num}"
          if roll_result.success_num > 0
            output_text += " NRS克服!!"
            return Result.success(output_text)
          else
            output_text += " NRS発症!! \n"
          end
        end

        # NRS発狂表の決定
        dice_face = 0
        additional = 0
        if type == 0
          case dificulty_s
          when "E"
            dice_face = 3
          when "N"
            dice_face = 6
          when "H", "U"
            dice_face = 6
            additional = 1
          end
          type = @randomizer.roll_once(dice_face) + additional
        end
        roll_command = "1D#{dice_face}#{additional > 0 ? '+' + additional.to_s : ''}"
        output_text += "NRS発狂#{dice_face > 0 ? "(#{roll_command}) ＞ " : ''}(#{type}) ＞ #{translate('NinjaSlayer2.table.NRS.items')[type - 1]}"
        return Result.failure(output_text)
      end

      # テキスト系処理
      # @param command [String]
      # @return [String, Integer]
      def proc_text(command)
        debug("text: #{command}")
        case command
        when RE_JUDGE_SATZ_BATZ
          # サツバツ判定(d6)
          return proc_satz_batz(Regexp.last_match[1].to_i)
        when RE_JUDGE_WASSHOI
          # Wasshoi!判定
          return proc_wasshoi(Regexp.last_match[1].to_i)
        when RE_JUDGE_WASSHOI_ENTRY
          # Wasshoi!判定
          return proc_wasshoi_entry(Regexp.last_match[1].to_i)
        when RE_JUDGE_NRS
          # NRS判定
          return proc_nrs(Regexp.last_match[2].to_i, Regexp.last_match[1], Regexp.last_match[3].to_i)
        end
      end

      RE_COUNT_SATZ_BATZ = %r{S([1-6]|[1-6]+(?:/[1-6]+)?\+)?$}i.freeze
      RE_COUNT_CRITICAL = /C([1-6]|[1-6]+\+)?$/i.freeze
      RE_COUNT_JUDGE = /(=|!=|>=|>|<=|<)([1-6]+\+|[1-6])/.freeze

      RE_JUDGE_DICEROLL = %r{^((?:(?:UH|[KENHU])?\d+,?)+)(?:\[((?:(?:S([1-6]|[1-6]+(?:/[1-6]+)?\+)?|C([1-6]*\+?)?|(=|!=|>=|>|<=|<)([1-6]+\+?))(?:\]\[)?)+)\])?$}i.freeze
      RE_JUDGE_SATZ_BATZ = /^SB(?:@([1-6]))?$/i.freeze
      RE_JUDGE_WASSHOI = /^WS([1-9]|10|11|12)$/i.freeze
      RE_JUDGE_WASSHOI_ENTRY = /^WSE(?:@([1-6]))?$/i.freeze
      RE_JUDGE_NRS = /^NRS(?:_(E|N|H|U|UH)(\d+))?(?:@([1-7]))?$/i.freeze

      # 難易度の文字表現から整数値への対応
      DIFFICULTY_SYMBOL_TO_INTEGER = {
        'K' => 2,
        'E' => 3,
        'N' => 4,
        'H' => 5,
        'U' => 6,
        'UH' => 6
      }.freeze

      register_prefix(
        "UH",
        "[KENHU]",
        "SB",
        "WS",
        "WSE",
        "NRS"
      )
    end
  end
end
