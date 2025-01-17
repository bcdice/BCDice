# frozen_string_literal: true

require "bcdice/game_system/one_way_heroics/tables"
require "bcdice/game_system/one_way_heroics/dungeon_table"
require "bcdice/game_system/one_way_heroics/random_event_table"

module BCDice
  module GameSystem
    class OneWayHeroics < Base
      # ゲームシステムの識別子
      ID = 'OneWayHeroics'

      # ゲームシステム名
      NAME = '片道勇者TRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かたみちゆうしやTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定　aJDx+y,z
        　a:ダイス数（省略時2個)、x:能力値、
        　y:修正値（省略可。「＋」のみなら＋１）、z:目標値（省略可）
        　例１）JD2+1,8 or JD2+,8　：能力値２、修正＋１、目標値８
        　例２）JD3,10 能力値３、修正なし、目標値10
        　例３）3JD4+ ダイス3個から2個選択、能力値４、修正なし、目標値なし
        ・ファンブル表 FT／魔王追撃表   DC／進行ルート表 PR／会話テーマ表 TT
        逃走判定表   EC／ランダムNPC特徴表 RNPC／偵察表 SCT
        施設表　FCLT／施設表プラス　FCLTP／希少動物表 RANI／王特徴表プラス KNGFTP
        野外遭遇表 OUTENC／野外遭遇表プラス OUTENCP
        モンスター特徴表 MONFT／モンスター特徴表プラス MONFTP
        ドロップアイテム表 DROP／ドロップアイテム表プラス DROPP
        武器ドロップ表 DROPWP／武器ドロップ表2 DROPWP2
        防具ドロップ表 DROPAR／防具ドロップ表2 DROPAR2
        聖武具ドロップ表 DROPHW／聖武具ドロップ表プラス DROPHWP
        食品ドロップ表 DROPFD／食品ドロップ表2 DROPFD2
        巻物ドロップ表 DROPSC／巻物ドロップ表2 DROPSC2
        その他ドロップ表 DROPOT／その他 ドロップ表2 DROPOT2
        薬品ドロップ表プラス DROPDRP／珍しい箱ドロップ表2 DROPRAREBOX2
        ・ランダムイベント表 RETx（x：現在の日数）、ランダムイベント表プラス RETPx
        　例）RET3、RETP4
        ・ダンジョン表 DNGNx（x：現在の日数）、ダンジョン表プラス DNGNPx
        　例）DNGN3、DNGNP4
      MESSAGETEXT

      def initialize(command)
        super(command)
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        case command
        when /^RET(\d+)$/
          day = Regexp.last_match(1).to_i
          RANDOM_EVENT_TABLE.roll_with_day(day, @randomizer)
        when /^RETP(\d+)$/
          day = Regexp.last_match(1).to_i
          RANDOM_EVENT_TABLE_PLUS.roll_with_day(day, @randomizer)
        when /^DNGN(\d+)$/
          day = Regexp.last_match(1).to_i
          DUNGEON_TABLE.roll_with_day(day, @randomizer)
        when /^DNGNP(\d+)$/
          day = Regexp.last_match(1).to_i
          DUNGEON_TABLE_PLUS.roll_with_day(day, @randomizer)
        when /^\d*JD/
          getRollDiceCommandResult(command)
        else
          roll_tables(command, TABLES)
        end
      end

      def getRollDiceCommandResult(command)
        return nil unless command =~ /^(\d*)JD(\d*)(\+(\d*))?(,(\d+))?$/

        diceCount = Regexp.last_match(1)
        diceCount = 2 if diceCount.empty?
        diceCount = diceCount.to_i
        return nil if diceCount < 2

        ability = Regexp.last_match(2).to_i
        target = Regexp.last_match(6)
        target = target.to_i unless target.nil?

        modifyText = Regexp.last_match(3) || ""
        modifyText = "+1" if modifyText == "+"
        modifyValue = modifyText.to_i

        dice, diceText = rollJudgeDice(diceCount)
        total = dice + ability + modifyValue

        text = command.to_s
        text += " ＞ #{diceCount}D6[#{diceText}]+#{ability}#{modifyText}"
        text += " ＞ #{total}"

        result = getJudgeReusltText(dice, total, target)
        text += " ＞ #{result}" unless result.empty?

        return text
      end

      def rollJudgeDice(diceCount)
        diceList = @randomizer.roll_barabara(diceCount, 6)
        dice = diceList.sum()
        diceText = diceList.join(",")

        if diceCount == 2
          return dice, diceText
        end

        diceList.sort!
        diceList.reverse!

        total = diceList[0] + diceList[1]
        text = "#{diceText}→#{diceList[0]},#{diceList[1]}"

        return total, text
      end

      def getJudgeReusltText(dice, total, target)
        return "ファンブル" if dice == 2
        return "スペシャル" if dice == 12

        return "" if target.nil?

        return "成功" if total >= target

        return "失敗"
      end

      register_prefix('\d*JD', 'RETP?', 'DNGNP?', TABLES.keys)
    end
  end
end
