# frozen_string_literal: true

require 'bcdice/dice_table/table'
require 'bcdice/dice_table/range_table'
require 'bcdice/arithmetic'

module BCDice
  module GameSystem
    class AnimaAnimus < Base
      # ゲームシステムの識別子
      ID = 'AnimaAnimus'

      # ゲームシステム名
      NAME = 'アニマアニムス'

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = 'あにまあにむす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定(xAN<=y±z)
        　十面ダイスをx個振って判定します。達成値が算出されます(クリティカル発生時は2増加)。
        　x：振るダイスの数。魂魄値や攻撃値。
        　y：成功値。
        　z：成功値への補正。省略可能。
        　(例) 2AN<=3+1 5AN<=7
        ・各種表
        　情報収集表　IGT/喪失表　LT
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        m = /(\d+)AN<=(\d+([+\-]\d+)*)/i.match(command)
        if TABLES.key?(command)
          return roll_tables(command, TABLES)
        elsif m
          return check_action(m)
        else
          return nil
        end
      end

      def check_action(match_data)
        dice_cnt = Arithmetic.eval(match_data[1], RoundType::FLOOR)
        target = Arithmetic.eval(match_data[2], RoundType::FLOOR)
        debug("dice_cnt", dice_cnt)
        debug("target", target)

        dice_arr = @randomizer.roll_barabara(dice_cnt, 10)
        dice_str = dice_arr.join(",")
        suc_cnt = dice_arr.count { |x| x <= target }
        has_critical = dice_arr.include?(1)
        result = has_critical ? suc_cnt + 2 : suc_cnt

        Result.new.tap do |r|
          r.text = "(#{dice_cnt}B10<=#{target}) ＞ #{dice_str} ＞ #{result > 0 ? '成功' : '失敗'}(達成値:#{result})#{has_critical ? ' (クリティカル発生)' : ''}"
          r.critical = has_critical
          r.success = result > 0
          r.failure = !r.success?
        end
      end

      TABLES = {
        'IGT' => DiceTable::Table.new(
          '情報収集表',
          '1d10',
          [
            'ストリートファイト/<格闘>/「俺に勝てたら教えてやるよ」情報を知る魂願者から勝負を挑まれた。生き延びるためにもこの勝負、負けるわけにはいかない。',
            '追跡！/<追跡／逃走>/有益な情報を持っている人間を見つけたが、こちらの顔を見るなり逃げ出した。どうにかして捕まえなくてはならない。',
            '脅し/<威圧>/ならず者たちが集まるバーにやってきた。裏社会に生きる彼らを脅せば有益な情報が手に入るはずだ。',
            'インターネット/<コンピュータ>/SNSやニュースなど、インターネット上の情報を調査する。デマには騙されないようにしなくては。',
            '瀕死の情報提供者/<医学>/情報を知る人物がいると聞いてやってきたら、その人物が瀕死の重傷を負っていた。なんとかして蘇生させなくては。',
            '潜入捜査/<隠密>/敵対する魂願者たちのグループに潜り込んでの調査活動。リスクは高いが、有益な情報が手に入る確率は高い。',
            '情報交換/<交渉>/友好的な関係にある魂願者との情報交換。うまく話を聞き出すことができるとよいが。',
            '魔宴の情報屋/<調達>/魔宴の情報屋に接触して情報を聞き出すことにした。一筋縄ではいかない相手らしいが、はたして……？',
            '違法調査/<犯罪>/法に触れるやり方で情報を集めることにした。ハッキング、窃盗、恐喝、どんな手段を選ぼうか。',
            '聞き込み/<自我>/街ゆく人びとに聞き込みを行なう。地道な活動こそが目標にたどり着くための最短の方法だ。',
          ]
        ),
        'LT' => DiceTable::RangeTable.new(
          '喪失表',
          '1d10',
          [
            [1..2, "存在/存在が希薄になり、知り合いや友人に自分の存在を忘れられてしまう。いずれ大切なパートナーの記憶からも消え、この世界でひとりぼっちになる。\nあなたの出自を消去すること。"],
            [3..4, "記憶/自分の大切な記憶をひとつ失なう。これからは力を使うたびに記憶をひとつ失なうことになり、最後には大切なパートナーのことも思い出せなくなってしまう。\nあなたのメモリアをひとつ選択して消去すること。シナリオメモリアは選択できない。"],
            [5..6, "容姿/だんだんと以前とはかけ離れた姿に変わっていく。いずれ誰も自分のことを自分だと気づかなくなるのだろう。\nあなたの特徴的な外見を失なう。内容をふさわしいものに書き換えること(特徴的な外見が美しい髪であれば醜い髪など)。"],
            [7..8, "感情/喜怒哀楽の感情のうち、いずれかひとつを失なう。力を使うたびに他の感情も失っていき、最後にはただ生き残るために戦う機械となる。\nポジティブかネガティブのどちらかを選択する。選択した感情をすべてのメモリアから消去する。消去した結果、表出感情がなくなってしまった場合、残った感情を表出感情にすること。なお、新しくメモリアを取得した場合も、選んだ感情を得ることはできない。"],
            [9..10, "五感/少しずつ五感が鈍くなる。今までできていたはずのことができなくなってしまう。\nあなたの特技をひとつ選択する。選択した特技に×をつけること。×が付いた技能で判定を行なうことはできず、判定を求められた場合は自動的に失敗となる。"],
          ]
        ),
      }.freeze

      # ダイスボットで使用するコマンドを配列で列挙する
      register_prefix('\d+AN<=', TABLES.keys)
    end
  end
end
