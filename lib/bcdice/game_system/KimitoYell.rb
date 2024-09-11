# frozen_string_literal: true

module BCDice
  module GameSystem
    class KimitoYell < Base
      # ゲームシステムの識別子
      ID = "KimitoYell"

      # ゲームシステム名
      NAME = "キミトエール！"

      # ゲームシステム名の読みがな
      SORT_KEY = "きみとええる"

      HELP_MESSAGE = <<~TEXT
              ■　判定 （nKY6 / nKY10）
                指定された能力値分（n個）のダイスを使って判定を行います。
        #{'  '}
          nKY6…「有利」を得ていない場合、6面ダイスをn個振って判定します。
          nKY10…「有利」を得ている場合、10面ダイスをn個振って判定します。
        #{'  '}
          6もしくは10の出目があればスペシャル。1の出目があればファンブル。
          スペシャルとファンブルは同時に発生した場合、両方の処理を行う。

        ■　表
        - ファンブル表（FT）
          ファンブル時の処理を決定します。
        #{'  '}
        - 新しい出会い表（）
        　　- 偶然出会った表（）
        　　- 交流のなかった身近な人表（）
        　　- 助けてくれた人表（）
        　　- どんな人だったか表（）
        　　- 変わった人だった表（）
          大切な世界フェイズの新しい出会いを求めるときに使用する表を振ります。
          新しい出会い表（コマンド）を使用した場合、その後の表も同時に振ります。
      TEXT

      register_prefix('\d+KY(6|10)')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
        @round_type = RoundType::CEIL
      end

      def eval_game_system_specific_command(command)
        return roll_ky_judge(command)
      end

      private

      def roll_ky_judge(command)
        # m[1]にダイス数、m[2]に6/10面がはいる
        m = /^(\d+)KY(6|10)$/.match(command)

        unless m
          return nil
        end

        # d6、d10の設定
        n_of_diceside = m[2].to_i == 10 ? 10 : 6

        # 振るさいころの数
        n_of_rolldice = m[1].to_i

        # 成功となる出目
        success_dices = [4, 5, 6, 7, 8, 9, 10]

        # スペシャルとなる出目
        special_dices = [6, 10]

        # ファンブルとなる出目
        fumble_dices = [1]

        # 各種テキストとResultに持っていくための初期値
        txt_special = "スペシャル（がんばりが1点上昇！）"
        txt_fumble = "ファンブル（ファンブル表：FTを振る）"
        txt_success = "成功"
        txt_failure = "失敗"

        result_txts = []
        is_critical = false
        is_fumble = false
        is_success = false
        is_failure = false

        # ダイスを振る
        dice_list = @randomizer.roll_barabara(n_of_rolldice, n_of_diceside)

        # 結果チェック
        is_critical = dice_list.intersection(special_dices).empty? ? false : true
        is_fumble = dice_list.intersection(fumble_dices).empty? ?  false : true
        is_success = dice_list.intersection(success_dices).empty? ?  false : true
        is_failure = dice_list.intersection(success_dices).empty? ?  true : false

        # 結果用テキストの生成
        if is_success == true
          result_txts.push(txt_success)
        end

        if is_failure == true
          result_txts.push(txt_failure)
        end

        if is_critical == true
          result_txts.push(txt_special)
        end

        if is_fumble == true
          result_txts.push(txt_fumble)
        end

        return Result.new.tap do |r|
          # 最終的に表示するテキスト
          r.text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{result_txts.join('・')}"

          # 各種パラメータ
          r.success = is_success
          r.failure = is_failure
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end
    end
  end
end
