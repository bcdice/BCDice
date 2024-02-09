# frozen_string_literal: true

module BCDice
  module GameSystem
    class KyokoShinshoku < Base
      # ゲームシステムの識別子
      ID = "KyokoShinshoku"

      # ゲームシステム名
      NAME = "虚構侵蝕TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "きよこうしんしよくTRPG"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定
        　ダイスを指定数ダイスロールして、最も高い出目を出力します。難易度を指定すると成否を判定します。
        KS(x,y)
        x：ダイスサイズ。1=D4（能力値1、2以上の出目が出ていたとしても最大1）／2=D4（能力値2、3以上の出目が出ていたとしても最大2）／3=D4（能力値3、出目4が出ていたとしても最大3）／4=D4／6=D6／8=D8／10=D10／12=D12／20=D20
        y：ダイス数（省略：1）

        KS(x,y)>=z
        x：ダイスサイズ。1=D4（能力値1、2以上の出目が出ていたとしても最大1）／2=D4（能力値2、3以上の出目が出ていたとしても最大2）／3=D4（能力値3、出目4が出ていたとしても最大3）／4=D4／6=D6／8=D8／10=D10／12=D12／20=D20
        y：ダイス数（省略：1）
        z：難易度

        ・観測ロール
        　［現実乖離］の段階に応じたダイスを指定数ダイスロールして、最も高い出目を出力します。
        KR(x)
        x=［現実乖離］の段階（1=D4／2=D6／3=D8／4=D10／5=D12／6=D20）

        KR(x,y)　観測ロール（リアリティラインあり）
        x=［現実乖離］の段階（1=D4／2=D6／3=D8／4=D10／5=D12／6=D20）
        y=［リアリティライン］のレベル（3=1個／2=2個／1=3個）

        ・虚構の収束の侵蝕度減少ロール
        　［現実乖離］の段階に応じたダイスを指定数ダイスロールして、その合計を出力します。
        KRS(x,y)
        x=［現実乖離］の段階（1=D4／2=D6／3=D8／4=D10／5=D12／6=D20）
        y=ダイスの個数
      MESSAGETEXT

      register_prefix('KS', 'KR', 'KRS')

      def eval_game_system_specific_command(command)
        roll_check(command) || roll_kansoku(command) || roll_shusoku(command)
      end

      private

      DICE_SIZE_TO_SIDES = {
        1 => 4,
        2 => 4,
        3 => 4,
        4 => 4,
        6 => 6,
        8 => 8,
        10 => 10,
        12 => 12,
        20 => 20,
      }.freeze

      def roll_check(command)
        m = /^KS(?:\((\d+),([-+\d]+)?\)|(\d+))(?:>=([-+\d]+))?$/.match(command)
        return nil unless m

        dice_size = m[1]&.to_i || m[3].to_i
        times = m[2] ? Arithmetic.eval(m[2], @round_type) : 1
        target = m[4] && Arithmetic.eval(m[4], @round_type)

        sides = DICE_SIZE_TO_SIDES[dice_size]

        return nil if sides.nil? || times.nil?

        dice_list = @randomizer.roll_barabara(times, sides).sort
        value = dice_list.max.clamp(1, dice_size)

        result =
          if value == 1
            Result.fumble("ファンブル")
          elsif target && value < target
            Result.failure("失敗")
          elsif target && value == sides
            Result.critical("クリティカル")
          elsif target && value >= target
            Result.success("成功")
          else
            Result.new()
          end

        result.text = [
          target ? "(KS(#{dice_size},#{times})>=#{target})" : "(KS(#{dice_size},#{times}))",
          ("#{value}[#{dice_list.join(',')}]" if times > 1),
          value,
          result.text,
        ].compact.join(" ＞ ")

        return result
      end

      GENJITU_KAIRI_TO_SIDES = [4, 6, 8, 10, 12, 20].freeze
      REALITY_LINE_TO_TIMES = {
        3 => 1,
        2 => 2,
        1 => 3,
      }.freeze

      def roll_kansoku(command)
        m = /^KR(?:(\d+)|\((\d),(\d)\))$/.match(command)
        return nil unless m

        dice_size = m[1]&.to_i || m[2].to_i
        reality_line = m[3]&.to_i

        if reality_line && (reality_line > 3 || reality_line < 1)
          return nil
        end

        sides = GENJITU_KAIRI_TO_SIDES[dice_size - 1]
        times = REALITY_LINE_TO_TIMES[reality_line] || 1

        return nil unless sides

        dice_list = @randomizer.roll_barabara(times, sides).sort
        value = dice_list.max

        cmd = reality_line ? "KR(#{dice_size},#{reality_line})" : "KR(#{dice_size})"

        if times == 1
          "(#{cmd}) ＞ #{value}"
        else
          "(#{cmd}) ＞ #{value}[#{dice_list.join(',')}] ＞ #{value}"
        end
      end

      def roll_shusoku(command)
        m = /^KRS(?:\((\d),([-+\d]+)\))$/.match(command)
        return nil unless m

        dice_size = m[1].to_i
        times = m[2] && Arithmetic.eval(m[2], @round_type)

        sides = GENJITU_KAIRI_TO_SIDES[dice_size - 1]
        return nil if sides.nil? || times.nil?

        dice_list = @randomizer.roll_barabara(times, sides)
        value = dice_list.sum

        if times == 1
          "(KRS(#{dice_size},#{times})) ＞ #{value}"
        else
          "(KRS(#{dice_size},#{times})) ＞ #{value}[#{dice_list.join(',')}] ＞ #{value}"
        end
      end
    end
  end
end
