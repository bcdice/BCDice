# frozen_string_literal: true

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

      # @付き追加判定の処理
      # @param at_command String 追加判定のコマンド
      # @return [String, Integer]
      def proc_dice_command_with_at(at_command)
        # コマンドを作り直して
        command = at_command.split("@")[0]
        eq_param = at_command.split("@")[1].split(",")

        eq_param.each do |i|
          command += "[=#{i}]"
        end

        # しれっと投げる
        case command
        when RE_JUDGE_DICEROLL
          return proc_dice_2nd(Regexp.last_match)
        else
          return nil
        end
      end

      RE_JUDGE_DICEROLL_TE = /^((?:(?:UH|[KENHU])?\d+,?)+)(@[1-6]+(,[1-6])*)$/i.freeze

      register_prefix(
        "UH",
        "[KENHU]"
      )
    end
  end
end
