# frozen_string_literal: true

require 'bcdice/base'

module BCDice
  module GameSystem
    class YuMyoKishi < Base
      # ゲームシステムの識別子
      ID = 'YuMyoKishi'

      # ゲームシステム名
      NAME = '幽冥鬼使'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'ゆうみようきし'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■判定　YM+a>=b　a:技能値（省略可）　b:目標値（省略可）
        　例：YM+4>=8: 技能値による修正が+4で、目標値8の克服判定を行う
        　　　YM>=8  : 技能値による修正なしで、目標値8の克服判定を行う
        　　　YM+6   : 技能値による修正が+6で、達成値を確認する

        ■代償表　COT
        ■転禍表　TRT
      MESSAGETEXT

      TABLES = {
        "COT" => DiceTable::Table.new(
          "代償表",
          "2D6",
          [
            "不慮の出逢い",
            "深淵を覗くとき",
            "時間の消費",
            "奇妙な情報",
            "優柔不断",
            "注意散漫",
            "心身耗弱",
            "不穏な情報",
            "遺留品",
            "迫りくる危機",
            "正体の露見",
          ]
        ),
        "TRT" => DiceTable::Table.new(
          "転禍表",
          "2D6",
          [
            "○○と瓜二つ",
            "絶対絶命",
            "悪癖災う",
            "冷酷な指令",
            "おびえる視線",
            "絡みつく妖気",
            "容赦ない評定",
            "無力な市民",
            "未練阻む",
            "縁の枷",
            "邪悪な刻印",
          ]
        ),
      }.freeze

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix("YM", TABLES.keys)

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command Begin")

        return roll_command(command) || roll_tables(command, TABLES)
      end

      def roll_command(command)
        parser = Command::Parser.new('YM', round_type: round_type)
                                .restrict_cmp_op_to(:>=, nil)
        cmd = parser.parse(command)

        unless cmd
          return nil
        end

        dice_list = @randomizer.roll_barabara(4, 6)
        value, status = sip_pat_a(dice_list)
        achievement = status == :wumian ? 0 : value + cmd.modify_number
        roll_text = [
          cmd.to_s,
          dice_list.join(','),
          value,
          value == achievement ? nil : achievement,
        ].compact.join(" ＞ ")

        if cmd.target_number.nil?
          if status == :wumian
            Result.failure(roll_text)
          elsif status == :yise
            Result.critical(roll_text)
          else
            Result.new(roll_text)
          end
        elsif status == :wumian
          Result.failure([roll_text, "可"].join(" ＞ "))
        elsif status == :yise
          Result.critical([roll_text, "優"].join(" ＞ "))
        elsif achievement >= cmd.target_number
          Result.success([roll_text, "良"].join(" ＞ "))
        else
          Result.failure([roll_text, "可"].join(" ＞ "))
        end
      end

      def sip_pat_a(dice_list) # 十八仔
        result = dice_list.each_with_object(Hash.new(0)) do |cur, acc|
          acc[cur] += 1
        end
        case result.count
        when 1
          # 全てゾロ目
          [20, :yise] # 一色
        when 2
          if result.values == [2, 2]
            # 同値のダイスが2つずつ
            [result.keys.max * 2, :normal]
          else
            # 3つの同値と1つの目のダイス
            [result.keys.sum, :normal]
          end
        when 3
          # 2つの同値と1つずつの目のダイス
          [result.select { |_k, v| v == 1 }.keys.sum, :normal]
        else
          # 全部バラバラ
          [0, :wumian] # 無面
        end
      end
    end
  end
end
