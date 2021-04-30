# frozen_string_literal: true

require "bcdice/game_system/satasupe/tables"

module BCDice
  module GameSystem
    class Satasupe < Base
      # ゲームシステムの識別子
      ID = 'Satasupe'

      # ゲームシステム名
      NAME = 'サタスペ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'さたすへ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定コマンド　(nR>=x[y,z,c] or nR>=x or nR>=[,,c] etc)
        　nが最大ロール回数、xが難易度、yが目標成功度、zがファンブル値、cが必殺値。
        　y と z と c は省略可能です。(省略時、y＝無制限、z＝1、c=13(なし))
        　c の後ろにSを記述すると必殺が出た時点で判定を終了します。
        　例）5R>=5[10,2,7S]
        ・性業値コマンド(SRx or SRx+y or SRx-y x=性業値 y=修正値)
        ・各種表 ： コマンド末尾に数字を入れると複数回の一括実行が可能　例）TAGT3
        　・タグ決定表(TAGT)
        　・命中判定ファンブル表(FumbleT)、致命傷表(FatalT)、
        　　　乗物致命傷表(FatalVT)
        　・ロマンスファンブル表(RomanceFT)
        　・アクシデント表(AccidentT)、汎用アクシデント表(GeneralAT)
        　・その後表　(AfterT)、臭い飯表(KusaiMT)、登場表(EnterT)、
        　　　落とし前表(PayT)、時間切れ表(TimeUT)、バッドトリップ表(BudTT)
        　・報酬表(Get〜) ： ガラクタ(GetgT)、実用品(GetzT)、値打ち物(GetnT)、
        　　　奇天烈(GetkT)
        　・NPCの年齢と好みを一括出力(NPCT)
        　・「サタスペ」のベースとアクセサリを出力(GETSSTx　xはアクセサリ数、省略時１)
        ・以下のコマンドは +,- でダイス目修正、=でダイス目指定が可能
        　例）CrimeIET+1　CrimeIET-1　CrimeIET=7
        　・情報イベント表(〜IET) ： 犯罪表(CrimeIET)、生活表(LifeIET)、
        　　　恋愛表(LoveIET)、教養表(CultureIET)、戦闘表(CombatIET)
        　・情報ハプニング表(〜IHT) ： 犯罪表(CrimeIHT)、生活表(LifeIHT)、
        　　　恋愛表(LoveIHT)、教養表(CultureIHT)、戦闘表(CombatIHT)
        　・遭遇表(～RET)：ミナミ遭遇表(MinamiRET)、中華街遭遇表(ChinatownRET)、
        　　　軍艦島遭遇表(WarshipLandRET)、官庁街遭遇表(CivicCenterRET)、
        　　　十三遭遇表(DowntownRET)、沙京遭遇表(ShaokinRET)、
        　　　らぶらぶ遭遇表(LoveLoveRET)、アジト遭遇表(AjitoRET)、
        　　　地獄湯遭遇表(JigokuSpaRET)、JAIL HOUSE遭遇表(JailHouseRET)
        　・イベント表(～IT)：治療イベント表(TreatmentIT)、大学イベント表(CollegeIT)
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      register_prefix('\d+R', 'SR', 'TAGT', 'GETSST', 'NPCT', TABLES.keys, ALIASES.keys)

      CREATE_ARMS_STRUCT = Struct.new(:base_parts, :accessory_parts, :parts_effect, :hit, :damage, :life, :kutibeni, :kiba, :abilities)

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command begin string", command)

        result = checkRoll(command)
        return result unless result.nil?

        debug("判定ロールではなかった")

        result = check_seigou(command)
        return result unless result.empty?

        debug("〔性業値〕チェックでもなかった")

        debug("各種表として処理")
        return rollTableCommand(command)
      end

      def checkRoll(string)
        debug("checkRoll begin string", string)

        m = /^(\d+)R>=(\d+)(\[(\d+)?(,|,\d+)?(,\d+(S)?)?\])?$/i.match(string)
        return nil unless m

        roll_times = m[1].to_i
        target = m[2].to_i
        params = m[3]

        min_suc, fumble, critical, is_critical_stop = get_roll_params(params)

        result = ""

        if target > 12
          result += "【#{string}】 ＞ 難易度が12を超えたため、超過分、ファンブル率が上昇！\n"
          while target > 12
            target -= 1
            fumble += 1
          end
        end

        if (critical < 1) || (critical > 12)
          critical = 13
        end

        if fumble >= 6
          result += "#{get_judge_info(target, fumble, critical)} ＞ ファンブル率が6を超えたため自動失敗！"
          return Result.failure(result)
        end

        if target < 5
          result += "【#{string}】 ＞ あらゆる難易度は5未満にはならないため、難易度は5になる！\n"
          target = 5
        end

        dice_str, total_suc, is_critical, is_fumble = check_roll_loop(roll_times, min_suc, target, critical, fumble, is_critical_stop)

        result += "#{get_judge_info(target, fumble, critical)} ＞ #{dice_str} ＞ 成功度#{total_suc}"

        if is_fumble
          result += " ＞ ファンブル"
        end

        if is_critical && (total_suc > 0)
          result += " ＞ 必殺発動可能！"
        end

        debug('checkRoll result result', result)

        return Result.new.tap do |r|
          r.text = result
          r.success = !is_fumble && min_suc > 0 && total_suc >= min_suc
          r.failure = is_fumble
          r.critical = is_critical
          r.fumble = is_fumble
        end
      end

      def get_roll_params(params)
        min_suc = 0
        fumble = 1
        critical = 13
        isCriticalStop = false

        # params => "[x,y,cS]"
        # ゲームシステムの識別子
        # ゲームシステム名
        # ゲームシステム名の読みがな
        # ダイスボットの使い方
        # params => "[x,y,cS]"
        unless params.nil?
          m = /\[(\d*)(,(\d*)?)?(,(\d*)(S)?)?\]/.match(params)
          if m
            min_suc = m[1].to_i
            fumble = m[3].to_i if m[3].to_i != 0
            critical = m[5].to_i if m[4]
            isCriticalStop = !m[6].nil?
          end
        end

        return min_suc, fumble, critical, isCriticalStop
      end

      def get_judge_info(target, fumble, critical)
        return "【難易度#{target}、ファンブル率#{fumble}、必殺#{critical == 13 ? 'なし' : critical.to_s}】"
      end

      def check_roll_loop(roll_times, min_suc, target, critical, fumble, is_critical_stop)
        dice_str = ''
        is_fumble = false
        is_critical = false
        total_suc = 0

        roll_times.times do |_i|
          debug('roll_times', roll_times)

          debug('min_suc, total_suc', min_suc, total_suc)
          # ゲームシステムの識別子
          # ゲームシステム名
          # ゲームシステム名の読みがな
          # ダイスボットの使い方
          # params => "[x,y,cS]"
          if min_suc != 0 && (total_suc >= min_suc)
            debug('(total_suc >= min_suc) break')
            break
          end

          d1 = @randomizer.roll_once(6)
          d2 = @randomizer.roll_once(6)

          dice_suc = 0
          dice_suc = 1 if target <= (d1 + d2)
          dice_str += "+" unless dice_str.empty?
          dice_str += "#{dice_suc}[#{d1},#{d2}]"
          total_suc += dice_suc

          if critical <= d1 + d2
            is_critical = true
            dice_str += "『必殺！』"
          end

          if (d1 == d2) && (d1 <= fumble) # ファンブルの確認
            is_fumble = true
            is_critical = false
            break
          end

          if is_critical && is_critical_stop # 必殺止めの確認
            break
          end
        end

        return dice_str, total_suc, is_critical, is_fumble
      end

      def check_seigou(string)
        debug("check_seigou begin string", string)

        m = /^SR(\d+).*$/i.match(string)
        return '' unless m

        target = m[1].to_i
        sr_parser = Command::Parser.new(/SR\d+/i, round_type: round_type)
                                   .restrict_cmp_op_to(nil)
        cmd = sr_parser.parse(string)
        return '' unless cmd

        dice = @randomizer.roll_sum(2, 6)
        diceTotal = dice + cmd.modify_number

        seigou = if target < diceTotal
                   "「激」"
                 elsif target > diceTotal
                   "「律」"
                 else # target == diceTotal
                   "「迷」"
                 end

        result = "〔性業値〕#{target}、「修正値」#{cmd.modify_number} ＞ ダイス結果：（#{dice}） ＞ #{dice}＋（#{cmd.modify_number}）＝#{diceTotal} ＞ #{seigou}"

        result += " ＞ 1ゾロのため〔性業値〕が1点上昇！" if dice == 2
        result += " ＞ 6ゾロのため〔性業値〕が1点減少！" if dice == 12

        debug('check_seigou result result', result)
        return result
      end

      ####################
      # 各種表

      def rollTableCommand(command)
        command = command.upcase
        result = []

        m = /([A-Za-z]+)(\d+)?(([+]|-|=)(\d+))?/.match(command)
        return result unless m

        command = m[1]
        counts = 1
        counts = m[2].to_i if m[2]
        operator = m[4]
        value = m[5].to_i

        debug("eval_game_system_specific_command command", command)

        case command
        when "TAGT"
          result = getTagTableResult(counts)

        when "GETSST"
          result = getCreateSatasupeResult(counts)

        when "NPCT"
          result = getNpcTableResult(counts)
        else
          result = getAnotherTableResult(command, counts, operator, value)
        end

        return result.join("\n")
      end

      def getTagTableResult(counts)
        result = []

        counts.times do |_i|
          roll_result = TAG_TABLE.roll(@randomizer)
          result.push("#{roll_result.table_name}:#{roll_result.value}:#{roll_result.body}")
        end

        return result
      end

      def getCreateSatasupeResult(counts)
        debug("getCreateSatasupeResult counts", counts)

        name = "サタスペ作成"

        arm = case @randomizer.roll_once(6)
              when 1
                CREATE_ARMS_STRUCT.new("「紙製の筒」", [], ["「命中：10、ダメージ：3、耐久度1」"], 10, 3, 1, 0, 0, [])
              when 2
                CREATE_ARMS_STRUCT.new("「木製の筒」", [], ["「命中：9、ダメージ：3、耐久度2」"], 9, 3, 2, 0, 0, [])
              when 3
                CREATE_ARMS_STRUCT.new("「小型のプラスチック製の筒」", [], ["「命中：9、ダメージ：4、耐久度2」"], 9, 4, 2, 0, 0, [])
              when 4
                CREATE_ARMS_STRUCT.new("「大型のプラスチック製の筒」", [], ["「命中：8、ダメージ：3、耐久度2、両手」"], 8, 3, 2, 0, 0, ["「両手」"])
              when 5
                CREATE_ARMS_STRUCT.new("「小型の金属製の筒」", [], ["「命中：9、ダメージ：4、耐久度3」"], 9, 4, 3, 0, 0, [])
              when 6
                CREATE_ARMS_STRUCT.new("「大型の金属製の筒」", [], ["「命中：8、ダメージ：5、耐久度3、両手」"], 8, 5, 3, 0, 0, ["「両手」"])
              end

        counts.times do |_i|
          part, effect, modifier = CREATE_ARMS_ACCESSORY_TABLE[@randomizer.roll_d66(D66SortType::ASC)]
          arm.accessory_parts << part
          arm.parts_effect << effect
          modifier.call(arm, @randomizer)
        end

        result = []
        result.push("#{name}：ベース部品：#{arm.base_parts}  アクセサリ部品：#{arm.accessory_parts.join}")
        result.push("部品効果：#{arm.parts_effect.join}")

        text = "完成品：サタスペ  （ダメージ＋#{arm.damage}・命中#{arm.hit}・射撃、"
        text += "「（判定前宣言）#{arm.kutibeni}回だけ、必殺10」" if arm.kutibeni > 0
        text += "「（判定前宣言）#{arm.kiba}回だけ、ダメージ＋２」" if arm.kiba > 0

        text += arm.abilities.sort.uniq.join

        text += "「サタスペ#{counts}」「耐久度#{arm.life}」）"

        result.push(text)

        return result
      end

      def getNpcTableResult(counts)
        name = "NPC表:"

        result = []

        counts.times do |_i|
          age, agen_const, agen_times = NPC_AGE_TABLE[@randomizer.roll_index(6)]
          ysold = @randomizer.roll_sum(agen_times, 6) + agen_const

          lmodValue = NPC_LMOOD_TABLE[@randomizer.roll_index(6)]
          lageValue = NPC_LAGE_TABLE[@randomizer.roll_index(3)]

          text = "#{name}#{age}(#{ysold}歳):#{lmodValue}#{lageValue}"
          result.push(text)
        end

        return result
      end

      def getAnotherTableResult(command, counts, operator, value)
        result = []

        table_name = ALIASES[command] || command
        table = TABLES[table_name]
        return result if table.nil?

        counts.times do |_i|
          _, index = getTableIndex(operator, value, 2, 6)

          info = table.choice(index)
          text = "#{info.table_name}:#{info.value}:#{info.body}"
          result.push(text)
        end

        return result
      end

      def getTableIndex(operator, value, diceCount, diceType)
        index = nil
        modify = 0

        case operator
        when "+"
          modify = value
        when "-"
          modify = value * -1
        when "="
          index = value
        end

        if index.nil?
          index = @randomizer.roll_sum(diceCount, diceType)
          index += modify
        end

        index = [index, diceCount * 1].max
        index = [index, diceCount * diceType].min

        return modify, index
      end
    end
  end
end
