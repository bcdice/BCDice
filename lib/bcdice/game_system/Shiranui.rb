# frozen_string_literal: true

module BCDice
  module GameSystem
    class Shiranui < Base
      # ゲームシステムの識別子
      ID = 'Shiranui'

      # ゲームシステム名
      NAME = '不知火'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しらぬい'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■∞D66ダイスロール
        「 ∞D66 」または「 ID66 」
        （ ID は Infinite D の略です）

        □行動力や攻撃力の指定
        「 x+∞D66 」または「 x+ID66 」
        （ x は行動力や攻撃力）

        □鬼火の使用について
        鬼火を使用する∞D66は、ダイスボットでサポートしていません。

        ■おみくじを引く
        OMKJ
      HELP

      INFINITE_D66_ROLL_REG = /^((\d+)\+)?(∞|I)D66$/i.freeze
      register_prefix('(\d+\+)?(∞|I)D66')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
      end

      def eval_game_system_specific_command(command)
        if (m = INFINITE_D66_ROLL_REG.match(command))
          fixed_score = m[1]&.to_i
          roll_infinite_d66(fixed_score)
        else
          roll_tables(command, TABLES)
        end
      end

      def roll_infinite_d66(fixed_score)
        steps = []

        while steps.empty? || steps.last.to_continue_diceroll?
          # 個別の出目をあつかうので、 roll_d66 ではなく roll_barabara を使う
          dices = @randomizer.roll_barabara(2, 6).sort

          steps << InifiniteD66Step.new(dices)
        end

        is_failure = steps.first.score.zero? # 「しくじり」か？
        total = is_failure ? 0 : steps.sum(&:score) + fixed_score.to_i

        result_text = "(#{self.class.make_command_text(fixed_score)})"
        result_text += " ＞ " + steps.map(&:to_s).join(' ＞ ')
        if is_failure
          result_text += " ＞ しくじり"
        else
          result_text += " ＞ " + self.class.score_expression_text(steps, fixed_score) if steps.size > 1 || !fixed_score.nil?
          result_text += " ＞ " + total.to_s
        end

        Result.new(result_text).tap do |r|
          r.critical = steps.size > 1
          r.failure = is_failure
          r.fumble = is_failure
        end
      end

      def self.make_command_text(fixed_score)
        fixed_score.nil? ? "∞D66" : "#{fixed_score}+∞D66"
      end

      def self.score_expression_text(steps, fixed_score)
        text = steps.map(&:score).join('+')
        text = "#{fixed_score}+(#{text})" unless fixed_score.nil?
        text
      end

      class InifiniteD66Step
        def initialize(dices)
          @dices = dices.dup.freeze
        end

        def score
          if repdigit?
            # ゾロ目の場合

            digit = @dices.first

            if digit == 1
              # 1 のゾロ目なら 0 となる
              0
            else
              # 1 以外のゾロ目なら、数字の 10 倍となる
              digit * 10
            end
          else
            # ゾロ目でない場合は、 D66 様式で値を算出する
            @dices[0] * 10 + @dices[1]
          end
        end

        def repdigit?
          @dices[0] == @dices[1]
        end

        # ダイスロールを継続する必要があるか？
        def to_continue_diceroll?
          repdigit? && @dices[0] != 1
        end

        def to_s
          "[#{@dices[0]},#{@dices[1]}]"
        end
      end

      TABLES = {
        "OMKJ" => DiceTable::Table.new(
          "おみくじ",
          "1D6",
          [
            "大凶［御利益１］――このみくじにあたる人は、凶運から逃れることができぬ者なり。まさに凶運にその身をゆだねてこそ、浮かぶ瀬もあれ。……これより上演中に演者が振る［∞Ｄ66］で初めて⚀⚀が出たら、御利益を使っても振り直しができない。",
            "凶［御利益２］――このみくじにあたる人は、吉兆を逃す定めにある。まさに、天の与うるを取らざれば反ってその咎めを受く。……これより上演中に演者が振る［∞Ｄ66］で初めて⚅⚅が出たら、強制的に１回の振り直しをする。",
            "小吉［御利益３］――このみくじにあたる人は、神使の機嫌を損ねている。神使が何に怒り、何に苛立っているのかは、まさに神のみぞ知る。……神使の機嫌が突然、悪くなる。これより上演中に神使は何かと理由をつけてはシラヌイの前から立ち去ろうとする。",
            "中吉［御利益４］――このみくじにあたる人は、神使の機嫌を良くすることを行った者なり。神使が何に喜び、なぜ機嫌が良いのか、まさに神のみぞ知る。……神使の機嫌がすこぶる良くなる。これより上演中に神使は上機嫌となり、シラヌイに何かにつけて話しかけてくれる。",
            "吉［御利益５］――このみくじにあたる人は、悪運を幸運へと変える道を進む者なり。まさに禍福は糾える縄の如し。……これより上演中に演者が振る［∞Ｄ66］で初めて⚀⚀が出たら、御利益を消費することなく、１回の振り直しをする。",
            "大吉［御利益６］――このみくじにあたる人は、思いもよらぬ幸運に巡り合う者なり。まさに、暗き道より出て、気づけば月の光あり。……これより上演中に演者が振る［∞Ｄ66］で１回だけ、サイコロの出目を⚅⚅に変えてよい。",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(TABLES.keys)
    end
  end
end
