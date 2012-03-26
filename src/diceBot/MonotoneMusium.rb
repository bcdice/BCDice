#--*-coding:utf-8-*--

class MonotoneMusium < DiceBot
  
  def initialize
    super
    
    @sendMode = 2
    @d66Type = 1
    @sortType = 1
  end
  
  def gameType
    "MonotoneMusium"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・モノトーンミュージアム　　判定　(2D6+m>=t[c,f])　(m:修正, t:目標値, c:クリティカル値, f:ファンブル値)
　　　　　　　　　　　　　兆候表　(OT)
　　　　　　　　　　　　　歪み表　(DT)
　　　　　　　　　　　世界歪曲表　(WDT)
MESSAGETEXT
  end
  
  def changeText(string)
    string
  end
  
  def dice_command(string, nick_e)
    
    secret_flg = false
    
    if(/2D6([\+\*\-][\d\+\*\-]+)?[>=]/ =~ string )
      output_msg = monotone_musium_check(string, nick_e)
      if(string =~ /S2D6/)
        secret_flg = true if(output_msg != '1')
      end
      return output_msg, secret_flg
    end
    
    return '1', secret_flg unless( /(^|\s)(S)?((O|[W]?D)T)(\s|$)/i =~ string )
    
    secretMarker = $2
    tableName = $3
    
    output_msg = monotone_musium_table(tableName, nick_e)
    
    if( secretMarker )     # 隠しロール
        secret_flg = true if(output_msg != '1');
    end
    
      return output_msg, secret_flg
  end
  
  
  def monotone_musium_check(string, nick_e)
    output = '1'
    
    crit = 12
    fumble = 2
    
    return output unless(/(^|\s)2D6([\+\-\d]*)>=(\d+)(\[(\d+)?(,(\d+))?\])?(\s|$)/i =~ string)
    modText = $2
    target = $3.to_i
    crit = $5.to_i if($5)
    fumble = $7.to_i if($7)
    
    mod = 0;
    mod = parren_killer("(0#{modText})") unless( modText.nil? )
    
    total, dice_str, dummy = roll(2, 6, @sortType && 1)
    total_n = total + mod.to_i
    
    output = "#{total}[#{dice_str}]＋#{mod} → #{total_n}"
    
    if(total >= crit)
      output += " ＞ 自動成功";
    elsif(total <= fumble)
      output += " ＞ 自動失敗";
    elsif(total_n >= target)
      output += " ＞ 成功";
    else
      output += " ＞ 失敗";
    end
    
    output = "#{nick_e}: (#{string}) ＞ #{output}"
    
    return output;
    
  end
  
  
  def monotone_musium_table(tableName, nick_e)
    output = '1'
    type = ""
    
    case tableName
    when /WDT/i
      type = '世界歪曲表';
      output, total_n = mm_world_distortion_table()
    when /OT/i
      type = '兆候表';
      output, total_n = mm_omens_table()
    when /DT/i
      type = '歪み表';
      output, total_n = mm_distortion_table()
    end
    
    output = "#{nick_e}: #{type}(#{total_n}) ＞ #{output}" if(output != '1')
    
    return output;
  end

  #**世界歪曲表(2D6)[WDT]
  def mm_world_distortion_table
    table = [
      '消失：世界からボスキャラクターが消去され、消滅する。エンディングフェイズへ。',
      '自己犠牲：チャート振ったPCのパートナーとなっているNPCのひとりが死亡する。チャート振ったPCのHPとMPを完全に回復させる。',
      '生命誕生：キミたちは大地の代わりに何かの生き物の臓腑の上に立っている。登場しているキャラクター全員に邪毒5 を与える。',
      '歪曲拡大：シーンに登場している紡ぎ手ではないNPCひとりが漆黒の凶獣（P.240）に変身する。',
      '暴走：“ほつれ ”がいくつも生まれ、シーンに登場しているすべてのキャラクターの剥離値を +1 する。',
      '幻像世界：周囲の空間は歪み、破壊的なエネルギーが充満する。次に行なわれるダメージロールに +5D6 する。',
      '変調：右は左に、赤は青に、上は下に、歪みが身体の動きを妨げる。登場しているキャラクター全員に狼狽を与える。',
      '空間消失：演目の舞台が煙のように消失する。圧倒的な喪失感により、登場しているキャラクター全員に放心を与える。',
      '生命消失：次のシーン以降、エキストラは一切登場できない。現在のシーンのエキストラに関してはGMが決定する。',
      '自己死：もっとも剥離値の高いPCひとりが戦闘不能になる。複数のPCが該当した場合はGMがランダムに決定する。',
      '世界死：世界の破滅。難易度12の【縫製】判定に成功すると破滅から逃れられる。失敗すると行方不明になる。エンディングフェイズへ。',
    ]
    
    return get_table_by_2d6(table)
  end
  
  
  #**兆候表(2d6)[OT]
  def mm_omens_table
    table = [
      '信念の喪失：[出自]を喪失する。特徴は失われない。',
      '昏倒：あなたは[戦闘不能]になる。',
      '肉体の崩壊：あなたは 2D6点のHPを失う。',
      '放心：あなたはバッドステータスの[放心]を受ける。',
      '重圧：あなたはバッドステータスの[重圧]を受ける。',
      '現在の喪失：現在持っているパートナーをひとつ喪失する。',
      'マヒ：あなたはバッドステータスの[マヒ]を受ける。',
      '邪毒：あなたはバッドステータスの[邪毒]5 を受ける。',
      '色彩の喪失：漆黒、墨白、透明化……。その禍々しい色彩の喪失は他らなぬ異形化の片鱗だ。',
      '理由の喪失：[境遇]をう喪失する。特徴は失われない。',
      '存在の喪失：あなたの存在は一瞬、この世界から消失する。',
    ]
    
    return get_table_by_2d6(table)
  end

  #**歪み表(2D6)[DT]
  def mm_distortion_table
    table = [
      '世界消失：演目の舞台がすべて失われる。舞台に残っているのはキミたちと異形、伽藍だけだ。クライマックスフェイズへ。',
      '生命減少：演目の舞台となっている街や国から動物や人間の姿が少なくなる。特に子供の姿は見られない。',
      '空間消失：演目の舞台の一部（建物一棟程度）が消失する。',
      '天候悪化：激しい雷雨に見舞われる。',
      '生命繁茂：シーン内に植物が爆発的に増加し、建物はイバラのトゲと蔓草に埋没する。',
      '色彩喪失：世界から色彩が失われる。紡ぎ手（PC）以外の人々は世界のすべてをモノクロームになったかのように認識する。',
      '神権音楽：美しいが不安を覚える音が流れる。音は人々にストレスを与え、街の雰囲気は悪化している。',
      '鏡面世界：演目の舞台に存在するあらゆる文字は鏡文字になる。',
      '時空歪曲：昼夜が逆転する。昼間であれば夜になり、夜であれば朝となる。',
      '存在修正：GMが任意に決定したNPCの性別や年齢、外見が変化する。',
      '人体消失：シーンプレイヤーのパートナーとなっているNPCが消失する。どのNPCが消失するかは、GMが決定する。',
    ]
    return get_table_by_2d6(table)
  end
  
end
