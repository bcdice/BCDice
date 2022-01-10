# frozen_string_literal: true

module BCDice
  module GameSystem
    class GurpsFW
      class TableWithDifficulty
        # @param [String] name 表の名前
        # @param [String] type 項目を選ぶときのダイスロールの方法 '1D6'など
        # @param [Array<Entry>] items
        def initialize(name, type, items)
          @name = name
          @items = items.freeze

          m = /(\d+)D(\d+)/i.match(type)
          unless m
            raise ArgumentError, "Unexpected table type: #{type}"
          end

          @times = m[1].to_i
          @sides = m[2].to_i
        end

        # @param [Difficulty] difficulty
        # @param [BCDice::Randomizer] randomizer
        def roll(difficulty, randomizer)
          value = randomizer.roll_sum(@times, @sides)
          index = value - @times

          "#{@name}：#{difficulty}(#{value}) ＞ #{@items[index].format(difficulty)}"
        end

        class Entry
          # @param [String] format
          # @param [Array<Array<String>>] arg
          def initialize(format, *arg)
            @format = format
            @arg = arg
          end

          # @param [Difficulty] difficulty
          # @return [String]
          def format(difficulty)
            arg = @arg.map { |a| a[difficulty.index] }
            Kernel.format(@format, *arg)
          end
        end

        class Difficulty
          LEVEL = [
            :easy,
            :nomal,
            :hard,
            :nightmare,
          ].freeze

          LEVEL_TO_S = {
            easy: "初級",
            nomal: "中級",
            hard: "上級",
            nightmare: "悪夢",
          }.freeze

          FLAG_TO_LEVEL = {
            "E" => :easy,
            "N" => :nomal,
            "H" => :hard,
            "L" => :nightmare, # N がかぶるので、おそらく Lunatic の L
          }.freeze

          def self.from_flag(flag)
            Difficulty.new(FLAG_TO_LEVEL[flag])
          end

          def initialize(level)
            @level = level
            @level_index = LEVEL.index(level)
            raise ArgumentError unless @level_index
          end

          def to_s
            LEVEL_TO_S[@level]
          end

          def index
            @level_index
          end
        end
      end

      TRAP_TABLE = TableWithDifficulty.new(
        "トラップリスト",
        "3D6",
        [
          TableWithDifficulty::Entry.new("トライディザスター：宝箱から広範囲に火炎・冷気・電撃が放たれる。PC全員に火炎により%sの「叩き」ダメージ、冷気により%sの「叩き」ダメージ、電撃により%sの「叩き」ダメージを与える(電撃は金属鎧の防護点無視)", ["3D", "4D", "5D", "7D"], ["3D", "4D", "5D", "7D"], ["2D", "3D", "4D", "6D"]),
          TableWithDifficulty::Entry.new("ペトロブラスター：宝箱を開けたキャラクターに《肉を石》をかける。技能レベルは%s。", ["20", "22", "24", "30"]),
          TableWithDifficulty::Entry.new("クロスボウストーム：宝箱から矢の嵐が放たれる罠。PC全員に%sの「刺し」ダメージを与える。盾の受動防御を無視した「よけ%s」で回避が可能。", ["2D", "3D", "5D", "8D"], ["", "-2", "-4", "-8"]),
          TableWithDifficulty::Entry.new("フォーチュンイーター：PC全員の幸運を食らい、フォーチュンを%s減少させる。フォーチュンが0の場合%sの防護点無視ダメージを受ける。", ["1", "2", "3", "5"], ["3D", "6D", "9D", "15D"]),
          TableWithDifficulty::Entry.new("スロット：スロットが揃うまで開かない宝箱。スロットを1回まわすには%sGPが必要。行動を消費して「視覚%s」判定に成功すればスロットはそろう。「反射神経」があれば「視覚」そのままで判定可能。", ["100", "300", "500", "1000"], ["-5", "-7", "-9", "-13"]),
          TableWithDifficulty::Entry.new("テレポーター：宝箱の周囲に存在するPC全員(とエンカウントしているモンスター)をダンジョン入口方面に転送する。深度が%s。", ["3D減少する", "4D減少する", "5D減少する", "0になる"]),
          TableWithDifficulty::Entry.new("アイスコフィン：宝箱を開けようとしたキャラクターに冷気で%sの「叩き」ダメージを与え更に最終的なダメージの半分のFPダメージを与える。", ["3D", "5D", "7D", "12D"]),
          TableWithDifficulty::Entry.new("クロスボウ：宝箱を開けようとしたキャラクターに%sの「刺し」ダメージを与える。盾の受動防御を無視した「よけ%s」で回避が可能。", ["2D", "3D", "5D", "8D"], ["", "-2", "-4", "-8"]),
          TableWithDifficulty::Entry.new("毒針：宝箱を開けようとしたキャラクターに%sの「刺し」ダメージを与える。1点でもダメージを受けると「生命力%s」で判定を行い、失敗すると1日間すべての判定に-2のペナルティを受ける。盾の受動防御を無視した「よけ%s」で回避が可能。", ["1D", "2D", "3D", "6D"], ["-4", "-5", "-6", "-8"], ["", "-2", "-4", "-8"]),
          TableWithDifficulty::Entry.new("アラーム：即座にその地形のエンカウント表(イベント表4-1～4-6)を振る。"),
          TableWithDifficulty::Entry.new("殺人鬼の斧：宝箱を開けようとしたキャラクターに%sの「切り」ダメージを与える。命中部位は「ランダム部位命中表」を用いて決定すること。盾の受動防御を無視した「よけ%s」で回避が可能。", ["3D", "4D", "6D", "10D"], ["", "-2", "-4", "-8"]),
          TableWithDifficulty::Entry.new("死神：宝箱を開けようとしたキャラクターにネクロマンサーの呪術【憑物】+【死神】の効果を与える。3ラウンドすべての判定に%sのペナルティを受け、効果が切れると同時に%sの防護点無視ダメージを受ける。", ["-1", "-2", "-3", "-4"], ["3D+3", "3D+6", "3D+9", "3D+15"]),
          TableWithDifficulty::Entry.new("幻の宝：宝箱は二重底になっている。「知力%s」か<商人%s>の判定に失敗すると、重さ10kgの価値のない偽の宝物を入手してしまう。偽の宝物はシナリオ終了まで捨てることはできないが「トレジャーイーター」の罠にかかると消滅する。", ["-5", "-7", "-9", "-13"], ["", "-2", "-4", "-8"]),
          TableWithDifficulty::Entry.new("エクスプロージョン：宝箱が爆発し、PC全員に%sの「叩き」ダメージを与える。宝箱の中身は粉々になる。", ["4D", "6D", "9D", "15D"]),
          TableWithDifficulty::Entry.new("レインボーポイズン：宝箱から七色の毒ガスが放たれる。PC全員が「生命力%s」で判定を行い、失敗するとHP、MP、FPに%sの防護点無視ダメージを受ける。", ["-4", "-5", "-6", "-8"], ["2D", "3D", "4D", "6D"]),
          TableWithDifficulty::Entry.new("デスクラウド：宝箱から致死性の毒ガスが放たれる。PC全員が「生命力%s」で判定を行い、失敗したPCは即座に死亡する。", ["-4", "-5", "-6", "-8"]),
        ]
      )
    end
  end
end
