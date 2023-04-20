# frozen_string_literal: true

module BCDice
  module GameSystem
    class HeroScale < Base
      # ゲームシステムの識別子
      ID = 'HeroScale'

      # ゲームシステム名
      NAME = '英雄の尺度'

      # ゲームシステム名の読みがな
      SORT_KEY = 'えいゆうのしやくと'

      HELP_MESSAGE = <<~TEXT
        同人TRPGシステム『英雄の尺度』用ダイスボット。
        基本ルールブック＋サプリメント対応。仮称は非対応。
        コマンド一覧は以下の通り。*添え字で内容は[]。†がついていたら添え字必須。
        5hs4 超越
        5hs4,b 肉体の超越
        5hs4,s,* 科学の超越[†達成値への加算値]
        5hs4,p 激情の超越
        4hs6 加護
        4hs6,s 選択の加護
        4hs6,p 安寧の加護
        4hs6,r 逆転の加護
        3hs8,*,* 契約[奉納の出目1,奉納の出目2]
        3hs8,a,*,* 享受の契約[†受諾出目1][†受諾出目2]
        3hs8,e,* 収奪の契約[†取得出目]
        3hs8,b 燃焼の契約
        3hs8,o,*,* 奉納の契約[奉納の出目1,奉納の出目2]
        2hs20 呪い
        2hs20,r 歪曲の呪い
        2hs20,c 崩壊の呪い
        2hs20,d 破滅の呪い
        3hs10 異物
        3hs10,i 模造の異物
        3hs10,m,* 混血の異物[追加振り基準出目（初期値10）]
        3hs10,b,* 彼方の異物[追加振り停止基準値（初期値666）]
        1hs60 報い
        1hs60,d 堕落の報い
        1hs60,o 忘却の報い
        1hs60,s,* 封印の報い[出目への係数]
        12hs2 同化
        12hs2,m,*,*,*,*,*,*,*,* 怪物の同化[*d2,*d4,*d6,*d8,*d10,*d12,*d20,*d60]
        12hs2,t,* [†2の枚数宣言]
        12hs2,c,* 法則の同化[†1の枚数宣言]
        1hs12 下位存在
        2hs12 中位存在
        2hs12,t 変遷の中位存在
        2hs12,c 偶然の中位存在
        2hs12,g,* 萌芽の上位存在[加算値]
        3hs12 上位存在
        3hs12,g 大神の上位存在
        3hs12,h 神性の上位存在
        3hs12,w 魔性の上位存在
        3hs12,m 悪意の上位存在
        3hs12,s,* 大罪の上位存在[†確定する目標値]
        3hs12,d 破壊の上位存在
        3hs12,a 懊悩の上位存在
        3hs12,o 試練の上位存在
        3hs12,c 創造の上位存在
        3hs12,e 元素の上位存在
        *hs* 乗算ロール
      TEXT

      register_prefix('\d+HS\d+')

      def eval_game_system_specific_command(command)
        return select_origin(command)
      end

      private

      def select_origin(command)
        order = command.split(",")

        case order[0]
        when "5HS4"
          return origin_great(order)
        when "4HS6"
          return origin_protection(order)
        when "3HS8"
          return origin_vow(order)
        when "2HS20"
          return origin_curse(order)
        when "3HS10"
          return origin_stranger(order)
        when "1HS60"
          return origin_karma(order)
        when "12HS2"
          return origin_absorption(order)
        when "1HS12"
          return origin_normal()
        when "2HS12"
          return origin_unique(order)
        when "3HS12"
          return origin_omnipotent(order)
        else
          message = order[0]
          dice = order[0].rpartition("HS")
          if dice.length > 2 && dice[0] =~ /^\d+$/ && dice[2] =~ /^\d+$/
            natural_result = @randomizer.roll_barabara(dice[0].to_i, dice[2].to_i)
            total = results_multiplication(natural_result)
            message += " ＞ #{total}[#{natural_result.join(',')}]"
            return message
          else
            return nil
          end
        end
      end

      # 超越
      def origin_great(order)
        natural_result = @randomizer.roll_barabara(5, 4)
        case order[1]
        when "P"
          message = fate_passion(natural_result)
        when "S"
          message = fate_science(natural_result, order)
        when "B"
          message = fate_body(natural_result)
        else
          total = results_multiplication(natural_result)
          message = "超越 ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_passion(natural_result)
        modified_result = []
        number_of_1 = natural_result.count(1)
        natural_result.each do |result|
          modified_result << result + number_of_1
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "激情の超越 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_science(natural_result, order)
        subtotal = results_multiplication(natural_result)
        if order.length > 2 && order[2] =~ /^\d+$/
          if order[2].to_i < 1024
            total = subtotal + order[2].to_i
            message = "科学の超越 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
            if total > 1023
              message += "(科学臨界)"
            end
          else
            message = "エラー：科学力が1024を超えています。"
          end
        else
          message = "エラー：科学力を設定してください。"
        end
        return message
      end

      def fate_body(natural_result)
        modified_result = natural_result.dup
        modified_result.each do |result|
          if result == 4
            modified_result << @randomizer.roll_once(4)
          end
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "肉体の超越 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      # 加護
      def origin_protection(order)
        natural_result = @randomizer.roll_barabara(4, 6)
        case order[1]
        when "R"
          message = fate_reversal(natural_result)
        when "P"
          message = fate_peace(natural_result)
        when "S"
          message = fate_choice(natural_result)
        else
          total = results_multiplication(natural_result)
          message = "加護 ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_reversal(natural_result)
        modified_result = []
        natural_result.each do |result|
          if result < 4
            result = 7 - result
          end
          modified_result << result
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "逆転の加護 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_peace(natural_result)
        subtotal = results_multiplication(natural_result)
        total = subtotal + 250
        message = "安寧の加護 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        return message
      end

      def fate_choice(natural_result)
        modified_result = natural_result.dup
        modified_result.concat(@randomizer.roll_barabara(3, 6))
        even_total = 1
        odd_total = 1
        modified_result.each do |result|
          if result.even?
            even_total *= result
          else
            odd_total *= result
          end
        end
        if even_total > odd_total
          total = even_total
        else
          total = odd_total
        end
        subtotal = results_multiplication(natural_result)
        message = "選択の加護 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      # 契約
      def origin_vow(order)
        natural_result = @randomizer.roll_barabara(3, 8)
        case order[1]
        when "O"
          message = fate_offering(natural_result, order)
        when "B"
          message = fate_burning(natural_result)
        when "E"
          message = fate_exploitation(natural_result, order)
        when "A"
          message = fate_acceptance(natural_result, order)
        else
          subtotal = results_multiplication(natural_result)
          if order.length > 2 && order[1] =~ /^\d+$/ && order[2] =~ /^\d+$/
            modified_result = natural_result.dup
            modified_result <<  order[1].to_i
            modified_result <<  order[2].to_i
            total = results_multiplication(modified_result)
            message = "契約 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
          else
            message = "契約 ＞ #{subtotal}[#{natural_result.join(',')}]"
          end
        end
        return message
      end

      def fate_offering(natural_result, order)
        subtotal = results_multiplication(natural_result)
        if order.length > 3 && order[2] =~ /^\d+$/ && order[3] =~ /^\d+$/
          modified_result = natural_result.dup
          modified_result <<  order[2].to_i
          modified_result <<  order[3].to_i
          total = results_multiplication(modified_result)
          message = "奉納の契約 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        else
          message = "奉納の契約 ＞ #{subtotal}[#{natural_result.join(',')}]"
        end
        offering_result = natural_result.dup
        offering_result.sort!.reverse!.shift(1)
        message += "(奉納：#{offering_result.join(',')})"
        return message
      end

      def fate_burning(natural_result)
        subtotal = results_multiplication(natural_result)
        total = subtotal * 6
        message = "燃焼の契約 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        return message
      end

      def fate_exploitation(natural_result, order)
        subtotal = results_multiplication(natural_result)
        if order.length > 2 && order[2] =~ /^\d+$/
          modified_result = natural_result.dup
          modified_result[modified_result.index(modified_result.min)] = order[2].to_i
          total = results_multiplication(modified_result)
          message = "収奪の契約 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        else
          message = "エラー：収奪数を指定してください。"
        end
        return message
      end

      def fate_acceptance(natural_result, order)
        subtotal = results_multiplication(natural_result)
        if order.length > 3 && order[2] =~ /^\d+$/ && order[3] =~ /^\d+$/
          change_result = natural_result.min(2)
          modified_result = natural_result.dup
          modified_result[modified_result.index(change_result[0])] = order[2].to_i
          modified_result[modified_result.index(change_result[1])] = order[3].to_i
          total = results_multiplication(modified_result)
          message = "享受の契約 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        else
          message = "エラー：享受数を指定してください。"
        end
        return message
      end

      # 呪い
      def origin_curse(order)
        natural_result = @randomizer.roll_barabara(2, 20)
        case order[1]
        when "R"
          message = fate_ruin(natural_result)
        when "C"
          message = fate_collapse(natural_result)
        when "D"
          message = fate_distortion(natural_result)
        else
          total = results_multiplication(natural_result)
          message = "呪い ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_ruin(natural_result)
        modified_result = natural_result.dup
        modified_result.concat(@randomizer.roll_barabara(2, 20))
        total = 1
        modified_result.each do |result|
          if result > 10
            total *= result
          end
        end
        subtotal = results_multiplication(natural_result)
        message = "破滅の呪い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_collapse(natural_result)
        modified_result = natural_result.dup
        collapse_result = result_raoundup(natural_result[natural_result.index(natural_result.max)])
        if modified_result[0] == modified_result[1]
          modified_result[0] = collapse_result
          modified_result[1] = collapse_result
          modified_result << collapse_result
          modified_result << collapse_result
        else
          modified_result[natural_result.index(natural_result.max)] = collapse_result
          modified_result.insert(natural_result.index(natural_result.max), collapse_result)
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "崩壊の呪い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_distortion(natural_result)
        modified_result = natural_result.dup

        if modified_result[0] == modified_result[1]
          modified_result[0] += 13
          modified_result[1] += 13
        else
          modified_result[natural_result.index(natural_result.min)] += 13
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "歪曲の呪い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      # 異物
      def origin_stranger(order)
        natural_result = @randomizer.roll_barabara(3, 10)
        natural_result = stranger_effection(natural_result)
        case order[1]
        when "I"
          message = fate_imitation(natural_result)
        when "M"
          message = fate_mixed(natural_result, order)
        when "B"
          message = fate_beyond(natural_result, order)
        else
          total = results_multiplication(natural_result)
          message = "異物 ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_imitation(natural_result)
        modified_result = natural_result.dup
        modified_result.sort!
        modified_result[0] = (modified_result[0] + modified_result[1] * 10) == 0 ? 100 : (modified_result[0] + modified_result[1] * 10)
        modified_result[1] = modified_result[2]
        modified_result.delete_at(2)
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "模造の異物 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_mixed(natural_result, order)
        subtotal = results_multiplication(natural_result)
        if order.length > 2 && order[2] =~ /^\d+$/
          mixed_score = order[2].to_i
        else
          mixed_score = 1
        end
        modified_result = natural_result.dup
        if mixed_score <= natural_result.min
          modified_result << @randomizer.roll_once(12)
          total = results_multiplication(modified_result)
          message = "混血の異物 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}](追加振り)"
        else
          modified_result[natural_result.index(natural_result.min)] = 10
          total = results_multiplication(modified_result)
          message = "混血の異物 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}](10置換)"
        end
        return message
      end

      def fate_beyond(natural_result, order)
        modified_result = natural_result.dup
        subtotal = results_multiplication(natural_result)
        total = subtotal
        beyond_limit = 666
        if order.length > 2 && order[2] =~ /^\d+$/ && (order[2].to_i < 666)
          beyond_limit = order[2].to_i
        end
        while total != 0 && total <= beyond_limit
          modified_result << @randomizer.roll_d9
          total = results_multiplication(modified_result)
        end
        message = "彼方の異物 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      # 報い
      def origin_karma(order)
        natural_result = @randomizer.roll_barabara(1, 60)
        case order[1]
        when "D"
          message = fate_depravity(natural_result)
        when "O"
          message = fate_oblivion(natural_result)
        when "S"
          message = fate_sealed(natural_result, order)
        else
          total = results_multiplication(natural_result)
          message = "報い ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_depravity(natural_result)
        subtotal = results_multiplication(natural_result)
        modified_result = natural_result.dup
        depravity_num1 = natural_result[0] % 10
        depravity_num10 = natural_result[0] / 10
        if depravity_num10 > 1
          modified_result << depravity_num10
        end
        if depravity_num1 > 1
          modified_result << depravity_num1
        end
        total = results_multiplication(modified_result)
        message = "堕落の報い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_oblivion(natural_result)
        modified_result = natural_result.dup
        modified_result << @randomizer.roll_once(60)
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result) / 2
        message = "忘却の報い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_sealed(natural_result, order)
        modified_result = natural_result.dup
        subtotal = results_multiplication(natural_result)
        sealed_break = 1
        if order.length > 2 && order[2] =~ /^\d+$/
          sealed_break = order[2].to_i
        end
        modified_result[0] *= sealed_break
        total = subtotal * sealed_break
        message = "封印の報い ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        if total <= 30
          sealed_break *= 4
          message += "(封印解除成功：#{sealed_break})"
        elsif total <= 60
          sealed_break *= 2
          message += "(封印解除成功：#{sealed_break})"
        else
          message += "(封印解除失敗：#{sealed_break})"
        end
        return message
      end

      # 同化
      def origin_absorption(order)
        natural_result = @randomizer.roll_barabara(12, 2)
        case order[1]
        when "M"
          message = fate_monster(natural_result, order)
        when "T"
          message = fate_treasure(natural_result, order)
        when "C"
          message = fate_concept(natural_result, order)
        else
          total = results_multiplication(natural_result)
          message = "同化 ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_monster(_natural_result, order)
        modified_result = []
        if order.length > 9 && order[2] =~ /^\d+$/ && order[3] =~ /^\d+$/ && order[4] =~ /^\d+$/ && order[5] =~ /^\d+$/ && order[6] =~ /^\d+$/ && order[7] =~ /^\d+$/ && order[8] =~ /^\d+$/ && order[9] =~ /^\d+$/
          if order[2].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[2].to_i, 2))
          end
          if order[3].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[3].to_i, 4))
          end
          if order[4].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[4].to_i, 6))
          end
          if order[5].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[5].to_i, 8))
          end
          count_of_10 = order[6].to_i
          while count_of_10 > 0
            modified_result << @randomizer.roll_d9
            count_of_10 -= 1
          end
          if order[7].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[7].to_i, 12))
          end
          if order[8].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[8].to_i, 20))
          end
          if order[9].to_i > 0
            modified_result.concat(@randomizer.roll_barabara(order[9].to_i, 60))
          end
          total = results_multiplication(modified_result)
          subtotal = modified_result.sum
          message = "怪物の同化 ＞ #{total}[#{modified_result.join(',')}] 浸蝕値：#{subtotal}"
          if [2, 4, 6, 8, 10, 12, 20, 60].include?(subtotal)
            message += "(変異進行)"
          end
          if modified_result.include?(1)
            message += "(人間性喪失)"
          end
        else
          message = "エラー：変異状態を指定してください。"
        end
        return message
      end

      def fate_treasure(natural_result, order)
        modified_result = natural_result.dup
        subtotal = results_multiplication(natural_result)
        total = subtotal
        if order.length > 2 && order[2] =~ /^\d+$/
          treasure_point = order[2].to_i
          if modified_result.count(2) >= treasure_point
            total *= treasure_point
            message = "秘宝の同化 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}(同調成功)"
          else
            message = "秘宝の同化 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}(同調失敗)"
          end
        else
          message = "エラー：解放率を指定してください。"
        end
        return message
      end

      def fate_concept(natural_result, order)
        modified_result = natural_result.dup
        subtotal = results_multiplication(natural_result)
        if order.length > 2 && order[2] =~ /^\d+$/
          existence_scale = order[2].to_i
          if existence_scale > 12
            existence_scale = 12
          end
          modified_result.fill(2, 0, existence_scale)
          total = results_multiplication(modified_result)
          message = "概念の同化 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        else
          message = "エラー：事象強度を指定してください。"
        end
        return message
      end

      # 下位存在
      def origin_normal()
        natural_result = @randomizer.roll_barabara(1, 12)
        total = results_multiplication(natural_result)
        message = "下位存在 ＞ #{total}[#{natural_result.join(',')}]"
        return message
      end

      # 中位存在
      def origin_unique(order)
        natural_result = @randomizer.roll_barabara(2, 12)
        case order[1]
        when "G"
          message = fate_growth(natural_result, order)
        when "T"
          message = fate_transition(natural_result)
        when "C"
          message = fate_chance(natural_result)
        else
          total = results_multiplication(natural_result)
          message = "中位存在 ＞ #{total}[#{natural_result.join(',')}]"
        end
        return message
      end

      def fate_growth(natural_result, order)
        subtotal = results_multiplication(natural_result)
        total = subtotal
        if order.length > 2 && order[2] =~ /^\d+$/
          total += order[2].to_i
          message = "萌芽の中位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        else
          message = "萌芽の中位存在 ＞ #{subtotal}[#{natural_result.join(',')}]"
        end
        growth_level = order[2].to_i + 50
        message += "(成長段階：#{growth_level})"
        return message
      end

      def fate_transition(natural_result)
        modified_result = natural_result.dup
        modified_result << @randomizer.roll_d9
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "変遷の中位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_chance(natural_result)
        modified_result = natural_result.dup
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        if modified_result[0] == modified_result[1]
          total *= 24
          message = "偶然の中位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        else
          message = "偶然の中位存在 ＞ #{subtotal}[#{natural_result.join(',')}]"
        end
        return message
      end

      # 上位存在
      def origin_omnipotent(order)
        natural_result = @randomizer.roll_barabara(3, 12)

        case order[1]
        when "G"
          message = fate_god(natural_result)
        when "H"
          message = fate_holy(natural_result)
        when "W"
          message = fate_wicked(natural_result)
        when "M"
          message = fate_malice(natural_result)
        when "S"
          message = fate_sin(natural_result, order)
        when "D"
          message = fate_destruction(natural_result)
        when "A"
          message = fate_anguish(natural_result)
        when "O"
          message = fate_ordeal(natural_result)
        when "C"
          message = fate_creation(natural_result)
        when "E"
          message = fate_element()
        else
          total = results_multiplication(natural_result)
          message = "上位存在 ＞ #{total}[#{natural_result.join(',')}]"
        end

        return message
      end

      def fate_god(natural_result)
        modified_result = []
        natural_result.each do |result|
          modified_result << result + 3
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "大神の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_holy(natural_result)
        modified_result = []
        natural_result.each do |result|
          modified_result << result + 1
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "神性の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_wicked(natural_result)
        subtotal = results_multiplication(natural_result)
        total = subtotal + 120
        message = "魔性の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        return message
      end

      def fate_malice(natural_result)
        subtotal = results_multiplication(natural_result)
        total = subtotal * 2
        message = "悪意の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}"
        return message
      end

      def fate_sin(natural_result, order)
        subtotal = results_multiplication(natural_result)
        total = subtotal
        if order.length > 2 && order[2] =~ /^\d+$/
          message = "大罪の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}]"
          sin_weight = order[2].to_i
          sin_count = 0
          while sin_count < 3 && total < sin_weight
            modified_result = @randomizer.roll_barabara(3, 12)
            total = results_multiplication(modified_result)
            message += " ＞ #{total}[#{modified_result.join(',')}]"
            sin_count += 1
          end
        else
          message = "エラー：罪の重さを指定してください。"
        end
        return message
      end

      def fate_destruction(natural_result)
        modified_result = natural_result.dup
        modified_result << @randomizer.roll_once(12)
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result) - 300
        message = "破壊の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_anguish(natural_result)
        modified_result = []
        natural_result.each do |result|
          if result < 7
            result = 7
          end
          modified_result << result
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "懊悩の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_ordeal(natural_result)
        modified_result = []
        natural_result.each do |result|
          if result < 9
            result = 9
          end
          modified_result << result
        end
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "試練の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      def fate_creation(natural_result)
        modified_result = natural_result.dup
        temporary_result = natural_result.dup
        temporary_result.sort!
        modified_result << temporary_result[1]
        subtotal = results_multiplication(natural_result)
        total = results_multiplication(modified_result)
        message = "創造の上位存在 ＞ #{subtotal}[#{natural_result.join(',')}] ＞ #{total}[#{modified_result.join(',')}]"
        return message
      end

      def fate_element()
        modified_result = []
        modified_result << @randomizer.roll_once(4)
        modified_result << @randomizer.roll_once(6)
        modified_result << @randomizer.roll_once(8)
        modified_result << @randomizer.roll_once(12)
        modified_result << @randomizer.roll_once(20)
        total = results_multiplication(modified_result)
        message = "元素の上位存在 ＞ #{total}[#{modified_result.join(',')}]"
        return  message
      end

      # 汎用
      def results_multiplication(result_list)
        total = 1
        result_list.each do |result|
          total *= result
        end
        return total
      end

      def stranger_effection(result_list)
        stranger_list = []
        result_list.each do |result|
          stranger_list << result - 1
        end
        return stranger_list
      end

      def result_raoundup(result)
        if result.even?
          return result / 2
        else
          return result / 2 + 1
        end
      end
    end
  end
end
