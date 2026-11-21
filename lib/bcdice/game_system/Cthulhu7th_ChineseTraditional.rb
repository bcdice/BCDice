# frozen_string_literal: true

require "bcdice/game_system/Cthulhu7th_ChineseTraditional/rollable"
require "bcdice/game_system/Cthulhu7th_ChineseTraditional/full_auto"

module BCDice
  module GameSystem
    class Cthulhu7th_ChineseTraditional < Base
      # ゲームシステムの識別子
      ID = 'Cthulhu7th:ChineseTraditional'

      # ゲームシステム名
      NAME = '克蘇魯神話第7版'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Chinese Traditional:克蘇魯神話第7版'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定 CC(x)<=（目標值）
        x：獎勵或懲罰骰，可以省略。
        即使沒有目標值，也會顯示1D100。
        自動判定：大失敗／失敗／成功／一般成功／困難成功／極限成功／大成功。
        例）CC<=30，CC2<=50，CC(+2)<=50，CC(-1)<=75，CC-1<=50，CC1<=65，CC+1<=65，CC

        ・技能擲骰的難度指定 CC(x)<=(目標值)(難度)
        透過指定難度，大失敗/成功／失敗／大成功／失敗將自動判定。
        指定難度：
        r：常規，h：困難，e：極限，c：大成功
        例）CC<=70r，CC1<=60h，CC-2<=50e，CC2<=99c

        ・組合判定 (CBR(x,y))
        對於目標值 x 和 y 進行百分比擲骰並判定成敗。
        例）CBR(50,20)

        ・機關槍的射擊判定 FAR(w,x,y,z,d,v)
        w：子彈數量（1～100）， x：技能值（1～100）， y：故障值，
        z：獎勵或懲罰骰（-2～2），可以省略。
        d：指定難度以結束連射（常規：r，困難：h，極限：e），可以省略。
        v：更改彈藥的數量，可以省略。
        只計算命中數和貫通數，剩餘彈藥數。傷害計算不包括在內。
        例）FAR(25,70,98)， FAR(50,80,98,-1)， far(30,70,99,1,R)
        far(25,88,96,2,h,5)， FaR(40,77,100,,e,4)， fAr(20,47,100,,,3)

        ・各種表
        【狂氣相關】
        ・即時型瘋狂檢定（Bouts of Madness Real Time） CCRT
        ・總結型瘋狂檢定（Bouts of Madness Summary） CCSU
        ・恐懼症表（Sample Phobias） CCPH／狂熱症表（Sample Manias） CCMA
        【魔術相關】
        ・推骰時施法失敗擲骰表（Casting Roll）
        弱小咒語的情況 CCCL／強力咒語的情況 CCPC
      INFO_MESSAGE_TEXT

      register_prefix('CC', 'CBR', 'FAR', 'CCRT', 'CCSU', 'CCCL', 'CCPC', 'CCPH', 'CCMA')

      def eval_game_system_specific_command(command)
        case command
        when /^CBR/i
          combine_roll(command)
        when /^FAR/i
          getFullAutoResult(command)
        when "CCRT" # 狂氣の發作（即時）
          roll_CCRT_table()
        when "CCSU" # 狂気の發作（總結型）
          roll_CCSU_table()
        when "CCCL" # キャスティング・ロールのプッシュに失敗した場合（小）
          roll_1d8_table("推骰時施法失敗擲骰表(小)", FAILED_CASTING_L_TABLE)
        when "CCPC" # キャスティング・ロールのプッシュに失敗した場合（大）
          roll_1d8_table("推骰時施法失敗擲骰表(大)", FAILED_CASTING_M_TABLE)
        when "CCPH" # 恐懼症表
          roll_1d100_table("恐懼症表", PHOBIAS_TABLE)
        when "CCMA" # 狂熱症表
          roll_1d100_table("狂熱症表", MANIAS_TABLE)
        when /^CC/i
          skill_roll(command)
        end
      end

      class ResultLevel
        LEVEL = [
          :fumble,
          :failure,
          :success,
          :regular_success,
          :hard_success,
          :extreme_success,
          :critical,
        ].freeze

        LEVEL_TO_S = {
          critical: "大成功",
          extreme_success: "極限成功",
          hard_success: "困難成功",
          regular_success: "一般成功",
          success: "成功",
          fumble: "大失敗",
          failure: "失敗",
        }.freeze

        def self.with_difficulty_level(total, difficulty)
          fumble = difficulty < 50 ? 96 : 100

          if total == 1
            ResultLevel.new(:critical)
          elsif total >= fumble
            ResultLevel.new(:fumble)
          elsif total <= difficulty
            ResultLevel.new(:success)
          else
            ResultLevel.new(:failure)
          end
        end

        def self.from_values(total, difficulty, fumbleable = false)
          fumble = difficulty < 50 || fumbleable ? 96 : 100

          if total == 1
            ResultLevel.new(:critical)
          elsif total >= fumble
            ResultLevel.new(:fumble)
          elsif total <= (difficulty / 5)
            ResultLevel.new(:extreme_success)
          elsif total <= (difficulty / 2)
            ResultLevel.new(:hard_success)
          elsif total <= difficulty
            ResultLevel.new(:regular_success)
          else
            ResultLevel.new(:failure)
          end
        end

        def initialize(level)
          @level = level
          @level_index = LEVEL.index(level)
          raise ArgumentError unless @level_index
        end

        def success?
          @level_index >= LEVEL.index(:success)
        end

        def failure?
          @level_index <= LEVEL.index(:failure)
        end

        def critical?
          @level == :critical
        end

        def fumble?
          @level == :fumble
        end

        def to_s
          LEVEL_TO_S[@level]
        end
      end

      private

      include Rollable

      def roll_1d8_table(table_name, table)
        total_n = @randomizer.roll_once(8)
        index = total_n - 1

        text = table[index]

        return "#{table_name}(#{total_n}) ＞ #{text}"
      end

      def roll_1d100_table(table_name, table)
        total_n = @randomizer.roll_once(100)
        index = total_n - 1

        text = table[index]

        return "#{table_name}(#{total_n}) ＞ #{text}"
      end

      def skill_roll(command)
        m = /^CC([-+]?\d+)?(?:<=(\d+)([RHEC])?)?$/.match(command)
        unless m
          return nil
        end

        bonus_dice = m[1].to_i
        difficulty = m[2]&.to_i
        difficulty_level = m[3]

        if difficulty == 0
          difficulty = nil
        elsif difficulty_level == "H"
          difficulty /= 2
        elsif difficulty_level == "E"
          difficulty /= 5
        elsif difficulty_level == "C"
          difficulty = 0
        end

        if bonus_dice == 0 && difficulty.nil?
          dice = @randomizer.roll_once(100)
          return "1D100 ＞ #{dice}"
        end

        if bonus_dice.abs > 100
          return "請將獎勵・懲罰骰的數量設置在-100以上及100以下"
        end

        total, total_list = roll_with_bonus(bonus_dice)

        expr = difficulty.nil? ? "1D100" : "1D100<=#{difficulty}"
        result =
          if difficulty_level
            ResultLevel.with_difficulty_level(total, difficulty)
          elsif difficulty
            ResultLevel.from_values(total, difficulty)
          end

        sequence = [
          "(#{expr}) 獎勵・懲罰骰[#{bonus_dice}]",
          total_list.join(", "),
          total,
          result,
        ].compact

        Result.new.tap do |r|
          r.text = sequence.join(" ＞ ")
          if result
            r.condition = result.success?
            r.critical = result.critical?
            r.fumble = result.fumble?
          end
        end
      end

      def getFullAutoResult(command)
        FullAuto.eval(command, @randomizer)
      end

      def combine_roll(command)
        m = /^CBR\((\d+),(\d+)\)$/.match(command)
        return nil unless m

        difficulty_1 = m[1].to_i
        difficulty_2 = m[2].to_i

        total = @randomizer.roll_once(100)

        result_1 = ResultLevel.from_values(total, difficulty_1)
        result_2 = ResultLevel.from_values(total, difficulty_2)

        rank =
          if result_1.success? && result_2.success?
            "成功"
          elsif result_1.success? || result_2.success?
            "部分成功"
          else
            "失敗"
          end

        Result.new.tap do |r|
          r.text = "(1d100<=#{difficulty_1},#{difficulty_2}) ＞ #{total}[#{result_1},#{result_2}] ＞ #{rank}"
          r.success = result_1.success? && result_2.success?
          r.failure = result_1.failure? && result_2.failure?
        end
      end

      # 表一式
      # 即時の恐懼症表
      def roll_CCRT_table()
        total_n = @randomizer.roll_once(10)
        text = MADNESS_REAL_TIME_TABLE[total_n - 1]

        time_n = @randomizer.roll_once(10)

        return "瘋狂發作（即時型）(#{total_n}) ＞ #{text}(1D10＞#{time_n}回合)"
      end

      MADNESS_REAL_TIME_TABLE = [
        '失憶（Amnesia）：調查員完全忘記了自上個安全地點以來的所有記憶。對他們而言，似乎上一刻還在享用早餐，下一瞬卻面對著可怕的怪物。',
        '假性殘疾（Psychosomatic Disability）：調查員經歷著心理上的失明、失聰或肢體缺失感，陷入無法自救的困境。',
        '暴力傾向（Violence）：調查員在一陣狂暴中失去理智，對周圍的敵人與友方展開毫不留情的攻擊。',
        '偏執（Paranoia）：調查員經歷著嚴重的偏執妄想，他感覺到每個人都在暗中威脅他！沒有一個人可被信任！他被無形的目光監視；他將被背叛；所見的一切皆是詭計，萬事皆虛。',
        '人際依賴（Significant Person）：守秘人細心檢視調查員背景中的重要人物條目。調查員誤將場景中的另一人視為其重要人物，並基於這種錯誤的認知行動。',
        '昏厥（Faint）：調查員突然失去意識，陷入短暫的昏迷。',
        '逃避行為（Flee in Panic）：調查員在極度恐慌中，無論如何都想逃離當前的境地，即使這意味著奪走唯一的交通工具且撇下他人。',
        '歇斯底里（Physical Hysterics or Emotional Outburst）：調查員在情緒的漩渦中崩潰，表現出無法控制的大笑、哭泣或尖叫等極端情感。',
        '恐懼（Phobia）：調查員突如其來地產生一種新的恐懼症，例如幽閉恐懼症、惡靈恐懼症或蟑螂恐懼症。即使恐懼的來源並不在場，他們在接下來的輪數中仍會想像其存在，所有行動都將受到懲罰骰的影響。',
        '狂躁（Mania）：調查員獲得一種新的狂躁症，例如嚴重的潔癖強迫症、非理性的說謊強迫症或異常喜愛蠕蟲的強迫症。在接下來的輪數內，他們會不斷追求滿足這種狂躁，所有行動都將受到懲罰骰的影響。',
      ].freeze

      # 略式の恐怖表
      def roll_CCSU_table()
        total_n = @randomizer.roll_once(10)
        text = MADNESS_SUMMARY_TABLE[total_n - 1]

        time_n = @randomizer.roll_once(10)

        return "狂氣發作（總結型）(#{total_n}) ＞ #{text}(1D10＞#{time_n}時間)"
      end

      MADNESS_SUMMARY_TABLE = [
        '失憶（Amnesia）：調查員回過神來，發現自己身處一個陌生的地方，完全忘記了自己的身份。記憶將隨著時間的推移逐漸恢復。',
        '被盜（Robbed）：調查員在恢復意識後，驚覺自己身體無恙，卻遭到盜竊。如果他們攜帶了珍貴之物（見調查員背景），則需進行幸運檢定以決定是否被竊取。其他所有有價值的物品則自動消失。',
        '遍體鱗傷（Battered）：調查員在醒來後，發現自己滿身是傷，傷痕纍累。生命值減少至瘋狂前的一半，但不會造成重傷。他們並未遭到盜竊，傷害的來源由守秘人決定。',
        '暴力傾向（Violence）：調查員陷入一場強烈的暴力與破壞的狂潮。當他們回過神來時，可能會意識到自己所做的事情，也可能完全失去記憶。調查員施加暴力的對象，以及是否造成死亡或僅僅是傷害，均由守秘人決定。',
        '極端信念（Ideology/Beliefs）：查看調查員背景中的思想與信念。調查員將以極端且瘋狂的方式表現出某種信念。例如，一位虔誠的信徒可能會在地鐵上高聲傳道。',
        '重要之人（Significant People）：考慮調查員背景中對其至關重要的人物及其原因。在那1D10小時或更久的時間內，調查員曾不顧一切地接近那個人，並努力加深彼此的關係。',
        '被收容（Institutionalized）：調查員在精神病院病房或警察局牢房中醒來，慢慢回想起導致自己被關押的經過。',
        '逃避行為（Flee in panic）：調查員恢復意識時，發現自己身處遙遠的地方，可能迷失在荒野，或是在開往未知目的地的列車或長途巴士上。',
        '恐懼（Phobia）：調查員突然獲得一種新的恐懼症。擲1D100以決定具體的恐懼症狀，或由守秘人選擇。調查員醒來後，會開始採取各種措施以避開恐懼的源頭。',
        '狂躁（Mania）：調查員獲得一種新的狂躁症。在表中擲1D100以決定具體的狂躁症狀，或由守秘人選擇。在這次瘋狂的發作中，調查員將全然沉浸於新的狂躁症狀中。該症狀是否對他人可見則取決於守秘人和調查員。',
      ].freeze

      # キャスティング・ロールのプッシュに失敗した場合（小）
      FAILED_CASTING_L_TABLE = [
        '視力模糊或暫時失明。',
        '殘缺不全的尖叫聲、聲音或其他噪音。',
        '強烈的風或其他大氣效應。',
        '流血——可能是由於施法者、在場其他人或環境（如牆壁）的出血。',
        '奇異的幻象和幻覺。',
        '周圍的小動物爆炸。',
        '異臭的硫磺味。',
        '不小心召喚了神話生物。',
      ].freeze

      # キャスティング・ロールのプッシュに失敗した場合（大）
      FAILED_CASTING_M_TABLE = [
        '大地震動，牆壁破裂。',
        '巨大的雷電聲。',
        '血從天而降。',
        '施法者的手被乾枯和燒焦。',
        '施法者不正常地老化（年齡增加2D10歲，並應用特徵修正，請參見老化規則）。',
        '強大或眾多的神話生物出現，從施法者開始攻擊附近所有人！',
        '施法者或附近的所有人被吸到遙遠的時間或地方。',
        '不小心召喚了神話神明。',
      ].freeze

      # 恐懼症表
      PHOBIAS_TABLE = [
        '洗澡恐懼症（Ablutophobia）：對於洗滌或洗澡的恐懼。',
        '恐高症（Acrophobia）：對於身處高處的恐懼。',
        '飛行恐懼症（Aerophobia）：對飛行的恐懼。',
        '廣場恐懼症（Agoraphobia）：對於開放的（擁擠）公共場所的恐懼。',
        '恐鶏症（Alektorophobia）：對鶏的恐懼。',
        '大蒜恐懼症（Alliumphobia）：對大蒜的恐懼。',
        '乘車恐懼症（Amaxophobia）：對於乘坐地面載具的恐懼。',
        '恐風症（Ancraophobia）：對風的恐懼。',
        '男性恐懼症（Androphobia）：對於成年男性的恐懼。',
        '恐英症（Anglophobia）：對英格蘭或英格蘭文化的恐懼。',
        '恐花症（Anthophobia）：對花的恐懼。',
        '截肢者恐懼症（Apotemnophobia）：對截肢者的恐懼。',
        '蜘蛛恐懼症（Arachnophobia）：對蜘蛛的恐懼。',
        '閃電恐懼症（Astraphobia）：對閃電的恐懼。',
        '廢墟恐懼症（Atephobia）：對遺迹或殘址的恐懼。',
        '長笛恐懼症（Aulophobia）：對長笛的恐懼。',
        '細菌恐懼症（Bacteriophobia）：對細菌的恐懼。',
        '導彈/子彈恐懼症（Ballistophobia）：對導彈或子彈的恐懼。',
        '跌落恐懼症（Basophobia）：對於跌倒或摔落的恐懼。',
        '書籍恐懼症（Bibliophobia）：對書籍的恐懼。',
        '植物恐懼症（Botanophobia）：對植物的恐懼。',
        '美女恐懼症（Caligynephobia）：對美貌女性的恐懼。',
        '寒冷恐懼症（Cheimaphobia）：對寒冷的恐懼。',
        '恐鐘錶症（Chronomentrophobia）：對於鐘錶的恐懼。',
        '幽閉恐懼症（Claustrophobia）：對於處在封閉的空間中的恐懼。',
        '小丑恐懼症（Coulrophobia）：對小丑的恐懼。',
        '恐犬症（Cynophobia）：對狗的恐懼。',
        '惡魔恐懼症（Demonophobia）：對邪靈或惡魔的恐懼。',
        '人群恐懼症（Demophobia）：對人群的恐懼。',
        '牙科恐懼症①（Dentophobia）：對牙醫的恐懼。',
        '丟弃恐懼症（Disposophobia）：對於丟弃物件的恐懼（貯藏癖）。',
        '皮毛恐懼症（Doraphobia）：對動物皮毛的恐懼。',
        '過馬路恐懼症（Dromophobia）：對於過馬路的恐懼。',
        '教堂恐懼症（Ecclesiophobia）：對教堂的恐懼。',
        '鏡子恐懼症（Eisoptrophobia）：對鏡子的恐懼。',
        '針尖恐懼症（Enetophobia）：對針或大頭針的恐懼。',
        '昆蟲恐懼症（Entomophobia）：對昆蟲的恐懼。',
        '恐猫症（Felinophobia）：對猫的恐懼。',
        '過橋恐懼症（Gephyrophobia）：對於過橋的恐懼。',
        '恐老症（Gerontophobia）：對於老年人或變老的恐懼。',
        '恐女症（Gynophobia）：對女性的恐懼。',
        '恐血症（Haemaphobia）：對血的恐懼。',
        '宗教罪行恐懼症（Hamartophobia）：對宗教罪行的恐懼。',
        '觸摸恐懼症（Haphophobia）：對於被觸摸的恐懼。',
        '爬蟲恐懼症（Herpetophobia）：對爬行動物的恐懼。',
        '迷霧恐懼症（Homichlophobia）：對霧的恐懼。',
        '火器恐懼症（Hoplophobia）：對火器的恐懼。',
        '恐水症（Hydrophobia）：對水的恐懼。',
        '催眠恐懼症①（Hypnophobia）：對於睡眠或被催眠的恐懼。',
        '白袍恐懼症（Iatrophobia）：對醫生的恐懼。',
        '魚類恐懼症（Ichthyophobia）：對魚的恐懼。',
        '蟑螂恐懼症（Katsaridaphobia）：對蟑螂的恐懼。',
        '雷鳴恐懼症（Keraunophobia）：對雷聲的恐懼。',
        '蔬菜恐懼症（Lachanophobia）：對蔬菜的恐懼。',
        '噪音恐懼症（Ligyrophobia）：對刺耳噪音的恐懼。',
        '恐湖症（Limnophobia）：對湖泊的恐懼。',
        '機械恐懼症（Mechanophobia）：對機器或機械的恐懼。',
        '巨物恐懼症（Megalophobia）：對於龐大物件的恐懼。',
        '捆綁恐懼症（Merinthophobia）：對於被捆綁或緊縛的恐懼。',
        '流星恐懼症（Meteorophobia）：對流星或隕石的恐懼。',
        '孤獨恐懼症（Monophobia）：對於一人獨處的恐懼。',
        '不潔恐懼症（Mysophobia）：對污垢或污染的恐懼。',
        '粘液恐懼症（Myxophobia）：對粘液（史萊姆）的恐懼。',
        '屍體恐懼症（Necrophobia）：對屍體的恐懼。',
        '數字8恐懼症（Octophobia）：對數字8的恐懼。',
        '恐牙症（Odontophobia）：對牙齒的恐懼。',
        '恐夢症（Oneirophobia）：對夢境的恐懼。',
        '稱呼恐懼症（Onomatophobia）：對於特定詞語的恐懼。',
        '恐蛇症（Ophidiophobia）：對蛇的恐懼。',
        '恐鳥症（Ornithophobia）：對鳥的恐懼。',
        '寄生蟲恐懼症（Parasitophobia）：對寄生蟲的恐懼。',
        '人偶恐懼症（Pediophobia）：對人偶的恐懼。',
        '吞咽恐懼症（Phagophobia）：對於吞咽或被吞咽的恐懼。',
        '藥物恐懼症（Pharmacophobia）：對藥物的恐懼。',
        '幽靈恐懼症（Phasmophobia）：對鬼魂的恐懼。',
        '日光恐懼症（Phenogophobia）：對日光的恐懼。',
        '鬍鬚恐懼症（Pogonophobia）：對鬍鬚的恐懼。',
        '河流恐懼症（Potamophobia）：對河流的恐懼。',
        '酒精恐懼症（Potophobia）：對酒或酒精的恐懼。',
        '恐火症（Pyrophobia）：對火的恐懼。',
        '魔法恐懼症（Rhabdophobia）：對魔法的恐懼。',
        '黑暗恐懼症（Scotophobia）：對黑暗或夜晚的恐懼。',
        '恐月症（Selenophobia）：對月亮的恐懼。',
        '火車恐懼症（Siderodromophobia）：對於乘坐火車出行的恐懼。',
        '恐星症（Siderophobia）：對星星的恐懼。',
        '狹室恐懼症（Stenophobia）：對狹小物件或地點的恐懼。',
        '對稱恐懼症（Symmetrophobia）：對對稱的恐懼。',
        '活埋恐懼症（Taphephobia）：對於被活埋或墓地的恐懼。',
        '公牛恐懼症（Taurophobia）：對公牛的恐懼。',
        '電話恐懼症（Telephonophobia）：對電話的恐懼。',
        '怪物恐懼症①（Teratophobia）：對怪物的恐懼。',
        '深海恐懼症（Thalassophobia）：對海洋的恐懼。',
        '手術恐懼症（Tomophobia）：對外科手術的恐懼。',
        '十三恐懼症（Triskadekaphobia）：對數字13的恐懼症。',
        '衣物恐懼症（Vestiphobia）：對衣物的恐懼。',
        '女巫恐懼症（Wiccaphobia）：對女巫與巫術的恐懼。',
        '黃色恐懼症（Xanthophobia）：對黃色或「黃」字的恐懼。',
        '外語恐懼症（Xenoglossophobia）：對外語的恐懼。',
        '异域恐懼症（Xenophobia）：對陌生人或外國人的恐懼。',
        '動物恐懼症（Zoophobia）：對動物的恐懼。',
      ].freeze

      # 狂熱症表
      MANIAS_TABLE = [
        '沐浴癖（Ablutomania）：執著於清洗自己。',
        '猶豫癖（Aboulomania）：病態地猶豫不定。',
        '喜暗狂（Achluomania）：對黑暗的過度熱愛。',
        '喜高狂（Acromaniaheights）：狂熱迷戀高處。',
        '親切癖（Agathomania）：病態地對他人友好。',
        '喜曠症（Agromania）：强烈地傾向於待在開闊空間中。',
        '喜尖狂（Aichmomania）：痴迷於尖銳或鋒利的物體。',
        '戀猫狂（Ailuromania）：近乎病態地對猫友善。',
        '疼痛癖（Algomania）：痴迷於疼痛。',
        '喜蒜狂（Alliomania）：痴迷於大蒜。',
        '乘車癖（Amaxomania）：痴迷於乘坐車輛。',
        '欣快癖（Amenomania）：不正常地感到喜悅。',
        '喜花狂（Anthomania）：痴迷於花朵。',
        '計算癖（Arithmomania）：狂熱地痴迷於數字。',
        '消費癖（Asoticamania）：魯莽衝動地消費。',
        '隱居癖（Eremiomania）：過度地熱愛獨自隱居。',
        '芭蕾癖（Balletmania）：痴迷於芭蕾舞。',
        '竊書癖（Biliokleptomania）：無法克制偷竊書籍的衝動。',
        '戀書狂（Bibliomania）：痴迷於書籍和/或閱讀',
        '磨牙癖（Bruxomania）：無法克制磨牙的衝動。',
        '靈臆症（Cacodemomania）：病態地堅信自己已被一個邪惡的靈體占據。',
        '美貌狂（Callomania）：痴迷於自身的美貌。',
        '地圖狂（Cartacoethes）：在何時何處都無法控制查閱地圖的衝動。',
        '跳躍狂（Catapedamania）：痴迷於從高處跳下。',
        '喜冷症（Cheimatomania）：對寒冷或寒冷的物體的反常喜愛。',
        '舞蹈狂（Choreomania）：無法控制地起舞或發顫。',
        '戀床癖（Clinomania）：過度地熱愛待在床上。',
        '戀墓狂（Coimetormania）：痴迷於墓地。',
        '色彩狂（Coloromania）：痴迷於某種顔色。',
        '小丑狂（Coulromania）：痴迷於小丑。',
        '恐懼狂（Countermania）：執著於經歷恐怖的場面。',
        '殺戮癖（Dacnomania）：痴迷於殺戮。',
        '魔臆症（Demonomania）：病態地堅信自己已被惡魔附身。',
        '抓撓癖（Dermatillomania）：執著於抓撓自己的皮膚。',
        '正義狂（Dikemania）：痴迷於目睹正義被伸張。',
        '嗜酒狂（Dipsomania）：反常地渴求酒精。',
        '毛皮狂（Doramania）：痴迷於擁有毛皮。',
        '贈物癖（Doromania）：痴迷於贈送禮物。',
        '漂泊症（Drapetomania）：執著於逃離。',
        '漫游癖（Ecdemiomania）：執著於四處漫游。',
        '自戀狂（Egomania）：近乎病態地以自我爲中心或自我崇拜。',
        '職業狂（Empleomania）：對於工作的無盡病態渴求。',
        '臆罪症（Enosimania）：病態地堅信自己帶有罪孽。',
        '學識狂（Epistemomania）：痴迷於獲取學識。',
        '靜止癖（Eremiomania）：執著於保持安靜。',
        '乙醚上癮（Etheromania）：渴求乙醚。',
        '求婚狂（Gamomania）：痴迷於進行奇特的求婚。',
        '狂笑癖（Geliomania）：無法自製地，强迫性的大笑。',
        '巫術狂（Goetomania）：痴迷於女巫與巫術。',
        '寫作癖（Graphomania）：痴迷於將每一件事寫下來。',
        '裸體狂（Gymnomania）：執著於裸露身體。',
        '妄想狂（Habromania）：近乎病態地充滿愉快的妄想（而不顧現實狀况如何）。',
        '蠕蟲狂（Helminthomania）：過度地喜愛蠕蟲。',
        '槍械狂（Hoplomania）：痴迷於火器。',
        '飲水狂（Hydromania）：反常地渴求水分。',
        '喜魚癖（Ichthyomania）：痴迷於魚類。',
        '圖標狂（Iconomania）：痴迷於圖標與肖像',
        '偶像狂（Idolomania）：痴迷於甚至願獻身於某個偶像。',
        '信息狂（Infomania）：痴迷於積累各種信息與資訊。',
        '射擊狂（Klazomania）：反常地執著於射擊。',
        '偷竊癖（Kleptomania）：反常地執著於偷竊。',
        '噪音癖（Ligyromania）：無法自製地執著於製造響亮或刺耳的噪音。',
        '喜綫癖（Linonomania）：痴迷於綫繩。',
        '彩票狂（Lotterymania）：極端地執著於購買彩票。',
        '抑鬱症（Lypemania）：近乎病態的重度抑鬱傾向。',
        '巨石狂（Megalithomania）：當站在石環中或立起的巨石旁時，就會近乎病態地寫出各種奇怪的創意。',
        '旋律狂（Melomania）：痴迷於音樂或一段特定的旋律。',
        '作詩癖（Metromania）：無法抑制地想要不停作詩。',
        '憎恨癖（Misomania）：憎恨一切事物，痴迷於憎恨某個事物或團體。',
        '偏執狂（Monomania）：近乎病態地痴迷與專注某個特定的想法或創意。',
        '誇大癖（Mythomania）：以一種近乎病態的程度說謊或誇大事物。',
        '臆想症（Nosomania）：妄想自己正在被某種臆想出的疾病折磨。',
        '記錄癖（Notomania）：執著於記錄一切事物（例如攝影）',
        '戀名狂（Onomamania）：痴迷於名字（人物的、地點的、事物的）',
        '稱名癖（Onomatomania）：無法抑制地不斷重複某個詞語的衝動。',
        '剔指癖（Onychotillomania）：執著於剔指甲。',
        '戀食癖（Opsomania）：對某種食物的病態熱愛。',
        '抱怨癖（Paramania）：一種在抱怨時産生的近乎病態的愉悅感。',
        '面具狂（Personamania）：執著於佩戴面具。',
        '幽靈狂（Phasmomania）：痴迷於幽靈。',
        '謀殺癖（Phonomania）：病態的謀殺傾向。',
        '渴光癖（Photomania）：對光的病態渴求。',
        '背德癖（ASPD）：病態地渴求違背社會道德。',
        '求財癖（Plutomania）：對財富的强迫性的渴望。',
        '欺騙狂（Pseudomania）：無法抑制的執著於撒謊。',
        '縱火狂（Pyromania）：執著於縱火。',
        '提問狂（Questiong-Asking Mania）：執著於提問。',
        '挖鼻癖（Rhinotillexomania）：執著於挖鼻子。',
        '塗鴉癖（Scribbleomania）：沉迷於塗鴉。',
        '列車狂（Siderodromomania）：認爲火車或類似的依靠軌道交通的旅行方式充滿魅力。',
        '臆智症（Sophomania）：臆想自己擁有難以置信的智慧。',
        '科技狂（Technomania）：痴迷於新的科技。',
        '臆咒狂（Thanatomania）：堅信自己已被某種死亡魔法所詛咒。',
        '臆神狂（Theomania）：堅信自己是一位神靈。',
        '抓撓癖（Titillomaniac）：抓撓自己的强迫傾向。',
        '手術狂（Tomomania）：對進行手術的不正常愛好。',
        '拔毛癖（Trichotillomania）：執著於拔下自己的頭髮。',
        '臆盲症（Typhlomania）：病理性的失明。',
        '嗜外狂（Xenomania）：痴迷於异國的事物。',
        '喜獸癖（Zoomania）：對待動物的態度近乎瘋狂地友好。',
      ].freeze
    end
  end
end
