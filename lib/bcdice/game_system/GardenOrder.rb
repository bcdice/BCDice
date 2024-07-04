# frozen_string_literal: true

module BCDice
  module GameSystem
    class GardenOrder < Base
      # ゲームシステムのの識別子
      ID = 'GardenOrder'

      # ゲームシステム名
      NAME = 'ガーデンオーダー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かあてんおおたあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・基本判定
        　GOx/y@z　x：成功率、y：連続攻撃回数（省略可）、z：クリティカル値（省略可）
        　（連続攻撃では1回の判定のみが実施されます）
        　例）GO55　GO100/2　GO70@10　GO155/3@44

        ・負傷表
        　DCxxy
        　xx：属性（切断：SL，銃弾：BL，衝撃：IM，灼熱：BR，冷却：RF，電撃：EL）
        　y：ダメージ
        　例）DCSL7　DCEL22

        ・負傷表(ソウルエンコーダー用)
        　SExxy
        　xx：属性（切断：SL，銃弾：BL，衝撃：IM，灼熱：BR，冷却：RF，電撃：EL）
        　y：ダメージ
        　例）SESL7　SEEL22
      INFO_MESSAGE_TEXT

      register_prefix(
        'GO',
        'DC(SL|BL|IM|BR|RF|EL).+',
        'SE(SL|BL|IM|BR|RF|EL).+'
      )

      def eval_game_system_specific_command(command)
        case command
        when %r{GO(-?\d+)(/(\d+))?(@(\d+))?}i
          success_rate = Regexp.last_match(1).to_i
          repeat_count = (Regexp.last_match(3) || 1).to_i
          critical_border_text = Regexp.last_match(5)
          critical_border = get_critical_border(critical_border_text, success_rate)

          return check_roll_repeat_attack(success_rate, repeat_count, critical_border)

        when /^(DC|SE)(SL|BL|IM|BR|RF|EL)(\d+)/i
          chart_type = Regexp.last_match(1)
          type = Regexp.last_match(2)
          damage_value = Regexp.last_match(3).to_i
          case chart_type
          when "DC"
            return look_up_damage_chart(type, damage_value)
          when "SE"
            return look_up_damage_se_chart(type, damage_value)
          end
        end

        return nil
      end

      def get_critical_border(critical_border_text, success_rate)
        return critical_border_text.to_i unless critical_border_text.nil?

        critical_border = [success_rate / 5, 1].max
        return critical_border
      end

      def check_roll_repeat_attack(success_rate, repeat_count, critical_border)
        success_rate_per_one = success_rate / repeat_count
        # 連続攻撃は最終的な成功率が50%以上であることが必要 cf. p217
        if repeat_count > 1 && success_rate_per_one < 50
          return "D100<=#{success_rate_per_one}@#{critical_border} ＞ 連続攻撃は成功率が50％以上必要です"
        end

        check_roll(success_rate_per_one, critical_border)
      end

      def check_roll(success_rate, critical_border)
        success_rate = 0 if success_rate < 0
        fumble_border = (success_rate < 100 ? 96 : 99)

        dice_value = @randomizer.roll_once(100)
        result = get_check_result(dice_value, success_rate, critical_border, fumble_border)

        result.text = "D100<=#{success_rate}@#{critical_border} ＞ #{dice_value} ＞ #{result.text}"
        return result
      end

      def get_check_result(dice_value, success_rate, critical_border, fumble_border)
        # クリティカルとファンブルが重なった場合は、ファンブルとなる。 cf. p175
        return Result.fumble("ファンブル") if dice_value >= fumble_border
        return Result.critical("クリティカル") if dice_value <= critical_border
        return Result.success("成功") if dice_value <= success_rate

        return Result.failure("失敗")
      end

      def look_up_damage_chart(type, damage_value)
        chart_type = "DC"
        name, table = get_damage_table_info_by_type(type, chart_type)

        row = get_table_by_number(damage_value, table, nil)
        return nil if row.nil?

        "負傷表：#{name}[#{damage_value}] ＞ #{row[:damage]} ｜ #{row[:name]} … #{row[:text]}"
      end

      def look_up_damage_se_chart(type, damage_value)
        chart_type = "SE"
        name, table = get_damage_table_info_by_type(type, chart_type)

        row = get_table_by_number(damage_value, table, nil)
        return nil if row.nil?

        "負傷表(#{chart_type})：#{name}[#{damage_value}] ＞ #{row[:damage]} ｜ #{row[:name]} … #{row[:text]}"
      end

      def get_damage_table_info_by_type(type, chart_type)
        data = {}
        case chart_type
        when "DC"
          data = DAMAGE_TABLE[type]
        when "SE"
          data = DAMAGE_TABLE_SE[type]
        end
        return nil if data.nil?

        return data[:name], data[:table]
      end

      DAMAGE_TABLE = {
        "SL" => {
          name: "切断",
          table: [
            [5,
             {name: "切り傷",
              text: "皮膚が切り裂かれる。",
              damage: "軽傷1"}],
            [10,
             {name: "脚部負傷",
              text: "足が切り裂かれ、思わずひざまずく。",
              damage: "軽傷２／マヒ"}],
            [13,
             {name: "出血",
              text: "斬り裂かれた傷から出血が続く。",
              damage: "軽傷３／ＤＯＴ：軽傷1"}],
            [16,
             {name: "胴部負傷",
              text: "胴部に大きな傷を受ける。",
              damage: "軽傷４"}],
            [19,
             {name: "腕部負傷",
              text: "腕に大きな傷を受ける。",
              damage: "重傷1／ＤＯＴ：軽傷1"}],
            [22,
             {name: "腹部負傷",
              text: "腹部を深く切り裂かれる。",
              damage: "重傷２"}],
            [25,
             {name: "大量出血",
              text: "傷は深く、そこから大量に出血する。",
              damage: "重傷２／ＤＯＴ：軽傷２"}],
            [28,
             {name: "裂傷",
              text: "治りにくい傷をつけられる。",
              damage: "重傷３"}],
            [31,
             {name: "視界不良",
              text: "頭部に受けた傷から血が流れ、視界がふさがれる。",
              damage: "重傷３／スタン"}],
            [34,
             {name: "胸部負傷",
              text: "胸から腰にかけて大きく切り裂かれる。",
              damage: "致命傷1"}],
            [37,
             {name: "動脈切断",
              text: "動脈が切り裂かれ、噴き出るように出血する。",
              damage: "致命傷1／ＤＯＴ：軽傷３"}],
            [39,
             {name: "胸部切断",
              text: "傷が肺にまで達し、喀血する。",
              damage: "致命傷２"}],
            [9999,
             {name: "脊髄損傷",
              text: "脊髄が損傷する。",
              damage: "致命傷２／放心、スタン、マヒ"}],
          ]
        },

        "BL" => {
          name: "銃弾",
          table: [
            [5,
             {name: "腕部損傷",
              text: "銃弾が腕をかすめた。",
              damage: "軽傷２"}],
            [10,
             {name: "腕部貫通",
              text: "銃弾が腕を貫く。痛みはあるが動作に支障はない。",
              damage: "軽傷３"}],
            [13,
             {name: "胴部負傷",
              text: "胴部に銃弾をくらう。痛みで動きが鈍くなる。",
              damage: "軽傷４／スロウ：－３"}],
            [16,
             {name: "肩負傷",
              text: "肩を貫かれる。骨が砕けたようだ。",
              damage: "重傷1"}],
            [19,
             {name: "腹部負傷",
              text: "腹部が貫かれる。かろうじて内臓にダメージはないようだ。",
              damage: "重傷２"}],
            [22,
             {name: "脚部貫通",
              text: "脚を銃弾に貫かれ、その場でひざまずく。",
              damage: "重傷２／マヒ"}],
            [25,
             {name: "消化器系損傷",
              text: "胃などの消化器官にダメージを受ける。",
              damage: "重傷３"}],
            [28,
             {name: "盲管銃弾",
              text: "身体に弾丸が深々と刺さる。激痛が走る。",
              damage: "重傷３／スロウ：－5"}],
            [31,
             {name: "内臓損傷",
              text: "いくつかの内臓にダメージを受ける。",
              damage: "致命傷1／スタン"}],
            [34,
             {name: "胴部貫通",
              text: "腹部への攻撃が貫通し、出血する。",
              damage: "致命傷1／ＤＯＴ：軽傷1"}],
            [37,
             {name: "胸部負傷",
              text: "銃弾で肺を貫かれる。",
              damage: "致命傷２"}],
            [39,
             {name: "致命的な一撃",
              text: "銃弾が頭部に命中。ショックで意識を飛ばされる。",
              damage: "致命傷２／放心"}],
            [9999,
             {name: "必殺の一撃",
              text: "銃弾が心臓の近くを貫く。動脈にダメージを受けたようだ。",
              damage: "致命傷２／ＤＯＴ：重傷1"}],
          ]
        },

        "IM" => {
          name: "衝撃",
          table: [
            [5,
             {name: "打撲",
              text: "攻撃を受けた箇所がどす黒く腫れ上がる。",
              damage: "軽傷1"}],
            [10,
             {name: "転倒",
              text: "衝撃で転倒する。",
              damage: "軽傷1／マヒ"}],
            [13,
             {name: "平衡感覚喪失",
              text: "衝撃で三半規管にダメージを受ける。",
              damage: "軽傷２、疲労２"}],
            [16,
             {name: "ボディーブロー",
              text: "腹部に直撃。痛みが継続し、体力を奪う。",
              damage: "軽傷３／ＤＯＴ：疲労３"}],
            [19,
             {name: "痛打",
              text: "胴部や脚部などに打撃を受ける。",
              damage: "軽傷４／スタン"}],
            [22,
             {name: "頭部痛打",
              text: "頭部にクリーンヒット。意識がもうろうとする。",
              damage: "軽傷5／放心"}],
            [25,
             {name: "脚部骨折",
              text: "攻撃が足に命中し、骨折する。",
              damage: "重傷1／スロウ：－5"}],
            [28,
             {name: "大転倒",
              text: "激しい衝撃によって、負傷すると共に大きく体勢を崩す。",
              damage: "重傷1／マヒ、スタン"}],
            [31,
             {name: "脳震盪",
              text: "脳が大きく揺さぶられ、意識が飛びそうになる。",
              damage: "重傷２／放心"}],
            [34,
             {name: "複雑骨折",
              text: "攻撃を受けた部分が大きくひしゃげ、複雑骨折したようだ。",
              damage: "重傷３／放心、スタン"}],
            [37,
             {name: "頭部裂傷",
              text: "頭部に命中。皮膚が大きく裂ける。",
              damage: "致命傷1、疲労３"}],
            [39,
             {name: "肋骨負傷",
              text: "折れた肋骨が肺に突き刺さり、まともに呼吸を行なうことができない。",
              damage: "致命傷1／放心、スタン"}],
            [9999,
             {name: "内臓損傷",
              text: "衝撃が身体の芯まで届き、内臓がいくつか傷ついたようだ。",
              damage: "致命傷２／ＤＯＴ：重傷1"}],
          ]
        },

        "BR" => {
          name: "灼熱",
          table: [
            [5,
             {name: "火傷",
              text: "皮膚に小さな火傷を負う。",
              damage: "軽傷1"}],
            [10,
             {name: "温度上昇",
              text: "熱によって、怪我だけではなく体力も奪われる。",
              damage: "軽傷２、疲労1"}],
            [13,
             {name: "恐怖",
              text: "燃え上がる炎に恐怖を感じ、身体がすくんで動きが止まる。",
              damage: "軽傷３／放心"}],
            [16,
             {name: "発火",
              text: "衣服や身体の一部に火が燃え移る。",
              damage: "軽傷３／ＤＯＴ：軽傷1"}],
            [19,
             {name: "爆発",
              text: "爆発により吹き飛ばされ、転倒する。",
              damage: "重傷1／マヒ"}],
            [22,
             {name: "大火傷",
              text: "痕が残るほどの大きな火傷を負う。",
              damage: "重傷２"}],
            [25,
             {name: "熱波",
              text: "火傷と強力な熱により意識がもうろうとする。",
              damage: "重傷２／スタン"}],
            [28,
             {name: "大爆発",
              text: "激しい爆発で吹き飛ばされ、ダメージと共に転倒する。",
              damage: "重傷３／マヒ"}],
            [31,
             {name: "大発火",
              text: "広範囲に火が燃え移る。",
              damage: "重傷３／ＤＯＴ：軽傷1"}],
            [34,
             {name: "炭化",
              text: "高熱のあまり、焼けた部分が炭化してしまう。",
              damage: "致命傷1"}],
            [37,
             {name: "内臓火傷",
              text: "高温の空気を吸い込む、気道にも火傷を負ってしまう。",
              damage: "致命傷1／ＤＯＴ：軽傷1"}],
            [39,
             {name: "全身火傷",
              text: "身体の各所に深い火傷を負う。",
              damage: "致命傷２"}],
            [9999,
             {name: "致命的火傷",
              text: "身体の大部分に焼けどを負う。",
              damage: "致命傷２／スタン"}],
          ]
        },

        "RF" => {
          name: "冷却",
          table: [
            [5,
             {name: "冷気",
              text: "軽い凍傷を受ける。",
              damage: "軽傷1"}],
            [10,
             {name: "霜の衣",
              text: "身体が薄い氷で覆われ、動きが鈍る。",
              damage: "軽傷1／疲労1"}],
            [13,
             {name: "凍傷",
              text: "凍傷により身体が傷つけられる。",
              damage: "軽傷3"}],
            [16,
             {name: "体温低下",
              text: "冷気によって体温を奪われる。",
              damage: "軽傷３／ＤＯＴ：疲労1"}],
            [19,
             {name: "氷の枷",
              text: "肘や膝などが氷で覆われ、動きが取りにくくなる。",
              damage: "重傷1／マヒ"}],
            [22,
             {name: "大凍傷",
              text: "身体の各所に凍傷を受ける。",
              damage: "重傷1／ＤＯＴ：疲労２"}],
            [25,
             {name: "氷の束縛",
              text: "下半身が凍りつき、動くことができない。",
              damage: "重傷２／マヒ"}],
            [28,
             {name: "視界不良",
              text: "頭部にも氷が張り、視界がふさがれる。",
              damage: "重傷２／スタン"}],
            [31,
             {name: "腕部凍結",
              text: "腕が凍りづけになり、動かすことができない。",
              damage: "重傷３／放心"}],
            [34,
             {name: "重度凍傷",
              text: "さらに体温が低下し、深刻な凍傷を受ける。",
              damage: "致命傷1"}],
            [37,
             {name: "全身凍結",
              text: "全身が凍りづけになる。",
              damage: "致命傷1／ＤＯＴ：疲労２"}],
            [39,
             {name: "致命的凍傷",
              text: "身体全身に凍傷を受ける。",
              damage: "致命傷２"}],
            [9999,
             {name: "氷の棺",
              text: "完全に氷に閉じ込められる。",
              damage: "致命傷２／スタン、マヒ"}],
          ]
        },

        "EL" => {
          name: "電撃",
          table: [
            [5,
             {name: "静電気",
              text: "全身の毛が逆立つ。",
              damage: "疲労３"}],
            [10,
             {name: "電熱傷",
              text: "電流によって傷つく。",
              damage: "疲労1、軽傷1"}],
            [13,
             {name: "感電",
              text: "電流で傷つくと共に、身体が軽くしびれる。",
              damage: "疲労２、軽傷２"}],
            [16,
             {name: "閃光",
              text: "激しい電光により、一時的に視界がふさがれる。",
              damage: "軽傷３／スタン"}],
            [19,
             {name: "脚部感電",
              text: "電流により脚がしびれ、動けなくなる。",
              damage: "重傷1／マヒ"}],
            [22,
             {name: "大電熱傷",
              text: "身体の各所が電流によって傷つく。",
              damage: "疲労２、重傷２"}],
            [25,
             {name: "腕部負傷",
              text: "電流で腕がしびれ、動けなくなる。",
              damage: "軽傷1、重傷２／放心"}],
            [28,
             {name: "大感電",
              text: "電流によって身体中がしびれ、動けなくなる。",
              damage: "重傷２／スタン、マヒ"}],
            [31,
             {name: "一時心停止",
              text: "強力な電撃のショックにより、心臓がほんの一瞬だけ止まる。",
              damage: "疲労３、重傷３"}],
            [34,
             {name: "大電流",
              text: "全身に電流が駆け巡る。",
              damage: "重傷３／放心、マヒ"}],
            [37,
             {name: "致命電熱傷",
              text: "全身が電流によって傷つく。",
              damage: "重傷1、致命傷1"}],
            [39,
             {name: "心停止",
              text: "強力な電撃のショックにより、心臓が一時的に止まる。死の淵が見える。",
              damage: "疲労３、重傷1、致命傷1"}],
            [9999,
             {name: "組織炭化",
              text: "全身が電流で焼かれ、あちこちの組織が炭化する。",
              damage: "致命傷２／スタン"}],
          ]
        }
      }.freeze

      DAMAGE_TABLE_SE = {
        "SL" => {
          name: "切断",
          table: [
            [5,
             {name: "軽い衝撃",
              text: "たいした傷ではないが、衝撃を受ける。",
              damage: "スタン"}],
            [10,
             {name: "小さな傷",
              text: "外装に傷がつく。",
              damage: "軽傷1"}],
            [13,
             {name: "大きな傷",
              text: "外装に大きな傷がつく。",
              damage: "軽傷2"}],
            [16,
             {name: "とても大きな傷",
              text: "外装にさらに大きな傷がつき、内部もダメージを受ける。",
              damage: "軽傷3/DOT:軽傷1"}],
            [19,
             {name: "外観破損",
              text: "外装の一部が欠ける。",
              damage: "軽傷4"}],
            [22,
             {name: "内部破損",
              text: "外装の一部が破損し、内部もダメージを受ける。",
              damage: "重傷1/DOT:軽傷1"}],
            [25,
             {name: "内部大破損",
              text: "内部の一部が大きく破損する。",
              damage: "重傷2"}],
            [28,
             {name: "一時不全",
              text: "外装の一部が壊れ、内部も大きなダメージを受ける。",
              damage: "重傷2/DOT:軽傷2"}],
            [31,
             {name: "裂傷",
              text: "傷をつけられ、内部が顔をのぞかせる。",
              damage: "重傷3"}],
            [34,
             {name: "視界不良",
              text: "取りつけられているカメラに不都合が生じる",
              damage: "重傷3/スタン"}],
            [37,
             {name: "大裂傷",
              text: "大きく切り裂かれ、内部が露わになる。",
              damage: "致命傷1"}],
            [39,
             {name: "機能不全",
              text: "重要な部品が壊れ、このままで機能に大きな障害が出る。",
              damage: "致命傷1/DOT:軽傷3"}],
            [9999,
             {name: "致命的損傷",
              text: "機能が停止しかねないほどの大きな損傷を受ける。",
              damage: "致命傷2"}],
          ]
        },

        "BL" => {
          name: "銃弾",
          table: [
            [5,
             {name: "軽い衝撃",
              text: "銃弾ははじいたが、衝撃を受ける。",
              damage: "スタン"}],
            [10,
             {name: "小さな銃創",
              text: "銃弾ははじいたが、外装に凹みができた。",
              damage: "軽傷2"}],
            [13,
             {name: "大きな銃創",
              text: "かろうじて銃弾ははじいたが、外装に大きな凹みができた。",
              damage: "軽傷3"}],
            [16,
             {name: "機能低下",
              text: "銃弾の衝撃で、内部の機能に不都合が講じた。",
              damage: "軽傷4/スロウ:-3"}],
            [19,
             {name: "とても大きな銃創",
              text: "銃弾をはじけず、外装に食い込んだ。",
              damage: "重傷1"}],
            [22,
             {name: "銃弾停止",
              text: "銃弾が貫通した。かろうじて内部にダメージはないようだ。",
              damage: "重傷2"}],
            [25,
             {name: "内部損傷",
              text: "銃弾が貫通した時、内部の機能に衝撃を受ける。",
              damage: "重傷2/放心"}],
            [28,
             {name: "内部破壊",
              text: "銃弾が貫通した時、内部にも大きなダメージを受ける。",
              damage: "重傷3"}],
            [31,
             {name: "内部大破壊",
              text: "銃弾が貫通した時、その衝撃で内部に一時的な損傷を受ける。",
              damage: "重傷3/スロウ:-5"}],
            [34,
             {name: "機能一部停止",
              text: "銃弾によって内部の機能が一時的に役に立たなくなっている。",
              damage: "致命傷1/スタン"}],
            [37,
             {name: "破損",
              text: "銃弾によって外装が吹き飛び、内部の一部が破壊される。",
              damage: "致命傷1/DOT:軽傷1"}],
            [39,
             {name: "大破損",
              text: "銃弾によって外装ごと内部の一部が吹き飛ぶ。",
              damage: "致命傷2"}],
            [9999,
             {name: "致命的な一撃",
              text: "銃弾が重要な部位に命中。衝撃で機能の大部分が一時的に停止する。",
              damage: "致命傷2/放心"}],
          ]
        },

        "IM" => {
          name: "衝撃",
          table: [
            [5,
             {name: "軽い衝撃",
              text: "傷も凹みもないが、衝撃を受ける。",
              damage: "スタン"}],
            [10,
             {name: "衝撃",
              text: "衝撃を受けて外装が凹む。",
              damage: "軽傷1"}],
            [13,
             {name: "大きな衝撃",
              text: "衝撃を受けて外装が大きく凹む。",
              damage: "軽傷2"}],
            [16,
             {name: "とても大きな衝撃",
              text: "衝撃を受けて外装が大きく凹み、機能が瞬間的に停止する。",
              damage: "軽傷2/放心"}],
            [19,
             {name: "内部圧迫",
              text: "外装が凹み、内部を圧迫している。",
              damage: "軽傷3/DOT:疲労3"}],
            [22,
             {name: "痛打",
              text: "当たり所が悪く、カメラ機能が一時的に停止する。",
              damage: "軽傷4/スタン"}],
            [25,
             {name: "内部衝撃",
              text: "当たり所が悪く、内部に大きなダメージを与える。機能が一時的に停止する。",
              damage: "軽傷5/放心"}],
            [28,
             {name: "機能障害",
              text: "衝撃によって機能の動作に障害が発生する。",
              damage: "重傷1/スロウ:-5"}],
            [31,
             {name: "外裝損傷",
              text: "外装が損傷し、その破片が内部に突き刺さる。",
              damage: "重傷1/放心、スタン"}],
            [34,
             {name: "外装大損傷",
              text: "外装が大きく損傷し、内部もいくつか破壊される。",
              damage: "重傷2/放心"}],
            [37,
             {name: "外装破壊",
              text: "外装の一部が吹き飛び、内部も破壊される。",
              damage: "重傷3/放心、スタン"}],
            [39,
             {name: "外装大破壊",
              text: "外装の一部が吹き飛び、内部も一緒に吹き飛ばされる。",
              damage: "致命傷1、疲労3"}],
            [9999,
             {name: "致命的破壊",
              text: "外装のほとんどが破壊され、内部もひしゃげ、潰される。",
              damage: "致命傷1/放心、スタン"}],
          ]
        },

        "BR" => {
          name: "灼熱",
          table: [
            [5,
             {name: "軽い溶解",
              text: "外装が少しだけ溶け、機能が低下する。",
              damage: "スタン"}],
            [10,
             {name: "溶解",
              text: "外装が溶ける。",
              damage: "軽傷1"}],
            [13,
             {name: "温度上昇",
              text: "熱によって、外装だけでなく内部も少しだけ溶解する。",
              damage: "軽傷2、疲労1"}],
            [16,
             {name: "温度大上昇",
              text: "熱によって、外装だけでなく内部が溶解する。",
              damage: "軽傷3/放心"}],
            [19,
             {name: "発火",
              text: "外装に火が燃え移る。",
              damage: "軽傷3/DOT:軽傷1"}],
            [22,
             {name: "爆発",
              text: "爆発により外装の一部が吹き飛ばされる。",
              damage: "重傷1/スタン"}],
            [25,
             {name: "痕が残るほどの大きく外装が溶解する。",
              text: "大溶解",
              damage: "重傷2"}],
            [28,
             {name: "熱波",
              text: "強力な熱により内部機能が低下する。",
              damage: "重傷2/スタン"}],
            [31,
             {name: "大爆発",
              text: "激しい爆発で外装が大きく吹き飛ばされ、内部にもダメージを受ける。",
              damage: "重傷3/放心"}],
            [34,
             {name: "大発火",
              text: "広範囲に火が燃え移る。",
              damage: "重傷3/DOT:軽傷1"}],
            [37,
             {name: "炭化",
              text: "高熱のあまり、焼けた部分が炭化してしまう。",
              damage: "致命傷1"}],
            [39,
             {name: "内部溶解",
              text: "内部に熱や炎が回り、大きく溶解する。",
              damage: "致命傷1/DOT:軽傷1"}],
            [9999,
             {name: "致命的溶解",
              text: "外装や内部の大部分が溶解する。",
              damage: "致命傷2"}],
          ]
        },

        "RF" => {
          name: "冷却",
          table: [
            [5,
             {name: "軽い冷却",
              text: "冷気で機能が低下する。",
              damage: "スタン"}],
            [10,
             {name: "冷気",
              text: "外装が薄い氷で覆われる。",
              damage: "軽傷1"}],
            [13,
             {name: "霜の衣",
              text: "外装が薄い氷で覆われ、動作が鈍る。",
              damage: "軽傷2/疲労1"}],
            [16,
             {name: "軽い凍結",
              text: "凍結によって外装の一部が痛む。",
              damage: "軽傷3"}],
            [19,
             {name: "温度低下",
              text: "冷気によって機能が低下する。",
              damage: "軽傷3/DOT:疲労1"}],
            [22,
             {name: "氷の枷",
              text: "可動部などが氷で覆われ、動きが取りにくくなる。",
              damage: "重傷1/スタン"}],
            [25,
             {name: "大凍結",
              text: "外装の大部分が凍結する。",
              damage: "重傷1/DOT:疲労2"}],
            [28,
             {name: "氷の束縛",
              text: "可動部などが完全に凍りつき、動くことができない。",
              damage: "重傷2/放心"}],
            [31,
             {name: "視界不良",
              text: "カメラのレンズにも氷が張り、視界がふさがれる。",
              damage: "重傷2/スタン"}],
            [34,
             {name: "動作不良",
              text: "凍結によって一部動作に不都合が生じている。",
              damage: "重傷3/放心"}],
            [37,
             {name: "重度凍結",
              text: "さらに温度が低下し、内部にも深刻なダメージを受ける。",
              damage: "致命傷1"}],
            [39,
             {name: " 全身凍結",
              text: "全体が凍りづけになる。",
              damage: "致命傷1/DOT:疲労2"}],
            [9999,
             {name: "致命的凍結",
              text: "外装だけでなく、内部も致命的なダメージを受ける。",
              damage: "致命傷2"}],
          ]
        },

        "EL" => {
          name: "電撃",
          table: [
            [5,
             {name: "軽い電撃",
              text: "電撃で機能が低下する。",
              damage: "スタン"}],
            [10,
             {name: "帯電",
              text: "帯電により軽いダメージを受ける。",
              damage: "疲労3"}],
            [13,
             {name: "電熱傷",
              text: "電流によって外装が傷つく。",
              damage: "疲労1、軽傷1"}],
            [16,
             {name: "軽い感電",
              text: "電流で傷つくと共に、内部に軽いダメージを受ける。",
              damage: "疲労2、軽傷2"}],
            [19,
             {name: "閃光",
              text: "激しい閃光により、一時的にカメラ機能がマヒする。",
              damage: "軽傷3/スタン"}],
            [22,
             {name: "感電",
              text: "電流により内部がダメージを受け、一時的に動作がマヒする。",
              damage: "重傷1/放心"}],
            [25,
             {name: "大電熱傷",
              text: "外装の各所が電流によって傷つく。",
              damage: "疲労2、重傷2"}],
            [28,
             {name: "感電による負傷",
              text: "外装だけでなく、内部も大きなダメージを受け、機能がマヒする。",
              damage: "軽傷1、重傷2/放心"}],
            [31,
             {name: "大感電",
              text: "電流によって機能のほとんどがマヒして、動作しなくなる。",
              damage: "重傷2/放心、スタン"}],
            [34,
             {name: "大電流",
              text: "強力な電撃のショックにより、内部にも多大なダメージを受ける。",
              damage: "疲労3、重傷3"}],
            [37,
             {name: "一時停止",
              text: "全身に電流が駆け巡り、機能の大部分が動作不良を起こす。",
              damage: "重傷3/放心、スタン"}],
            [39,
             {name: "致命電熱傷",
              text: "全体が電流によって傷つく。",
              damage: "重傷1、致命傷"}],
            [9999,
             {name: "機能停止",
              text: "強力な電撃のショックにより、故障寸前のダメージを受ける。",
              damage: "疲労3、重傷1、致命傷1"}],
          ]
        }
      }.freeze
    end
  end
end
