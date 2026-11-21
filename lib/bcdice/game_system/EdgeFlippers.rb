# frozen_string_literal: true

module BCDice
  module GameSystem
    class EdgeFlippers < Base
      # ゲームシステムの識別子
      ID = 'EdgeFlippers'

      # ゲームシステム名
      NAME = 'EDGE FLIPPERS'

      # ゲームシステム名の読みがな
      SORT_KEY = 'えつしふりつはあす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 汎用コマンド
          xHD+ySD=t,t,t
          人間ダイスと怪異ダイスをロールして、特定の出目があるか判定します。
          x: 人間ダイスの数
          y: 怪異ダイスの数
          t: 必要な出目（省略化）

        ■ 拮抗判定
          xHD+ySD=Xi
          人間ダイスと怪異ダイスをロールして、ゾロ目が必要数あるか判定します。
          i: 必要なゾロ目の個数

        ■ 全力判定
          xHFD>=t
          xSFD>=t
          x: ダイスの数
          t: 目標値（省略時20）

        ■ 存在判定
          EXIST -> 2HD+2SD

        ■ 都市判定
          xHCD -> xHD=1,2,3,4

        ■ 超常判定
          nSPD -> nSD=7,8,9,10

        ■ 術式判定
          TD

        ■ ランダム表
          BAET：【人間】にも【怪異】にも影響のある後遺症
          HAET：【人間寄り】の時に影響のある後遺症
          SAET：【怪異寄り】の時に影響のある後遺症
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        roll_hs(command) || roll_alias(command) || roll_fullpower(command) || roll_technical(command) || roll_tables(command, TABLES)
      end

      private

      class HSCommand
        class << self
          def parse(command)
            m = /^(?:(\d+)HD(?:\+(\d+)SD)?|(\d+)SD(?:\+(\d+)HD)?)(?:=(?:([\d,]+)|X(\d+)))?$/.match(command)
            return nil unless m

            h = m[1]&.to_i || m[4]&.to_i || 0
            s = m[2]&.to_i || m[3]&.to_i || 0
            targets = parse_target(m[5])
            same_value = m[6]&.to_i

            if h == 0 && s == 0
              return nil
            end

            return HSCommand.new(h, s, targets, same_value)
          end

          private

          def parse_target(str)
            return nil unless str

            str.split(",").filter { |s| !s.empty? }.map(&:to_i).sort
          end
        end

        def initialize(h, s, targets, same_value)
          @h = h
          @s = s
          @targets = targets
          @same_value = same_value
        end

        def roll(randomizer)
          @hv = randomizer.roll_barabara(@h, 6).sort
          @sv = randomizer.roll_barabara(@s, 10).sort
          values = (@hv + @sv).sort

          @is_success = if @targets
                          subset?(values, @targets)
                        elsif @same_value
                          values.group_by(&:itself).any? { |_k, v| v.length >= @same_value }
                        end

          Result.new.tap do |r|
            r.text = [expr(), result_values(), result_label].compact.join(" ＞ ")
            unless @is_success.nil?
              r.condition = @is_success
            end
          end
        end

        private

        def subset?(superset, subset)
          return true if subset.empty?

          i = 0
          superset.each do |a|
            b = subset[i]
            if b == a
              i += 1
              if i == subset.length
                return true
              end
            elsif a > b
              return false
            end
          end

          return false
        end

        def expr
          "(#{expr_body()}#{expr_cond()})"
        end

        def expr_body
          if @h != 0 && @s != 0
            "#{@h}HD+#{@s}SD"
          elsif @h != 0
            "#{@h}HD"
          else
            "#{@s}SD"
          end
        end

        def expr_cond
          if @targets
            "=#{@targets.join(',')}"
          elsif @same_value
            "=X#{@same_value}"
          else
            ""
          end
        end

        def result_values
          d6 = !@hv.empty? ? "D6[#{@hv.join(',')}]" : nil
          d10 = !@sv.empty? ? "D10[#{@sv.join(',')}]" : nil
          [d6, d10].compact.join(" ")
        end

        def result_label
          case @is_success
          when true
            "成功"
          when false
            "失敗"
          end
        end
      end

      def roll_hs(command)
        cmd = HSCommand.parse(command)
        return nil unless cmd

        cmd.roll(@randomizer)
      end

      def parse_target(str)
        return nil unless str

        str.split(",").filter { |s| !s.empty? }.map(&:to_i).sort
      end

      def subset?(superset, subset)
        return true if subset.empty?

        i = 0
        superset.each do |a|
          b = subset[i]
          if b == a
            i += 1
            if i == subset.length
              return true
            end
          elsif a > b
            return false
          end
        end

        return false
      end

      def roll_alias(command)
        case command
        when "EXIST"
          return roll_hs("2HD+2SD")
        end

        m = /^(\d+)(HCD|SPD)$/.match(command)
        return nil unless m

        n = m[1].to_i
        case m[2]
        when "HCD"
          roll_hs("#{n}HD=1,2,3,4")
        when "SPD"
          roll_hs("#{n}SD=7,8,9,10")
        end
      end

      def roll_fullpower(command)
        parser = Command::Parser.new(/[HS]FD/, round_type: @round_type)
                                .disable_modifier.enable_prefix_number.restrict_cmp_op_to(nil, :>=)
        parsed = parser.parse(command)
        return nil unless parsed

        n = parsed.prefix_number
        side = parsed.command == "HFD" ? 6 : 10
        target = parsed.target_number || 20
        return nil if n == 0

        dice = @randomizer.roll_barabara(n, side).sort
        sum = dice.sum()
        tries = [dice]
        while sum < target
          dice = @randomizer.roll_barabara(n, side).sort
          tries.push(dice)
          sum += dice.sum()
        end

        Result.new.tap do |r|
          r.text = "(#{n}#{parsed.command}>=#{target})"
          tries.each do |ds|
            r.text += " ＞ #{ds.sum}[#{ds.join(',')}]"
          end

          is_success = tries.length < 5
          r.text += " ＞ #{sum}(#{tries.length}回)"
          r.text += is_success ? " ＞ 成功" : " ＞ 失敗"
          r.condition = is_success
        end
      end

      def roll_technical(command)
        return nil unless command == "TD"

        value = @randomizer.roll_once(10)
        is_success = value <= 2
        Result.new.tap do |r|
          r.text = "(TD) ＞ #{value} ＞ #{is_success ? '成功' : '失敗'}"
          r.condition = is_success
        end
      end

      TABLES = {
        "BAET" => DiceTable::Table.new(
          "【人間】にも【怪異】にも影響のある後遺症",
          "1D12",
          [
            "鏡に映らない：鏡や水面に姿が映らなくなる。他者から見えなくなるわけではない",
            "部分的に透明：身体のどこかが透明になる",
            "部分的欠落：身体のどこかが消えて触ることもできなくなる。生命維持に影響はない",
            "角が生える：角が生えてくる。元から角がある場合はさらに追加",
            "しっぽ：動物のしっぽが生える",
            "けもみみ：動物の耳が頭に生える",
            "影がなくなる：自分の影がなくなってしまう",
            "涙が止まらない：ずっと涙が流れ続けて止まらなくなる",
            "視界の端に何かいる：常に視界の端に何かがいて、踊っている",
            "耳鳴り：ずっと耳鳴りがやまない。たまに幻聴がする",
            "美しい幻聴：時々他人の声が現実離れした美しい声に変わって聞こえる",
            "皮膚の下のうごめき：皮膚の下でずっと何かが蠢いているように感じられる",
          ]
        ),
        "HAET" => DiceTable::Table.new(
          "【人間寄り】の時に影響のある後遺症",
          "1D6",
          [
            "幻肢の感覚：存在しない追加の腕や翼の感覚がある",
            "声変わり：普段とは違う声になってしまう",
            "怪異の片鱗：【怪異寄り】のときの容姿の一部が【人間寄り】の時にも出てしまう",
            "幻覚：時折やけに生々しい幻覚が見えるようになる",
            "恐怖：あらゆるものが怖く見える",
            "怪異言語：【人間】の領域には存在しない謎の言語が理解できる",
          ]
        ),
        "SAET" => DiceTable::Table.new(
          "【怪異寄り】の時に影響のある後遺症",
          "1D6",
          [
            "吸精体質：他者に触れると生命力を吸収してしまう。特に仲の良い相手だとより強くなる",
            "威圧する視線：あなたの視線は周囲に強烈な威圧感を与えてしまう",
            "キメラ：あなたの容姿の一部が、他の【越境者】の【怪異寄り】のときの容姿のものと同じになる",
            "異なる怪異：あなた本来の【怪異】の姿とは違う姿に変化してしまう",
            "ポルターガイスト：周囲でラップ音や部品の浮遊といった怪現象が多発する",
            "人間そのもの：【怪異寄り】のときでも人間そのものの容姿になってしまう",
          ]
        ),
      }.freeze

      register_prefix('\d+HD', '\d+SD', '\d+HCD', '\d+SPD', '\d+HFD', '\dSFD', 'EXIST', 'TD', TABLES.keys)
    end
  end
end
