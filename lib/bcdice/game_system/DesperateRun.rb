# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class DesperateRun < Base
      # ゲームシステムの識別子
      ID = "DesperateRun"

      # ゲームシステム名
      NAME = "Desperate Run TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "てすへれいとらんTRPG"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・難易度算出コマンド　DDC
        ・判定コマンド　RCx　or　RCx+y　or　RCx-y（x＝難易度、y=修正値（省略可能））
        ・アクシデント表　ACT
        ・初期アイテム表　ITEMT
        ・動機表　DOUKIT
        ・死亡フラグ台詞表　FLAGT
        ・途中参加動機表　ENTRYT
        ・途中参加道中表　ROADT
      INFO_MESSAGE_TEXT

      TABLES = {
        "ACT" => DiceTable::Table.new(
          "アクシデント表",
          "1D6", [
            "ＰＣ全員、隊列を１Ｄ６で決める（１２：前列、３４：中列、５６：後列）",
            "１ターン、モンスター側のみ行動する。",
            "この戦闘の行動順が、ＰＣ→モンスター、から、モンスター→ＰＣに変わる。",
            "ＰＣ全員、アイテム１つを選んで失う。",
            "ＰＣ全員１Ｄ６を振る。この戦闘中、その出目はノープランになる。",
            "ＰＣ全員、Ｆｌａｇが１増加する。"
          ]
        ),
        "ITEMT" => DiceTable::Table.new(
          "初期アイテム表",
          "2D6", [
            "ロケットランチャー　効果：（装備）マカブルＬｖ＋３　回数：攻撃１回",
            "キーピック　効果：（消費）ムーブシーンで使用可。判定の出目の合計＋１　回数：２回",
            "レーダー　効果：（装備）ノープラン　装備時、「危険」を１減らすことが出来る　回数：危険減少２回",
            "食料　効果：（消費）ムーブシーンで使用可。Ｌｉｆｅ３回復　回数：１回",
            "応急キット　効果：（装備）メディカルＬｖ＋１　回数：回復３回",
            "刃物　効果：（装備）アタックＬｖ＋１　回数：攻撃６回",
            "銃　効果：（装備）シュートＬｖ＋１　回数：攻撃６回",
            "ドラッグ　効果：（消費）いつでも使用可。Ｂｒａｖｅ１回復　回数：１回",
            "金券　効果：（消費）アフタープレイで使用可。経験点＋２　回数：１回",
            "プロテクター　効果：（装備）ガードＬｖ＋１　回数：防御５回",
            "トミーガン　効果：（装備）チェーンＬｖ＋５　回数：攻撃１回"
          ]
        ),
        "DOUKIT" => DiceTable::Table.new(
          "動機表",
          "1D6", [
            "隷属。何か弱みに付け込まれ、嫌々ながらも参加することとなる。後ろめたい事、借金、など。",
            "献身。この番組は誰かのために出ている。病気の家族を救うため、参加者の一人が恋人である、など。",
            "成行。望んでいないのに参加することとなってしまった。誰かが勝手に申し込んだ、紛れ込んでしまった、など。",
            "渇望。とにかく何かを欲して参加している。金、スリル、金で手に入るもの、など。",
            "奇人。好き好んでこの番組に出ている。殺人癖、ナルシスト、自殺願望、化け物マニア、など。",
            "仕事。この番組に出るのは仕事だからだ。賞金稼ぎ、芸能人、記者、番組スタッフ、など。"
          ]
        ),
        "FLAGT" => DiceTable::Table.new(
          "死亡フラグ台詞表",
          "1D6", [
            "希望。「これが終わったら、一緒に酒でも飲もうや」「もう何も怖くない」など。",
            "望郷。「くそっ、、、俺には、帰りを待つ人が、、、っ！」「ああ、故郷のマルゲリータをもう一度食べたかった、、、」など。",
            "狂乱。「お前を、殺せば、俺は、億万長者なんだよぉぉぉお！！」「ヒハッ、死ね死ね死ね死ねぇぇぇぇ」など。",
            "絶望。「もうだめだぁ、、、おしまいだぁ、、、」「く、くるなっ、くるなぁぁぁぁ！！」など。",
            "慢心。「なんだ、こんなやつ、俺だけで十分だ」「大丈夫だ、問題ない」など。",
            "犠牲。「ふふ、俺なら大丈夫だ、、、気にするな」「お前ら下がれっ！ここは俺に任せろ！」など。"
          ]
        ),
        "ENTRYT" => DiceTable::Table.new(
          "途中参加動機表",
          "1D6", [
            "遅刻。もともと参加する予定だったのだが遅れてしまった。今からでも走れと無理矢理参加。",
            "現住。もともとここに住んでいた。何？番組？え？あ、お金もらえんの？イイネ！",
            "突発。もともと視聴者としてスタジオに居たんだけど、司会にうまく乗せられて・・・",
            "乱入。何か目的があって乱入した。今回のステージが簡単に見えたり、参加者に大事な人がいたのかもしれない。",
            "神隠。今回より前の番組に参加していたが行方不明・死んだと思われていた。が。君はまだここにいる。",
            "職員。あれ、逃げ遅れました？あらあら、大変ですね、しょうがないから参加者さんと一緒に走ってください。"
          ]
        ),
        "ROADT" => DiceTable::Table.new(
          "途中参加道中表",
          "1D6", [
            "死線。死ぬかと思った。Ｆｌａｇ＋１",
            "怪我。痛い。Ｌｉｆｅ－１",
            "失意。どうしてこうなった。Ｂｒａｖｅ－１。減らせない場合、Ｆｌａｇ＋１",
            "紛失。どっかいった。Ｉｔｅｍをどれか１つ捨てる。捨てれない場合、Ｆｌａｇ＋１",
            "追尾。後ろ！後ろーっ！参加開始部屋の危険＋１",
            "迷子。あれ、ここどこだ？途中参加道中表を振る回数＋２"
          ]
        )
      }.freeze

      register_prefix('RC\d+', 'DDC', TABLES.keys)

      def initialize(command)
        super(command)
        @sortType = true
        @d66_sort_type = D66SortType::ASC
      end

      private

      def eval_game_system_specific_command(command)
        check_roll(command) || ddc_table(command) || roll_tables(command, self.class::TABLES)
      end

      def check_roll(string)
        parser = Command::Parser.new(/RC\d+/, round_type: round_type)
                                .restrict_cmp_op_to(nil)
        cmd = parser.parse(string)
        return nil unless cmd

        target = cmd.command[2..-1].to_i

        result = "判定　難易度：#{target}　"
        if cmd.modify_number != 0
          result += "修正値：#{cmd.modify_number}　"
        end

        d1, d2 = @randomizer.roll_barabara(2, 6)
        dice_total = d1 + d2
        total = d1 + d2 + cmd.modify_number

        result += "＞　出目：#{d1}、#{d2}　＞　"

        result +=
          if d1 == d2
            "ゾロ目！【Ｃｒｉｔｉｃａｌ】"
          elsif dice_total == 7
            "ダイスの出目が表裏！【Ｆｕｍｂｌｅ】"
          elsif total >= target
            "#{total}、難易度以上！【Ｓｕｃｃｅｓｓ】"
          else
            "#{total}、難易度未満！【Ｍｉｓｓ】"
          end

        return result
      end

      def ddc_table(command)
        return nil if command != "DDC"

        d1, d2 = @randomizer.roll_barabara(2, 6)

        smaller, larger = [d1, d2].sort
        difference = larger - smaller

        "難易度決定：　出目：#{d1}、#{d2}　＞　#{larger}－#{smaller}＝#{difference}　＞　難易度#{5 + difference}"
      end
    end
  end
end
