# frozen_string_literal: true

module BCDice
  module GameSystem
    class Irisbane < Base
      # ゲームシステムの識別子
      ID = 'Irisbane'

      # ゲームシステム名
      NAME = '瞳逸らさぬイリスベイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひとみそらさぬいりすへいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■攻撃判定（ ATTACKx@y<=z ）
        x: 攻撃力
        y: 判定数
        z: 目標値
        （※ ATTACK は ATK または AT と簡略化可能）
        例） ATTACK2@3<=5
        例） ATK10@2<=4
        例） AT8@3<=2

        上記 x y z にはそれぞれ四則演算を指定可能。
        例） ATTACK2+7@3*2<=5-1

        □攻撃判定のダメージ増減（ ATTACKx@y<=z[+a]  ATTACKx@y<=z[-a]）
        末尾に [+a] または [-a] と指定すると、最終的なダメージを増減できる。
        a: 増減量
        例） ATTACK2@3<=5[+10]
        例） ATK10@2<=4[-8]
        例） AT8@3<=2[-8+5]

        ■シチュエーション（p115）
        SceneSituation, SSi
      HELP

      ATTACK_ROLL_REG = %r{^AT(TACK|K)?([+\-*/()\d]+)@([+\-*/()\d]+)<=([+\-*/()\d]+)(\[([+-])([+\-*/()\d]+)\])?}i.freeze
      register_prefix('AT(TACK|K)?')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        if (m = ATTACK_ROLL_REG.match(command))
          roll_attack(m[2], m[3], m[4], m[6], m[7])
        else
          roll_tables(command, TABLES)
        end
      end

      private

      def roll_attack(power_expression, dice_count_expression, border_expression, modification_operator, modification_expression)
        power = Arithmetic.eval(power_expression, RoundType::CEIL)
        dice_count = Arithmetic.eval(dice_count_expression, RoundType::CEIL)
        border = Arithmetic.eval(border_expression, RoundType::CEIL)
        modification_value = modification_expression.nil? ? nil : Arithmetic.eval(modification_expression, RoundType::CEIL)
        return if power.nil? || dice_count.nil? || border.nil?
        return if modification_operator && modification_value.nil?

        power = 0 if power < 0
        border = border.clamp(1, 6)

        command = make_command_text(power, dice_count, border, modification_operator, modification_value)

        if dice_count <= 0
          return "#{command} ＞ 判定数が 0 です"
        end

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        success_dice_count = dices.count { |dice| dice <= border }
        damage = success_dice_count * power

        message_elements = []
        message_elements << command
        message_elements << dices.join(',')
        message_elements << "成功ダイス数 #{success_dice_count}"
        message_elements << "× 攻撃力 #{power}" if success_dice_count > 0

        if success_dice_count > 0
          if modification_operator && modification_value
            message_elements << "ダメージ #{damage}#{modification_operator}#{modification_value}"
            damage = parse_operator(modification_operator).call(damage, modification_value)
            damage = 0 if damage < 0
            message_elements << damage.to_s
          else
            message_elements << "ダメージ #{damage}"
          end
        end

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = success_dice_count > 0
        end
      end

      def make_command_text(power, dice_count, border, modification_operator, modification_value)
        text = "(ATTACK#{power}@#{dice_count}<=#{border}"
        text += "[#{modification_operator}#{modification_value}]" if modification_operator
        text += ")"
        text
      end

      def parse_operator(operator)
        case operator
        when '+'
          lambda { |x, y| x + y }
        when '-'
          lambda { |x, y| x - y }
        end
      end

      TABLES = {
        "SceneSituation" => DiceTable::D66LeftRangeTable.new(
          "シチュエーション",
          BCDice::D66SortType::NO_SORT,
          [
            [1..3, [
              "【日常】何一つ変わることの無い日々の一幕。移ろい易い世界では、それはとても大切である。",
              "【準備】何かを為すための用意をする一幕。情報収集、買物遠征、やるべきことは一杯だ。",
              "【趣味】自分の時間を、有効活用している一幕。必要に追われていない分、心は軽く晴れやかだ。",
              "【喫茶】一息入れ、嗜好品を嗜む時の一幕。穏やかな空気は、だが、往々にして変わりやすい。",
              "【鍛錬】体を鍛え、心を養う修練の一幕。己さえ良ければ、その方法も何だって良い。",
              "【職務】役割の元、仕事に精を出す時の一幕。目的が何であれ、為すべきことに変わりはない。",
            ]],
            [4..6, [
              "【移動】何処かから何処かへと向かう一幕。進んでいるなら、手段も目的地も関係あるまい。",
              "【墓前】故人が眠る場所へと赴く一幕。共に眠ることだけは無いように。",
              "【操作】何かを操り、望みを果たしている一幕。運転にせよ何にせよ、脇見には注意が必要だ。",
              "【食事】何かを糧とし、己の力を蓄える一幕。行動すれば消耗する。腹が減っては何とやらだ。",
              "【休息】日々の合間の、憩いの一幕。“何もしない”というのも、立派な行いである。",
              "【夢幻】現実に存在しない何かへと耽る一幕。時間帯に関わらず、何時かは必ず覚めるだろう。",
            ]],
          ]
        ),
      }.transform_keys(&:upcase).freeze

      ALIAS = {
        "SSi" => "SceneSituation",
      }.transform_keys(&:upcase).transform_values(&:upcase).freeze

      register_prefix(TABLES.keys, ALIAS.keys)
    end
  end
end
