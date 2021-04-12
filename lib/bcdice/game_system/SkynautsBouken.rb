# frozen_string_literal: true

module BCDice
  module GameSystem
    class SkynautsBouken < Base
      # ゲームシステムの識別子
      ID = 'SkynautsBouken'

      # ゲームシステム名
      NAME = '歯車の塔の探空士（冒険企画局）'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はくるまのとうのすかいのおつ2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定（nSNt#f） n:ダイス数(省略時2)、t:目標値(省略時7)、f:ファンブル値(省略時1)
            例）SN6#2　3SN
        ・ダメージチェック (Dx/y@m) x:ダメージ範囲、y:攻撃回数
        　　m:《弾道学》（省略可）上:8、下:2、左:4、右:6
        　　例） D/4　D19/2　D/3@8　D[大揺れ]/2
        ・回避(AVO@mダメージ)
        　　m:回避方向（上:8、下:2、左:4、右:6）、ダメージ：ダメージチェック結果
        　　例）AVO@8[1,4],[2,6],[3,8]　AVO@2[6,4],[2,6]
        ・FT ファンブル表(p76)
        ・NV 航行表

        ⬛ 判定セット
        ・《回避運動》判定+回避（nSNt#f/AVO@ダメージ）
        　　nSNt#f → 成功なら AVO@m
        　　例）SN/AVO@8[1,4],[2,6],[3,8]　3SN#2/AVO@2[6,4],[2,6]
        ・砲撃判定+ダメージチェック　(nSNt#f/Dx/y@m)
        　　行為判定の出目変更タイミングを逃すので要GMの許可
        　　nSNt#f → 成功なら Dx/y@m
        　　例）SN/D/4　3SN#2/D[大揺れ]/2
      MESSAGETEXT

      TABLES = {
        'FT' => DiceTable::Table.new(
          'ファンブル表',
          '1D6', [
            "なんとか大事にはいたらなかった。通常の失敗と同様の処理を行うこと。",
            "転んでしまった。キミは[転倒](p107)する。",
            "失敗にイライラしてしまった。キミた獲得している【キズナ】1つの「支援チェック」にチェックを入れる。",
            "自身のいるマスを[破損](p104)させる。この[破損]によって、キミの【生命点】は減少しない。",
            "頭をぶつけてしまった。キミの【生命点】を「1d6点」減少する。",
            "奇跡的な結果。 この行為判定は成功となる。",
          ]
        ),
        'NV' => DiceTable::Table.new(
          '航海表',
          '1d6',
          [
            'スポット1つ分進む',
            'スポット1つ分進む',
            'スポット1つ分進む',
            'スポット2つ分進む',
            'スポット2つ分進む',
            'スポット3つ分進む',
          ]
        )
      }.freeze

      DIRECTION_INFOS = {
        0 => {name: "", position_diff: [0, 0]},
        1 => {name: "左下", position_diff: [-1, +1]},
        2 => {name: "下", position_diff:  [0, +1]},
        3 => {name: "右下", position_diff: [+1, +1]},
        4 => {name: "左", position_diff: [-1, 0]},
        5 => {name: "", position_diff: [0, 0]},
        6 => {name: "右", position_diff: [+1, 0]},
        7 => {name: "左上", position_diff: [-1, -1]},
        8 => {name: "上", position_diff:  [0, -1]},
        9 => {name: "右上", position_diff: [+1, -1]},
      }.freeze

      D_REGEXP = %r{^D([12346789]{0,8})(\[.+\]|S|F|SF|FS)?/(\d{1,2})(@([2468]))?$}.freeze

      register_prefix('D', '2D6<=', '\d?SN', 'NV', '\d?AVO', 'BOM')

      def initialize(command)
        super(command)
        @round_type = RoundType::FLOOR # 端数切り捨て
      end

      def eval_game_system_specific_command(command)
        command_sn(command) || command_d(command) || command_avo(command) || command_snavo(command) ||
          command_snd(command) || roll_tables(command, TABLES)
      end

      def command_sn(command)
        debug("SN", command)
        cmd = Command::Parser.new(/[1-9]?SN(\d{0,2})/, round_type: round_type)
                             .restrict_cmp_op_to(nil)
                             .enable_fumble.enable_critical.parse(command)
        return nil unless cmd

        # [dice_count]SN[target]
        dice_count, target = cmd.command.split("SN", 2).map(&:to_i)
        dice_count = 2 if dice_count == 0
        target = 7 if target == 0
        fumble = cmd.fumble.nil? ? 1 : cmd.fumble

        debug("SN Parsed", dice_count, target, fumble)

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        dice_largest = dice_list.sort[-2..-1]
        res = if dice_largest == [6, 6]
                Result.critical("スペシャル（【生命点】1d6回復）")
              elsif dice_list.max <= fumble
                Result.fumble("ファンブル（ファンブル表FT）")
              elsif dice_largest.sum >= target
                Result.success("成功")
              else
                Result.failure("失敗")
              end
        res.text = ["#{dice_count}SN#{target}##{fumble}", dice_list.to_s, "#{dice_largest.sum}#{dice_largest}", res.text]
                   .compact.join(" ＞ ")
        res
      end

      def command_d(command)
        m = D_REGEXP.match(command)
        return nil unless m

        fire_count = m[3].to_i # 砲撃回数
        fire_range = m[1].to_s # 砲撃範囲
        ballistics = m[5].to_i # 《弾道学》

        points = get_fire_points(fire_count, fire_range)
        command = command.sub("SF/", "[大揺れ,火災]/").sub("FS/", "[火災,大揺れ]/").sub("F/", "[火災]/").sub("S/", "[大揺れ]/")
        result = [command, get_points_text(points, 0, 0)]
        if ballistics != 0
          dir = DIRECTION_INFOS[ballistics]
          diff_x, diff_y = dir[:position_diff]
          result << "\《弾道学》" + dir[:name]
          result << get_points_text(points, diff_x, diff_y)
        end

        result.compact.join(" ＞ ")
      end

      def command_avo(command)
        debug("AVO", command)
        dmg = command.match(/^AVO@([2468])(.*?)$/)
        return nil unless dmg

        dir = DIRECTION_INFOS[dmg[1].to_i]
        diff_x, diff_y = dir[:position_diff]
        "《回避運動》#{dir[:name]} ＞ " + dmg[2].gsub(/\(?\[(\d),(\d{1,2})\]\)?/) do
          y = Regexp.last_match(1).to_i + diff_y
          x = Regexp.last_match(2).to_i + diff_x
          get_xy_text(x, y)
        end
      end

      def command_snavo(command)
        sn, avo = command.split(%r{/?AVO}, 2)
        debug("SNAVO", sn, avo)
        am = /^@([2468])(.*?)$/.match(avo)
        return nil unless am

        res = command_sn(sn)
        return nil unless res

        if res.success?
          res.text += "\n ＞ AVO#{avo}\n ＞ " + command_avo("AVO" + avo)
        end
        res
      end

      def command_snd(command)
        sn, d = command.split(%r{/?D}, 2)
        debug("SND", sn, d)
        m = D_REGEXP.match("D" + d)
        return nil unless m

        res = command_sn(sn)
        return nil unless res

        if res.success?
          res.text += " ＞ #{command_d('D' + d)}"
        end
        res
      end

      def get_points_text(points, diff_x, diff_y)
        "[縦,横]=" + points.map do |list|
          list.map do |x, y|
            get_xy_text(x + diff_x, y + diff_y)
          end.join()
        end.join(",")
      end

      # 範囲内なら[y,x]、範囲外なら([y,x])と表示
      def get_xy_text(x, y)
        if (2..12).include?(x) && (1..6).include?(y)
          "[#{y},#{x}]"
        else
          "([#{y},#{x}])"
        end
      end

      # 命中場所と範囲から、ダメージ位置を割り出す
      def get_fire_points(fire_count, fire_range)
        range = fire_range.chars.map(&:to_i)
        fire_count.times.map do
          y = @randomizer.roll_once(6) # 縦
          x = @randomizer.roll_sum(2, 6) # 横

          [[x, y]] + range.map do |r|
            xdiff, ydiff = DIRECTION_INFOS[r][:position_diff]
            [x + xdiff, y + ydiff]
          end
        end
      end
    end
  end
end
