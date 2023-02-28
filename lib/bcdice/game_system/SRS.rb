# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'

module BCDice
  module GameSystem
    class SRS < Base
      # ゲームシステムの識別子
      ID = 'SRS'

      # ゲームシステム名
      NAME = 'スタンダードRPGシステム'

      # ゲームシステム名の読みがな
      SORT_KEY = 'すたんたあとRPGしすてむ'

      HELP_MESSAGE_1 = <<~HELP_MESSAGE
        ・判定
        　・通常判定：2D6+m@c#f>=t または 2D6+m>=t[c,f]
        　　修正値m、目標値t、クリティカル値c、ファンブル値fで判定ロールを行います。
        　　修正値、クリティカル値、ファンブル値は省略可能です（[]ごと省略可、@c・#fの指定は順不同）。
        　　クリティカル値、ファンブル値の既定値は、それぞれ12、2です。
        　　自動成功、自動失敗、成功、失敗を自動表示します。

        　　例) 2d6>=10　　　　　修正値0、目標値10で判定
        　　例) 2d6+2>=10　　　　修正値+2、目標値10で判定
        　　例) 2d6+2>=10[11]　　↑をクリティカル値11で判定
        　　例) 2d6+2@11>=10 　　↑をクリティカル値11で判定
        　　例) 2d6+2>=10[12,4]　↑をクリティカル値12、ファンブル値4で判定
        　　例) 2d6+2@12#4>=10 　↑をクリティカル値12、ファンブル値4で判定
        　　例) 2d6+2>=10[,4]　　↑をクリティカル値12、ファンブル値4で判定（クリティカル値の省略）
        　　例) 2d6+2#4>=10　　　↑をクリティカル値12、ファンブル値4で判定（クリティカル値の省略）
      HELP_MESSAGE

      HELP_MESSAGE_2 = <<~HELP_MESSAGE
        　・クリティカルおよびファンブルのみの判定：2D6+m@c#f または 2D6+m[c,f]
        　　目標値を指定せず、修正値m、クリティカル値c、ファンブル値fで判定ロールを行います。
        　　修正値、クリティカル値、ファンブル値は省略可能です（[]は省略不可、@c・#fの指定は順不同）。
        　　自動成功、自動失敗を自動表示します。

        　　例) 2d6[]　　　　修正値0、クリティカル値12、ファンブル値2で判定
        　　例) 2d6+2[11]　　修正値+2、クリティカル値11、ファンブル値2で判定
        　　例) 2d6+2@11 　　修正値+2、クリティカル値11、ファンブル値2で判定
        　　例) 2d6+2@12#4 　修正値+2、クリティカル値12、ファンブル値4で判定
      HELP_MESSAGE

      HELP_MESSAGE_3 = <<~HELP_MESSAGE
        ・D66ダイスあり（入れ替えなし)
      HELP_MESSAGE

      # 既定のダイスボット説明文
      DEFAULT_HELP_MESSAGE = "#{HELP_MESSAGE_1}\n#{HELP_MESSAGE_2}\n#{HELP_MESSAGE_3}"

      HELP_MESSAGE = DEFAULT_HELP_MESSAGE

      # 成功判定のエイリアスコマンド定義用のクラスメソッドを提供するモジュール
      module ClassMethods
        # 成功判定のエイリアスコマンドの一覧
        # @return [Array<String>]
        attr_reader :aliases

        # ダイスボットの説明文を返す
        # @return [String]
        attr_reader :help_message

        # 成功判定のエイリアスコマンドを設定する
        # @param [String] aliases エイリアスコマンド（可変長引数）
        # @return [self]
        #
        # エイリアスコマンドとして指定した文字列がコマンドの先頭にあれば、
        # 実行時にそれが2D6に置換されるようになる。
        def set_aliases_for_srs_roll(*aliases)
          aliases_upcase = aliases.map(&:upcase)

          @aliases = aliases_upcase.map { |a| Regexp.escape(a) }
          @help_message = concatenate_help_messages(aliases_upcase)
          return self
        end

        # 成功判定のエイリアスコマンドを未設定にする
        # @return [self]
        def clear_aliases_for_srs_roll
          @aliases = []
          @help_message = SRS::DEFAULT_HELP_MESSAGE
          return self
        end

        private

        # ダイスボットの説明文を結合する
        # @param [Array<String>] aliases エイリアスコマンドの配列
        # @return [String] 結合された説明文
        # @todo 現在は2文字のエイリアスコマンドに幅を合わせてある。
        #   エイリアスコマンドの文字数が変わる場合があれば、位置を調整するコードが
        #   必要。
        def concatenate_help_messages(aliases)
          help_msg_for_aliases_for_target_value =
            aliases
            .map do |a|
              "　　例) #{a}+2>=10　　　　 2d6+2>=10と同じ（#{a}が2D6のショートカットコマンド）\n"
            end
            .join()
          help_msg_for_aliases_for_without_target_value =
            aliases
            .map do |a|
              "　　例) #{a}　　　　　 2d6[]と同じ（#{a}が2D6のショートカットコマンド）\n" \
              "　　例) #{a}+2@12#4　　2d6+2@12#4と同じ（#{a}が2D6のショートカットコマンド）\n"
            end
            .join()

          return "#{SRS::HELP_MESSAGE_1}" \
                 "#{help_msg_for_aliases_for_target_value}\n" \
                 "#{SRS::HELP_MESSAGE_2}" \
                 "#{help_msg_for_aliases_for_without_target_value}\n" \
                 "#{SRS::HELP_MESSAGE_3}"
        end
      end

      class << self
        # クラスが継承されたときに行う処理
        # @return [void]
        def inherited(subclass)
          subclass
            .extend(ClassMethods)
            .clear_aliases_for_srs_roll
        end

        # ダイスボットの説明文を返す
        # @return [String] 既定のダイスボット説明文
        def help_message
          DEFAULT_HELP_MESSAGE
        end

        # 成功判定のエイリアスコマンドの一覧
        # @return [Array<String>]
        def aliases
          []
        end
      end

      # 固有のコマンドの接頭辞を設定する
      register_prefix('2D6')

      # ダイスボットを初期化する
      def initialize(command)
        super(command)

        # 式、出目ともに送信する

        # バラバラロール（Bコマンド）でソートする
        @sort_add_dice = true
        # D66ダイスあり（出目をソートしない）
        @d66_sort_type = D66SortType::NO_SORT
      end

      # ダイスボットの説明文を返す
      # @return [String]
      def help_message
        self.class.help_message
      end

      # 成功判定のエイリアスコマンドの一覧
      # @return [Array<String>]
      def aliases
        self.class.aliases
      end

      # 既定のクリティカル値
      DEFAULT_CRITICAL_VALUE = 12
      # 既定のファンブル値
      DEFAULT_FUMBLE_VALUE = 2

      # 成功判定コマンドのノード
      SRSRollNode = Struct.new(
        :modifier, :critical_value, :fumble_value, :target_value
      ) do
        # 成功判定の文字列表記を返す
        # @return [String]
        def to_s
          lhs = "2D6#{Format.modifier(modifier)}"
          expression = target_value ? "#{lhs}>=#{target_value}" : lhs

          return "#{expression}[#{critical_value},#{fumble_value}]"
        end
      end

      # 固有のダイスロールコマンドを実行する
      # @param [String] command 入力されたコマンド
      # @return [Result, nil] ダイスロールコマンドの実行結果
      def eval_game_system_specific_command(command)
        legacy_c_f_match = /(.+)\[(.*)\]\z/.match(command)
        node =
          if legacy_c_f_match
            parse_legacy(legacy_c_f_match[1], legacy_c_f_match[2])
          else
            parse(command)
          end

        if node
          return execute_srs_roll(node)
        end

        return nil
      end

      private

      def parse(command)
        if command == "2D6"
          # if there are no special modifier or specifier,
          # fallback to default dice command
          return nil
        end

        prefix_re = Regexp.new(["2D6"].concat(aliases()).join('|'), Regexp::IGNORECASE)
        parser = Command::Parser.new(prefix_re, round_type: @round_type)
                                .enable_critical
                                .enable_fumble
                                .restrict_cmp_op_to(nil, :>=)
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        cmd.critical ||= DEFAULT_CRITICAL_VALUE
        cmd.fumble ||= DEFAULT_FUMBLE_VALUE

        return SRSRollNode.new(cmd.modify_number, cmd.critical, cmd.fumble, cmd.target_number)
      end

      def parse_legacy(command, c_f)
        parsed_c_f = c_f.split(",")
        critical, fumble = case parsed_c_f.length
                           when 0
                             [DEFAULT_CRITICAL_VALUE, DEFAULT_FUMBLE_VALUE]
                           when 1
                             [Integer(parsed_c_f[0], exception: false), DEFAULT_FUMBLE_VALUE]
                           when 2
                             if parsed_c_f[0] == ""
                               [DEFAULT_CRITICAL_VALUE, Integer(parsed_c_f[1], exception: false)]
                             else
                               [Integer(parsed_c_f[0], exception: false), Integer(parsed_c_f[1], exception: false)]
                             end
                           end
        if critical.nil? || fumble.nil?
          return nil
        end

        prefix_re = Regexp.new(["2D6"].concat(aliases()).join('|'), Regexp::IGNORECASE)
        parser = Command::Parser.new(prefix_re, round_type: @round_type)
                                .restrict_cmp_op_to(nil, :>=)
        cmd = parser.parse(command)
        unless cmd
          return nil
        end

        return SRSRollNode.new(cmd.modify_number, critical, fumble, cmd.target_number)
      end

      # 成功判定を実行する
      # @param [SRSRollNode] srs_roll 成功判定ノード
      # @return [Result] 成功判定結果
      def execute_srs_roll(srs_roll)
        dice_list = @randomizer.roll_barabara(2, 6)
        dice_list.sort! if @sort_add_dice

        sum = dice_list.sum()
        dice_str = dice_list.join(",")

        modified_sum = sum + srs_roll.modifier

        result = compare_result(srs_roll, sum, modified_sum)

        parts = [
          "(#{srs_roll})",
          "#{sum}[#{dice_str}]#{Format.modifier(srs_roll.modifier)}",
          modified_sum,
          result.text
        ]

        result.text = parts.compact.join(' ＞ ')
        result
      end

      # ダイスロール結果を目標値、クリティカル値、ファンブル値と比較する
      # @param [SRSRollNode] srs_roll 成功判定ノード
      # @param [Integer] sum 出目の合計
      # @param [Integer] modified_sum 修正後の値
      # @return [Result] 比較結果
      def compare_result(srs_roll, sum, modified_sum)
        if sum >= srs_roll.critical_value
          Result.critical("自動成功")
        elsif sum <= srs_roll.fumble_value
          Result.fumble("自動失敗")
        elsif srs_roll.target_value.nil?
          Result.new
        elsif modified_sum >= srs_roll.target_value
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
