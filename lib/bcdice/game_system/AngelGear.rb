# frozen_string_literal: true

require "bcdice/dice_table/table"
require "bcdice/dice_table/d66_grid_table"
require "bcdice/arithmetic"

module BCDice
  module GameSystem
    class AngelGear < Base
      # ゲームシステムの識別子
      ID = 'AngelGear'

      # ゲームシステム名
      NAME = 'エンゼルギア 天使大戦TRPG The 2nd Editon'

      # ゲームシステム名の読みがな
      SORT_KEY = 'エンセルキア2'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定　nAG[s][±a]
        []内は省略可能。
        n:判定値
        s:技能値
        a:修正
        （例）
        12AG 10AG3±20

        ・感情表　ET
      MESSAGETEXT

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        if (m = /^(\d+)AG(\d+)?(([+\-]\d+)*)$/.match(command))
          resolute_action(m[1].to_i, m[2]&.to_i, m[3], command)
        else
          roll_tables(command, TABLES)
        end
      end

      def resolute_action(num_dice, skill_value, modify, command)
        dice = @randomizer.roll_barabara(num_dice, 6).sort
        dice_text = dice.join(",")
        modify_n = 0
        success = 0

        if skill_value
          success = dice.count { |val| val <= skill_value }
          modify_n = Arithmetic.eval(modify, RoundType::FLOOR) unless modify.empty?
        end

        output = "(#{command}) ＞ #{success}[#{dice_text}]#{format('%+d', modify_n)} ＞ 成功数: #{success + modify_n}"
        if success + modify_n >= 100
          output += "(福音発生)"
        end
        return output
      end

      TABLES = {
        'ET' => DiceTable::D66GridTable.new(
          '感情表',
          [
            [
              '好奇心（好奇心）',
              '憧れ（あこがれ）',
              '尊敬（そんけい）',
              '仲間意識（なかまいしき）',
              '母性愛（ぼせいあい）',
              '感心（かんしん）'
            ],
            [
              '純愛（じゅんあい）',
              '友情（ゆうじょう）',
              '同情（どうじょう）',
              '父性愛（ふせいあい）',
              '幸福感（こうふくかん）',
              '信頼（しんらい）'
            ],
            [
              '競争心（きょうそうしん）',
              '親近感（しんきんかん）',
              'まごころ',
              '好意（こうい）',
              '有為（ゆうい）',
              '崇拝（すうはい）'
            ],
            [
              '大嫌い（だいきらい）',
              '妬み（ねたみ）',
              '侮蔑（ぶべつ）',
              '腐れ縁（くされえん）',
              '恐怖（きょうふ）',
              '劣等感（れっとうかん）'
            ],
            [
              '偏愛（へんあい）',
              '寂しさ（さびしさ）',
              '憐憫（れんびん）',
              '闘争心（とうそうしん）',
              '食傷（しょくしょう）',
              '嘘つき（うそつき）'
            ],
            [
              '甘え（あまえ）',
              '苛立ち（いらだち）',
              '下心（したごころ）',
              '憎悪（ぞうお）',
              '疑惑（ぎわく）',
              '支配（しはい）'
            ],
          ]
        )
      }.freeze

      register_prefix('(\d+)AG(\d+)?(([\+\-]\d+)*)', TABLES.keys)
    end
  end
end
