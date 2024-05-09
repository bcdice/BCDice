# frozen_string_literal: true

require "bcdice/base"

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
        ・航行イベント表
        　・NEN 航行系
        　・NEE 遭遇系
        　・NEO 船内系
        　・NEH 困難系
        　・NEL 長旅系

        ■ 判定セット
        ・《回避運動》判定+回避（nSNt#f/AVO@ダメージ）
        　　nSNt#f → 成功なら AVO@m
        　　例）SN/AVO@8[1,4],[2,6],[3,8]　3SN#2/AVO@2[6,4],[2,6]
        ・砲撃判定+ダメージチェック　(nSNt#f/Dx/y@m)
        　　行為判定の出目変更タイミングを逃すので要GMの許可
        　　nSNt#f → 成功なら Dx/y@m
        　　例）SN/D/4　3SN#2/D[大揺れ]/2
      MESSAGETEXT

      class << self
        private

        def translate_direction_infos(locale)
          {
            0 => {name: "", position_diff: [0, 0]},
            1 => {name: I18n.translate('SkynautsBouken.directions.lower_left', locale: locale, raise: true), position_diff: [-1, +1]},
            2 => {name: I18n.translate('SkynautsBouken.directions.lower', locale: locale, raise: true), position_diff: [0, +1]},
            3 => {name: I18n.translate('SkynautsBouken.directions.lower_right', locale: locale, raise: true), position_diff: [+1, +1]},
            4 => {name: I18n.translate('SkynautsBouken.directions.left', locale: locale, raise: true), position_diff: [-1, 0]},
            5 => {name: "", position_diff: [0, 0]},
            6 => {name: I18n.translate('SkynautsBouken.directions.right', locale: locale, raise: true), position_diff: [+1, 0]},
            7 => {name: I18n.translate('SkynautsBouken.directions.upper_left', locale: locale, raise: true), position_diff: [-1, -1]},
            8 => {name: I18n.translate('SkynautsBouken.directions.upper', locale: locale, raise: true), position_diff: [0, -1]},
            9 => {name: I18n.translate('SkynautsBouken.directions.upper_right', locale: locale, raise: true), position_diff: [+1, -1]},
          }.freeze
        end

        def translate_tables(locale)
          {
            'FT' => DiceTable::Table.from_i18n('SkynautsBouken.FumbleTable', locale),
            'NV' => DiceTable::Table.from_i18n('SkynautsBouken.VoyageTable', locale),
            "NEN" => DiceTable::Table.from_i18n('SkynautsBouken.NavigationEventNavigationTable', locale),
            "NEE" => DiceTable::Table.from_i18n('SkynautsBouken.NavigationEventEncounterTable', locale),
            "NEO" => DiceTable::Table.from_i18n('SkynautsBouken.NavigationEventOnBoardTable', locale),
            "NEH" => DiceTable::Table.from_i18n('SkynautsBouken.NavigationEventHardTable', locale),
            "NEL" => DiceTable::Table.from_i18n('SkynautsBouken.NavigationEventLongJourneyTable', locale),
          }.freeze
        end
      end

      TABLES = translate_tables(@locale)

      register_prefix('D', '\d?SN', 'AVO', TABLES.keys)

      def initialize(command)
        super(command)
        @round_type = RoundType::FLOOR # 端数切り捨て
      end

      def eval_game_system_specific_command(command)
        command_sn(command) || command_d(command) || command_avo(command) || command_snavo(command) ||
          command_snd(command) || roll_tables(command, TABLES)
      end

      private

      DIRECTION_INFOS = translate_direction_infos(@locale)

      D_REGEXP = %r{^D([1-46-9]{0,8})(\[.+\]|S|F|SF|FS)?/(\d{1,2})(@([2468]))?$}.freeze

      def command_sn(command)
        debug("SN", command)
        cmd = Command::Parser.new(/[1-9]?SN(\d{0,2})/, round_type: round_type)
                             .restrict_cmp_op_to(nil)
                             .enable_fumble.parse(command)
        return nil unless cmd

        # [dice_count]SN[target]
        dice_count, target = cmd.command.split("SN", 2).map(&:to_i)
        dice_count = 2 if dice_count == 0
        target = 7 if target == 0
        fumble = cmd.fumble.nil? ? 1 : cmd.fumble

        debug("SN Parsed", dice_count, target, fumble)

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        dice_top_two = dice_list.sort[-2..-1]
        res = if dice_top_two == [6, 6]
                Result.critical(translate('SkynautsBouken.special'))
              elsif dice_list.max <= fumble
                Result.fumble(translate('SkynautsBouken.fumble'))
              elsif dice_top_two.sum >= target
                Result.success(translate('success'))
              else
                Result.failure(translate('failure'))
              end

        if dice_count == 2
          res.text = ["(#{dice_count}SN#{target}##{fumble})", "#{dice_top_two.sum}[#{dice_list.join(',')}]", res.text]
                     .compact.join(" ＞ ")
        else
          res.text = ["(#{dice_count}SN#{target}##{fumble})", "[" + dice_list.join(",") + "]", "#{dice_top_two.sum}[#{dice_top_two.join(',')}]", res.text]
                     .compact.join(" ＞ ")
        end
        res
      end

      def command_d(command)
        m = D_REGEXP.match(command)
        return nil unless m

        fire_count = m[3].to_i # 砲撃回数
        fire_range = m[1].to_s # 砲撃範囲
        ballistics = m[5].to_i # 《弾道学》

        points = get_fire_points(fire_count, fire_range)
        command = command.sub("SF/", "[#{translate('SkynautsBouken.big_shake')},#{translate('SkynautsBouken.fire')}]/")
                         .sub("FS/", "[#{translate('SkynautsBouken.fire')},#{translate('SkynautsBouken.big_shake')}]/")
                         .sub("F/", "[#{translate('SkynautsBouken.fire')}]/").sub("S/", "[#{translate('SkynautsBouken.big_shake')}]/")
        result = ["(#{command})", get_points_text(points, 0, 0)]
        if ballistics != 0
          dir = DIRECTION_INFOS[ballistics]
          diff_x, diff_y = dir[:position_diff]
          result[-1] += "\n"
          result << "《#{translate('SkynautsBouken.ballistics')}》#{dir[:name]}"
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
        "《#{translate('SkynautsBouken.avoidance')}》#{dir[:name]} ＞ " + dmg[2].gsub(/\(?\[(\d),(\d{1,2})\]\)?/) do
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
          res.text += "\n ＞ " + command_avo("AVO" + avo)
        end
        res
      end

      def command_snd(command)
        sn, d = command.split(%r{/?D}, 2)
        debug("SND", sn, d)
        m = D_REGEXP.match("D#{d}")
        return nil unless m

        res = command_sn(sn)
        return nil unless res

        if res.success?
          res.text += "\n ＞ #{command_d('D' + d)}"
        end
        res
      end

      def get_points_text(points, diff_x, diff_y)
        "[#{translate('SkynautsBouken.y')},#{translate('SkynautsBouken.x')}]=" + points.map do |list|
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
