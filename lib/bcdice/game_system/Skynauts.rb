# frozen_string_literal: true

module BCDice
  module GameSystem
    class Skynauts < Base
      # ゲームシステムの識別子
      ID = 'Skynauts'

      # ゲームシステム名
      NAME = '歯車の塔の探空士（六畳間幻想空間）'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はくるまのとうのすかいのおつ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ◆判定　(SNn)、(2D6<=n)　n:目標値（省略時:7）
        　例）SN5　SN5　SN(3+2)
        ◆航行チェック　(NV+n)　n:修正値（省略時:0）
        　例）NV　NV+1
        ◆ダメージチェック　(Dx/y@m)　x:ダメージ左側の値、y:ダメージ右側の値
        　m:《弾道学》（省略可）上:8、下:2、左:4、右:6
        　飛空艇シート外の座標は()が付きます。
        　例） D/4　D19/2　D/3@8　D[大揺れ]/2
        ◆砲撃判定+ダメージチェック　(BOMn/Dx/y@m)　n:目標値（省略時:7）
        　x:ダメージ左側の値、y:ダメージ右側の値
        　m:《弾道学》（省略可）上:8、下:2、左:4、右:6
        　例） BOM/D/4　BOM9/D19/2@4
        ◆《回避運動》　(AVOn@mXX)　n:目標値（省略時:7）
        　m:回避方向。上:8、下:2、左:4、右:6、XX：ダメージチェック結果
        　例）
        　AVO9@8[縦1,横4],[縦2,横6],[縦3,横8]　AVO@2[縦6,横4],[縦2,横6]
      MESSAGETEXT

      register_prefix('D', '2D6<=', 'SN', 'NV', 'AVO', 'BOM')

      def initialize(command)
        super(command)
        @round_type = RoundType::FLOOR # 端数切り捨て
      end

      def eval_game_system_specific_command(command)
        debug("\n=======================================\n")
        debug("eval_game_system_specific_command command", command)

        return get_judge_result(command) || navigation_result(command) || get_fire_result(command) ||
               get_bomb_result(command) || get_avoid_result(command)
      end

      private

      def get_judge_result(command)
        return nil unless (m = /^2D6<=(\d)$/i.match(command) || /^SN(\d*)$/i.match(command))

        debug("====get_judge_result====")

        target = m[1].empty? ? 7 : m[1].to_i # 目標値。省略時は7
        debug("目標値", target)

        dice_list = @randomizer.roll_barabara(2, 6)
        total = dice_list.sum()
        text = "(2D6<=#{target}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{total}"
        if total <= 2
          Result.fumble(text + " ＞ ファンブル")
        elsif total <= target
          Result.success(text + " ＞ 成功")
        else
          Result.failure(text + " ＞ 失敗")
        end
      end

      def navigation_result(command)
        return nil unless (m = /^NV(\+(\d+))?$/.match(command))

        debug("====navigation_result====")

        bonus = m[2].to_i # 〈操舵室〉の修正。GMの任意修正にも対応できるように(マイナスは無視)
        debug("移動修正", bonus)

        total = @randomizer.roll_once(6)
        move_point_base = (total / 2) <= 0 ? 1 : (total / 2)
        movePoint = move_point_base + bonus
        debug("移動エリア数", movePoint)

        Result.new("航行チェック(最低1)　(1D6/2+#{bonus}) ＞ #{total} /2+#{bonus} ＞ #{move_point_base}+#{bonus} ＞ #{movePoint}エリア進む")
      end

      DIRECTION_INFOS = {
        1 => {name: "左下", position_diff: {x: -1, y: +1}},
        2 => {name: "下", position_diff: {x: 0, y: +1}},
        3 => {name: "右下", position_diff: {x: +1, y: +1}},
        4 => {name: "左",   position_diff: {x: -1, y: 0}},
        # 5 は中央。算出する意味がないので対象外
        6 => {name: "右",   position_diff: {x: +1, y: 0}},
        7 => {name: "左上", position_diff: {x: -1, y: -1}},
        8 => {name: "上", position_diff: {x: 0, y: -1}},
        9 => {name: "右上", position_diff: {x: +1, y: -1}},
      }.freeze

      def get_direction_info(direction, key, default_value = nil)
        info = DIRECTION_INFOS[direction.to_i]
        return default_value if info.nil?

        return info[key]
      end

      def get_fire_result(command)
        return nil unless (m = %r{^D([12346789]*)(\[.+\])*/(\d{1,2})(@([2468]))?$}.match(command))

        debug("====get_fire_result====")

        fire_count = m[3].to_i # 砲撃回数
        fire_range = m[1].to_s # 砲撃範囲
        ballistics = m[5].to_i # 《弾道学》
        debug("fire_count", fire_count)
        debug("fire_range", fire_range)
        debug("ballistics", ballistics)

        fire_point = get_fire_point(fire_range, fire_count) # 着弾座標取得（3次元配列）
        result = [command, get_fire_point_text(fire_point, fire_count).text] # 表示用文字列作成

        if ballistics != 0 # 《弾道学》有
          result << "《弾道学》:#{get_direction_info(ballistics, :name, '')}\n"
          result << get_fire_point_text(fire_point, fire_count, ballistics).text
        end
        Result.new(result.join(" ＞ "))
      end

      def get_fire_point(fire_range, fire_count)
        debug("====get_fire_point====")

        fire_point = []

        fire_count.times do |count|
          debug("\n砲撃回数", count + 1)

          fire_point << []

          y_pos = @randomizer.roll_once(6) # 縦
          x_pos = @randomizer.roll_sum(2, 6) # 横
          position = [x_pos, y_pos]

          fire_point[-1] << position

          debug("着弾点", fire_point)

          fire_range.chars do |range_text|
            debug("範囲", range_text)

            position_diff = get_direction_info(range_text, :position_diff, {})
            position = [x_pos + position_diff[:x].to_i, y_pos + position_diff[:y].to_i]

            fire_point[-1] << position
            debug("着弾点:範囲", fire_point)
          end
        end

        debug("\n最終着弾点", fire_point)

        return fire_point
      end

      def get_fire_point_text(fire_point, _fire_count, direction = 0)
        debug("====get_fire_point_text====")

        fire_text_list = []
        fire_point.each do |point|
          text = ""
          point.each do |x, y|
            # 《弾道学》《回避運動》などによる座標移動
            x, y = get_move_point(x, y, direction)

            # マップ外の座標は括弧を付ける
            text += in_map_position?(x, y) ? "[縦#{y},横#{x}]" : "([縦#{y},横#{x}])"
            debug("着弾点テキスト", text)
          end

          fire_text_list << text
        end

        Result.new(fire_text_list.join(","))
      end

      def in_map_position?(x, y)
        ((1 <= y) && (y <= 6)) && ((2 <= x) && (x <= 12))
      end

      def get_move_point(x, y, direction)
        debug("====get_move_point====")
        debug("方向", direction)
        debug("座標移動前(x,y)", x, y)

        position_diff = get_direction_info(direction, :position_diff, {})
        x += position_diff[:x].to_i
        y += position_diff[:y].to_i

        debug("\n座標移動後(x,y)", x, y)
        return x, y
      end

      def get_bomb_result(command)
        return nil unless (m = %r{^BOM(\d*)?/D([12346789]*)(\[.+\])*/(\d+)(@([2468]))?$}i.match(command))

        debug("====get_bomb_result====", command)

        target = m[1].to_s
        direction = m[6].to_i
        debug("弾道学方向", direction)

        sn = get_judge_result("SN" + target) # 砲撃判定

        if sn.failure?
          sn.text = "#{command} ＞ #{sn.text}"
          return sn
        end

        # ダメージチェック部分
        fire_command = command.slice(%r{D([12346789]*)(\[.+\])*/(\d+)(@([2468]))?})
        sn.text = "#{command} ＞ #{sn.text}\n ＞ #{get_fire_result(fire_command).text}"
        sn
      end

      def get_avoid_result(command)
        return nil unless (m = /^AVO(\d*)?(@([2468]))(\(?\[縦\d+,横\d+\]\)?,?)+$/.match(command))

        debug("====get_avoid_result====", command)

        direction = m[3].to_i
        debug("回避方向", direction)

        judge_command = command.slice(/^AVO(\d*)?(@([2468]))/) # 判定部分
        sn = get_judge_result("SN" + Regexp.last_match(1).to_s)

        if sn.failure?
          sn.text = "#{judge_command} ＞ 《回避運動》#{sn.text}"
          return sn
        end
        point_command = command.slice(/(\(?\[縦\d+,横\d+\]\)?,?)+/) # 砲撃座標

        fire_point = scan_fire_point(point_command)
        fire_count = fire_point.size
        Result.success([
          judge_command,
          "《回避運動》#{sn.text}\n",
          point_command,
          "《回避運動》:" + get_direction_info(direction, :name, "") + "\n",
          get_fire_point_text(fire_point, fire_count, direction).text
        ].compact.join(" ＞ "))
      end

      def scan_fire_point(command)
        debug("====scan_fire_point====", command)

        command = command.gsub(/\(|\)/, "") # 正規表現が大変なので最初に括弧を外しておく

        fire_point = []

        # 一組ずつに分ける("[縦y,横xの単位)
        command.split(/\],/).each do |point_text|
          debug("point_text", point_text)

          fire_point << []

          # D以外の砲撃範囲がある時に必要
          point_text.split(/\]/).each do |point|
            debug("point", point)

            fire_point[-1] << []

            next unless point =~ /[^\d]*(\d+),[^\d]*(\d+)/

            y = Regexp.last_match(1).to_i
            x = Regexp.last_match(2).to_i

            fire_point[-1][-1] = [x, y]

            debug("着弾点", fire_point)
          end
        end

        return fire_point
      end
    end
  end
end
