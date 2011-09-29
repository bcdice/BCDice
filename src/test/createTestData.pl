#!/usr/local/bin/perl
#どどんとふ付属のダイスボットは下記のボーンズ＆カーズを元に
#CGIとして動作するように拡張して作成してあります。
#なお、コメント等で記載されている必要モジュールはいずれも不要です。
#=================================================================================
#【ソフト名】  ゲーム設定型ダイスボット「ボーンズ＆カーズ(bcdice.pl)」
#【著作権者】  Faceless
#【対応環境】  Perl5.8以降の動作可能な環境。
#              必要モジュール NET::IRC, Math::Random::MT::Perl
#【開発言語】  ActivePerl v.5.10.0
#【開発環境】  WindowsXP Pro SP2 + P4
#【 種  別 】  フリーウエア(修正BSDライセンスに準拠)
#【転載条件】  修正BSDライセンス上で許可
#【連絡先 及び １次配布】  http://faceless-tools.cocolog-nifty.com/blog/
#=================================================================================
#require 5.008;                          # Perl 5.8以降向け

my $isPerl_5_8 = ($] >= 5.008  );

if( $isPerl_5_8 ) {
    require 5.008;							# Perl 5.8以降向け
}
use strict;
use warnings;
use utf8;                               # このソースはUTF-8で書かれています
my $verision = "1.2.38";                # B&Cのバージョン

# ======================= モジュールなど =============================

use lib "src_perl";
use torgtaitaiIRCForTest;
use CGI;

my $torgtaitaiMessage = "";
my $game_type = "diceBot";
my $rand_seed = 0;
my $isChangeReturnCode = 0;
my $chatChannel = 0;
my $speakerName = "speaker";
my $speakerState = "";
my $sendto = "";
my $color = "";


# for DiceBot Test################

my $isTestDiceBot = 1;

use subs qw( rand );

our @randomResults = ();

sub rand {
    my $max = shift;
    my $value = CORE::rand($max);
    
    if( $isTestDiceBot ) {
        my $text = sprintf("%s/%s", int($value) + 1, $max);
        push(@randomResults, $text);
    }
    
    return $value;
}

#################


if( ($#ARGV + 1) > 0 ) {
    $torgtaitaiMessage = $ARGV[0];
    $isChangeReturnCode = 1;
    
    if( ($#ARGV + 1) > 1 ) {
        #$rand_seed = $ARGV[1];
        $game_type = $ARGV[1];
     }
} else {
    my $cgi = new CGI;
    
    if( $isPerl_5_8 ) {
        print $cgi->header(-charset=>'UTF-8');
    } else {
        print $cgi->header();
     }
    
    $torgtaitaiMessage = $cgi->param('message');
    $game_type = $cgi->param('gameType');
    $game_type ||= 'diceBot';
    $rand_seed = $cgi->param('randomSeed');
    $chatChannel = $cgi->param('channel');
    $speakerName = $cgi->param('name');
    $speakerState = $cgi->param('state');
    $sendto = $cgi->param('sendto');
    $color = $cgi->param('color');
}

# ここでランダム関数を空回ししておき、乱数の精度を高める
sub initRamdForCgiLoop {
    my $loopCount = shift;
    for(my $i=1 ; $i <= $loopCount ; $i++) {
        rand(100);
    }
}
sub initRamdForCgi {
    &initRamdForCgiLoop( 100 );
    &initRamdForCgiLoop( rand(100) );
}

##########

sub decode {
    my $code = shift;
    my $str = shift;
    #print("code : " . $code . "\n");
    #print("str  : " . $str . "\n");
    return $str;
}

sub encode {
    my $code = shift;
    my $str = shift;
    #print("encode_ code : " . $code . "\n");
    #print("encode_ str  : " . $str . "\n");
    return $str;
}

sub printDiceBotParam {
    my $param = shift;
    
    if( $param ) {
        print($param);
    }
    print("\t");
}

my $irc = new torgtaitaiIRCForTest( ($torgtaitaiMessage), $game_type, $isTestDiceBot );
#print("##>customBot BEGIN<##");
#printDiceBotParam($chatChannel);
#printDiceBotParam($speakerName);
#printDiceBotParam($speakerState);
#printDiceBotParam($sendto);
#printDiceBotParam($color);
#print($torgtaitaiMessage);

# ========== モジュールなど ==========
use constant CHARCODE => 'utf8';		# 文字コードを指定(コンソールやカードファイル等)

if( $isPerl_5_8 ) {
    binmode STDIN, ':bytes';					# 入力コードが不定なのでbyteで読み込む
    binmode STDOUT, ":encoding(".CHARCODE.")";	# 標準出力も指定
    binmode STDERR, ":encoding(".CHARCODE.")";	# エラー出力も指定
}
 
if( $isPerl_5_8 ) {
    require "Encode.pm";
}
#use Encode;                                 # 多バイト文字モジュール
#use Net::IRC;                               # IRCモジュール
# BEGIN {     # メルセンヌ・ツイスターがインストールされていれば通常の乱数とコンパチで使う
#     my @list = ("Math::Random::MT::Perl",
#                 "Math::Random::MT",
#         );
#     foreach my $mod (@list) {
#         eval "use $mod qw(srand rand)";
#         if (! $@ ) {
#             last;
#         }
#     }
# }
#** 動作設定(ユーザによる変更ポイント)
my $NOTICE_SW = 1;                  # 送信の際に、どちらのコマンドを使うか？(notice=1, msg=0)
my $SEND_MODE = 2;                  # デフォルトの送信形式(0=結果のみ,1=0+式,2=1+ダイス個別)
my $SEND_STR_MAX = 400;             # 最大送信文字数(本来は500byte上限)
my $VOID_DICE = 1;                  # 発言の度に空ダイスを振るか？(Yes=1, No=0)
my $DICE_MAXCNT = 200;              # ダイスが振れる最大個数
my $DICE_MAXNUM = 1000;             # ダイスの最大面数
my $IRC_CODE = 'iso-2022-jp';       # IRCサーバとの通信に使うコードを指定
my $HAND_SRT = 1;                   # 手札をソートする必要があるか？(Yes=1, No=0)
my $END_MSG = 'お疲れ様';           # 終了用のTalkコマンド
my $QUIT_MSG = 'さようなら';        # 終了時のメッセージ
my $OPEN_DICE = 'Open Dice!';       # シークレットダイスの出目表示コマンド
my $OPEN_PLOT = 'Open Plot!';       # プロットの表示コマンド
my $ADD_PLOT = 'PLOT';              # プロットの入力コマンド
my $READY_CMD = '#HERE';            # 自分の居るチャンネルの宣言コマンド
my $RND_GNR_PREFIX = 'make ';    # ランダムジェネレータコマンドの接頭語

my $server = "localhost";               # サーバー
my $port = "6667";                      # ポート番号
my $chan = "#Dice_Test";                # ボットが最初に参加するチャンネル名
my $nick = "bcDICE";                    # ニックネーム
my $uern = "bones&cards_v".$verision;   # ユーザー名
my $ircn = "perldice";                  # IRCネーム
#** 動作設定終わり

#============================== 起動法 ==============================
# 上記設定をしてダブルクリック、
# もしくはコマンドラインで
#
# perl bcdice.pl
#
# とタイプして起動します。
#
# このとき起動オプションを指定することで、ソースを書き換えずに設定を変更出来ます。
#
# -s サーバ設定      「-s(サーバ):(ポート番号)」     (ex. -sirc.trpg.net:6667)
# -c チャンネル設定  「-c(チャンネル名)」            (ex. -c#CoCtest)
# -n Nick設定        「-n(Nick)」                    (ex. -nDicebot)
# -g ゲーム設定      「-g(ゲーム指定文字列)」        (ex. -gCthulhu)
# -m メッセージ設定  「-m(Notice_flgの番号)」        (ex. -m0)
# -e エクストラカード「-e(カードセットのファイル名)」(ex. -eTORG_SET.txt)
# -i IRC文字コード   「-i(文字コード名称)」          (ex. -iISO-2022-JP)
#
# ex. perl bcdice.pl -sirc.trpg.net:6667 -c#CoCtest -gCthulhu
#
# プレイ環境ごとにバッチファイルを作っておくと便利です。
#
# 終了時はボットにTalkで「お疲れ様」と発言します。($END_MSGで変更出来ます。)
#====================================================================

#** その他の変数定義(初期化)
#my $game_type = "";
#my $rand_seed = time;   # 乱数シード
my $DodontoFlg = 1;     # どどんとふらぐ(0=IRC, 1=どどんとふ)
#my $irc = new Net::IRC;

#削除（カード関連）

my $master = "";
my $modeflg = $SEND_MODE;
my $upperinf = 0;
my $upper_dice = 0;
my $max_dice = 0;
my $min_dice = 0;
my $reroll_cnt = 0;
my $reroll_n = 0;
my $rating_table = 0;
my $d66_on = 0;
my $sort_flg = 0;
my $d66_now = 0;
my $double_up = 0;
my $card_place = 1;
my $can_tap = 1;
my $short_spell = 1;
my $suc_def = "";
my $round_flg = 0;
my $double_type = 0;
my $IRC_NICK_REG = '[A-Za-z\d\-\[\]\\\'^{}_]+';
my %hold_member_list;
my %hold_dice;
my %plot_channel;
my %point_counter;
my %rnd_heroine;

&game_set($game_type) if($DodontoFlg);
&set_random_heroin;

##########################################################################
#**                              メイン
##########################################################################
# 起動時パラメータの解釈
foreach my $arg_wk (@ARGV) {   # コンソールからのパラメータ指定処理
    if($arg_wk =~/^-([scngmeir])(.+)$/i) {
        my $cmd = "\L$1";
        my $prm = $2;
        if($cmd eq "s") {      # サーバ設定(Server:Port)
            my @sp = split(/:/, $prm);
            $server = $sp[0];
            $port = $sp[1] if($sp[1]);
        } elsif($cmd eq "c") { # チャンネル設定
            $chan = decode(CHARCODE, $prm);
        } elsif($cmd eq "n") { # Nick設定
            $nick = $prm;
        } elsif($cmd eq "g") { # ゲーム設定
            &game_set($prm);
        } elsif($cmd eq "m") { # メッセージ設定(出力)
            $NOTICE_SW = int($prm);
#削除(カード関連)
        } elsif($cmd eq "i") { # IRCサーバの文字コード変更
            $IRC_CODE = $prm;
        }
    }
}

#srand(time + $rand_seed);             # 乱数のタネを明示的に設定(メルセンヌ・ツイスターでは明示的に宣言するべき)
srand(time);
&initRamdForCgi() unless($isTestDiceBot);

&debug_out("Creating connection to IRC server...\n");
my $conn = $irc->newconn(
    Server   => ($server),
    Port     => ($port),
    Nick     => ($nick),
    Ircname  => ($uern),
    Username => ($ircn))
    or die "$nick : Can't connect to IRC server.\n";

sub on_connect {
    my $self = shift;

    &debug_out("Joining ${chan} ...\n");
    $self->join(encode($IRC_CODE,$chan));
    $self->topic(encode($IRC_CODE,$chan));
}
sub on_init {
    my ($self, $event) = @_;
    my (@args) = ($event->args);

    shift (@args);
    &debug_out("*** @args\n");
}
sub on_part {
    my ($self, $event) = @_;
    my $channel = decode($IRC_CODE,($event->to)[0]);

    &debug_out("*** %s has left channel %s\n", $event->nick, $channel);
}
sub on_join {
    my ($self, $event) = @_;
    my $channel = decode($IRC_CODE,($event->to)[0]);
    my ($nick_j) = $event->nick;
    my ($host_j) = $event->userhost;

    &debug_out("*** %s (%s) has joined channel %s\n",
    $nick_j, $host_j, $channel);
    if ($event->userhost =~ /^someone\@somewhere\.else\.com$/) {  # Auto-ops anyone who
        &debug_out("Give @ to ${nick_j}\n");
        $self->mode(encode($IRC_CODE, $channel), "+o", $nick_j);      # matches hostmask.
    }
}
sub on_invite {
    my ($self, $event) =@_;
    my $channel = decode($IRC_CODE,($event->args)[0]);

    &debug_out("*** %s (%s) has invited me to channel %s\n",
    $event->nick, $event->userhost, $channel);
    
    $chan = &chan_add($chan, $channel);
    $self->join(encode($IRC_CODE, $channel));
    $self->topic(encode($IRC_CODE, $channel));
}
sub on_kick {
    my ($self, $event) = @_;
    my $channel = decode($IRC_CODE,($event->args)[0]);
    my ($nick_e, $mynick) = ($event->nick, $self->nick);
    my ($target) = ($event->to)[0];

    &debug_out("%s Kicked on %s by %s.\n", $target, $channel, $nick_e);
    if($mynick eq $target) {
        $chan = &chan_del($chan, $channel);
    }
}

sub on_msg {
    my ($self, $event) = @_;
    my ($nick_e) = $event->nick;
    my $temp = decode($IRC_CODE,($event->args)[0]);
    my ($output_msg, $arg, $tnick, $cnt);

    &debug_out("*$nick_e*  ", ($temp), "\n");
    my @CHAN_TO = split(/,/, $chan);
    if($temp =~ /->/) {
        ($arg, $tnick) = split(/->/, $temp);
    } else {
        $arg = $temp;
        $tnick = "";
    }
    $arg = parren_killer($arg);

    # ===== 設定関係 ========
    if($arg =~ /^set[\s]/i) {
        # マスター登録
        if($arg =~ /^set[\s]+master$/i) {
            if($master ne "") {
                if($nick_e eq $master) {
                    if($tnick ne "") {
                        $master = $tnick;
                        foreach my $chan_o (@CHAN_TO) {
                            &send_msg($self,$chan_o, "${master}さんをMasterに設定しました");
                        }
                    } else {
                        $master = "";
                        foreach my $chan_o (@CHAN_TO) {
                            &send_msg($self,$chan_o, "Master設定を解除しました");
                        }
                    }
                } else {
                    &send_msg($self,$nick_e, "Masterは${master}さんになっています");
                }
            } else {
                if($tnick ne "") {
                    $master = $tnick;
                } else {
                    $master = $nick_e;
                }
                foreach my $chan_o (@CHAN_TO) {
                    &send_msg($self,$chan_o, "${master}さんをMasterに設定しました");
                }
            }
        }
        # ゲーム設定
        elsif($arg =~ /^set[\s]+game$/i) {
            my $set_msg = &game_set($tnick);
            foreach my $chan_o (@CHAN_TO) {
                &send_msg($self,$chan_o, $set_msg);
            }
        }
        # 表示モード設定
        elsif($arg =~ /^set[\s]+v(iew[\s]*)?mode$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $modeflg = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        &send_msg($self,$chan_o, "ViewMode${modeflg}に変更しました");
                    }
                }
            }
        }
        # 上方無限ロール閾値設定 0=Clear
        elsif($arg =~ /^set[\s]+upper$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $upperinf = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        if($upperinf > 0) {
                            &send_msg($self,$chan_o, "上方無限ロールを${upperinf}以上に設定しました");
                        } else {
                            &send_msg($self,$chan_o, "上方無限ロールの閾値設定を解除しました");
                        }
                    }
                }
            }
        }
        # 個数振り足しロール回数制限設定 0=無限
        elsif($arg =~ /^set[\s]+reroll$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $reroll_cnt = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        if($reroll_cnt > 0) {
                            &send_msg($self,$chan_o, "個数振り足しロール回数を${reroll_n}以下に設定しました");
                        } else {
                            &send_msg($self,$chan_o, "個数振り足しロールの回数を無限に設定しました");
                        }
                    }
                }
            }
        }
        # デ－タ送信モード設定
        elsif($arg =~ /^set[\s]+s(end[\s]*)?mode$/i) {
             my $mode_str;
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $NOTICE_SW = int($1);
                    if ($NOTICE_SW) {
                        $mode_str = "notice-mode"
                    } else {
                        $mode_str = "msg-mode"
                    }
                    foreach my $chan_o (@CHAN_TO) {
                        &send_msg($self,$chan_o, "SendModeを${mode_str}に変更しました");
                    }
                }
            }
        }
        # レーティング表設定
        elsif($arg =~ /^set[\s]+r(ating[\s]*)?t(able)?$/i) {
             my $mode_str;
             my $pre_mode = $rating_table;
             if(($nick_e eq $master) || ($master eq "")) {
                if($tnick =~ /(\d+)/) {
                    $rating_table = int($1);
                    if ($rating_table > 1) {
                        $mode_str = "2.0-mode";
                        $rating_table = 2;
                    } elsif ($rating_table > 0) {
                        $mode_str = "new-mode";
                        $rating_table = 1;
                    } else {
                        $mode_str = "old-mode";
                        $rating_table = 0;
                    }
                } else {
                    if($tnick =~ /old/i) {
                        $rating_table = 0;
                        $mode_str = "old-mode";
                    } elsif($tnick =~ /new/i) {
                        $rating_table = 1;
                        $mode_str = "new-mode";
                    } elsif($tnick =~ /2\.0/i) {
                        $rating_table = 2;
                        $mode_str = "2.0-mode";
                    }
                }
            }
            if($rating_table != $pre_mode) {
                foreach my $chan_o (@CHAN_TO) {
                    &send_msg($self,$chan_o, "RatingTableを${mode_str}に変更しました");
                }
            }
        }
        # ソートモード設定
        elsif($arg =~ /^set[\s]+sort$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $sort_flg = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        &send_msg($self,$chan_o, "ソート無しに変更しました") if(!$sort_flg);
                        &send_msg($self,$chan_o, "ソート有りに変更しました") if($sort_flg);
                    }
                }
            }
        }
        # カードモード設定
#削除(カード関連)
        # 呪文モード設定
        elsif($arg =~ /^set[\s]+(shortspell|SS)$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $short_spell = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        &send_msg($self,$chan_o, "通常呪文モードに変更しました") if(!$short_spell);
                        &send_msg($self,$chan_o, "短い呪文モードに変更しました") if($short_spell);
                    }
                }
            }
        }
        # タップモード設定
        elsif($arg =~ /^set[\s]+tap$/i) {
             if(($nick_e eq $master) || ($master eq "")) {
                if ($tnick =~ /(\d+)/) {
                    $can_tap = int($1);
                    foreach my $chan_o (@CHAN_TO) {
                        &send_msg($self,$chan_o, "タップ不可モードに変更しました") if(!$can_tap);
                        &send_msg($self,$chan_o, "タップ可能モードに変更しました") if($can_tap);
                    }
                }
            }
        }
        # カード読み込み
#削除(カード関連)
    }

# ポイントカウンター関係
#削除

# プロット入力処理
#削除


# ボット終了命令
    elsif($arg =~ /^${END_MSG}$/) {
         if(($nick_e eq $master) || ($master eq "")) {
            $self->quit(encode($IRC_CODE,"$QUIT_MSG"));
            sleep 3;
            exit 0;
        }
    }
# モード確認
    elsif($arg =~ /^mode$/i) {
         if(($nick_e eq $master) || ($master eq "")) {
            $output_msg = "GameType = ".$game_type.", ViewMode = ".$modeflg.", Sort = ".$sort_flg;
            &send_msg($self,$nick_e, $output_msg);
        }
    }

# 簡易オンラインヘルプ
#削除

}

#sub on_public {
#    my ($self, $event) = @_;
#    my $channel = decode($IRC_CODE,($event->to)[0]);
#    my ($nick_e, $mynick) = ($event->nick, $self->nick);
#    my $arg = decode($IRC_CODE,($event->args)[0]);
#    my $output_msg;
#    my $secret_flg;
#
sub on_public {
    my $self = shift;
    my $arg = shift;
    my $channel = '';
    my ($nick_e, $mynick) = ('', '');
    my $output_msg;
    my $secret_flg;

    &debug_out("${channel} [${nick_e}] ${arg}\n");
    $arg = parren_killer($arg);

# 竹流ちゃんコマンド関係
    if($arg =~ /(^|\s+)${RND_GNR_PREFIX}/i) {
        my $output_msgs = &random_heroine_generator($arg);
        &send_msg($self, $channel, $output_msgs) if($output_msgs ne '1');
    }
# シークレットロールの表示
#削除

# ダイスロールの処理
    ($output_msg, $secret_flg) = &dice_command($arg, $nick_e);
    if($secret_flg) {   # 隠しロール
        if($output_msg ne "1") {
            &broadmsg($self, $output_msg, $nick_e);
#削除
        }
    } else {
        &send_msg($self,$channel, $output_msg) if($output_msg ne "1");
    }
# サタスペのチャート処理
    if($game_type eq "Satasupe") {
        if($arg =~ /(^|\s)(S)?(\w+)($|\s)/i) {
            my @output_msgs = &satasupe_table($3);
            my $i = 1;
            foreach my $msgs (@output_msgs) {
                if($2) {
                    &broadmsg($self, "$nick_e: ".$msgs, $nick_e) if($msgs);
                } else {
                    &send_msg($self, $channel, "$nick_e: ".$msgs) if($msgs);
                }
                sleep 1 if(!($i % 5));
                $i++;
            }
        }
    }

# カード処理
# 削除

# 四則計算代行
    if($arg =~ /(^|\s)C([-\d]+)\s*$/i) {
        $output_msg = $2;
        if($output_msg ne "") {
            &send_msg($self,$channel, "$nick_e: 計算結果 ＞ $output_msg");
        }
    }

    if(!$output_msg || $output_msg eq '1') {    # ダイスロール以外の発言では捨てダイス処理を
        rand 100 if($VOID_DICE);
    }

}
sub on_names {
    my ($self, $event) = @_;
    my (@list, $channel) = ($event->args);  # eat yer heart out, mjd!
    my $chan;

    ($chan, @list) = splice @list, 2;
    $chan = decode($IRC_CODE,$chan);
    &debug_out("Users on $chan: @list\n");
}
sub on_ping {
    my ($self, $event) = @_;
    my $nick = $event->nick;

    $self->ctcp_reply($nick, join (' ', ($event->args)));
    &debug_out("*** CTCP PING request from $nick received\n");
}
sub on_ping_reply {
    my ($self, $event) = @_;
    my ($args) = ($event->args)[1];
    my ($nick) = $event->nick;

    $args = time - $args;
    &debug_out("*** CTCP PING reply from $nick: $args sec.\n");
}
sub on_nick_taken {
    my ($self) = shift;

    $self->nick(substr($self->nick, -1) . substr($self->nick, 0, 8));
}
sub on_action {
    my ($self, $event) = @_;
    my ($nick, @args) = ($event->nick, $event->args);

    foreach my $arg_o (@args) {
        $arg_o = decode($IRC_CODE,$arg_o);
    }
    &debug_out("* $nick @args\n");
}
sub on_disconnect {
    my ($self, $event) = @_;

    &debug_out("Disconnected from ", $event->from(), " (",
          ($event->args())[0], "). Attempting to reconnect...\n");
    $self->connect();
}
sub on_topic {
    my ($self, $event) = @_;
    my (@args) = $event->args();
    my $chan = decode($IRC_CODE,($event->to())[0]);

    foreach  my $arg_o (@args) {
        $arg_o = decode($IRC_CODE,$arg_o);
    }
    if ($event->type() eq 'notopic') {
        &debug_out("No topic set for $args[1].\n");
    } elsif ($event->type() eq 'topic' and $event->to()) {
        &debug_out("Topic change for ", $chan, ": $args[0]\n");
    } else {
        &debug_out("The topic for $args[1] is \"$args[2]\".\n");
    }
}
sub chan_add {
    my ($list, $add_ch) = @_;

    $list .= "," if($list ne "");
    $list .= $add_ch;
    return $list;
}
sub chan_del {
    my ($list, $del_ch) = @_;
    my (@CHAN_TO, @CHAN_TO2);

    @CHAN_TO = split(/,/, $list);
    foreach my $chan_o (@CHAN_TO) {
        if($chan_o eq $del_ch) {
        } else {
            push(@CHAN_TO2, $chan_o);
        }
    }
    $list = join(",", @CHAN_TO2);
    return $list;
}

###########################################################################
#**                         各種コマンド処理
###########################################################################

#=========================================================================
#**                           コマンド分岐
#=========================================================================
sub dice_command {  # ダイスコマンドの分岐処理
    my $arg = "\U$_[0]";
    my $nick_e = $_[1];
    my $output_msg = '1';
    my $secret_flg = 0;

    if($arg =~ /[KDBRU][\d]/) {
    # ソードワールドのレーティング表ロール検出
        if($arg =~ /(^|\s)(S)?K[\d\+\-]+/i) {
            $output_msg = &rating("$arg", "$nick_e");
            if($2) {  # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    # D66ロール検出
        elsif($d66_on and $arg =~ /D66/) {
            $output_msg = &d66dice("$arg", "$nick_e");
            if($arg =~ /S\d*D66/) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    # 加算ロール検出
        elsif($arg =~ /[-\d]+D[\d\+\*\-D]+([<>=]+[?\-\d]+)?($|\s)/) {
            $output_msg = &dice("$arg", "$nick_e");
            if($arg =~ /S[-\d]+D[\d+-]+/) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    # バラバラロール検出
        elsif($arg =~ /[\d]+B[\d]+([<>=]+[\d]+)?($|\s)/) {
            $output_msg = &bdice("$arg", "$nick_e");
            if($arg =~ /S[\d]+B[\d]+/i) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    # 個数振り足しロール検出
        elsif($arg =~ /[\d]+R[\d]+/) {
            if($game_type eq "DoubleCross") {
                $output_msg = &dxdice("$arg", "$nick_e");
            } elsif($game_type eq "ArsMagica") {
                $output_msg = &arsmagica_stress("$arg", "$nick_e");
            } elsif($game_type eq "Tunnels & Trolls") {
                $output_msg = &tandt_berserk("$arg", "$nick_e");
            } elsif ($game_type eq "DarkBlaze") {
                $output_msg = &dark_blaze_check("$arg", "$nick_e");
            } elsif($game_type eq "NightWizard") {
                $output_msg = &night_wizard_check("$arg", "$nick_e");
            } elsif($game_type eq "TORG") {
                $output_msg = &torg_check("$arg", "$nick_e");
            } elsif($game_type eq "MeikyuKingdom") {
                $output_msg = &mayokin_check("$arg", "$nick_e");
            } elsif($game_type eq "EmbryoMachine") {
                $output_msg = &embryo_machine_check("$arg", "$nick_e");
            } elsif($game_type eq "GehennaAn") {
                $output_msg = &gehenna_an_check("$arg", "$nick_e");
            } elsif($game_type eq "Nechronica") {
                $output_msg = &nechronica_check("$arg", "$nick_e");
            } elsif($game_type eq "MeikyuDays") {
                $output_msg = &mayoday_check("$arg", "$nick_e");
            } elsif($game_type eq "BarnaKronika") {
                $output_msg = &barna_kronika_check("$arg", "$nick_e");
            } elsif($game_type eq "RokumonSekai2") {
                $output_msg = &rokumon2_check("$arg", "$nick_e");
            } else {
                $output_msg = &rdice("$arg", "$nick_e");
            }
            
            if($arg =~ /S[\d]+R[\d]+/i) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    # 上方無限ロール検出
        elsif($arg =~ /[\d]+U[\d]+/) {
            $output_msg = &udice("$arg", "$nick_e");
            if($arg =~ /S[\d]+U[\d]+/) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    # サタスペ関係
    if($game_type eq "Satasupe") {
        if($arg =~ /((^|\s)(\d+)(S)?R[>=]+(\d+)(\[(\d+)?(,\d+)?\])?($|\s))/i) { # 判定ロール
            $output_msg = &satasupe_check("\U$1", "$nick_e");
            if($4) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        } else {
        }
    }
    if($game_type eq "Chill") {
        # ストライクランク計算
        if($arg =~ /(^|\s)(S)?SR(\d+)($|\s)/i) {
            $output_msg = &strike_rank("$arg", "$nick_e");
            if($2) {   # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    # ウォーハンマー攻撃コマンド
    if($arg =~ /(^|\s)(S)?(WH\d+(@[\dWH]*)?)($|\s)/) {
        $output_msg = &wh_att("$3", "$nick_e");
        if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
        }
    }
    # アースドーンのステップダイス
    if($game_type eq "EarthDawn") {
        if( $arg =~ /((\d+)e(\d+)?(\+)?(\d+)?(d4)?(d6)?(d8)?(d10)?)($|\s)/i ){
            $output_msg = &ed_step("$arg", "\L$1","$nick_e");
            if( $arg =~ /s[[\d+]e[\d\+\*-](\+-)?(\d+)d(\d+)/i ){    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }

# 表関係
    if($arg =~ /((^|\s)(S)?(\w)?URGE(\s*)(\d+))($|\s)/i) {    # デモンパ系衝動表
        if($game_type eq "Demon Parasite") {        # デモンパ
            $output_msg = &dp_urge("\U$1", "$nick_e");
        } elsif($game_type eq "ParasiteBlood") {    # パラブラ
            $output_msg = &pb_urge("\U$1", "$nick_e");
        }
        if($3) {   # 隠しロール
            $secret_flg = 1 if($output_msg ne '1');
        }
    }
    if($arg =~ /((^|\s)(S)?WH[HABTLW]\d+)($|\s)/i) {  # ウォーハンマークリティカル表
        $output_msg = &wh_crit("\U$1", "$nick_e");
        if($3) {   # 隠しロール
            $secret_flg = 1 if($output_msg ne '1');
        }
    }
    if($arg =~ /((^|\s)(S)?RES[\-\d]+)($|\s)/i) { # CoC抵抗表コマンド
        $output_msg = &coc_res("\U$1", "$nick_e");
        if($3) {  # 隠しロール
            $secret_flg = 1 if($output_msg ne '1');
        }
    }

    if($game_type eq "ShinobiGami") {
        if($arg =~ /((^|\s)(S)?([CMDTNKG]|TK|GA|KY|JB)?[SFEGWB]T($|\s))/i) {
            $output_msg = &shinobigami_table("\U$1", "$nick_e");
            if($3) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif ($game_type eq "DarkBlaze") {
        if($arg =~ /((^|\s)(S)?BT(\d+)?($|\s))/i) {   # 掘り出し袋表
            my $dice = 1;
            $dice = $4 if($4);
            $output_msg = &dark_blaze_horidasibukuro_table($dice, "$nick_e");
        }
        if($3) {  # 隠しロール
            $secret_flg = 1 if($output_msg ne '1');
        }
    }
    elsif($game_type eq "DoubleCross") {
        if($arg =~ /((^|\s)(S)?ET($|\s))/i) {   # 感情表
            $output_msg = &dx_emotion_table("$nick_e");
            if($3) {  # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
       }
    }
    elsif($game_type eq "GundogZero") {
        if($arg =~ /(^|\s)(S)?((\w)(DP|F)T([\+\-\d]*))($|\s)/i) {
            $output_msg = &gundogzero_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "TORG") {
        if($arg =~ /(^|\s)(S)?([O]?([RITMDB]T)(\d+([\+\-]\d+)*))(\s|$)/i) {
            $output_msg = &torg_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "HuntersMoon") {
        if($arg =~ /(^|\s)(S)?(([CSHFD]LT)|ET|MAT|SAT\d*|T[SHABLE]T)(\s|$)/i) {
            $output_msg = &huntersmoon_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "MeikyuKingdom") {
        if($arg =~ /(^|\s)(S)?(([LOCAF]RT)|[TCSVF]BT|[TCSV]HT|K[DCM]T|CAT|FWT|CFT|TT|NT|ET|T\dT|NAME\d*|MPT|DFT\d*|IDT\d*|([WLRS]|RW|RU)IT|\dRET|PNT\d*|MLT\d*|IFT)(\s|$)/i) {
            $output_msg = &mayokin_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "EmbryoMachine") {
        if($arg =~ /(^|\s)(S)?(HLT|[MS]FT)(\s|$)/i) {
            $output_msg = &em_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "MagicaLogia") {
        if($arg =~ /((^|\s)(S)?([SFWAC]|FC|BG|DA|FA|WI|RT)T($|\s))/i) {
            $output_msg = &magicalogia_table("\U$1", "$nick_e");
            if($3) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "MeikyuDays") {
        if($arg =~ /(^|\s)(S)?([D]RT|[D]BT|[D]HT|[DMPL]CT|DNT|KST|CAT|FWT|CFT|DNT|APT|MPT|T\dT)(\s|$)/i) {
            $output_msg = &mayoday_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }
    elsif($game_type eq "Peekaboo") {
        if($arg =~ /(^|\s)(S)?(((S|PS|O)E|[IS]B)T)(\s|$)/i) {
            $output_msg = &peekaboo_table($3, "$nick_e");
            if($2) {    # 隠しロール
                $secret_flg = 1 if($output_msg ne '1');
            }
        }
    }

    if($arg =~ /((^|\s)(S)?choise\[[^,]+(,[^,]+)+\]($|\s))/i) {   # 選択コマンド
        $output_msg = &choise_random($1, "$nick_e");
        if($3) {  # 隠しロール
            $secret_flg = 1 if($output_msg ne '1');
        }
    }

    return ($output_msg, $secret_flg);
}
#削除

#=========================================================================
#**                           ランダマイザ
#=========================================================================
sub roll {  # ダイスロール
    my($dice_cnt, $dice_max, $dice_sort, $dice_add, $dice_ul, $dice_diff, $dice_re) = @_;
    my $total = 0;
    my $dice_str = "";
    my $cnt1 = 0;
    my $cnt_max = 0;
    my $n_max = 0;
    my $cnt_suc = 0;
    my $d9_on = 0;
    my $cnt_re = 0;
    my @dice_res;

    $dice_add = 0 if(!$dice_add);
    if(($d66_on) && ($dice_max == 66)) {
        $dice_sort = 0;
        $dice_cnt = 2;
        $dice_max = 6;
    }
    if(($game_type =~ /Gundog/) && ($dice_max == 9)) {
        $d9_on = 1; # ガンドッグのnD9処理
        $dice_max++;
    }
    if(($dice_cnt <= $DICE_MAXCNT) && ($dice_max <= $DICE_MAXNUM)) {
        for(my $i=1; $i <= $dice_cnt ; $i++) {
            my $dice_now = 0;
            my $dice_n = 0;
            my $dice_st_n = "";
            my $round = 0;
            do{
                if($game_type eq "DoubleCross" && $round >= 1) {    # ダブルクロス用出目読み替え
                    $dice_now += 10 - $dice_n;
                }
                $dice_n = int(rand $dice_max) + 1;
                $dice_n-- if($d9_on);
                $dice_now += $dice_n;
                if($modeflg >=2) {
                    $dice_st_n .= "," if($dice_st_n);
                    $dice_st_n .= "${dice_n}";
                }
                $round++;
            } while(($dice_add > 1) && ($dice_n >= $dice_add));
            $total +=  $dice_now;
            if($dice_ul) {
                my $suc = &check_hit($dice_now, $dice_ul, $dice_diff);
                $cnt_suc += $suc;
            }
            if($dice_re) {
                $cnt_re++ if($dice_now >= $dice_re);
            }
            if($modeflg >=2 && $round >= 2) {
                push @dice_res, "${dice_now}[${dice_st_n}]";
            } else {
                push @dice_res, "${dice_now}";
            }
            $cnt1++ if($dice_now == 1);
            $cnt_max++ if($dice_now == $dice_max);
            $n_max = $dice_now if($dice_now > $n_max);
        }
    }
    if($dice_sort) {
        $dice_str = join ",", sort { &dice_num($a) <=> &dice_num($b) } @dice_res;
    } else {
        $dice_str = join ",", @dice_res;
    }
    return ($total, $dice_str, $cnt1, $cnt_max, $n_max, $cnt_suc, $cnt_re);
}
sub dice_num {
    my $dice_str = $_[0];
    $dice_str =~ s/\[[\d,]+\]//;
    return $dice_str;
}

#==========================================================================
#**                            ダイスコマンド処理
#==========================================================================
####################             加算ダイス        ########################
sub dice {  # 加算ダイスロール
    my $dice_cnt = 0;
    my $dice_max = 0;
    my $total_n = 0;
    my $dice_n = 0;
    my $output = "";
    my $ulflg = "";
    my $diff = 0;
    my $n1 = 0;
    my $n_max = 0;
    my $check_on = 0;
    my $string = $_[0];

    if($string =~ /(^|\s)S?(([\d\+\*\-]*[\d]+D[\d]*[\d\+\*\-D]*)(([<>=]+)([?\-\d]+))?)($|\s)/) {
        $string = $2;
        if($4) {
            $ulflg = &cp_f($5);
            $diff = $6;
            $string = $3;
            $check_on = 1;
        }
        my @DICE_A = split(/\+/, $string);
        foreach my $dice_o (@DICE_A) {
            my @DICE_S = split(/-/, $dice_o);
            my $sub_flg = 1;
            foreach my $dice_h (@DICE_S) {
                if($dice_h) {
                    my($dice_now, $dice_n_wk, $dice_str, $n1_wk, $n_max_wk, $cnt_wk, $max_wk) = &dice_mul($dice_h, $check_on);
                    if($dice_now <= 0) {
                        return "1";
                    }
                    $total_n += ($dice_now) * $sub_flg;
                    $dice_n += $dice_n_wk * $sub_flg;
                    $n1 += $n1_wk;
                    $n_max += $n_max_wk;
                    $dice_cnt += $cnt_wk;
                    $dice_max = $max_wk if($max_wk > $dice_max);
                    if($modeflg > 0) {
                        if($sub_flg > 0) {
                            $output .= "+" if($output ne "");
                        } else {
                            $output .= "-";
                        }
                        $output .= "$dice_str";
                    }
                }
                $sub_flg = -1 if($sub_flg > 0);
            }
        }
        if($ulflg ne "") {
            $string .= "$ulflg$diff";
        }
        if($modeflg > 0) {
            if($output =~ /[^\d\[\]]+/) {
                $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
            } else {
                $output = "$_[1]: ($string) ＞ $total_n";
            }
        } else {
            $output = "$_[1]: ($string) ＞ $total_n";
        }
        if($game_type eq "NightmareHunterDeep") {   # D6の6の数分の補正処理
            if($n_max > 0 && $dice_max == 6) {
                $total_n += $n_max * 4;
                $output .= "+".$n_max."*4 ＞ $total_n";
            }
        }
        if($ulflg ne "") {  # 成功度判定処理
            $output .= &check_suc($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max);
            if($game_type eq "MagicaLogia") { 
                if ($dice_cnt == 2 && $dice_max == 6) {
                    $output =~ /\[([\d,]+)\]/;
                    my $dice_str = $1;
                    my @dice_arr = split(/,/, $dice_str);
                    $output .= &magicalogia_check_gain_ME($dice_arr[0], $dice_arr[1]);
                }
            }
        }
        if($game_type eq "NightmareHunterDeep") {   # 宿命表示
            $output .= " ＞ 宿命獲得" if($n1 && $dice_max == 6);
        } elsif($game_type eq "Tunnels & Trolls"){
            $output .= " ＞ 悪意".$n_max if(($n_max > 0) && ($dice_max == 6));
        } elsif($game_type eq "TokumeiTenkousei") { #エキストラパワーポイント獲得
            $output .= " ＞ ".($n1 * 5)."EPP獲得" if($n1 && $dice_max == 6);
        }
        if(($dice_cnt == 0) || ($dice_max == 0)) { $output = '1'; }
        return $output;
    } else {
    return "1";
    }
}
sub dice_mul {  # 加算ダイスロール(個別処理)
    my $dice_max = 0;
    my $string = $_[0];
    my $check_on = $_[1];
    my $dice_total = 1;
    my $dice_n = 0;
    my $output ="";
    my $n1 = 0;
    my $n_max = 0;
    my $dice_cnt_total = 0;
    my $double_check = 0;

    if($double_up){ # 振り足しありのゲームでダイスが二個以上
        if($double_type <= 0){  # 判定のみ振り足し
            $double_check = 1 if($check_on);
        } elsif($double_type <= 1){ # ダメージのみ振り足し
            $double_check = 1 if(! $check_on);
        } else {    # 両方振り足し
            $double_check = 1;
        }
    }
    while($string=~ /(^([\d]+\*[\d]+)\*(.+)|(.+)\*([\d]+\*[\d]+)$|(.+)\*([\d]+\*[\d]+)\*(.+))/) {
        if($2) {
            $string = parren_killer('('.$2.')').'*'.$3;
        }elsif($5) {
            $string = $4.'*'.parren_killer('('.$5.')');
        }elsif($7) {
            $string = $6.'*'.parren_killer('('.$7.')').'*'.$8;
        }
    }
    my @MUL_CMD = split(/\*/, $string);
    foreach my $mul_line (@MUL_CMD) {
        if($mul_line =~ /([\d]+)D([\d]+)/) {
            my $dice_cnt = $1;
            $dice_max = $2;
            if($dice_max > $DICE_MAXNUM) {
                return(0, 0, "", 0, 0, 0, 0);
            }
            my($dice_now, $dice_str, $n1_wk, $n_max_wk);
            $dice_now = $n1_wk = $n_max_wk = 0;
            $dice_str = "";
            my @dice_arr;
            push(@dice_arr,$dice_cnt);
            do {
                my $dice_wk = shift @dice_arr;
                $dice_cnt_total += $dice_wk;
                my @DICE_DAT = &roll($dice_wk, $dice_max, ($sort_flg & 1));
                $dice_now += $DICE_DAT[0];
                $dice_str .= "][" if($dice_str ne "");
                $dice_str .= $DICE_DAT[1];
                $n1_wk += $DICE_DAT[2];
                $n_max_wk += $DICE_DAT[3];
                if($double_check && $dice_wk >= 2) {    # 振り足しありでダイスが二個以上
                    my @dice_num = split(/,/, $DICE_DAT[1]);
                    my @dice_face;
                    for(my $i = 0; $i < $dice_max; $i++){
                        push(@dice_face, 0);
                    }
                    foreach my $dice_o (@dice_num){
                        $dice_face[$dice_o - 1] += 1;
                    }
                    foreach my $dice_o (@dice_face){
                        if($double_up == 1){ # 全部同じ目じゃないと振り足しなし
                            push(@dice_arr, $dice_o) if( $dice_o == $dice_wk );
                        } else {
                            push(@dice_arr, $dice_o) if( $dice_o >= $double_up );
                        }
                    }
                }
            } while(@dice_arr);
            if($game_type eq "CthulhuTech" && $check_on && $dice_max == 10) { # クトゥルフ・テックの判定用ダイス計算
                $dice_now = cthulhutech_check($dice_str);
            }
            $dice_total *= $dice_now;
            $dice_n += $dice_now;
            $n1 += $n1_wk;
            $n_max += $n_max_wk;
            if($output ne "") {
                $output .= "*";
            }
            if($modeflg > 1) {
                    $output .= $dice_now."[$dice_str]";
            } elsif($modeflg > 0) {
                    $output .= "$dice_now";
            }
        } else {
            $dice_total *= ($mul_line);
            if($output ne "") {
                $output .= "*";
            }
            if(($mul_line) < 0) {
                $output .= "($mul_line)";
            } else {
                $output .= "$mul_line";
            }
        }
    }
    return($dice_total, $dice_n, $output, $n1, $n_max, $dice_cnt_total, $dice_max);
}

####################         バラバラダイス       ########################
sub bdice { # 個数判定型ダイスロール
    my $total_n = 0;
    my $suc = 0;
    my $ulflg = "";
    my $diff = 0;
    my $output = "";
    my $string = $_[0];

    $string =~ s/-[\d]+B[\d]+//g;   # バラバラダイスを引き算しようとしているのを除去
    if($string =~ /(^|\s)S?(([\d]+B[\d]+(\+[\d]+B[\d]+)*)(([<>=]+)([\d]+))?)($|\s)/) {
        $string = $2;
        if($5) {
            $ulflg = &cp_f($6);
            $diff = $7;
            $string = $3;
        } elsif($suc_def) {
            if($suc_def =~/([<>=]+)(\d+)/) {
                $ulflg = &cp_f($1);
                $diff = $2;
            }
        }
        my @DICE_A = split(/\+/, $string);
        my $dice_cnt_total = 0;
        my $n1_total = 0;
        foreach my $dice_o (@DICE_A) {
            my ($dice_cnt, $dice_max) = split(/[bB]/, $dice_o);
            my @DICE_DAT = &roll($dice_cnt, $dice_max, ($sort_flg & 2), 0, $ulflg, $diff);
            $suc += $DICE_DAT[5];
            $output .= "," if($output ne "");
            $output .= $DICE_DAT[1];
            $n1_total += $DICE_DAT[2];
            $dice_cnt_total += $dice_cnt;
        }
        if($ulflg ne "") {
            $string .= "$ulflg$diff";
            $output = "$output ＞ 成功数$suc";
            if($game_type eq "ShadowRun4") {    # SR4用グリッチ処理
                if($n1_total >= ($dice_cnt_total / 2)) {    # グリッチ！
                    if($suc) {
                        $output .= ' ＞ グリッチ';
                    } else {
                        $output .= ' ＞ クリティカルグリッチ';
                    }
                }
            }
        }
        $output = "$_[1]: ($string) ＞ $output";
    } else {
        $output = '1';
    }
    return $output;
}

####################        個数振り足しダイス     ########################
sub rdice { # 個数振り足し型ダイスロール
    my($dice_cnt, $dice_max, $round);
    my $total_n = 0;
    my $suc = 0;
    my $ulflg = "";
    my $diff = 0;
    my $output = "";
    my $output2 = "";
    my $string = $_[0];
    my $roll_re = 0;
    my $next_roll = 0;

    $string =~ s/-[\d]+R[\d]+//g;   # 振り足しロールの引き算している部分をカット
    if($string =~ /(^|\s)S?([\d]+R[\d\+R]+)(\[(\d+)\])?(([<>=]+)([\d]+))?(\@(\d+))?($|\s)/) {
        $string = $2;
        if($3) {
            $roll_re = $4;
        } elsif($8) {
            $roll_re = $9;
        } elsif($5) {
            $roll_re = $7;
        } elsif($reroll_n) {
            $roll_re = $reroll_n;
        } else {
            return '条件が間違っています'
        }
        if($5) {
            $ulflg = &cp_f($6);
            $diff = $7;
        } elsif($suc_def) {
            if($suc_def =~/([<>=]+)(\d+)/) {
                $ulflg = &cp_f($1);
                $diff = $2;
            }
        }
        my @DICE_A = split(/\+/, $string);
        my $n1_total = 0;
        my $dice_cnt_total =0;
        foreach my $dice_o (@DICE_A) {
            ($dice_cnt, $dice_max) = split(/[rR]/, $dice_o);
            if(&check_r($dice_max, $ulflg, $diff)) {
                my @DICE_DAT = &roll($dice_cnt, $dice_max, ($sort_flg & 2), 0, $ulflg, $diff, $roll_re);
                $suc += $DICE_DAT[5];
                $output .= "," if($output ne "");
                $output .= $DICE_DAT[1];
                $next_roll += $DICE_DAT[6];
                $n1_total += $DICE_DAT[2];
                $dice_cnt_total += $dice_cnt;
            } else {
                $suc = 0;
                $next_roll = 0;
                $output = '条件が間違っています';
                last;
            }
        }
        $round = 0;
        if($next_roll > 0) {
            $dice_cnt = $next_roll;
            do {
                $output2 .= "$output + ";
                $output = "";
                my @DICE_DAT = &roll($dice_cnt, $dice_max, ($sort_flg & 2), 0, $ulflg, $diff, $roll_re);
                $suc += $DICE_DAT[5];
                $output .= $DICE_DAT[1];
                $round++;
                $dice_cnt_total += $dice_cnt;
                $dice_cnt = $DICE_DAT[6];
            } while (($dice_cnt > 0) && (($round < $reroll_cnt)||(!$reroll_cnt)));
        }

        $output = "$output2$output ＞ 成功数$suc";
        $string .= "[${roll_re}]${ulflg}${diff}";
        if($game_type eq "ShadowRun4") {    # SR4用グリッチ処理
            if($n1_total >= ($dice_cnt_total / 2)) {    # グリッチ！
                if($suc) {
                    $output .= ' ＞ グリッチ';
                } else {
                    $output .= ' ＞ クリティカルグリッチ';
                }
            }
        }
        $output = "$_[1]: ($string) ＞ $output";

        if(length($output) > $SEND_STR_MAX) {   # 長すぎたときの救済
            $output = "$_[1]: ($string) ＞ ... ＞ 回転数${round} ＞ 成功数$suc";
        }
    } else {
        $output = '1';
    }
    return $output;
}
sub check_r {   # 振り足しロールの条件確認
    my $dice_max = $_[0];
    my $ulflg    = $_[1];
    my $diff     = $_[2];
    my $flg = 1;

    if($ulflg eq '<=') {
        $flg = 0 if($diff >= $dice_max);
    } elsif($ulflg eq '>=') {
        $flg = 0 if($diff <= 1);
    } elsif($ulflg eq '<>') {
        $flg = 0 if(($diff > $dice_max)||($diff < 1));
    } elsif($ulflg  eq '<') {
        $flg = 0 if($diff > $dice_max);
    } elsif($ulflg eq '>') {
        $flg = 0 if($diff < 1);
    }
    return $flg;
}

####################          上方無限ダイス      ########################
sub udice { # 上方無限型ダイスロール
    my($dice_cnt, $dice_max, $dice_now, $i, $suc2);
    my($upper, $dice_n, $max, $cnt1, $dice_cnt_a, $dice_add2);
    my $total_n = 0;
    my $suc = 0;
    my $ulflg = "";
    my $diff = 0;
    my $output = "";
    my $max_o = 0;
    my $cnt_o = 0;
    my $dice_add = 0;
    my $string = $_[0];

    $string =~ s/-[sS]?[\d]+[uU][\d]+//g;   # 上方無限の引き算しようとしてる部分をカット
    if($string =~ /(^|\s)[sS]?(\d+[uU][\d\+\-uU]+)(\[(\d+)\])?(([<>=]+)(\d+))?(\@(\d+))?($|\s)/) {
        $string = $2;
        if($5) {
            $ulflg = &cp_f($6);
            $diff = $7;
        }
        if($3) {
            $upper = $4;
        } elsif($8) {
            $upper = $9;
        } else {
            if($upperinf eq "Max") {
                $upper = 2;
            } else {
                $upper = $upperinf;
            }
        }
        if($upper <= 1) {
            $output = "$_[1]: ($string\[$upper\]) ＞ 無限ロールの条件がまちがっています"
        } else {
            my @DICE_A = split(/\+/, $string);
            my (@dice_cmd, @dice_bns);
            foreach my $dice_o (@DICE_A) {
                 if($dice_o =~/[Uu]/) {
                    push @dice_cmd, $dice_o;
                } else {
                    push @dice_bns, $dice_o;
                }
            }
            my $bonus_str = join "+", @dice_bns;
            my $bonus_ttl = 0;
            $bonus_ttl = parren_killer("(".$bonus_str.")") if($bonus_str);
            foreach my $dice_o (@dice_cmd) {
                ($dice_cnt, $dice_max) = split(/[uU]/, $dice_o);
                if($upperinf eq "Max") {
                    $upper = $dice_max;
                }
                my @DICE_DAT = &roll($dice_cnt, $dice_max, ($sort_flg & 2), $upper, $ulflg, $diff - $bonus_ttl);
                $suc += $DICE_DAT[5];
                $output .= "," if($output ne "");
                $output .= $DICE_DAT[1];
                $max_o = $DICE_DAT[4] if($DICE_DAT[4] > $max_o);
                $cnt_o += $DICE_DAT[2];
                $dice_cnt_a += $dice_cnt;
                $dice_add += $DICE_DAT[0];
            }
            if($bonus_ttl) {
                if($bonus_ttl > 0) {
                    $output .= "+${bonus_ttl}";
                } else {
                    $output .= "${bonus_ttl}";
                }
                $max_o += $bonus_ttl;
                $dice_add += $bonus_ttl;
            }
            $string .= "[$upper]";
            if(($max_dice != 0) && ($dice_cnt_a > 1)) {
                $output = "$output ＞ ${max_o}";
            }
            if($ulflg ne "") {
                $output = "$output ＞ 成功数$suc";
                $string .= "$ulflg$diff";
            } else {
                if($game_type eq "DoubleCross") {   # ダブルクロス用
                    if($cnt_o >= $dice_cnt_a) {
                        $output =~ s/[\s]＞[\s][\d]+$//;
                        $output = "$output ＞ ファンブル";
                    }
                } else {
                    $output .= " / ${dice_add}(最大/合計)" if($dice_cnt_a > 1);
                }
            }
            $output = "$_[1]: ($string) ＞ $output";

            if (length($output) > $SEND_STR_MAX) {
                $output ="$_[1]: ($string) ＞ ... ＞ ${max_o}";
                if($ulflg eq "") {
                    $output .= " / ${dice_add}(最大/合計)" if($dice_cnt_a > 1);
                }
            }
        }
    } else {
        $output = '1';
    }
    return $output;
}

####################             D66ダイス        ########################
sub d66dice {
    my $string = "\U$_[0]";
    my $output = '1';
    my $count = 1;
    
    if($string =~ /(^|\s)((\d*)D66)(\s|$)/) {
        $string = $2;
        $count = $3 if($3);
        $output = "";
        for(my $i = 0; $i < $count; $i++) {
            $output .= "," if($output);
            $output .= &d66($d66_on);
        }
        $output = "$_[1]: ($string) ＞ ".$output;
    }
    
    return $output;
}
sub d66 {
    my $mode = shift;
    my $output = 0;

    my $dice_a = int(rand(6) + 1);
    my $dice_b = int(rand(6) + 1);
    if($mode > 1) {
        # 大小でスワップするタイプ
        if($dice_a < $dice_b) {
            $output = $dice_a * 10 + $dice_b;
        } else {
            $output = $dice_a + $dice_b * 10;
        }
    } else {
        # 出目そのまま
        $output = $dice_a * 10 + $dice_b;
    }
    
    return $output;
}


####################             DXダイス         ########################
sub dxdice {    # ダブルクロス型個数振り足しダイスロール
    my($dice_cnt, $dice_max, $round);
    my $total_n = 0;
    my $ulflg = "";
    my $diff = 0;
    my $output = "";
    my $output2 = "";
    my $string = $_[0];
    my $roll_re = 0;
    my $next_roll = 0;

    $string =~ s/-[\d]+[rR][\d]+//g;    # 振り足しロールの引き算している部分をカット
    if($string =~ /(^|\s)[sS]?([\d]+[rR][\d\+\-rR]+)(\[(\d+)\])?(([<>=]+)(\d+))?($|\s)/) {
        $string = $2;
        if($3) {
            $roll_re = $4;
        } elsif($reroll_n) {
            $roll_re = $reroll_n;
        } else {
            return '条件が間違っています'
        }
        if($5) {
            $ulflg = &cp_f($6);
            $diff = $7;
        } elsif($suc_def) {
            if($suc_def =~/([<>=]+)(\d+)/) {
                $ulflg = &cp_f($1);
                $diff = $2;
            }
        }
        my @DICE_A = split(/\+/, $string);
        my (@dice_cmd, @dice_bns);
        foreach my $dice_o (@DICE_A) {
             if($dice_o =~/[Rr]/) {
                if($dice_o =~ /-/) {
                    my @dice_wk = split /-/, $dice_o;
                    push @dice_cmd, shift @dice_wk;
                    push @dice_bns, "0-".join "-", @dice_wk;
                } else {
                    push @dice_cmd, $dice_o;
                }
            } else {
                push @dice_bns, $dice_o;
            }
        }
        my $bonus_str = join "+", @dice_bns;
        my $bonus_ttl = 0;
        $bonus_ttl = parren_killer("(".$bonus_str.")") if($bonus_str);
        my $n1_total = 0;
        my $dice_cnt_total =0;
        foreach my $dice_o (@dice_cmd) {
            my $subtotal = 0;
            ($dice_cnt, $dice_max) = split(/[rR]/, $dice_o);
            my @dice_dat = &roll($dice_cnt, $dice_max, ($sort_flg & 2), 0, "", 0, $roll_re);
            $output .= "," if($output ne "");
            $next_roll += $dice_dat[6];
            $n1_total += $dice_dat[2];
            $dice_cnt_total += $dice_cnt;
            if($dice_dat[6] > 0) {  # リロール時の特殊処理
                if($game_type eq "DoubleCross" && $dice_max == 10) {
                    $subtotal = 10;
                } else {            # 特殊処理無し(最大値)
                    $subtotal = $dice_dat[4];
                }
            } else {
                $subtotal = $dice_dat[4];
            }
            $output .= "${subtotal}[${dice_dat[1]}]";
            $total_n += $subtotal;
        }
        $round = 0;
        if($next_roll > 0) {
            $dice_cnt = $next_roll;
            do {
                my $subtotal = 0;
                $output2 .= "$output+";
                $output = "";
                my @dice_dat = &roll($dice_cnt, $dice_max, ($sort_flg & 2), 0, "", 0, $roll_re);
                $round++;
#               $n1_total += $dice_dat[2];
                $dice_cnt_total += $dice_cnt;
                $dice_cnt = $dice_dat[6];
                if($dice_dat[6] > 0) {  # リロール時の特殊処理
                    if($game_type eq "DoubleCross" && $dice_max == 10) {
                        $subtotal = 10;
                    } else {            # 特殊処理無し(最大値)
                        $subtotal = $dice_dat[4];
                    }
                } else {
                    $subtotal = $dice_dat[4];
                }
                $output .= "${subtotal}[${dice_dat[1]}]";
                $total_n += $subtotal;
            } while (($dice_cnt > 0) && (($round < $reroll_cnt)||(!$reroll_cnt)));
        }
        $total_n += $bonus_ttl;
        if($bonus_ttl > 0) {
            $output = "${output2}${output}+${bonus_ttl} ＞ ${total_n}";
        } elsif($bonus_ttl < 0) {
            $output = "${output2}${output}${bonus_ttl} ＞ ${total_n}";
        } else {
            $output = "${output2}${output} ＞ ${total_n}";
        }
        $string .= "[${roll_re}]";
        $string .= "${ulflg}${diff}" if($ulflg ne "");
        $output = "$_[1]: ($string) ＞ $output";
        if(length($output) > $SEND_STR_MAX) {   # 長すぎたときの救済
            $output = "$_[1]: ($string) ＞ ... ＞ 回転数${round} ＞ ${total_n}";
        }
        if($ulflg ne "") {  # 成功度判定処理
            $output .= &check_suc($total_n, 0, $ulflg, $diff, $dice_cnt_total, $dice_max, $n1_total, 0);
        } else {    # 目標値無し判定
            if($round <= 0) {
                if($game_type eq "DoubleCross" && $dice_max == 10) {
                    if($n1_total >= $dice_cnt_total) {
                        $output .= " ＞ ファンブル";
                    }
                }
            }
        }
    } else {
        $output = '1';
    }
    return $output;
}

####################            サタスペ           ########################
sub satasupe_check {
    my $string = $_[0];
    my $output = "";

    if($game_type eq "Satasupe") {
        if($string =~ /(^|\s)S?((\d+)(S)?R([>=]+)(\d+)(\[(\d+)?(,\d+)?\])?)($|\s)/i) {
            $string = $2;
            my $roll_times = $3;
            my $ulflg = &cp_f($5);
            my $target = $6;
            my $param = $7;
            my $min_suc = 0;
            my $fumble = 1;
            if($param) {
                $param =~ s/(\[|\])//g;
                my @dmy = split /,/, $param;
                if($dmy[0] && ($dmy[0] > 0)) {
                    $min_suc = $dmy[0];
                }
                if($dmy[1] && ($dmy[1] > 1)) {
                    $fumble = $dmy[1];
                }
            }
            my $total_suc = 0;
            my $fumble_flg = 0;
            my $i = 0;
            my $dice_str = "";
            while(($i < $roll_times) && (!$fumble_flg) && (($total_suc < $min_suc) || !$min_suc)) {
                my $d1 = int(rand 6) + 1;
                my $d2 = int(rand 6) + 1;
                if(($d1 == $d2) and ($d1 <= $fumble)) { # ファンブルの確認
                    $fumble_flg = 1;
                }
                my $dice_suc = 0;
                $dice_suc = 1 if($target <= ($d1 + $d2));
                $dice_str .= "+" if($dice_str);
                $dice_str .= "${dice_suc}[${d1},${d2}]";
                $total_suc += $dice_suc;
                $i++;
            }
            $output = "$_[1]: ($string) ＞ $dice_str ＞ 成功度$total_suc";
            if($fumble_flg) {
                $output .= " ＞ ファンブル";
            }
        }
    }

    return $output;
}

####################           Ars Magica          ########################
sub arsmagica_stress {
    my $string = $_[0];
    my $output = "1";

    if($game_type eq "ArsMagica") {
        if($string =~ /(^|\s)S?(1[rR]10([\+\-\d]*)(\[(\d+)\])?(([>=]+)(\d+))?)(\s|$)/i) {
            my $diff = 0;
            my $botch = 1;
            my $bonus = 0;
            my $crit_mul = 1;
            my $total = 0;
            my $ulflg = "";
            $botch = $5 if($4);
            if($6) {
                $ulflg = &cp_f($7);
                $diff = $8;
            }
            $bonus = parren_killer("(0".$3.")") if($3);

            my $die = int(rand 10);
            $output = "($2) ＞ ";
            if($die == 0) { # botch?
                my $count0 = 0;
                my @dice_n;
                for(my $i = 0; $i < $botch; $i++) {
                    my $botch_die = int(rand 10);
                    $count0++ unless($botch_die);
                    push @dice_n, $botch_die;
                }
                @dice_n = sort {$a<=>$b} @dice_n if($sort_flg);
                $output .= "0[$die,".(join ",", @dice_n)."]";
                if($count0) {
                    $bonus = 0;
                    if($count0 > 1) {
                        $output .= " ＞ ${count0}Botch!";
                    } else {
                        $output .= " ＞ Botch!";
                    }
                    $ulflg = "";
                } else {
                    if($bonus > 0) {
                        $output .= "+$bonus ＞ ".$bonus;
                    } elsif($bonus < 0) {
                        $output .= "$bonus ＞ ".$bonus;
                    } else {
                        $output .= " ＞ 0";
                    }
                    $total = $bonus;
                }
            } elsif($die == 1) {    # Crit
                my $crit_dice = "";
                while ($die == 1) {
                    $crit_mul *= 2;
                    $die = int(rand 10) + 1;
                    $crit_dice .= "$die,";
                }
                $total = $die * $crit_mul;
                $crit_dice =~ s/,$//;
                $output .= "$total";
                if($modeflg) {
                    $output .= "[1,$crit_dice]";
                }
                $total = $total + $bonus;
                if($bonus > 0) {
                    $output .= "+$bonus ＞ $total";
                } elsif($bonus < 0) {
                    $output .= "$bonus ＞ $total";
                }
            } else {
                $total = $die + $bonus;
                if($bonus > 0) {
                    $output .= "$die+$bonus ＞ $total";
                } elsif($bonus < 0) {
                    $output .= "$die$bonus ＞ $total";
                } else {
                    $output .= "$total";
                }
            }
            if($ulflg ne "") {  # 成功度判定処理
                $output .= &check_suc($total, 0, $ulflg, $diff, 1, 10, 0, 0);
            }
        }
    }
    return $output;
}

####################   Tunnels and Trolls Berserk  ########################
sub tandt_berserk{
    my $string = $_[0];
    my $output = "1";

    if($game_type eq "Tunnels & Trolls") {
        if($string =~ /(^|\s)S?((\d+)[rR]6([\+\-\d]*)(\[(\w+)\])?)(\s|$)/i) {
            $string = $2;
            my $dice_c = $3;
            my $bonus = 0;
            $bonus = parren_killer("(0".$4.")") if($4);
            my $hyper_flg = 0;
            $hyper_flg = 1 if($5 and ($6 =~ /[Hh]/));
            my @dice_arr;
            my $dice_now = 0;
            my $dice_str = "";
            my $first_r = 1;
            my $n_max = 0;
            my $total_n = 0;
            my $bonus2 = 0;

            # ２回目以降
            push(@dice_arr, $dice_c);
            do {
                my $dice_wk = shift @dice_arr;
                my @DICE_DAT = &roll($dice_wk, 6, ($sort_flg & 1));
                if($dice_wk >= 2) { # ダイスが二個以上
                    my @dice_num = split(/,/, $DICE_DAT[1]);
                    my @dice_face;
                    for(my $i = 0; $i < 6; $i++){
                        push(@dice_face, 0);
                    }
                    foreach my $dice_o (@dice_num){
                        $dice_face[$dice_o - 1] += 1;
                    }
                    foreach my $dice_o (@dice_face){
                        if( $dice_o >= 2 ) {
                            $dice_o++ if($hyper_flg);
                            push(@dice_arr, $dice_o);
                        }
                    }
                    if($first_r and (scalar @dice_arr < 1)) {
                        my $min1 = 0;
                        my $min2 = 0;
                        for(my $i = 5; $i > -1; $i--) {
                            if( $dice_face[$i] > 0 ) {
                                $min2 = $min1;
                                $min1 = $i;
                            }
                        }
                        $bonus2 = -($min2 - $min1);
                        $DICE_DAT[3]-- if($min2 == 5);
                        if($hyper_flg) {
                            push(@dice_arr, 3);
                        } else {
                            push(@dice_arr, 2);
                        }
                    }
                }
                $dice_now += $DICE_DAT[0];
                $dice_str .= "][" if($dice_str ne "");
                $dice_str .= $DICE_DAT[1];
                $n_max += $DICE_DAT[3];
                $first_r = 0;
            } while(@dice_arr);
            $total_n = $dice_now + $bonus + $bonus2;
            $dice_str = "[".$dice_str."]";
            $output = "${dice_now}${dice_str}";
            if($bonus2 < 0) {
                $output .= "${bonus2}";
            }
            if($bonus > 0) {
                $output .= "+${bonus}";
            } elsif($bonus < 0) {
                $output .= "${bonus}";
            }
            if($modeflg > 0) {
                if($output =~ /[^\d\[\]]+/) {
                    $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
                } else {
                    $output = "$_[1]: ($string) ＞ $total_n";
                }
            } else {
                $output = "$_[1]: ($string) ＞ $total_n";
            }
            $output .= " ＞ 悪意".$n_max if(($n_max > 0));
        }
    }
    return $output;
}

####################         ダークブレイズ        ########################
sub dark_blaze_check {
    my $string = $_[0];
    my $output = "1";

    if ($game_type eq "DarkBlaze") {
        if($string =~ /(^|\s)S?(3[rR]6([\+\-\d]+)?(\[(\d+),(\d+)\])(([>=]+)(\d+))?)(\s|$)/i) {
            $string = $2;
            my $mod = 0;
            my $abl = 1;
            my $skl = 1;
            my $ulflg = "";
            my $diff = 0;
            $mod = parren_killer("(0".$3.")") if($3);
            if($4) {
                $abl = $5;
                $skl = $6;
            }
            if($7) {
                $ulflg = &cp_f($8);
                $diff = $9;
            }
            my($total, $out_str) = &dark_blaze_dice($mod, $abl, $skl);
            $output = "$_[1]: ($string) ＞ $out_str";
            if($ulflg ne "") {  # 成功度判定処理
                $output .= &check_suc($total, 0, $ulflg, $diff, 3, 6, 0, 0);
            }
        }
    }
    return $output;
}
sub dark_blaze_dice {
    my ($mod, $abl, $skl) = @_;
    my $output = "";
    my $total = 0;
    my $crit = 0;
    my $fumble = 0;
    my $dice_c = 3 + abs($mod);
    my @dummy = &roll($dice_c, 6, 1);
    shift @dummy;
    my $dice_str = shift @dummy;
    my @dice_arr = split /,/, $dice_str;
    for(my $i = 0; $i < 3; $i++) {
        my $ch = $dice_arr[$i];
        $ch = $dice_arr[$dice_c - $i - 1] if($mod < 0);
        $total++ if($ch <= $abl);
        $total++ if($ch <= $skl);
        $crit++ if($ch <= 2);
        $fumble++ if($ch >= 5);
    }
    if($crit >= 3) {
        $output = " ＞ クリティカル";
        $total = 6 + $skl;
    }
    if($fumble >= 3) {
        $output = " ＞ ファンブル";
        $total = 0;
    }
    $output = "${total}[${dice_str}]${output}";

    return ($total, $output);
}

####################        ナイトウィザード       ########################
sub night_wizard_check {
    my $string = $_[0];
    my $output = '1';
    
    my $num = '[,\d\+\-]+';
    if($string =~ /(^|\s)S?(2R6m\[(${num})\](c\[(${num})\])?(f\[(${num})\])?(([>=]+)(\d+))?)(\s|$)/i) {
        my ($base, $mod) = split /,/, $3;
        my $crit = 0;
        my $fumble = 0;
        my $ulflg = "";
        my $diff = 0;
        $string = $2;
        $base = parren_killer("(0".$base.")");
        $mod = parren_killer("(0".$mod.")");
        if($4) {
            $crit = $5;
        }
        if($6) {
            $fumble = $7;
        }
        if($8) {
            $ulflg = &cp_f($9);
            $diff = $10;
        }
        
        my ($total, $out_str) = &nw_dice($base, $mod, $crit, $fumble);
        $output = "$_[1]: ($string) ＞ $out_str";
        if($ulflg ne "") {  # 成功度判定処理
            $output .= &check_suc($total, 0, $ulflg, $diff, 3, 6, 0, 0);
        }
    }
    return $output;
}
sub nw_dice {
    my ($base, $mod, $crit, $fumble) = @_;
    my @crit_arr = (10,);
    my @fumble_arr = (5,);
    my $total = 0;
    my $output = "";
    if($crit) {
        @crit_arr = split /,/, $crit;
    }
    if($fumble) {
        @fumble_arr = split /,/, $fumble;
    }

    my @dummy = &roll(2, 6, 0);
    my $dice_n = shift @dummy;
    my $dice_str = shift @dummy;
    my $fumble_flg = 0;
    foreach my $f (@fumble_arr) {
        if($dice_n == $f) {
            $fumble_flg = 1;
            $total = $base - 10;
            last;
        }
    }
    if($fumble_flg) {
        $output = "${base}-10[${dice_str}] ＞ ${total}";
    } else {
        my $crit_flg = 1;
        $total = $base + $mod;
        $output = "$total";
        while($crit_flg) {
            $crit_flg = 0;
            foreach my $c (@crit_arr) {
                if($dice_n == $c) {
                    $total += 10;
                    $crit_flg = 1;
                    $output .= "+10[${dice_str}]";
                    last;
                }
            }
            if($crit_flg) {
                @dummy = &roll(2, 6, 0);
                $dice_n = shift @dummy;
                $dice_str = shift @dummy;
            } else {
                $total += $dice_n;
                $output .= "+${dice_n}[${dice_str}] ＞ ${total}";
            }
        }
    }
    return ($total, $output);
}

####################              TORG             ########################
sub torg_check {
    my $string = $_[0];
    my $output = '1';

    if($string =~ /(^|\s)(1R20([+-]\d+)*)(\s|$)/i) {
        $string = $2;
        my $mod = $3;
        $mod = parren_killer("(0".$mod.")") if($mod);
        my ($skilled, $unskilled, $dice_str) = &torg_dice;
        my $sk_bonus = &get_torg_bonus($skilled);
        if($mod) {
            if($mod > 0) {
                $output = "${sk_bonus}[${dice_str}]+$mod";
            } else {
                $output = "${sk_bonus}[${dice_str}]$mod";
            }
        } else {
            $output = "${sk_bonus}[${dice_str}]";
        }
        $output .= " ＞ ".($sk_bonus + $mod);
        if($skilled != $unskilled) {
            $output .= "(技能無".(&get_torg_bonus($unskilled) + $mod).")"
        }
        $output = "$_[1]: ($string) ＞ $output";
    }

    return $output;
}

sub torg_dice {
    my $crit_sk = my $crit_us = 1;
    my $skilled = 0;
    my $unskilled = 0;
    my $dice_str = "";

    while($crit_sk) {
        my @dummy = &roll(1, 20, 0);
        my $dice_n = shift @dummy;
        $skilled += $dice_n;
        $unskilled += $dice_n if($crit_us);
        $dice_str .= "$dice_n,";
        if($dice_n == 20) {
            $crit_us = 0;
        } elsif($dice_n != 10) {
            $crit_sk = 0;
            $crit_us = 0;
        }
    }
    chop $dice_str if($dice_str);
    return ($skilled, $unskilled, $dice_str);
}

####################         迷宮キングダム        ########################
sub mayokin_check {
    my $string = $_[0];
    my $output = "1";

    if($string =~ /(^|\s)S?((\d+)[rR]6([\+\-\d]*)(([>=]+)(\d+))?)(\s|$)/i) {
        $string = $2;
        my $dice_c = $3;
        my $bonus = 0;
        my $ulflg = "";
        my $diff = 0;
        $bonus = parren_killer("(0".$4.")") if($4);
        $ulflg = $6 if($6);
        $diff = $7 if($7);
        my $dice_now = 0;
        my $dice_str = "";
        my $n_max = 0;
        my $total_n = 0;

        my @DICE_DAT = &roll($dice_c, 6, ($sort_flg & 1));
        $dice_str = $DICE_DAT[1];
        my @dice_num = split(/,/, $DICE_DAT[1]);
        $dice_now = $dice_num[$dice_c - 2] + $dice_num[$dice_c - 1];
        $total_n = $dice_now + $bonus;
        $dice_str = "[".$dice_str."]";
        $output = "${dice_now}${dice_str}";
        if($bonus > 0) {
            $output .= "+${bonus}";
        } elsif($bonus < 0) {
            $output .= "${bonus}";
        }
        if($modeflg > 0) {
            if($output =~ /[^\d\[\]]+/) {
                $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
            } else {
                $output = "$_[1]: ($string) ＞ $total_n";
            }
        } else {
            $output = "$_[1]: ($string) ＞ $total_n";
        }
        if($ulflg ne "") {  # 成功度判定処理
            $output .= &check_suc($total_n, $dice_now, $ulflg, $diff, 2, 6, 0, 0);
        }
    }
    return $output;
}

####################            EarthDawn          ########################
sub ed_step{    #アースドーンステップ表
    return '1' if($game_type ne "EarthDawn"); 
    
    my(@mod, @d20, @d12, @d10, @d8, @d6, @d4, @exsuc, @ssuc, @gsuc, @nsuc, @fsuc, @stable);
    #表      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 34x 3x 4x 5x 6x 7x 8x 9x10x11x12x13x
    @mod = (-2,-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    @d20 = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    @d12 = ( 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,);
    @d10 = ( 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 2, 3, 2, 1, 1, 1, 2, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 2, 1,);
    @d8  = ( 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0,);
    @d6  = ( 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 0, 0, 0,);
    @d4  = ( 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    @exsuc=( 6, 8,10,12,14,17,19,20,22,24,25,27,29,32,33,35,37,38,39,41,42,44,45,47,48,49,51,52,54,55,56,58,59,60,62,64,65,67,68,70,71,72,);
    @ssuc= ( 4, 6, 8,10,11,13,15,16,18,19,21,22,24,26,27,29,30,32,33,34,35,37,38,40,41,42,43,45,46,47,48,49,51,52,53,55,56,58,59,60,61,62,);
    @gsuc= ( 2, 4, 6, 7, 9,10,12,13,14,15,17,18,20,21,22,24,25,26,27,28,29,31,32,33,34,35,36,38,39,40,41,42,43,45,46,47,48,50,51,52,53,54,);
    @nsuc= ( 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,);
    @fsuc= ( 0, 1, 1, 1, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 8, 8, 9,10,11,12,13,13,14,15,16,17,18,18,18,20,21,22,23,23,24,25,26,26,27,28,29,30,);
    @stable = (\@mod, \@d20, \@d12, \@d10, \@d8, \@d6, \@d4, \@exsuc, \@ssuc, \@gsuc, \@nsuc, \@fsuc);
    #ステップ表作成終了
    my $str = $_[0];
    my $string = "";
    my $output = "";
    my $sn = 0;
    my $isf = 1;
    my $ST2 = 0;
    my $dice_in = 0;
    my $dice_now = 0;
    
    unless( $str =~ /(\d+)E(\d+)?(\+)?(\d+)?(d\d+)?/i) {
        return '1';
    }
    
    my $ST  = ($1);      #ステップ
    my $TN  = 0;         #目標値
    my $PM  = 0;         #カルマダイスの有無
    my $KD1 = 0;         #カルマダイスの個数又は修正
    my $KD2 = 0;         #カルマダイスの種類
    
    #空値があった時の為のばんぺいくん
    if($ST > 40) {
        $ST2 = $ST;
        $ST = 40;
    }
    
    if($2) {
        $TN = ($2);
        $TN = 42 if($TN > 43);
    }
    $PM = ($3) if($3);
    $KD1= ($4) if($4);
    $KD2= ($5) if($5);
    my $NMOD = $stable[0][$ST -1];
    my $N20  = $stable[1][$ST -1];
    my $N12  = $stable[2][$ST -1];
    my $N10  = $stable[3][$ST -1];
    my $N8   = $stable[4][$ST -1];
    my $N6   = $stable[5][$ST -1];
    my $N4   = $stable[6][$ST -1];
    my $TEX  = $stable[7][$TN -1];
    my $TS   = $stable[8][$TN -1];
    my $TG   = $stable[9][$TN -1];
    my $TNM  = $stable[10][$TN -1];
    my $TF   = $stable[11][$TN -1];
    if( $PM !~ /\+/ ){
    }elsif( $KD2 =~ /d20/i ){ $N20 = $N20 + $KD1;
    }elsif( $KD2 =~ /d12/i ){ $N12 = $N12 + $KD1;
    }elsif( $KD2 =~ /d10/i ){ $N10 = $N10 + $KD1;
    }elsif( $KD2 =~ /d8/i  ){ $N8  = $N8  + $KD1;
    }elsif( $KD2 =~ /d6/i  ){ $N6  = $N6  + $KD1;
    }elsif( $KD2 =~ /d4/i  ){ $N4  = $N4  + $KD1;
    }else{ $NMOD = $NMOD + $KD1;
    }
    if($N20 > 0){       #d20ぶんのステップ判定
        $string .= $N20.'d20[';
        for( my $i = 1; $i <= $N20 ; $i++){
            $dice_now = ( int(rand 20) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in +=  $dice_now;
            while( $dice_now == 20 ){
                $dice_now = ( int(rand 20) + 1 );
                $dice_in += $dice_now;
            }
            $sn += $dice_in;
            $string .= $dice_in;
            if( $i != $N20 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($N12 > 0){       #d12ぶんのステップ判定
        if($N20 > 0){ $string .= '+'; }
        $string .= $N12.'d12[';
        for( my $i=1; $i <= $N12 ; $i++){
            $dice_now = ( int(rand 12) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in += $dice_now;
            while( $dice_now == 12 ){
                $dice_now = ( int(rand 12) + 1 );
                $dice_in += $dice_now;
            }
            $string .= $dice_in;
            $sn += $dice_in;
            if( $i != $N12 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($N10 > 0){       #d10ぶんのステップ判定
        if(($N20 > 0)|($N12 > 0)){ $string .= '+'; }
        $string .= $N10.'d10[';
        for( my $i=1; $i <= $N10 ; $i++){
            $dice_now = ( int(rand 10) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in += $dice_now;
            while( $dice_now == 10 ){
                $dice_now = ( int(rand 10) + 1 );
                $dice_in += $dice_now;
            }
            $string .= $dice_in;
            $sn += $dice_in;
            if( $i != $N10 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($N8 > 0){        #d8ぶんのステップ判定
        if(($N20 > 0)|($N12 > 0)|($N10 > 0 )){ $string .= '+'; }
        $string .= $N8.'d8[';
        for( my $i=1; $i <= $N8 ; $i++){
            $dice_now = ( int(rand 8) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in += $dice_now;
            while( $dice_now == 8 ){
                $dice_now = ( int(rand 8) + 1 );
                $dice_in += $dice_now;
            }
            $string .= $dice_in;
            $sn += $dice_in;
            if( $i != $N8 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($N6 > 0){        #d6ぶんのステップ判定
        if(($N20 > 0)|($N12 > 0)|($N10 > 0)|($N8 > 0)){ $string .= '+'; }
        $string .= $N6.'d6[';
        for( my $i=1; $i <= $N6 ; $i++){
            $dice_now = ( int(rand 6) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in += $dice_now;
            while( $dice_now == 6 ){
                $dice_now = ( int(rand 6) + 1 );
                $dice_in += $dice_now;
            }
            $string .= $dice_in;
            $sn += $dice_in;
            if( $i != $N6 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($N4 > 0){        #d4ぶんのステップ判定
        if(($N20 > 0)|($N12 > 0)|($N10 > 0)|($N8 > 0)|($N6 > 0)){ $string .= '+'; }
        $string .= $N4.'d4[';
        for( my $i=1; $i <= $N4 ; $i++){
            $dice_now = ( int(rand 4) + 1 );
            if($dice_now != 1){ $isf = 0; }
            $dice_in += $dice_now;
            while( $dice_now == 4 ){
                $dice_now = ( int(rand 4) + 1 );
                $dice_in += $dice_now;
            }
            $string .= $dice_in;
            $sn += $dice_in;
            if( $i != $N4 ){
                $string .= ',';
            }
            $dice_in = 0;
        }
        $string .= ']';
    }
    
    if($NMOD != 0){     #修正分の適用
        if( $NMOD > 0 ){
            $string .= '+';
        }
        $string .= $NMOD;
        $sn += $NMOD;
    }
    
    #ステップ判定終了
    $string .= ' ＞ '.$sn;
    
    #結果判定
    if($TN > 0){
        $string .= ' ＞ ';
        if($isf == 1){
            $string .= '自動失敗';
        }elsif($sn >= $TEX){
            $string .= '最良成功';
        }elsif($sn >= $TS){
            $string .= '優成功';
        }elsif($sn >= $TG){
            $string .= '良成功';
        }elsif($sn >= $TN){
            $string .= '成功';
        }elsif($sn < $TF){
            $string .= '大失敗';
        }else{
            $string .= '失敗';
        }
    }
    
    $output = $_[2].': ステップ'.$ST.'>='.$TN.' ＞ '.$string;
    return ($output);
}
# 41以上のステップの為の配列です。
# 以下のようなルールでダイスを増やしています。より正しいステップ計算法をご存知の方は、
# どうぞそちらに合せて調整して下さい。
#　基本：　2d20+d10+d8
#　これを仮にステップ34xとしています。
#　一般式としては、ステップxxのダイスは、

#　 ステップ34xのダイス
# + [(xx-45)/11]d20
# + ステップ[(xx-34)を11で割った余り+3]のダイス

####################        エムブリオマシン      ########################
sub embryo_machine_check {
    my $string = $_[0];
    my $output = '1';

    if($string =~ /(^|\s)S?(2[rR]10([\+\-\d]+)?([>=]+(\d+))(\[(\d+),(\d+)\]))(\s|$)/i) {
        $string = $2;
        my $ulflg = ">=";
        my $diff = 0;
        my $crit = 20;
        my $fumble = 2;
        my $mod = "";
        my $total_n = 0;
        $mod = parren_killer("(0".$3.")") if($3);
        $diff = $5 if($5);
        $crit = $7 if($7);
        $fumble = $8 if($8);
        
        (my $dice_now, my $dice_str, my $dummy) = &roll(2, 10, ($sort_flg & 1));
        (my $dice_loc, $dummy) = &roll(2, 10);
        my @dice_arr = split /,/, $dice_str;
        my $big_dice = $dice_arr[1];
        $output = "${dice_now}[${dice_str}]";
        $total_n = $dice_now + $mod;
        if($mod > 0) {
            $output .= "+${mod}";
        } elsif($mod < 0) {
            $output .= "${mod}";
        }
        if($output =~ /[^\d\[\]]+/) {
            $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
        } else {
            $output = "$_[1]: ($string) ＞ $output";
        }
        # 成功度判定
        if($dice_now <= $fumble) {
            $output .= " ＞ ファンブル";
        } elsif($dice_now >= $crit) {
            $output .= " ＞ クリティカル ＞ ".&em_hit_level_table($big_dice)."(ダメージ+10) ＞ [".$dice_loc."]".&em_hit_location_table($dice_loc);
        } elsif($total_n >= $diff) {
            $output .= " ＞ 成功 ＞ ".&em_hit_level_table($big_dice)." ＞ [".$dice_loc."]".&em_hit_location_table($dice_loc);
        } else {
            $output .= " ＞ 失敗";
        }
    }
    return $output;
}

####################      ゲヘナ・アナスタシス    ########################
sub gehenna_an_check {
    my $string = $_[0];
    my $output = '1';

    if($string =~ /(^|\s)S?((\d+)[rR]6([\+\-\d]+)?([>=]+(\d+))(\[(\d)\]))(\s|$)/i) {
        $string = $2;
        my $ulflg = ">=";
        my $dice_n = 1;
        my $diff = 0;
        my $fumble = 2;
        my $mod = 0;
        my $total_n = 0;
        my $mode = 0;
        $dice_n = $3 if($3);
        $mod = parren_killer("(0".$4.")") if($4);
        $diff = $6 if($6);
        $mode = $8 if($8);
        
        (my $dice_now, my $dice_str, my $dummy) = &roll($dice_n, 6, ($sort_flg & 1));
        my @dice_arr = split /,/, $dice_str;
        my $dice_1st = "";
        my $luck_flg = 1;
        $dice_now = 0;
        # 幸運の助けチェック
        foreach my $i (@dice_arr) {
            if($dice_1st) {
                if($dice_1st != $i or $i < $diff ) {
                    $luck_flg = 0;
                }
            } else {
                $dice_1st = $i;
            }
            $dice_now += 1 if($i >= $diff);
        }
        $dice_now *= 2 if($luck_flg && $dice_n > 1);
        $output = "${dice_now}[${dice_str}]";
        $total_n = $dice_now + $mod;
        if($mod > 0) {
            $output .= "+${mod}";
        } elsif($mod < 0) {
            $output .= "${mod}";
        }
        if($output =~ /[^\d\[\]]+/) {
            $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
        } else {
            $output = "$_[1]: ($string) ＞ $output";
        }
        # 連撃増加値と闘技チット
        if($mode) {
            my $bonus_str = '';
            my $ma_bonus = int(($total_n  - 1) / 2);
            $ma_bonus = 7 if($ma_bonus > 7);
            
            $bonus_str .= '連撃[+'.$ma_bonus.']/' if($ma_bonus > 0);
            $bonus_str .= '闘技['.&ga_ma_chit_table($total_n).']';
            $output .= " ＞ $bonus_str";
        }
    }
    return $output;
}

####################           ネクロニカ         ########################
sub nechronica_check {
    my ($string, $nick_t) = @_;
    my $output = '1';

    if($string =~ /(^|\s)S?((\d+)[rR]10([\+\-\d]+)?(\[(\d+)\])?)(\s|$)/i) {
        $string = $2;
        my $ulflg = ">=";
        my $dice_n = 1;
        my $diff = 6;
        my $mod = 0;
        my $total_n = 0;
        my $mode = 0;   # 0=判定モード, 1=戦闘モード
        $dice_n = $3 if($3);
        $mod = parren_killer("(0".$4.")") if($4);
        $mode = $6 if($5);
        
        # $total, $dice_str, $cnt1, $cnt_max, $n_max, $cnt_suc, $cnt_re
        my ($dice_now, $dice_str, $n1, $cnt_max, $n_max) = &roll($dice_n, 10, 1);
        $total_n = $n_max + $mod;
        $output = "${nick_t}: ($string) ＞ [${dice_str}]";
        if($mod < 0) {
            $output .= "${mod}";
        } elsif($mod > 0) {
            $output .= "+${mod}";
        }
        $n1 = 0;
        $cnt_max = 0;
        my @dice = split(/,/, $dice_str);
        for(my $i=0; $i<scalar @dice; $i++) {
            $dice[$i] += $mod;
            $n1 += 1 if($dice[$i] <= 1);
            $cnt_max += 1 if($dice[$i] >= 10);
        }
        $dice_str = join ",", @dice;
        $output .= "  ＞ ${total_n}[${dice_str}]";        
        # $total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max
        $output .= &check_suc($total_n, $n_max, $ulflg, $diff, $dice_n, 10, $n1, $n_max);
        if($dice_n > 1 && $n1 >= 1 && $total_n <= $diff) {
            $output .= " ＞ 損傷${n1}";
        }
        if($mode) {
            my $hit_loc = &nechronica_hit_location_table($total_n);
            if($hit_loc ne '1') {
                $output .= " ＞ ".$hit_loc;
            }
        }
    }
    return $output;
}

####################           迷宮デイズ         ########################
sub mayoday_check {
    my $string = $_[0];
    my $output = "1";

    if($string =~ /(^|\s)S?((\d+)[rR]6([\+\-\d]*)(([>=]+)(\d+))?)(\s|$)/i) {
        $string = $2;
        my $dice_c = $3;
        my $bonus = 0;
        my $ulflg = "";
        my $diff = 0;
        $bonus = parren_killer("(0".$4.")") if($4);
        $ulflg = $6 if($6);
        $diff = $7 if($7);
        my $dice_now = 0;
        my $dice_str = "";
        my $n_max = 0;
        my $total_n = 0;

        my @DICE_DAT = &roll($dice_c, 6, ($sort_flg & 1));
        $dice_str = $DICE_DAT[1];
        my @dice_num = split(/,/, $DICE_DAT[1]);
        $dice_now = $dice_num[$dice_c - 2] + $dice_num[$dice_c - 1];
        $total_n = $dice_now + $bonus;
        $dice_str = "[".$dice_str."]";
        $output = "${dice_now}${dice_str}";
        if($bonus > 0) {
            $output .= "+${bonus}";
        } elsif($bonus < 0) {
            $output .= "${bonus}";
        }
        if($modeflg > 0) {
            if($output =~ /[^\d\[\]]+/) {
                $output = "$_[1]: ($string) ＞ $output ＞ $total_n";
            } else {
                $output = "$_[1]: ($string) ＞ $total_n";
            }
        } else {
            $output = "$_[1]: ($string) ＞ $total_n";
        }
        if($ulflg ne "") {  # 成功度判定処理
            $output .= &check_suc($total_n, $dice_now, $ulflg, $diff, 2, 6, 0, 0);
        }
    }
    return $output;
}

####################        バルナ・クロニカ      ########################
sub barna_kronika_check {
    my ($string, $nick_t) = @_;
    my $output = '1';

    if($string =~ /(^|\s)S?((\d+)[rR]6(\[([,\d]+)\])?)(\s|$)/i) {
        $string = $2;
        my $dice_n = 1;
        my $total_n = 0;
        my $mode = 0;       # 0=判定モード, 1=戦闘モード
        my $cc = 0;         # 0=通常, 1～6=クリティカルコール
        $dice_n = $3 if($3);
        ($mode, $cc) = split ",",$5 if($4);
        my($dice_str, $suc, $set, $at_str) = &barna_kronika_roll($dice_n, $mode, $cc);
        $output = "${nick_t}: ($string) ＞ [${dice_str}] ＞ ";
        if($mode) {
            $output .= $at_str;
        } else {
            if($suc > 1) {
                $output .= "成功数${suc}";
            } else {
                $output .= "失敗";
            }
            $output .= ",セット${set}" if($set > 0);
        }
    }
    return $output;
}

sub barna_kronika_roll {
    my ($dice_n, $mode, $cc) = @_;
    my $output = '';
    my $suc = 0;
    my $set = 0;
    my $at_str = '';
    my @dice_cnt = (0, 0, 0, 0, 0, 0);

    for(my $i = 0; $i < $dice_n; $i++) {
        my $idx = int(rand 6);
        $dice_cnt[$idx]++;
        $suc = $dice_cnt[$idx] if($dice_cnt[$idx] > $suc);
    }
    for(my $i = 0; $i < 6; $i++) {
        my $dc = $dice_cnt[$i];
        if($dc > 0) {
            for(my $cnt = 0; $cnt < $dc; $cnt++) {
                $output .= ($i + 1).',';
            }
            if($mode) {
                if($cc) {
                    if($cc == ($i + 1)) {
                        $at_str .= &barna_kronika_hit_location_table($i + 1).":攻撃値".($dc * 2).",";
                    }
                } else {
                    if($dc > 1) {
                        $at_str .= &barna_kronika_hit_location_table($i + 1).":攻撃値".$dc.",";
                    }
                }
            }
            $set++ if($dc > 1);
        }
    }
    if($cc) {
        my $c_cnt = scalar $dice_cnt[$cc - 1];
        $suc = $c_cnt * 2;
        if($c_cnt) {
            $set = 1;
        } else {
            $set = 0;
        }
    }
    if($mode && $suc < 2) {
        $at_str = "失敗";
    }
    $output =~ s/,$//;
    $at_str =~ s/,$//;
    return ($output, $suc, $set, $at_str);
}

####################          六門世界2nd.        ########################
sub rokumon2_check {
    my ($string, $nick_t) = @_;
    my $mod = 0;
    my $target = 0;
    my $abl = 0;
    my $output = '1';
    
    if($string =~ /3R6([\+\-\d]*)<=(\d+)\[(\d+)\]/i) {
        $mod = &parren_killer("(0".$1.")") if($1);
        $target = $2;
        $abl = $3;
        my($dstr, $suc, $sum) = &rokumon2_roll($mod, $target, $abl);
        $output = "${sum}[${dstr}] ＞ $suc ＞ 評価".&rokumon2_suc_rank($suc);
        $output .= "(+${suc}d6)" if($suc);
    }
    $output = "${nick_t}: (${string}) ＞ ${output}";

    return $output;
}

sub rokumon2_roll {
    my($mod, $target, $abl) = @_;
    my $suc = 0;
    
    my($dtotal, $dicestr, $dummy) = &roll(3 + abs($mod), 6 , 1);
    my @dice = split /,/, $dicestr;
    for(my $i = 0; $i < abs($mod); $i++) {
        if($mod < 0) {
            shift @dice;
        } else {
            pop @dice;
        }
    }
    my $cnt5 = 0;
    my $cnt2 = 0;
    my $sum = 0;
    foreach my $die1 (@dice) {
        $cnt5++ if($die1 >= 5);
        $cnt2++ if($die1 <= 2);
        $suc++  if($die1 <= $abl);
        $sum += $die1;
    }
    if($sum < $target) {
        $suc += 2;
    } elsif($sum == $target) {
        $suc += 1;
    }
    $suc = 0 if($cnt5 >= 3);
    $suc = 5 if($cnt2 >= 3);
    return $dicestr, $suc, $sum;
}

sub rokumon2_suc_rank {
    my @suc_rank = ('E','D','C','B','A','S');
    return $suc_rank[$_[0]];
}


####################        その他ダイス関係      ########################
#削除

#=========================================================================
#**                     ゲーム固有コマンド処理
#=========================================================================

#** 汎用表サブルーチン
sub get_table_by_number {
    my $index = shift @_;
    my @table = @_;
    my $output = '1';

    foreach my $item_ref (@table) {
        my @item = @$item_ref;
        my $number = $item[0];
        
        if( $number >= $index ) {
            $output = $item[1];
            last;
        }
    }
    
    return $output;
}


####################        SWレーティング表       ########################
sub rating {    # レーティング表
    return '1' if(! $game_type =~ /^SwordWorld/i);  # 他ゲーム中の暴発防止
    my($key, $dice, $output, $dice_str, $mod, $key_max);
    my($dicestr_wk, $dice_wk, $dice_add, $rate_wk, $rate_str);
    my(@A, @RATE3, @RATE4, @RATE5, @RATE6, @RATE7, @RATE8, @RATE9, @RATE10, @RATE11, @RATE12, @RATE);

    my $add_p = "";
    my $dec_p = "";
    my $total_n = 0;
    my $round = 0;
    my $dice_f = 0;
    my $crit = 10;
    my $string = $_[0];
    if($string =~ /(^|\s)[sS]?(((k|K)[\d\+\-]+)([cmCM]\[([\d\+\-]+)\])*([\d\+\-]*)([cmCM]\[([\d\+\-]+)\])*)($|\s)/) {
        $string = $2;
        if($string =~ /c\[(\d+)\]/i) {
            $crit = ($1);
            $crit = 3 if($crit < 3);        # エラートラップ(クリティカル値が3未満なら3とする)
            $string =~ s/c\[(\d+)\]//ig;
        }
        if($string =~ /m\[([\d\+\-]+)\]/i) {
            $mod = $1;
            unless($mod =~ /[\+\-]/) {
                $dice_f = $mod;
                $mod = 0;
            }
            $string =~ s/m\[([\d\+\-]+)\]//ig;
        }
        if($string =~ /K(\d+)([\d\+\-]*)/i) {   # ボーナスの抽出
            $key = $1;
            $add_p = (parren_killer("(".$2.")")) if($2); 
        } else {
            $key = $string;
        }
        $key =~ /([\d]+)/;
        $key = $1;
        if($key eq "") { return '1'; }
        # 2.0対応
        my @RATE_20;
        $RATE_20[0]= '*,0,0,0,1,2,2,3,3,4,4';
        $RATE_20[1]= '*,0,0,0,1,2,3,3,3,4,4';
        $RATE_20[2]= '*,0,0,0,1,2,3,4,4,4,4';
        $RATE_20[3]= '*,0,0,1,1,2,3,4,4,4,5';
        $RATE_20[4]= '*,0,0,1,2,2,3,4,4,5,5';
        $RATE_20[5]= '*,0,1,1,2,2,3,4,5,5,5';
        $RATE_20[6]= '*,0,1,1,2,3,3,4,5,5,5';
        $RATE_20[7]= '*,0,1,1,2,3,4,4,5,5,6';
        $RATE_20[8]= '*,0,1,2,2,3,4,4,5,6,6';
        $RATE_20[9]= '*,0,1,2,3,3,4,4,5,6,7';
        $RATE_20[10]='*,1,1,2,3,3,4,5,5,6,7';

        $RATE_20[11]='*,1,2,2,3,3,4,5,6,6,7';
        $RATE_20[12]='*,1,2,2,3,4,4,5,6,6,7';
        $RATE_20[13]='*,1,2,3,3,4,4,5,6,7,7';
        $RATE_20[14]='*,1,2,3,4,4,4,5,6,7,8';
        $RATE_20[15]='*,1,2,3,4,4,5,5,6,7,8';
        $RATE_20[16]='*,1,2,3,4,4,5,6,7,7,8';
        $RATE_20[17]='*,1,2,3,4,5,5,6,7,7,8';
        $RATE_20[18]='*,1,2,3,4,5,6,6,7,7,8';
        $RATE_20[19]='*,1,2,3,4,5,6,7,7,8,9';
        $RATE_20[20]='*,1,2,3,4,5,6,7,8,9,10';

        $RATE_20[21]='*,1,2,3,4,6,6,7,8,9,10';
        $RATE_20[22]='*,1,2,3,5,6,6,7,8,9,10';
        $RATE_20[23]='*,2,2,3,5,6,7,7,8,9,10';
        $RATE_20[24]='*,2,3,4,5,6,7,7,8,9,10';
        $RATE_20[25]='*,2,3,4,5,6,7,8,8,9,10';
        $RATE_20[26]='*,2,3,4,5,6,8,8,9,9,10';
        $RATE_20[27]='*,2,3,4,6,6,8,8,9,9,10';
        $RATE_20[28]='*,2,3,4,6,6,8,9,9,10,10';
        $RATE_20[29]='*,2,3,4,6,7,8,9,9,10,10';
        $RATE_20[30]='*,2,4,4,6,7,8,9,10,10,10';

        $RATE_20[31]='*,2,4,5,6,7,8,9,10,10,11';
        $RATE_20[32]='*,3,4,5,6,7,8,10,10,10,11';
        $RATE_20[33]='*,3,4,5,6,8,8,10,10,10,11';
        $RATE_20[34]='*,3,4,5,6,8,9,10,10,11,11';
        $RATE_20[35]='*,3,4,5,7,8,9,10,10,11,12';
        $RATE_20[36]='*,3,5,5,7,8,9,10,11,11,12';
        $RATE_20[37]='*,3,5,6,7,8,9,10,11,12,12';
        $RATE_20[38]='*,3,5,6,7,8,10,10,11,12,13';
        $RATE_20[39]='*,4,5,6,7,8,10,11,11,12,13';
        $RATE_20[40]='*,4,5,6,7,9,10,11,11,12,13';

        $RATE_20[41]='*,4,6,6,7,9,10,11,12,12,13';
        $RATE_20[42]='*,4,6,7,7,9,10,11,12,13,13';
        $RATE_20[43]='*,4,6,7,8,9,10,11,12,13,14';
        $RATE_20[44]='*,4,6,7,8,10,10,11,12,13,14';
        $RATE_20[45]='*,4,6,7,9,10,10,11,12,13,14';
        $RATE_20[46]='*,4,6,7,9,10,10,12,13,13,14';
        $RATE_20[47]='*,4,6,7,9,10,11,12,13,13,15';
        $RATE_20[48]='*,4,6,7,9,10,12,12,13,13,15';
        $RATE_20[49]='*,4,6,7,10,10,12,12,13,14,15';
        $RATE_20[50]='*,4,6,8,10,10,12,12,13,15,15';

        $RATE_20[51]='*,5,7,8,10,10,12,12,13,15,15';
        $RATE_20[52]='*,5,7,8,10,11,12,12,13,15,15';
        $RATE_20[53]='*,5,7,9,10,11,12,12,14,15,15';
        $RATE_20[54]='*,5,7,9,10,11,12,13,14,15,16';
        $RATE_20[55]='*,5,7,10,10,11,12,13,14,16,16';
        $RATE_20[56]='*,5,8,10,10,11,12,13,15,16,16';
        $RATE_20[57]='*,5,8,10,11,11,12,13,15,16,17';
        $RATE_20[58]='*,5,8,10,11,12,12,13,15,16,17';
        $RATE_20[59]='*,5,9,10,11,12,12,14,15,16,17';
        $RATE_20[60]='*,5,9,10,11,12,13,14,15,16,18';

        $RATE_20[61]='*,5,9,10,11,12,13,14,16,17,18';
        $RATE_20[62]='*,5,9,10,11,13,13,14,16,17,18';
        $RATE_20[63]='*,5,9,10,11,13,13,15,17,17,18';
        $RATE_20[64]='*,5,9,10,11,13,14,15,17,17,18';
        $RATE_20[65]='*,5,9,10,12,13,14,15,17,18,18';
        $RATE_20[66]='*,5,9,10,12,13,15,15,17,18,19';
        $RATE_20[67]='*,5,9,10,12,13,15,16,17,19,19';
        $RATE_20[68]='*,5,9,10,12,14,15,16,17,19,19';
        $RATE_20[69]='*,5,9,10,12,14,16,16,17,19,19';
        $RATE_20[70]='*,5,9,10,12,14,16,17,18,19,19';

        $RATE_20[71]='*,5,9,10,13,14,16,17,18,19,20';
        $RATE_20[72]='*,5,9,10,13,15,16,17,18,19,20';
        $RATE_20[73]='*,5,9,10,13,15,16,17,19,20,21';
        $RATE_20[74]='*,6,9,10,13,15,16,18,19,20,21';
        $RATE_20[75]='*,6,9,10,13,16,16,18,19,20,21';
        $RATE_20[76]='*,6,9,10,13,16,17,18,19,20,21';
        $RATE_20[77]='*,6,9,10,13,16,17,18,20,21,22';
        $RATE_20[78]='*,6,9,10,13,16,17,19,20,22,23';
        $RATE_20[79]='*,6,9,10,13,16,18,19,20,22,23';
        $RATE_20[80]='*,6,9,10,13,16,18,20,21,22,23';

        $RATE_20[81]='*,6,9,10,13,17,18,20,21,22,23';
        $RATE_20[82]='*,6,9,10,14,17,18,20,21,22,24';
        $RATE_20[83]='*,6,9,11,14,17,18,20,21,23,24';
        $RATE_20[84]='*,6,9,11,14,17,19,20,21,23,24';
        $RATE_20[85]='*,6,9,11,14,17,19,21,22,23,24';
        $RATE_20[86]='*,7,10,11,14,17,19,21,22,23,25';
        $RATE_20[87]='*,7,10,12,14,17,19,21,22,24,25';
        $RATE_20[88]='*,7,10,12,14,18,19,21,22,24,25';
        $RATE_20[89]='*,7,10,12,15,18,19,21,22,24,26';
        $RATE_20[90]='*,7,10,12,15,18,19,21,23,25,26';

        $RATE_20[91] ='*,7,11,13,15,18,19,21,23,25,26';
        $RATE_20[92] ='*,7,11,13,15,18,20,21,23,25,27';
        $RATE_20[93] ='*,8,11,13,15,18,20,22,23,25,27';
        $RATE_20[94] ='*,8,11,13,16,18,20,22,23,25,28';
        $RATE_20[95] ='*,8,11,14,16,18,20,22,23,26,28';
        $RATE_20[96] ='*,8,11,14,16,19,20,22,23,26,28';
        $RATE_20[97] ='*,8,12,14,16,19,20,22,24,26,28';
        $RATE_20[98] ='*,8,12,15,16,19,20,22,24,27,28';
        $RATE_20[99] ='*,8,12,15,17,19,20,22,24,27,29';
        $RATE_20[100]='*,8,12,15,18,19,20,22,24,27,30';

        $key_max = (scalar @RATE_20)-1;
        foreach my $rate_wk (@RATE_20) {
            my @rate_arr = split /,/, $rate_wk;
            push @A, 0;
            push @RATE3, int($rate_arr[1]);
            push @RATE4, int($rate_arr[2]);
            push @RATE5, int($rate_arr[3]);
            push @RATE6, int($rate_arr[4]);
            push @RATE7, int($rate_arr[5]);
            push @RATE8, int($rate_arr[6]);
            push @RATE9, int($rate_arr[7]);
            push @RATE10, int($rate_arr[8]);
            push @RATE11, int($rate_arr[9]);
            push @RATE12, int($rate_arr[10]);
        }
        if($rating_table == 1) {
            # 完全版準拠に差し替え
            $RATE12[31] = $RATE12[32] = $RATE12[33] = 10;
        }
        @RATE = (\@A, \@A, \@A, \@RATE3, \@RATE4, \@RATE5, \@RATE6, \@RATE7, \@RATE8, \@RATE9, \@RATE10, \@RATE11, \@RATE12);
        if($key > $key_max) { return "キーナンバーは${key_max}までです"; }
        $output = "$_[1]: KeyNo."."$key";
        $output .= "c[$crit]" if($crit < 13);
        if($mod) {
            $output .= "m[$mod]";
        } elsif($dice_f) {
            $output .= "m[$dice_f]";
        }
        if($add_p) {
            $output .= "+${add_p}" if($add_p > 0);
            $output .=  "${add_p}" if($add_p < 0);
        }
        $output .= " ＞ ";

        $dice_wk = "";
        do {
            ($dice, $dice_str) = &roll(2, 6);
            if($dice_f) {
                $dice = $dice_f;
                $dice_f = 0;
                $dice = 2 if($dice < 2);
                $dice = 12 if($dice > 12);
            } elsif($mod) {
                $dice += $mod;
                $mod = 0;
                $dice = 2 if($dice < 2);
                $dice = 12 if($dice > 12);
            }
            $rate_wk = $RATE[$dice][$key];
            $total_n += $rate_wk;
            $dice_add += $dice;
            if($dice_wk ne "") {
                $dice_wk .= ",$dice";
                $dicestr_wk .= " $dice_str";
                if($dice > 2) {
                    $rate_str .= ",$rate_wk";
                } else {
                    $rate_str .= ",**";
                }
            } else {
                $dice_wk = "$dice";
                $dicestr_wk = "$dice_str";
                if($dice > 2) {
                    $rate_str .= "$rate_wk";
                } else {
                    $rate_str .= "**";
                }
            }
            $round++;
        } while($dice >= $crit);
        if($modeflg > 1) {          # 表示モード２以上
            $output .= "2D:[$dicestr_wk]=$dice_wk ＞ $rate_str";
        } elsif($modeflg > 0) { # 表示モード１以上
            $output .= "2D:$dice_wk ＞ $total_n";
        } else {                    # 表示モード０
            $output .= "$total_n";
        }
        if($dice_add <= 2) {
            return "$output ＞ 自動的失敗";
        }

        if($add_p) {
            $output .= "+${add_p}" if($add_p > 0);
            $output .=  "${add_p}" if($add_p < 0);
            $total_n += $add_p;
            $output .= " ＞ $total_n";
        }
        if ($round > 1) {
            $round--;   # ここでは「回転数=クリティカルの出た数」とする
            $output .= " ＞ ${round}回転";
        }

        if (length($output) > $SEND_STR_MAX) {  # 回りすぎて文字列オーバーフロウしたときの救済
            if($crit < 13) {
                $output = "$_[1]: KeyNo."."$key"."[$crit] ＞ ... ＞ $total_n ＞ ${round}回転";
            } else {
                $output = "$_[1]: KeyNo."."$key"." ＞ ... ＞ $total_n ＞ ${round}回転";
            }
        }
        return $output;
     } else {
        return '1';
     }
}

####################    CHILLストライクランク表    ########################
sub strike_rank {   # Chillのストライクランク
    return '1' if($game_type ne "Chill");   # 他ゲーム中の暴発防止
    my $output = '';
    my $string = $_[0];
    my ($wounds, $sta_loss, $dice, $dice_add, $dice_str);

    if($string =~ /(^|\s)[sS]?(SR|sr)(\d+)($|\s)/) {
        my ($dice_w, $dice_ws, $dice_wa);
        if($3 < 14) {
            ($sta_loss, $dice, $dice_add, $dice_str) = &chill_sr($3);
            ($wounds, $dice_w, $dice_wa, $dice_ws) = &chill_sr($3 - 3);
            $dice = $dice.', '.$dice_w;
            $dice_add .= ', '.$dice_wa;
            $dice_str = $dice_str.', '.$dice_ws;
        } else {
            my $wounds_wk;
            ($sta_loss, $dice, $dice_add, $dice_str) = &chill_sr(13);
            ($wounds, $dice_ws) = &roll(4, 10);
            $dice = '5d10*3, 4d10+'.(($3 - 13) * 2).'d10';
            $dice_add .= ', '.$wounds;
            $dice_str = $dice_str.', '.$dice_ws;
            ($wounds_wk, $dice_ws) = &roll(($3 - 13) * 2, 10);
            $dice_str .= '+'.$dice_ws;
            $dice_add .= '+'.$wounds_wk;
            $wounds += $wounds_wk;
        }
        if($modeflg > 1) {
            $output = $dice_str.' ＞ '.$dice_add.' ＞ スタミナ損失'.$sta_loss.', 負傷'.$wounds;
        }
        elsif($modeflg > 0) {
            $output = $dice_add.' ＞ スタミナ損失'.$sta_loss.', 負傷'.$wounds;
        }
        else {
            $output = 'スタミナ損失'.$sta_loss.', 負傷'.$wounds;
        }
        $string .= ':'.$dice
    }
    if($output) {
        $output = "$_[1]: ($string) ＞ $output";
        return $output;
    } else {
        return "1";
    }
}
sub chill_sr {
    my ($dice, $dice_add, $dice_str, $damage);
    my $sr = $_[0];

    $sr = int($sr);
    if($sr < 1) {
        $damage = 0;
        $dice_str = '-';
        $dice_add = '-';
        $dice = '-';
    }
    elsif($sr < 2) {
        $dice = '0or1';
        ($damage, $dice_str) = &roll(1, 2);
        $damage -= 1;
        $dice_add = $damage;
    }
    elsif($sr < 3) {
        $dice = '1or2';
        ($damage, $dice_str) = &roll(1, 2);
        $dice_add = $damage;
    }
    elsif($sr < 4) {
        $dice = '1d5';
        ($damage, $dice_str) = &roll(1, 5);
        $dice_add = $damage;
    }
    elsif($sr < 10) {
        $dice = ($sr - 3).'d10';
        ($damage, $dice_str) = &roll($sr - 3, 10);
        $dice_add = $damage;
    }
    elsif($sr < 13) {
        $dice = ($sr - 6).'d10*2';
        ($damage, $dice_str) = &roll($sr - 6, 10);
        $dice_add = $damage.'*2';
        $damage = $damage * 2;
        $dice_str = '('.$dice_str.')*2';
    } else {
        $dice = '5d10*3';
        ($damage, $dice_str) = &roll(5, 10);
        $dice_add = $damage.'*3';
        $damage = $damage * 3;
        $dice_str = '('.$dice_str.')*3';
    }
    return($damage,$dice,$dice_add,$dice_str);
}

####################         デモンパ衝動表        ########################
sub dp_urge {   # デモンパラサイトの衝動表
    return '1' if($game_type ne "Demon Parasite");  # 他ゲーム中の暴発防止
    my @URGE;

    my $string = $_[0];
    if($string =~/(\w)?URGE\s*(\d+)/i) {
        my $urge_type;
        my $urgelv = ($2);
        if(!$1) {
            $urge_type = 1;
        } elsif($1 =~ /n/i) {   # 新衝動表
            $urge_type = 2;
        } elsif($1 =~ /a/i) {   # 誤作動表
            $urge_type = 3;
        } elsif($1 =~ /m/i) {   # ミュータント衝動表
            $urge_type = 4;
        } elsif($1 =~ /u/i) {   # 鬼御魂(戦闘外)衝動表
            $urge_type = 5;
        } elsif($1 =~ /c/i) {   # 鬼御魂(戦闘中)衝動表
            $urge_type = 6;
        } else {    # あり得ない文字
            $urge_type = 1;
        }
        if(($urgelv < 1) || ($urgelv > 5)) {
            return '衝動段階は1から5です';
        } elsif($urge_type) {
            @URGE = &dp_urge_get($urge_type);
            my ($dice_now, $dice_str) = &roll(2, 6);
            my $output = $urgelv.'-'.$dice_now.':'.$URGE[$urgelv - 1][$dice_now - 2];
            if($urge_type <= 1) {
                $output = $_[1].': 衝動表'.$output;
            } elsif($urge_type <= 2) {
                $output = $_[1].': 新衝動表'.$output;
            } elsif($urge_type <= 3) {
                $output = $_[1].': 誤作動表'.$output;
            } elsif($urge_type <= 4) {
                $output = $_[1].': ミュータント衝動表'.$output;
            } elsif($urge_type <= 5) {
                $output = $_[1].': 鬼御魂(戦闘外)衝動表'.$output;
            } else {
                $output = $_[1].': 鬼御魂(戦闘中)衝動表'.$output;
            }
            return $output;
        }
    } else {
        return '1';
    }
}
sub dp_urge_get {
    my(@URGE1, @URGE2, @URGE3, @URGE4, @URGE5, @URGE);
    my $urge_type = $_[0];

    if($urge_type <= 1) {
        @URGE1 = (
            '『怒り』突然強い怒りに駆られる。近くの対象に(非暴力の)怒りを全力でぶつける。このターンの終了まで「行動不能」となる。[経験値20点]',
            '『絶叫』寄生生物が体内で蠢く。その恐怖に絶叫。このターンの終了まで「行動不能」となる。[経験値10点]',
            '『悲哀』急に悲しいことを思い出して動きが止まる。このターンの終了まで「行動不能」となる。[経験値10点]',
            '『微笑』可笑しくてしょうがない。くすくす笑いが止まらず、このターンの終了まで「行動不能」となる。[経験値10点]',
            '『鈍感』衝動に気が付かなかった。何も起こらない。[経験値0点]',
            '『抑制』衝動を抑え込んだ。何も起こらない。[経験値0点]',
            '『我慢』衝動を我慢した。何も起こらない。[経験値0点]',
            '『前兆』悪魔的特徴が一瞬目立つ。１ターン(10秒)持続。変身中なら影響なし。[経験値10点]',
            '『発現』悪魔的特徴が急に目立つ。60ターン(10分)持続。変身中なら影響なし。[経験値10点]',
            '『変化』利き腕/前脚が２ターン(20秒)かけて悪魔化する。18ターン(3分)持続。変身中なら影響なし。[経験値20点]',
            '『顕現』利き腕/前脚が瞬時に悪魔化。60ターン(10分)持続。変身中なら影響なし。[経験値20点]',
            );
        @URGE2 = (
            '『茫然』思考が止まり、このターンの終了まで「攻撃」行動を行えない。回避行動に影響はない。[経験値20点]',
            '『激怒』側にいるもの(生物、物体問わず)が憎く、殴る。変身後ならば次のターンの終了まで、すべての命中判定+5、回避判定-5。[経験値20点]',
            '『残忍』殺意、破壊衝動が一瞬増す。戦闘中ならば次のターンに行われる「攻撃」行動の達成値に+5。[経験値20点]',
            '『落涙』過去の悲しい想い出が去来し、涙が溢れる。１ターン(10秒)「通常」行動を行えない。回避行動に影響はない。[経験値10点]',
            '『抑制』衝動を抑え込んだ。何も起こらない。[経験値0点]',
            '『我慢』衝動を我慢した。何も起こらない。[経験値0点]',
            '『忍耐』肉体を傷つけて衝動に耐えた。５ダメージ。[経験値10点]',
            '『辛抱』ほんの一瞬、全身が変身しかかる。無理に抑えたので、５ダメージ。変身中なら影響なし。[経験値10点]',
            '『異貌』３ターン(30秒)かけて顔が変身する。18ターン(3分)持続。変身中なら影響なし。[経験値20点]',
            '『苦痛』寄生生物が体内で暴れ、痛みにのけぞる。10ダメージ。[経験値20点]',
            '『変貌』変身後の(特異な)外見的特徴が３ターン(30秒)かけて現れる。18ターン(3分)持続。変身中なら影響なし。[経験値20点]',
            );
        @URGE3 = (
            '『憤怒』怒りに全身が満たされる。次のターンの終了まで、すべてのダメージのサイコロを+1個する。[経験値20点]',
            '『加速』ほとばしる衝動により。次のターンは【行動値】が２倍になる。[経験値20点]',
            '『発露』力が溢れ出る。次のターンの終了まで、すべてのダメージに+5、防御点-5(最低0)される。[経験値20点]',
            '『乾き』攻撃衝動を抑えられない。次のターンの終了まで全ての命中判定+5、回避判定-5。[経験値10点]',
            '『絶叫』あらん限りの声で叫ぶ。このターンの終了まで、全ての回避判定に-10。[経験値10点]',
            '『我慢』衝動を我慢した。何も起こらない。[経験値0点]',
            '『限界』衝動を無理矢理抑え込む。あちこちの血管が破裂し、10ダメージ。[経験値10点]',
            '『解放』衝動に耐えられず変身が始まる。３ターン(30秒)かけて変身。変身中なら影響なし。[経験値10点]',
            '『本能』衝動に駆られ、瞬時に変身。次のターン、目の前の動くものを敵味方区別無く攻撃する。[経験値20点]',
            '『保身』次のターンの終了まで、敵を攻撃できない。全ての防御力に+5。[経験値20点]',
            '『救済』悪魔寄生体が危機を察知し、【エナジー】を20点回復する。[経験値20点]',
            );
        @URGE4 = (
            '『癒し』衝動を１点使った回復を行う。[経験値20点]',
            '『離脱』その場から逃げ出す。逃げられない場合は、うずくまって動けなくなる。１ターン(10秒)経過すれば我に返る。[経験値20点]',
            '『脱力』急に力が抜ける。次のターンの終了まで、全ての判定に-5される。[経験値20点]',
            '『全力』激しい躁状態。次のターンの終了まで、命中判定に+10、回避判定に-10[経験値20点]',
            '『混沌』意味のある言葉を話せなくなる。１時間持続する。[経験値10点]',
            '『限界』衝動を無理矢理抑え込む。あちこちの血管が破裂し、10ダメージ。[経験値10点]',
            '『本能』衝動に駆られ、瞬時に変身。次のターン、目の前の動くものを敵味方区別無く攻撃する。[経験値20点]',
            '『焦燥』焦りから「転倒」する。[経験値20点]',
            '『猜疑』味方が急に敵に思える。即座に近くの味方に一回攻撃し、自動命中となる。いなければ影響なし。[経験値20点]',
            '『自虐』自分が許せない。自分へ攻撃(自動命中。ダメ－ジは通常)。[経験値20点]',
            '『自浄』少し我に返る。衝動が２点回復する。[経験値20点]',
            );
        @URGE5 = (
            '『絶望』自殺を試みる。変身中ならば最強の攻撃(特殊能力等を使用しての攻撃)を自分へ与える。[経験値30点]',
            '『賛美』敵(複数いる場合はリーダー格)を主と思いこむ。主が倒されるか、このターンの終了まで主の命令を聞く。[経験値30点]',
            '『拒絶』変身が解除される。変身していなければ影響なし。[経験値20点]',
            '『飢餓』近くの無防備な対象を喰らおうとする。邪魔する物は敵として攻撃する。次ターンの終了時に我に返る。[経験値20点]',
            '『暗闇』視神経に影響が出る。以後１日「暗闇」になる。[経験値20点]',
            '『混乱』意味のある言葉を話せなくなる。１時間持続する。[経験値20点]',
            '『嫉妬』仲間に猛烈な嫉妬を覚える。即座に一番近くの味方を攻撃。判定は自動的に効果的成功となる。いなければ影響なし。[経験値20点]',
            '『暴君』自分が最強に思えてしかたがない。60ターン(10分)攻撃判定の達成値に+10、回避判定の達成値は-10。[経験値20点]',
            '『無双』全力だが無防備。60ターン(10分)、全てのダメージに+10、防御点0、【行動値】0。[経験値20点]',
            '『定着』変身していなければ、即座に変身。肉体が変身に馴染んでしまう。24時間、変身が解除されなくなる。[経験値30点]',
            '『眠り』猛烈な睡魔に襲われる。60ターン(10分)、もしくは戦闘終了まで起こしても起きない。[経験値30点]',
            );
    } elsif($urge_type <= 2) {  # 新衝動表
        @URGE1 = (
            '『開眼』潜在能力が発揮される。10分間、あらゆる戦闘以外の判定に+5。',
            '『集中』感覚が研ぎ澄まされる。次のターンの終了まで、射撃の命中判定に+5。',
            '『迅速』運動神経が上昇する。20分間、戦闘以外の【機敏】判定に+5。',
            '『怪力』怪力を発揮する。20分間、戦闘以外の【肉体】判定に+5。',
            '『鈍感』衝動に気が付かない。何も起こらない。',
            '『抑制』衝動を抑え込む。何も起こらない。',
            '『我慢』衝動を我慢する。何も起こらない。',
            '『無心』冷静になる。20分間、戦闘以外の【精神】判定に+5。',
            '『解放』感覚が解放される。20分間、戦闘以外の【感覚】判定に+5。',
            '『攻撃』攻撃の姿勢を取る。次のターンの終了まで、すべてのダメージが+5。',
            '『防御』防御の姿勢を取る。このターンの終了まで、すべての防御力が+5。',
            );
        @URGE2 = (
            '『敵視』激しい攻撃本能に駆られる。次のターンの終了まで、肉弾ダメージ+10。',
            '『忘我』怒りに痛みを忘れる。エナジー5点回復。',
            '『閃き』頭が冴える。20分間、戦闘以外の【知力】判定に+5。',
            '『全力』筋肉のリミッターが一時的にはずれる。次のターンの終了まで、肉弾ダメージに+5。',
            '『抑制』衝動を抑え込む。何も起こらない。',
            '『我慢』衝動を我慢する。何も起こらない。',
            '『反射』反射神経が研ぎ澄まされる。次のターンの終了まで、射撃の回避判定に+5。',
            '『機転』わずかなチャンスを見逃さなくなる。20分間、戦闘以外の【幸運】判定に+5。',
            '『耐性』精神力が上昇する。次のターンの終了まで、特殊防御力+5。',
            '『怒り』敵に対する怒りにとらわれる。次のターンの終了まで、肉弾の命中判定に+10。',
            '『活発』明るく活発になる。戦闘終了まで【行動値】+5。',
            );
        @URGE3 = (
            '『漲り』体の奥底から力がみなぎってくる。エナジー10点回復。',
            '『分析』相手の動きを冷静に分析できるようになる。5ターンの間、射撃ダメージに+10。',
            '『慈愛』万人に対して慈愛を感じるようになる。5ターンの間、回復に振るダイスが+1d。',
            '『慎重』敵の攻撃に慎重になる。次のターンの終了まで、すべての回避判定に+5。',
            '『本能』攻撃本能がむき出しになる。5ターンの間、特殊の命中判定に+5。',
            '『性急』気が早くなる。次のターンの終了まで、【行動値】に+3',
            '『凶暴』イライラが止まらなくなる。5ターンの間、肉弾の命中判定に+5。',
            '『楽観』気分がリラックスする。エナジー5点回復。',
            '『自閉』自分の殻に閉じこもろうとする。5ターンの間、特殊防御力に+5。',
            '『反射』敵の攻撃に即座に反応できる。5ターンの間、肉弾の回避判定に+10。',
            '『快感』快感を覚える。衝動が1点回復する。',
            );
        @URGE4 = (
            '『情熱』激しい情熱が噴き出してくる。エナジー10点と衝動1点回復。',
            '『気合』体中に気合いが入る。10ターンの間、すべてのダメージに+10。',
            '『加速』体中の神経が加速する。10ターンの間、すべての命中判定に+10。',
            '『利己』考え方が利己的になる。10ターンの間、特殊の命中判定に+10。',
            '『頑強』肉体が鋼のように強くなる。10ターンの間、肉弾防御力に+5。',
            '『察知』相手の動きを察知できる。10ターンの間、射撃防御力に+5。',
            '『殺意』激しい殺意にとらわれる。10ターンの間、特殊ダメージに+10。',
            '『静観』心が落ち着き冷静になる。10ターンの間、射撃の回避判定に+5。',
            '『是空』頭が冴えて敵の行動が読める。10ターンの間、すべての回避判定に+5。',
            '『心眼』心の目で相手の行動を読める。5ターンの間、射撃の回避判定に+10。',
            '『自愛』何をおいても自分が愛しく思える。5ターンの間、特殊の回避判定に+10。',
            );
        @URGE5 = (
            '『神速』人知を超えたスピードに目覚める。戦闘終了まで「通常」行動を２回行えるようになる。',
            '『流水』超感覚に目覚める。10ターンの間、すべての回避判定に+10。',
            '『覚醒』肉体の回復力が限界突破。エナジー20点回復。',
            '『忍耐』あらゆる苦痛に耐える鋼の精神が宿る。10ターンの間、すべての防御力に+5。',
            '『予知』第六感が研ぎ澄まされる。10ターンの間、射撃の命中とダメージに+10。',
            '『豪傑』身体能力が限界を超えて上昇する。10ターンの間、肉弾の命中とダメージに+10。',
            '『殺気』猛烈な殺意がみなぎる。10ターンの間、特殊の命中判定とダメージに+10。',
            '『発動』反射神経が飛躍的に加速される。10ターンの間、【行動値】+10。',
            '『激情』激しい感情があふれ出す。10ターンの間、すべてのダメージに+10。',
            '『超人』運動神経が飛躍的に加速される。10ターンの間、すべての命中判定に+15。',
            '『悟り』心が解放され無我の境地に達する。衝動が３点回復する',
            );
    } elsif($urge_type <= 3) {  # 誤作動表
        @URGE1 = (
            '『緊急停止』機能に異常発生。次のターンの終了まで、「行動不能」になる。[30点]',
            '『動力不調』動力装置に異常発生。このターンの終了時まで、「行動不能」になる。[30点]',
            '『腕部停止』腕部機構に異常発生。このターンの終了時まで、「タイミング：攻撃」が行えない。[20点]',
            '『脚部停止』脚部機構に異常発生。このターンの終了時まで、あらゆる「移動」を行えない。[20点]',
            '『機能制動』機能が一瞬停止するが、影響なし。[10点]',
            '『不良調整』機能に違和感。影響なし。[10点]',
            '『機能安定』機能が安定した。影響なし。[10点]',
            '『機能暴発』直前に使用した《兵装》がこのターンの終了時まで使用不能。未使用なら影響なし。[20点]',
            '『離脱機能』機能の異常発生。行動を消費することなく、即座に敵から「移動(全力)」で離れる。[20点]',
            '『排熱暴走』排熱機能に異常発生。次のターン終了時まで「着火」状態となる。[30点]',
            '『作動予測』次に起きる誤作動を予測できる。「第2限界点」に達したとき、「作動予測」以外の任意の誤作動を選択できる。[30点]',
            );
        @URGE2 = (
            '『安全機能』安全機能が作動。このターンの終了時まで、あらゆる判定に-5。[40点]',
            '『筋肉萎縮』人工筋肉に異常発生。次のターン終了時まで、【肉体】判定に-2。[30点]',
            '『出力低下』駆動部に異常発生。次のターンの終了時まで、【機敏】判定に-2。[30点]',
            '『感覚異常』視界機能に異常発生。次のターンの終了時まで、【感覚】判定に-2。[20点]',
            '『視界不良』視界機能に異常発生。次のターンの終了時まで、【幸運】判定に-2。[20点]',
            '『機能制動』機能が一瞬停止するが、影響なし。[10点]',
            '『不良調整』機能に違和感。影響なし。[10点]',
            '『援護不通』援護ソフトが誤作動。次のターンの終了時まで、【知力】判定-2。[20点]',
            '『発声変調』発声機能に異常発生。次のターンの終了時まで、【精神】判定-2。[30点]',
            '『装甲軟化』防御機構に異常発生。あらゆる防御力に-5。[30点]',
            '『作動予測』次に起きる誤作動を予測できる。「第3限界点」に達したとき、「作動予測」以外の任意の誤作動を選択できる。[40点]',
            );
        @URGE3 = (
            '『動力漏電』動力から漏電。『負荷』が2点上昇。[40点]',
            '『駆動異常』脚部に異常発生。次のターンの終了時まで、「移動」距離半減。[40点]',
            '『足下転倒』バランサーに異常発生。「転倒」状態となる。[30点]',
            '『出力向上』《兵装》機能が向上。次のターンの終了時まで、特殊ダメージに+1d点。[30点]',
            '『機能制動』機能が一瞬停止するが、影響なし。[20点]',
            '『機能暴走』攻撃機能が暴走し、戦闘能力が上昇。「着火」状態になるが、あらゆるダメージに+10。[20点]',
            '『身体向上』格闘機能が向上。次のターンの終了時まで、肉弾ダメージに+1d点。[30点]',
            '『反射向上』反応速度が向上。次のターンの終了時まで、【行動値】が+5。[30点]',
            '『精度向上』標準機能が向上。次のターンの終了時まで、射撃ダメージに+1d点。[30点]',
            '『電子賦活』電磁障壁が突如回復。【電力】が10点回復する。[30点]',
            '『作動予測』次に起きる誤作動を予測できる。「第4限界点」に達したとき、「作動予測」以外の任意の誤作動を選択できる。[40点]',
            );
        @URGE4 = (
            '『照準誤認』照準機能に異常発生。即座に最も近い味方を全力攻撃。[50点]',
            '『攻撃特化』攻撃機能が上昇。次のターン終了時まで、あらゆるダメージに+2dされるが「タイミング：防御」を行えない。[40点]',
            '『機内窒息』呼吸補助機能に異常発生。次のターン終了時まで、「窒息」状態。[40点]',
            '『機能増強』全機能が飛躍的に向上。次のターン終了時まで、《兵装》のコストを払わなくて良い。[30点]',
            '『音声遮断』聴覚機能に異常発生。次のターン終了時まで、一切の物音が聞こえず、あらゆる回避判定に-5。[30点]',
            '『電流加速』電磁障壁が効率的に流れる。『負荷』が1点回復。[20点]',
            '『精密射撃』照準の精度が向上。あらゆるダメージに+5点。[30点]',
            '『電力浪費』電磁障壁が過剰に使用される。【電力】が10点減少。[30点]',
            '『荷電暴走』【電力】を5点消費するが、次のターン終了時まで、あらゆるダメージに+10点。[40点]',
            '『状況分析』視界機能が向上。あらゆる命中判定に+5。[40点]',
            '『作動予測』次に起きる誤作動を予測できる。「第5限界点」に達したとき、「作動予測」以外の任意の誤作動を選択できる。[50点]',
            );
        @URGE5 = (
            '『出力過剰』全出力が過剰。次のターン終了時まで、あらゆるダメージの総計が2倍になるが《兵装》のコストも2倍になる。[50点]',
            '『機関暴走』放熱機能が暴走。自分を中心に半径5m以内すべての対象を「着火」状態にする。[50点]',
            '『機体清冽』機能異常から復帰。「気絶」「死亡」を除く、あらゆる状態変化がすべて消滅。[40点]',
            '『鉄壁装甲』防御機能が向上。次のターン終了時まで、あらゆる防御力に+5。[30点]',
            '『緊急駆動』回避機能が向上。次のターン終了時まで、あらゆる回避判定に+5。[30点]',
            '『出力増大』装備補助機能が向上。次のターン終了時まで、「所持品」あるいは《兵装》を使用したダメージ総計が2倍になる。[30点]',
            '『機体加速』運動機能が暴走。次のターン終了時まで、【行動値】が2倍となる。[30点]',
            '『自動追尾』自動追尾機能が発動。次のターン終了時まで、あらゆる命中値に+5。[40点]',
            '『限定解除』全機能の限界を解除。次のターン終了時まで、あらゆるダメージに+10。[50点]',
            '『負荷軽減』急激に機体の負荷が低下。『負荷』が2点回復する。[50点]',
            '『複合反応』この表を2回振る。ただし、同じ結果が出た場合は適用するのは一度だけ。獲得経験値は累積する。[0点]',
            );
    } elsif($urge_type <= 4) {  # ミュータント衝動表
        @URGE1 = (
            '『怒り』突然強い怒りに駆られる。近くの対象にあたりちらす。このターンの終了まで「行動不能」となる。[20点]',
            '『絶叫』悪魔寄生体が蠢きだす。その恐怖に絶叫。このターンの終了まで「行動不能」となる。[10点]',
            '『悲哀』急に悲しいことを思い出す。このターンの終了まで「行動不能」となる。[10点]',
            '『微笑』可笑しくてしょうがない。くすくす笑いが止まらず、このターンの終了まで「行動不能」となる。[10点]',
            '『鈍感』衝動に気が付かなかった。何も起こらない。[0点]',
            '『抑制』衝動を抑え込んだ。何も起こらない。[0点]',
            '『我慢』衝動を我慢した。何も起こらない。[0点]',
            '『前兆』悪魔的特徴が一瞬目立つ。１ターン(10秒)持続。《擬態変化》を解いているなら影響なし。[10点]',
            '『発現』悪魔的特徴が急に目立つ。60ターン(10分)持続。《擬態変化》を解いているなら影響なし。[10点]',
            '『解除』利き腕/前脚の《擬態変化》が２ターン(20秒)かけて解除される。18ターン(3分)持続。《擬態変化》を解いているなら影響なし。[20点]',
            '『顕現』利き腕/前脚の《擬態変化》が瞬時に解除。60ターン(10分)持続。《擬態変化》を解いているなら影響なし。[20点]',
            );
        @URGE2 = (
            '『茫然』思考が止まり、このターンの終了まで「攻撃」行動を行えない。その他の行動は影響なし。[20点]',
            '『激怒』側にいるもの(生物、物体問わず)が憎くなり、殴る。《擬態変化》を解いているならば次のターンの終了まで、すべての命中判定+5、回避判定-5。[20点]',
            '『残忍』殺意、破壊衝動が一瞬増す。戦闘中ならば次のターンに行われる「攻撃」行動の達成値に+5。[20点]',
            '『落涙』過去の悲しい想い出が去来し、涙が溢れる。１ターン(10秒)「通常」行動を行えない。その他の行動に影響はない。[10点]',
            '『抑制』衝動を抑え込んだ。何も起こらない。[0点]',
            '『我慢』衝動を我慢した。何も起こらない。[0点]',
            '『忍耐』肉体を傷つけて衝動に耐えた。5点ダメージ。[10点]',
            '『辛抱』ほんの一瞬、《擬態変化》が解けかかる。無理に抑えたので5点ダメージ。《擬態変化》を解いているなら影響なし。[10点]',
            '『異貌』３ターン(30秒)かけて《擬態変化》が解除される。18ターン(3分)持続。《擬態変化》を解いているなら影響なし。[20点]',
            '『苦痛』寄生生物が体内で暴れ狂う。10点ダメージ。[20点]',
            '『変貌』特異な外見的特徴が３ターン(30秒)かけて現れる。18ターン(3分)持続。《擬態変化》を解いているなら影響なし。[20点]',
            );
        @URGE3 = (
            '『憤怒』怒りに全身が満たされる。次のターンの終了まで、すべてのダメージを+1d点する。[20点]',
            '『加速』ほとばしる衝動により。次のターンは【行動値】が２倍になる。[20点]',
            '『発露』力が溢れ出る。次のターンの終了まで、すべてのダメージに+5、防御点-5(最低0)される。[20点]',
            '『乾き』攻撃衝動を抑えられない。次のターンの終了まで全ての命中判定+5、回避判定-5。[10点]',
            '『絶叫』あらん限りの声で叫ぶ。このターンの終了まで、あらゆる回避判定に-10。[10点]',
            '『我慢』衝動を我慢した。何も起こらない。[0点]',
            '『限界』衝動を無理矢理抑え込む。10点ダメージ。[10点]',
            '『解放』衝動に耐えられず擬態が解ける。３ターン(30秒)かけて解除。《擬態変化》を解いているなら影響なし。[10点]',
            '『本能』衝動に駆られ、《擬態変化》が瞬時に解除。次のターンは、目の前の動くものを敵味方区別無く攻撃する。[20点]',
            '『保身』次のターンの終了まで、敵を攻撃できない。全ての防御力に+5。[20点]',
            '『救済』悪魔寄生体が危機を察知し、【エナジー】を20点回復する。[20点]',
            );
        @URGE4 = (
            '『癒し』【エナジー】が即座に3d点回復。[20点]',
            '『離脱』その場から逃げ出す。逃げられない場合は、うずくまって動けなくなる。１ターン(10秒)経過すれば我に返る。[20点]',
            '『脱力』急に力が抜ける。次のターンの終了まで、全ての判定に-5される。[20点]',
            '『全力』激しい躁状態。次のターンの終了まで、命中判定に+10、回避判定に-10。[20点]',
            '『混沌』1時間の間、意味のある言葉を話せなくなる。[10点]',
            '『争乱』体内で共生生物同士が争い、暴れ回る。衝動が1点増える。[10点]',
            '『本能』衝動に駆られ、《擬態変化》が瞬時に解除。次のターン、目の前の動くものを敵味方区別無く攻撃する。[20点]',
            '『焦燥』焦りから「転倒」する。[20点]',
            '『猜疑』味方が急に敵に思える。即座に近くの味方に1回攻撃(自動命中。ダメージは通常)。いなければ影響なし。[20点]',
            '『自虐』自分が許せない。自分へ素手攻撃(自動命中。ダメ－ジは通常)。[20点]',
            '『自浄』少し我に返る。衝動が2点回復する。[20点]',
            );
        @URGE5 = (
            '『絶望』無力感にさいなまれる。次のターンの終了時まで「行動不能」となる。[30点]',
            '『眠り』猛烈な睡魔に襲われる。60ターン(10分)、もしくは戦闘終了まで起こしても起きない。[30点]',
            '『誤動』突然《擬態変化》が使用され、人間の姿になる(衝動も通常通り使用する)。既に使用していた場合は変化無し。[20点]',
            '『暗闇』視神経に影響が出る。以後1日「暗闇」になる。[20点]',
            '『再生』共生生物が危機を察知し、【エナジー】を10点回復する。[20点]',
            '『混乱』1時間の間、意味のある言葉を話せなくなる。[20点]',
            '『硬化』急に体が硬直する。このターンの終了時まで、あらゆる命中判定に-10、防御力に+10。[20点]',
            '『暴君』自分が最強に思えてしかたがない。60ターン(10分)攻撃判定に+10、回避判定に-10。[20点]',
            '『無双』全力だが無防備。60ターン(10分)、全てのダメージに+10、防御点と【行動値】は0。[20点]',
            '『喪失』《擬態変化》が使用中なら、即座に解除。さらに24時間、《擬態変化》が使えなくなる。[30点]',
            '『進化』共生生物たちが上手く混じって身体能力が向上する。次の判定の達成値+10。[30点]',
            );
    } elsif($urge_type <= 5) {  # 鬼御魂(戦闘外)衝動表
        @URGE1 = (
            '『恐怖』恐怖の感情が爆発し、目に映るすべてが恐ろしくなる。[20点]',
            '『落涙』過去の悲しい思い出が去来し、涙が溢れる。[10点]',
            '『哄笑』突如として精神が高揚し、狂ったように笑う。[10点]',
            '『咆哮』<和魂>によって怒りが増し、突如として雄たけびを上げる。[10点]',
            '『抑制』衝動を完全に律する。何も起こらない。[0点]',
            '『沈静』穏やかな気分になる。[0点]',
            '『理性』衝動を理性で押さえ込む。何も起こらない。[0点]',
            '『破裂』衝動を押さえ込もうとして体内の欠陥が破裂、喀血する。[10点]',
            '『喪失』一瞬、〈和魂〉の神通力が失われる。[10点]',
            '『枯渇』吸血への渇望が押さえられず、一般人を血走った目で見つめる。[10点]',
            '『内包』凄まじい勢いで体内に妖気が内包され、力が増す。[20点]',
            );
        @URGE2 = (
            '『飢餓』突然の吸血衝動。一般人を猛烈に襲いたくなる。[20点]',
            '『封印』妖気を操作できず、1分間《特殊能力》を使用できない。[20点]',
            '『拒絶』情緒が不安定となり、味方が急に怖くなる。[20点]',
            '『拡散』突如として全身から妖気が噴出、目の前の対象を吹き飛ばす。[10点]',
            '『抑制』衝動を完全に律する。なにも起こらない。[0点]',
            '『治癒』疲れが癒される。[0点]',
            '『本能』暴力衝動に駆られ、瞬時に“異形化"してしまう。[10点]',
            '『破砕』破壊衝動が巻き起こり、目の前の障害物を破壊する。[20点]',
            '『悪寒』突如として悪寒が走り、物事に集中できなくなる。',
            '『心傷』突如としてトラウマを思い出し、立ちつくす。[20点]',
            '『回想』過去の思い出が去来、活力がみなぎる。[30点]',
            );
        @URGE3 = (
            '『不動』妖気が全身を駆け巡り、激痛によって動けなくなる。[20点]',
            '『脱力』突如として妖気が衰え、脱力のあまり膝をつく。[20点]',
            '『異形』瞬時にして犬歯が肥大し、目が紅く、邪悪に輝く。[20点]',
            '『精密』突如として視界が広がり、目視せずとも背後の風景や人物を見通せる。[10点]',
            '『獰猛』突如として怒りの感情が湧き起こり、目前の対象を罵倒する。[0点]',
            '『高揚』〈和魂〉の影響により精神が高揚、躁状態となる。[0点]',
            '『憎悪』突如として憎悪が沸き起こり、目前の対象に掴みかかる。[0点]',
            '『加速』全身に妖気が駆け巡り、反射速度が増し、10秒を1分のように感じる。[10点]',
            '『平穏』精神に変調が起こり、異常なほど理性的になる。[20点]',
            '『慈愛』あらゆる者に自愛を抱き、親身に接する。[20点]',
            '『支配』一瞬〈和魂〉を完全支配、次に行う戦闘外の判定を1回だけ効果的成功する。[20点]',
            );
        @URGE4 = (
            '『変質』突如として妖気が変質、半径5mにわたって透明な壁を展開する。[30点]',
            '『増強』妖気によって身体能力が増強され、10分間[運動]上級を取得する。[20点]',
            '『拡大』妖気が目視できるほど両腕から発散、20m先の物体を操作できる。[20点]',
            '『清浄』妖気を開放、<鬼御魂>を持たない半径10m内全ての生物を眠らせる。[10点]',
            '『透視』濃密な妖気が瞳に宿り、1分間20mの距離を透視できる。[10点]',
            '『強行』突如として妖気が増し、接触した対象を【肉体】x2m吹き飛ばす。[0点]',
            '『衝撃』妖気が殺傷能力を帯び、接触した物体を破壊。20秒間、手足が簡易の肉弾武器となる。[10点]',
            '『撃滅』妖気が稲妻や火災へと変異し、接触した物体を「着火」させる。[20点]',
            '『展開』全身を包む妖気の層が厚くなり、1分間物理的な接触を行えない。[20点]',
            '『模倣』<和魂>が精神を活性化させ、異常な記憶力を手に入れる。[20点]',
            '『支配』一瞬<和魂>を完全支配、次に行う戦闘外の判定を1回だけ効果的成功する。[20点]',
            );
        @URGE5 = (
            '『解放』妖気を無尽蔵に解放、1分間、戦闘外で使用する「コスト」を無視できる。[30点]',
            '『加速』妖気が両足に集中、1分間、時速50kmで疾走できる。[20点]',
            '『付与』妖気が感覚に集中、1分間50m先を透視できる。[20点]',
            '『強固』妖気が全身に浸透、1分間「窒息」「状態変化」のダメージを無効。[20点]',
            '『破壊』全妖気が膂力に変換され、1分間【肉体】判定の達成値を2倍にする。[20点]',
            '『爆散』1分間妖気が変質、接触した対象を爆破でき、障害物を瞬時に破壊。[10点]',
            '『浄化』半径10m全てを浄化、範囲内で持続する《特殊能力》の効果を無効化。[20点]',
            '『律動』半径10m内の<鬼御魂>を持たない生物を1分間気絶させる。[20点]',
            '『修復』妖気が極限まで活性化され、疲労を取り払う。[20点]',
            '『本性』瞬時に異形化。異形化中であれば、さらに禍々しい姿へ変質する。[20点]',
            '『覚醒』1時間、全身から閃光を発し、高さが【精神】mの“光の柱"に包まれる。[30点]',
            );
    } else {                    # 鬼御魂(戦闘中)衝動表
        @URGE1 = (
            '『恐怖』効果が発生したターンの終了時まで「行動不能」状態となる。',
            '『落涙』1ターン(10秒)「通常」行動を行えない。回避行動に影響はない。',
            '『哄笑』効果が発生したターンの終了時まで「行動不能」となる。',
            '『咆哮』効果が発生したターンの終了時まで「行動不能」となる。',
            '『抑制』影響なし。',
            '『沈静』【エナジー】を3点回復する。',
            '『理性』影響なし。',
            '『破裂』【エナジー】が5点減少する。',
            '『喪失』次ターンの【行動値】が半減(端数切捨て)。',
            '『枯渇』次ターンの終了時まで、あらゆるダメージに「+2」点。',
            '『内包』『衝動』が2点回復する。',
            );
        @URGE2 = (
            '『飢餓』最も近くの無防備な対象から血液摂取を試みる。対象が<鬼御魂>を持たない場合、血液採取の効果を得られる。',
            '『封印』効果が発生したターンの終了時まで《特殊能力》を使用できない。',
            '『拒絶』効果が発生したターンの終了時まで、味方を対象とした《特殊効果》を使用不可。',
            '『拡散』半径5m以内の対象全ての【エナジー】を1d点減少する(抵抗不可、防御力無視)。',
            '『抑制』影響なし。',
            '『治癒』【エナジー】を5点回復する。',
            '『本能』即座に“異形化"、ターン終了まで任意のダメージ1つに「+1d」点。',
            '『破砕』行動を消費することなく、近くに存在する障害物1つを瞬時に破壊。',
            '『悪寒』効果が発生したターンの終了時まで、あらゆる判定の達成値に「-5」。',
            '『心傷』効果が発生したターンの終了時まで、「タイミング:攻撃」を行えない。',
            '『回想』『衝動』を3点回復する。',
            );
        @URGE3 = (
            '『不動』次のターンの終了時まで「タイミング:通常」を行えない。',
            '『脱力』次のターンの終了時まで「転倒」状態となる。',
            '『異形』次に行う行為判定は、出目に関係なく効果的成功として扱う。',
            '『精密』次のターンの終了時まで、射撃ダメージに「+5」点。',
            '『獰猛』次のターンの終了時まで、肉弾ダメージに「+5」点。',
            '『高揚』次のターンの終了時まで、あらゆるダメージに「+1d」点。',
            '『憎悪』次のターンの終了時まで、特殊ダメージに「+5」点。',
            '『加速』次のターンの終了時まで【行動値】に「+5」。',
            '『平穏』あらゆる「状態変化」を任意で1つ消滅させる。',
            '『慈愛』半径5m内の味方全ての【エナジー】を5点回復する。',
            '『支配』「衝動表」の結果を、第三段階の中から任意のものから1つ選択できる。',
            );
        @URGE4 = (
            '『変質』次のターンの終了時まで、任意の防御力の1つに「+10」点。',
            '『増強』次のターンの終了時まで、任意の回避判定1つに「+5」。',
            '『拡大』次のターンの終了時まで、任意の命中判定1つに「+5」。',
            '『清浄』半径10m内の味方全ての【エナジー】を5点回復する。',
            '『透視』次のターン終了時まで、射撃ダメージに「+10」点。',
            '『強行』次のターンは、「タイミング:攻撃」を余分に1回行うことができる。',
            '『衝撃』次のターンの終了時まで、肉弾ダメージに「+10」点。',
            '『撃滅』次のターンの終了時まで、特殊ダメージに「+10」点。',
            '『展開』次のターンの終了時まで、本人が受けるあらゆるダメージを半減できる。',
            '『模倣』次のターンの終了時まで、敵が使用した《特殊能力》1つを1回だけ使用可能。',
            '『支配』「衝動表」の結果を、第四段階の中から任意のものから1つ選択できる。',
            );
        @URGE5 = (
            '『解放』次のターンの終了時まで、あらゆる戦闘修正が2倍となる。',
            '『加速』次のターンの終了時まで、【行動値】が2倍となる。',
            '『付与』次のターンの終了時まで、射撃ダメージの総計を2倍にできる。',
            '『強固』次のターンの終了時まで、あらゆる防御力に「+10」点。',
            '『破壊』次のターンの終了時まで、肉弾ダメージの総計を2倍にできる。',
            '『爆散』次のターンの終了時まで、あらゆるダメージに「+2d」点。',
            '『浄化』『衝動』を1d点回復する。',
            '『律動』次のターンの終了時まで、特殊ダメージの総計を2倍にできる。',
            '『修復』【エナジー】が最大値まで回復する。',
            '『本性』この戦闘中のみ、最終能力を2回使用できる。',
            '『覚醒』第五段階を2回振り、双方の効果を適応する。',
            );
    }
    @URGE = (\@URGE1, \@URGE2, \@URGE3, \@URGE4, \@URGE5);
    return @URGE;
}

####################         パラブラ衝動表        ########################
sub pb_urge {   # パラサイトブラッドの衝動表
    return '1' if($game_type ne "ParasiteBlood");  # 他ゲーム中の暴発防止

    my $string = $_[0];
    if($string =~/(\w*)URGE\s*(\d+)/i) {
        my $urge_type;
        my $urgelv = ($2);
        if(!$1) {
            $urge_type = 1;
        } elsif($1 =~ /A/i) {    # 誤作動表
            $urge_type = 2;
        } else {    # あり得ない文字
            $urge_type = 1;
        }
        if(($urgelv < 1) || ($urgelv > 5)) {
            return '衝動段階は1から5です';
        } elsif($urge_type) {
            my ($dice_now, $dice_str) = &roll(2, 6);
            my $output = &get_pb_urge_table($urgelv, $dice_now, $urge_type);
            $output = $urgelv.'-'.$dice_now.':'.$output;
            if($urge_type <= 1) {
                $output = $_[1].': 衝動表'.$output;
            } elsif($urge_type <= 2) {
                $output = $_[1].': 誤作動表'.$output;
            }
            return $output;
        }
    } else {
        return '1';
    }
}

sub get_pb_urge_table {
    my ($level, $dice, $urge_type) = @_;
    my @URGE;

    if($urge_type <= 1) { # 衝動表
        @URGE = &get_pb_normal_urge_table;
    } elsif($urge_type <= 2) { # AASとサイボーグの誤作動表
        @URGE = &get_pb_aas_urge_table;
    } else {  # エラートラップ
        @URGE = &get_pb_normal_urge_table;
    }
    return $URGE[$level - 1 ][$dice - 2];
}

sub get_pb_normal_urge_table {
    my(@URGE1, @URGE2, @URGE3, @URGE4, @URGE5);
    @URGE1 = (
        '『怒り/20』突然強い怒りに駆られる。最も近い対象を罵倒し、そのターンの終了まで[行動不能]となる。',
        '『暗闇/20』視神経に悪影響が出て、24時間[暗闇]になる。',
        '『悲哀/10』突然の悲みに動きが止まる。そのターンの終了まで[行動不能]となる。',
        '『微笑/10』可笑しくてしょうがない。笑いが止まらず、そのターンの終了まで[行動不能]となる。',
        '『鈍感/ 0』衝動に気が付かない。影響なし。',
        '『抑制/ 0』衝動を抑制した。影響なし。',
        '『我慢/ 0』衝動を我慢した。影響なし。',
        '『前兆/10』悪魔的特徴が1ターン(10秒)目立つ。〈悪魔化〉時は影響なし。',
        '『変化/10』利き腕や前脚のみ、2ターン(20秒)かけて〈悪魔化〉する。〈悪魔化〉時は影響なし。',
        '『拒絶/10』〈悪魔化〉が解除される。通常時は影響なし。',
        '『定着/20』通常時であれば、即座に〈悪魔化〉する。肉体が〈悪魔化〉に馴染み、24時間通常時に戻れない。',
        );
    @URGE2 = (
        '『賛美/20』最も近くの対象を主と思いこむ。1時間または自身か対象が[気絶・戦闘不能・死亡]するまで、対象のあらゆる命令を聞く。',
        '『茫然/20』思考が停止。そのターンの終了まで[タイミング:攻撃]を行えない。',
        '『苦痛/20』"悪魔寄生体"が体内で暴れる。苦痛を感じ、【エナジー】を10消費。',
        '『落涙/10』過去の悲しい想い出が去来し、涙が溢れる。そのターンの終了まで[タイミング:通常]を行えない。',
        '『限界/10』溢れる力が限界を超え、全身の血管が破裂。【エナジー】を5消費。',
        '『辛抱/10』突如全身が〈悪魔化〉しようとしたが、意思の力で抑制。【エナジー】を5消費。〈悪魔化〉時は影響なし。',
        '『忍耐/ 0』衝動に耐えた。影響なし。',
        '『抑制/ 0』衝動を抑制した。影響なし。',
        '『我慢/ 0』衝動を我慢した。影響なし。',
        '『嫉妬/10』最も近くの対象に猛烈な嫉妬を感じ、[距離:移動10m/対象:1体]に通常肉弾攻撃を行う。',
        '『変貌/20』〈悪魔化〉する。その際、特異な外見が目立つ。〈悪魔化〉時は影響なし。',
        );
    @URGE3 = (
        '『異貌/20』3ターンかけて、顔のみが〈悪魔化〉する。〈悪魔化〉時は影響なし。',
        '『解放/20』衝動に耐えきれず3ターンかけて〈悪魔化〉する。〈悪魔化〉時は影響なし。',
        '『発露/20』全身を駆け抜ける衝動により力が溢れる。次のターンの終了まで、ダメージに+5。',
        '『渇望/10』攻撃衝動を抑えられない。次のターンの終了まで、命中判定の達成値に+5。',
        '『絶叫/10』あらん限りの声で叫び、力が増す。次のターンの終了まで、ダメージに+1d。',
        '『我慢/ 0』衝動を我慢した。影響なし。',
        '『憤怒/10』全身に怒りが満ちて攻撃力上昇。次のターンの終了まで、ダメージに+1d。',
        '『加速/10』全身を駆け抜ける衝動により速度上昇。次のターンの終了まで【行動値】が2倍。',
        '『嫌悪/20』最も近くの対象に嫌悪を感じ、[距離:移動10m/対象:1体]に通常肉弾攻撃を行う。',
        '『保身/20』突如として防御能力が高まる。次のターンの終了まで、防御力に+5。',
        '『救済/20』"悪魔寄生体"が危機を察知し、【エナジー】を20回復。',
        );
    @URGE4 = (
        '『転倒/20』踏み込んだ瞬間、あまりの衝撃に地面をえぐり[転倒]してしまう。',
        '『脱力/20』急に力が抜ける。そのターンの終了まで、判定の達成値に-5。',
        '『困惑/20』精神に変調があらわれ、空間認識能力が狂う。次のターンの終了まで、[タイミング:瞬間]の《特殊能力》を行えない。',
        '『全力/20』激しい躁状態。次のターンの終了まで、命中判定に+10。加えて[タイミング:ターン開始]の《特殊能力》を使用できなくなる。',
        '『咆吼/10』大声で叫び、意味のある言葉を話せなくなる。１時間持続する。',
        '『狂気/10』心が狂気に満たされ、強いストレスを感じる。【衝動】を2蓄積させる。',
        '『本能/20』"悪魔寄生体"の生存本能が自我を支配。次のターンの終了まで、ダメージに+5。',
        '『治癒/20』衝動を1蓄積させ、《肉体修復》を行う。',
        '『敵意/20』最も近い対象に強い敵意を抱く。[距離:移動10m/対象:1体]に通常肉弾攻撃を行い、クリティカルとなる。',
        '『自虐/20』自分が許せず自虐行為を行う。【エナジー】を10消費するが、次のターンの終了までダメージに+10。',
        '『自浄/20』少し我に返る。【衝動】が2回復。',
        );
    @URGE5 = (
        '『睡眠/30』猛烈な睡魔に襲われ意識を失う。そのターンの終了まで[気絶]となる。',
        '『飢餓/30』猛烈な飢餓感。20m以内の最も近い[気絶・戦闘不能・死亡]の対象へ移動し、喰らう。次のターンの終了まで、対象は【エナジー】を1dずつ消費。',
        '『激怒/20』突如として強い怒りが湧き、周囲が見えなくなる。次のターンの終了まで、[タイミング:瞬間]の《特殊能力》を行えない。',
        '『顕現/20』利き腕や前脚がさらに外骨格化し、肉体に強い負荷がかかる。【衝動】を3蓄積',
        '『好機/20』チャンスに本能が素早く反応。即座に[タイミング:攻撃]の行動を1回だけ行える。',
        '『狂化/20』精神に変調、心が強い狂気で満たされ、自虐行為に走る。【エナジー】を20消費する。',
        '『混乱/20』精神に変調が現れ、肉体を意のままに動かせない。次のターンの終了まで、判定の達成値に-5。',
        '『暴君/20』自分が最強に思えてしょうがない。60ターン(10分)の間、【行動値】とダメージに+5。',
        '『無双/20』達人の感覚が目覚める。60ターン(10分)の間、命中判定と回避判定の達成値に+5。',
        '『発現/30』通常時であれば、即座に《悪魔化》する。特異な外見が60ターン(10分)目立ち、その間、命中判定とダメージに+5。',
        '『絶望/30』全身が絶望に満たされ、全てを破壊したくなる。次のターンの終了まで、ダメージに+15。',
        );
    my @URGE = (\@URGE1, \@URGE2, \@URGE3, \@URGE4, \@URGE5);
    return @URGE;
}

#**パラサイトブラッドの誤作動表(2d6)
sub get_pb_aas_urge_table {
    my(@URGE1, @URGE2, @URGE3, @URGE4, @URGE5);
#**第１段階
    @URGE1 = (
        '『緊急停止/20』機能異常の警報と共に、機能が緊急停止。次のターンのターン終了時まで［行動不能］となる。' ,
        '『動作不調/10』駆動系に異常発生。このターンのターン終了まで［行動不能］となる。' ,
        '『腕部停止/10』腕部機能に異常発生。このターンのターン終了まで［タイミング：攻撃］を失う。' ,
        '『視覚異常/10』センサー系に異常。60ターン（10分）の間、［暗闇］となる。' ,
        '『機能制動/0』機能が一瞬停止するが、以後正常に動作。影響なし。' ,
        '『機能安定/0』機能がむしろ安定した。影響なし。' ,
        '『不良調整/0』機能に違和感を覚えるが誤差の範囲内。影響なし。' ,
        '『機能暴発/10』兵装の調子が悪化。次のターンのターン終了まで、［タイミング：準備］の《兵装》が使用できない。' ,
        '『離脱機能/10』異常発生。即座に［戦闘移動］を行い、最も近い敵から遠ざかるように移動する。' ,
        '『排熱暴走/10』排熱機能に異常。次のターンのターン終了まで［着火］状態となる。特殊ダメージは本人のものを使用する。' ,
        '『電装異常/20』電装系に異常。即座に【負荷】が2点蓄積する。',
    );
#**第２段階
    @URGE2 = (
        '『安全機能/20』セーフティが誤動作。このターンのターン終了まで判定の達成値に-5。' ,
        '『筋肉萎縮/20』人工筋肉に異常発生。60ターン（10分）の間、【肉体】判定の達成値に-2。' ,
        '『出力低下/20』駆動部に異常発生。60ターン（10分）の間、【機敏】判定の達成値に-2。' ,
        '『感覚異常/10』感覚機能に異常発生。60ターン（10分）の間、【感覚】判定の達成値に-2。' ,
        '『視界不良/10』視覚機能に異常発生。60ターン（10分）の間、【幸運】判定の達成値に-2。' ,
        '『機能安定/0』機能がむしろ安定した。影響なし。' ,
        '『不良調整/0』機能に違和感を覚えるが誤差の範囲内。影響なし。',
        '『援護不通/10』援護ソフトが誤作動。60ターン（10分）の間、【知力】判定の達成値に-2。' ,
        '『発声不調/20』通話機能に異常。60ターン（10分）の間、声を出しても雑音だらけになって意味が通じず、さらに【精神】判定の達成値に-2。' ,
        '『装甲軟化/20』防御機能に異常。次のターンのターン終了まで、防御力に-5。' ,
        '『装備異常/20』精密動作に異常発生。装備している［通常アイテム］の武器がランダムでひとつ、［装備］から外れる。' ,
    );
#**第３段階
    @URGE3 = (
        '『動力漏電/20』動力が漏電し始める。【負荷】が2点蓄積する。' ,
        '『脚部異常/20』脚部に異常発生。次のターンのターン終了まで［戦闘移動］［全力移動］の距離が半分になる。' ,
        '『足下転倒/20』バランサーに異常発生。［転倒］状態となる。' ,
        '『出力向上/20』突然出力が上昇する。次のターンのターン終了まで、特殊ダメージに+1d。' ,
        '『機能制動/10』一瞬違和感を覚えるが、以後正常に動作。影響なし。' ,
        '『障壁減衰/10』電力が減衰する。【電力】を5消費する。' ,
        '『身体向上/10』格闘機能が向上。次のターンのターン終了まで、肉弾ダメージに+1d。' ,
        '『精度向上/20』火器管制機能が向上。次のターンのターン終了まで、射撃ダメージに+1d。' ,
        '『反射鋭化/20』反応速度が加速した。次のターンのターン終了まで、【行動値】に+5。' ,
        '『友軍誤認/20』警戒装置が誤動。最も近い［距離：移動10m/対象：1体］に通常肉弾攻撃を行う。' ,
        '『電子賦活/20』電磁障壁が突如復帰。【電力】が10回復する。' ,
    );
#**第４段階
    @URGE4 = (
        '『照準誤認/20』照準機能に異常発生。最も近い［距離：移動10m/対象：1体］に通常肉弾攻撃を行う。判定は自動的にクリティカルとなる。' ,
        '『攻撃特化/20』攻撃機能が異常動作。次のターンのターン終了まで、ダメージに+2d。ただし、その間［タイミング：瞬間］を行えない。' ,
        '『機内窒息/20』呼吸機能に異常。次のターンのターン終了まで［窒息］状態となる。' ,
        '『自動援護/20』援護機能が自動的に作動する。即座に［タイミング：準備］を1回行う。',
        '『音声遮断/10』聴覚機能に異常発生。次のターンのターン終了まで一切の物音が聞こえず、回避判定の達成値に-5。' ,
        '『電流加速/10』突然電磁障壁が効率的に流れる。【電力】が10回復。' ,
        '『精密射撃/20』照準機能が向上。60ターン（10分間）の間、ダメージに+5。' ,
        '『緊急措置/20』突然、緊急時の対策機能が発動する。【負荷】が2蓄積し、【電力】が20回復する。' ,
        '『荷電暴走/20』電流の流れに異常が発生。【HP】を10消費し、次のターンのターン終了までダメージに+10。' ,
        '『状況分析/20』周辺解析ソフトが高速で動作。60ターン（10分間）の間、命中判定の達成値に+5。' ,
        '『機能再生/20』兵装に誤作動。取得済みの使用不能になった《兵装》を1つ指定し、再び使用できるようになる。' ,
    );
#**第５段階
    @URGE5 = (
        '『機能停止/30』機能が作動しなくなる。このターンのターン終了まで、【負荷】を蓄積させる行動が取れなくなる。' ,
        '『機関暴走/30』放熱機関が暴走する。本人を中心として［対象：半径5m全て］が次のターンのターン終了まで［着火］状態となる。特殊ダメージはこの表を振ったPCのものを使用する。' ,
        '『電力低下/20』出力が上がらない。【電力】が20減少する。' ,
        '『急速修復/20』電磁障壁と生命維持装置が高速処理を始める。【HP】が20回復。' ,
        '『駆動不調/20』駆動系に動作不良。次のターンのターン終了まで、判定の達成値に-5。' ,
        '『機体清冽/20』機能が初期化され、異常から復帰。［気絶・死亡・戦闘不能］以外の状態変化がすべて解除される。' ,
        '『機体減速/20』運動機能が暴走。次のターンのターン終了まで【行動値】に-10（最低1）。' ,
        '『排毒噴出/20』排気機構が誤作動。［対象：半径5m全て］が次のターンのターン終了まで［猛毒］状態となる。' ,
        '『緊急駆動/20』機動性が向上。次のターンのターン終了まで判定の達成値に+5。' ,
        '『負荷軽減/30』急激に負荷が解消される。【負荷】が2点回復する。' ,
        '『出力過剰/30』全出力が過剰なまでに上昇する。次のターンのターン終了までダメージに+10。' ,
    );
    my @URGE = (\@URGE1, \@URGE2, \@URGE3, \@URGE4, \@URGE5);
    return @URGE;
}


####################            WHFRP関連          ########################
sub wh_crit {
    return '1' if($game_type ne "Warhammer"); 
    # クリティカル効果データ
    my @WHH = (
        '01:打撃で状況が把握出来なくなる。次ターンは1回の半アクションしか行なえない。',
        '02:耳を強打された為、耳鳴りが酷く目眩がする。1Rに渡って一切のアクションを行なえない。',
        '03:打撃が頭皮を酷く傷つけた。【武器技術度】に-10%。治療を受けるまで継続。',
        '04:鎧が損傷し当該部位のAP-1。修理するには(職能:鎧鍛冶)テスト。鎧を着けていないなら1Rの間アクションを行なえない。',
        '05:転んで倒れ、頭がくらくらする。1Rに渡ってあらゆるテストに-30で、立ち上がるには起立アクションが必要。',
        '06:1d10R気絶。',
        '07:1d10分気絶。以後CTはサドンデス。',
        '08:顔がずたずたになって倒れ、以後無防備状態。治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。【頑強】テストに失敗すると片方の視力を失う。',
        '09:凄まじい打撃により頭蓋骨が粉砕される。死は瞬時に訪れる。',
        '10:死亡する。いかに盛大に出血し、どのような死に様を見せたのかを説明してもよい。',
        );
    my @WHA = (
        '01:手に握っていたものを落とす。盾はくくりつけられている為、影響なし。',
        '02:打撃で腕が痺れ、1Rの間使えなくなる。',
        '03:手の機能が失われ、治療を受けるまで回復できない。手で握っていたもの(盾を除く)は落ちる。',
        '04:鎧が損傷する。当該部位のAP-1。修理するには(職能:鎧鍛冶)テスト。鎧を着けていないなら腕が痺れ、1Rの間使えなくなる。',
        '05:腕の機能が失われ、治療を受けるまで回復できない。手で握っていたもの(盾を除く)は落ちる。',
        '06:腕が砕かれる。手で握っていたもの(盾を除く)は落ちる。出血がひどく、治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。',
        '07:手首から先が血まみれの残骸と化す。手で握っていたもの(盾を除く)は落ちる。出血がひどく、治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。【頑健】テストに失敗すると手の機能を失う。',
        '08:腕は血まみれの肉塊がぶら下がっている状態になる。手で握っていたもの(盾を除く)は落ちる。治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。【頑健】テストに失敗すると肘から先の機能を失う。',
        '09:大動脈に傷が及んだ。コンマ数秒の内に損傷した肩から血を噴出して倒れる。ショックと失血により、ほぼ即死する。',
        '10:死亡する。いかに盛大に出血し、どのような死に様を見せたのかを説明してもよい。',
        );
    my @WHB = (
        '01:打撃で息が詰まる。1Rの間、キャラクターの全てのテストや攻撃に-20%。',
        '02:股間への一撃。苦痛のあまり、1Rに渡って一切のアクションを行なえない。',
        '03:打撃で肋骨がぐちゃぐちゃになる。以後治療を受けるまでの間、【武器技術度】に-10%。',
        '04:鎧が損傷する。当該部位のAP-1。修理するには(職能:鎧鍛冶)テスト。鎧を着けていないなら股間への一撃、1Rに渡って一切のアクションを行なえない。',
        '05:転んで倒れ、息が詰まって悶絶する。1Rに渡ってあらゆるテストに-30の修正、立ち上がるには起立アクションが必要。',
        '06:1d10R気絶。',
        '07:ひどい内出血が起こり、無防備状態。出血がひどく、治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。',
        '08:脊髄が粉砕されて倒れ、以後治療を受けるまで無防備状態。以後CTはサドンデスを適用。【頑強】テストに失敗すると腰から下が不随になる。',
        '09:凄まじい打撃により複数の臓器が破裂し、死は数秒のうちに訪れる。',
        '10:死亡する。いかに盛大に出血し、どのような死に様を見せたのかを説明してもよい。',
        );
    my @WHL = (
        '01:よろめく。次のターン、1回の半アクションしか行なえない。',
        '02:脚が痺れる。1Rに渡って【移動】は半減し、脚に関連する【敏捷】テストに-20%。回避が出来なくなる。',
        '03:脚の機能が失われ、治療を受けるまで回復しない。【移動】は半減し、脚に関連する【敏捷】テストに-20%。回避が出来なくなる。',
        '04:鎧が損傷する。当該部位のAP-1。修理するには(職能:鎧鍛冶)テスト。鎧を着けていないなら脚が痺れる、1Rに渡って【移動】は半減し、脚に関連する【敏捷】テストに-20%、回避不可になる。',
        '05:転んで倒れ、頭がくらくらする。1Rに渡ってあらゆるテストに-30の修正、立ち上がるには起立アクションが必要。',
        '06:脚が砕かれ、無防備状態。出血がひどく、治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。',
        '07:脚は血まみれの残骸と化し、無防備状態になる。治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。【頑強】テストに失敗すると足首から先を失う。',
        '08:脚は血まみれの肉塊がぶらさがっている状態。以後無防備状態。治療を受けるまで毎Rの被害者のターン開始時に20%で死亡。以後CTはサドンデスを適用。【頑強】テストに失敗すると膝から下を失う。',
        '09:大動脈に傷が及ぶ。コンマ数秒の内に脚の残骸から血を噴出して倒れ、ショックと出血で死は瞬時に訪れる。',
        '10:死亡する。いかに盛大に出血し、どのような死に様を見せたのかを説明してもよい。',
        );
    my @WHW = (
        '01:軽打。1ラウンドに渡って、あらゆるテストに-10％。',
        '02:かすり傷。+10％の【敏捷】テストを行い、失敗なら直ちに高度を1段階失う。地上にいるクリーチャーは、次のターンには飛び立てない。',
        '03:損傷する。【飛行移動力】が2点低下する。-10％の【敏捷】テストを行い、失敗なら直ちに高度を1段階失う。地上にいるクリーチャーは、次のターンには飛び立てない。',
        '04:酷く損傷する。【飛行移動力】が4点低下する。-30％の【敏捷】テストを行い、失敗なら直ちに高度を1段階失う。地上にいるクリーチャーは、1d10ターンが経過するまで飛び立てない。',
        '05:翼が使えなくなる。【飛行移動力】が0に低下する。飛行中のものは落下し、高度に応じたダメージを受ける。地上にいるクリーチャーは、怪我が癒えるまで飛び立てない。',
        '06:翼の付け根に傷が開く。【飛行移動力】が0に低下する。飛行中のものは落下し、高度に応じたダメージを受ける。地上にいるクリーチャーは、怪我が癒えるまで飛び立てない。治療を受けるまで毎R被害者のターン開始時に20％の確率で死亡。以後CTはサドンデスを適用。',
        '07:翼は血まみれの残骸と化し、無防備状態になる。【飛行移動力】が0に低下する。飛行中のものは落下し、高度に応じたダメージを受ける。地上にいるクリーチャーは、怪我が癒えるまで飛び立てない。治療を受けるまで毎R被害者のターン開始時に20％の確率で死亡。以後CTはサドンデスを適用。【頑強】テストに失敗すると飛行能力を失う。',
        '08:翼が千切れてバラバラになり、無防備状態になる。【飛行移動力】が0に低下する。飛行中のものは落下し、高度に応じたダメージを受ける。地上にいるクリーチャーは、怪我が癒えるまで飛び立てない。治療を受けるまで毎R被害者のターン開始時に20％の確率で死亡。以後CTはサドンデスを適用。飛行能力を失う。',
        '09:大動脈が切断された。コンマ数秒の内に血を噴き上げてくずおれる、ショックと出血で死は瞬時に訪れる。',
        '10:死亡する。いかに盛大に出血し、どのような死に様を見せたのかを説明してもよい。',
        );
    my @WHCT = (
         5, 7, 9,10,10,10,10,10,10,10,  #01-10
         5, 6, 8, 9,10,10,10,10,10,10,  #11-20
         4, 6, 8, 9, 9,10,10,10,10,10,  #21-30
         4, 5, 7, 8, 9, 9,10,10,10,10,  #31-40
         3, 5, 7, 8, 8, 9, 9,10,10,10,  #41-50
         3, 4, 6, 7, 8, 8, 9, 9,10,10,  #51-60
         2, 4, 6, 7, 7, 8, 8, 9, 9,10,  #61-70
         2, 3, 5, 6, 7, 7, 8, 8, 9, 9,  #71-80
         1, 3, 5, 6, 6, 7, 7, 8, 8, 9,  #81-90
         1, 2, 4, 5, 6, 6, 7, 7, 8, 8,  #91-00
    );
    # クリティカル表作成終了
    my $string = $_[0];
    my $dst = $_[1];
    my $output = "1";
    if($string =~ /WH([HABTLW])(\d+)/) {
        my $whp = ($1);     #部位
        my $whlv = ($2);    #クリティカル値
        $whlv = 10 if($whlv > 10);
        $whlv = 1 if($whlv < 1);
        my($whpp, @whppp);
        if($whp =~ /H/i) {
            $whpp = '頭部';
            @whppp = @WHH;
        } elsif($whp =~ /A/i) {
            $whpp = '腕部';
            @whppp = @WHA;
        } elsif($whp =~ /[TB]/i) {
            $whpp = '胴体';
            @whppp = @WHB;
        } elsif($whp =~ /L/i) {
            $whpp = '脚部';
            @whppp = @WHL;
        } elsif($whp =~ /W/i) {
            $whpp = '翼部';
            @whppp = @WHW;
        }
        my ($dice_now, $dice_str) = &roll(1, 100);
        my $crit_no = int(($dice_now - 1) / 10) * 10;
        my $crit_num = $WHCT[$crit_no + $whlv - 1];
        $output = $whppp[$crit_num - 1];
        if($crit_num >= 5) {
            $output .= 'サドンデス×'
        } else {
            $output .= 'サドンデス○'
        }
        $output = $dst.":".$whpp.'CT表'."(${dice_now}+${whlv}) ＞ ".$output;
    }
    return "$output";
}
sub wh_atpos {  #WHFRP2命中部位表
    my $pos_num = $_[0];
    my $pos_type = $_[1];
    my @pos_2l = (
        '二足',
        '15','頭部',
        '35','右腕',
        '55','左腕',
        '80','胴体',
        '90','右脚',
        '100','左脚',
    );
    my @pos_2lw = (
        '有翼二足',
        '15','頭部',
        '25','右腕',
        '35','左腕',
        '45','右翼',
        '55','左翼',
        '80','胴体',
        '90','右脚',
        '100','左脚',
    );
    my @pos_4l = (
        '四足',
        '15','頭部',
        '60','胴体',
        '70','右前脚',
        '80','左前脚',
        '90','右後脚',
        '100','左後脚',
    );
    my @pos_4la = (
        '半人四足',
        '10','頭部',
        '20','右腕',
        '30','左腕',
        '60','胴体',
        '70','右前脚',
        '80','左前脚',
        '90','右後脚',
        '100','左後脚',
    );
    my @pos_4lw = (
        '有翼四足',
        '10','頭部',
        '20','右翼',
        '30','左翼',
        '60','胴体',
        '70','右前脚',
        '80','左前脚',
        '90','右後脚',
        '100','左後脚',
    );
    my @pos_b = (
        '鳥',
        '15','頭部',
        '35','右翼',
        '55','左翼',
        '80','胴体',
        '90','右脚',
        '100','左脚',
    );
    my @wh_pos = (\@pos_2l, \@pos_2lw, \@pos_4l, \@pos_4la, \@pos_4lw, \@pos_b);
    my $output = "";
    my $pos_t = 0;
    if($pos_type ne "") {
        if($pos_type =~/\@(2W|W2)/i) {
            $pos_t = 1;
        } elsif($pos_type =~ /\@(4W|W4)/i) {
            $pos_t = 4;
        } elsif($pos_type =~ /\@(4H|H4)/i) {
            $pos_t = 3;
        } elsif($pos_type =~ /\@4/i) {
            $pos_t = 2;
        } elsif($pos_type =~ /\@W/i) {
            $pos_t = 5;
        } elsif(!($pos_type =~ /\@(2H|H2|2)/i)) {
            $pos_t = -1;
        }
    }
    if($pos_t < 0) {
        foreach my $pos_i (@wh_pos) {
            $output .= ' '.${$pos_i}[0].":";
            for(my $i = 1; $i <= scalar @{$pos_i}; $i += 2) {
                if($pos_num <= ${$pos_i}[$i]) {
                    $output .= ${$pos_i}[$i+1];
                    last;
                }
            }
        }
    } else {
        my $pos_i = $wh_pos[$pos_t];
        $output .= ' '.${$pos_i}[0].":";
        for(my $i = 1; $i <= scalar @{$pos_i}; $i += 2) {
            if($pos_num <= ${$pos_i}[$i]) {
                $output .= ${$pos_i}[$i+1];
                last;
            }
        }
    }
    return $output;
}
sub wh_att {
    return '1' if($game_type ne "Warhammer"); 
    my $string = $_[0];
    my $type = "";
    my $output = '1';

    if($string =~/(.+)(@.*)/) {
        $string = $1;
        $type = $2;
    }
    if($string =~ /WH(\d+)/i) {
        my $diff = $1;
        my ($total_n, $dice_dmy) = &roll(1, 100);
        $output = "$_[1]: ($string) ＞ $total_n";
        $output .= &check_suc($total_n, 0, "<=", $diff, 1, 100, 0, $total_n);
        my $pos_num = ($total_n % 10)*10+int($total_n / 10);
        $pos_num = 100 if($total_n >= 100);
        $output .= &wh_atpos($pos_num, $type) if($total_n <= $diff);
    }
    return $output;
}

####################           CthulhuTech         ########################
sub cthulhutech_check { # CthulhuTechの判定用ダイス計算
    my $dice_str = $_[0];
    my @DICE_ARR = split(/,/, $dice_str);
    my @dice_num = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    my $max_num = 0;

    foreach my $dice_n (@DICE_ARR) {
        $dice_num[($dice_n -1)] += 1;
        $max_num = $dice_n if($dice_n > $max_num);  # 1.個別のダイスの最大値
    }
    if(scalar @DICE_ARR > 1) {  # ダイスが2個以上ロールされている
        for(my $i=0; $i < 10; $i++) {
            if($dice_num[$i] > 1) { # 2.同じ出目の合計値
                my $dice_now = $dice_num[$i] * ($i + 1);
                $max_num = $dice_now if($dice_now > $max_num);
            }
        }
        if(scalar @DICE_ARR > 2) {  # ダイスが3個以上ロールされている
            for(my $i=0; $i < 10; $i++) {
                if($dice_num[$i] > 0) {
                    if($dice_num[$i + 1] > 0 && $dice_num[$i + 2] > 0) {    # 3.連続する出目の合計
                        my $dice_now = $i * 3 + 6;  # ($i+1) + ($i+2) + ($i+3) = $i*3 + 6
                        for(my $i2 = $i + 3; $i2 < 10; $i2++) {
                            if($dice_num[$i2] > 0) {
                                $dice_now += $i2 + 1;
                            } else {
                                last;
                            }
                        }
                        $max_num = $dice_now if($dice_now > $max_num);
                    }
                }
            }
        }
    }
    return $max_num;
}

####################         Call Of Cthulhu        ########################
sub coc_res{    # CoCの抵抗ロール
    my $string = $_[0];
    my $output = "1";

    if($game_type eq "Cthulhu") {
        if($string =~ /res([-\d]+)/i) {
            my $target =  $1 * 5 + 50;
            if($target < 5){    # 自動失敗
                $output = "$_[1]: (1d100<=${target}) ＞ 自動失敗";
            } elsif($target > 95){  # 自動成功
                $output = "$_[1]: (1d100<=${target}) ＞ 自動成功";
            } else {    # 通常判定
                my ($total_n, $dice_dmy) = &roll(1, 100);
                if($total_n <= $target){
                    $output = "$_[1]: (1d100<=${target}) ＞ ${total_n} ＞ 成功";
                } else {
                    $output = "$_[1]: (1d100<=${target}) ＞ ${total_n} ＞ 失敗";
                }
            }
        }
    }
    return $output;
}

####################        ダブルクロス 3rd       ########################
#** 感情表
sub dx_emotion_table {
    my $output = '1';
    if($game_type eq "DoubleCross") {
        my ($pos_dice, $pos_table) = &dx_feel_positive_table;
        my ($neg_dice, $neg_table) = &dx_feel_negative_table;
        my ($dice_now, $dice_dmy) = &roll(1, 2);
        if($pos_table ne '1' and $neg_table ne '1') {
            if($dice_now < 2){
                $pos_table = "○".$pos_table;
            } else {
                $neg_table = "○".$neg_table;
            }
            $output = "$_[0]: 感情表(${pos_dice}-${neg_dice}) ＞ ${pos_table} - ${neg_table}";
        }
    }
    return $output;
}

#** 感情表（ポジティブ）
sub dx_feel_positive_table {
    my @table = (
        [0, '傾倒(けいとう)'],
        [5, '好奇心(こうきしん)'],
        [10, '憧憬(どうけい)'],
        [15, '尊敬(そんけい)'],
        [20, '連帯感(れんたいかん)'],
        [25, '慈愛(じあい)'],
        [30, '感服(かんぷく)'],
        [35, '純愛(じゅんあい)'],
        [40, '友情(ゆうじょう)'],
        [45, '慕情(ぼじょう)'],
        [50, '同情(どうじょう)'],
        [55, '遺志(いし)'],
        [60, '庇護(ひご)'],
        [65, '幸福感(こうふくかん)'],
        [70, '信頼(しんらい)'],
        [75, '執着(しゅうちゃく)'],
        [80, '親近感(しんきんかん)'],
        [85, '誠意(せいい)'],
        [90, '好意(こうい)'],
        [95, '有為(ゆうい)'],
        [100, '尽力(じんりょく)'],
        [101, '懐旧(かいきゅう)'],
        [102, '任意(にんい)'],
        );
    
    return &dx_feel_table( @table );
}

#** 感情表（ネガティブ）
sub dx_feel_negative_table {
    my @table = (
        [0, '侮蔑(ぶべつ)'],
        [5, '食傷(しょくしょう)'],
        [10, '脅威(きょうい)'],
        [15, '嫉妬(しっと)'],
        [20, '悔悟(かいご)'],
        [25, '恐怖(きょうふ)'],
        [30, '不安(ふあん)'],
        [35, '劣等感(れっとうかん)'],
        [40, '疎外感(そがいかん)'],
        [45, '恥辱(ちじょく)'],
        [50, '憐憫(れんびん)'],
        [55, '偏愛(へんあい)'],
        [60, '憎悪(ぞうお)'],
        [65, '隔意(かくい)'],
        [70, '嫌悪(けんお)'],
        [75, '猜疑心(さいぎしん)'],
        [80, '厭気(いやけ)'],
        [85, '不信感(ふしんかん)'],
        [90, '不快感(ふかいかん)'],
        [95, '憤懣(ふんまん)'],
        [100, '敵愾心(てきがいしん)'],
        [101, '無関心(むかんしん)'],
        [102, '任意(にんい)'],
        );
    
    return &dx_feel_table( @table );
}

sub dx_feel_table {
    my @table = @_;
    my ($dice_now, $dice_dmy) = &roll(1, 100);
    my $output = get_table_by_number($dice_now, @table);

    return ($dice_now, $output);
}


####################           シノビガミ          ########################
#** テーブル振り分け
sub shinobigami_table {
    my ($string, $nick) = @_;
    my $output = '1';
    
    if($game_type eq "ShinobiGami") {
        if($string =~ /((\w)*ST)/i) {  # シーン表
            $output = &sinobigami_scene_table("\U$1", "$nick");
        }
        elsif($string =~ /(FT)/i) {   # ファンブル表
            $output = &sinobigami_fumble_table("$nick");
        }
        elsif($string =~ /(ET)/i) {   # 感情表
            $output = &sinobigami_emotion_table("$nick");
        }
        elsif($string =~ /([G]?WT)/i) {   # 変調表
            $output = &sinobigami_wrong_table("\U$1", "$nick");
        }
        elsif($string =~ /(BT)/i) {   # 戦場表
            $output = &sinobigami_battlefield_table("$nick");
        }
    }
    return $output;
}

#** シーン表
sub sinobigami_scene_table {
    my $string = "\U$_[0]";
    my $nick = $_[1];
    my $output = '1';
    my $type = "";
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

    if($string =~ /CST/i) {
        $type = '都市';
    } elsif($string =~ /MST/i) {
        $type = '館';
    } elsif($string =~ /DST/i) {
        $type = '出島';
    } elsif($string =~ /TST/i) {
        $type = 'トラブル';
    } elsif($string =~ /NST/i) {
        $type = '日常';
    } elsif($string =~ /TKST/i) {
        $type = '東京';
    } elsif($string =~ /KST/i) {
        $type = '回想';
    } elsif($string =~ /GST/i) {
        $type = '戦国';
    } elsif($string =~ /GAST/i) {
        $type = '学校';
    } elsif($string =~ /KYST/i) {
        $type = '京都';
    } elsif($string =~ /JBST/i) {
        $type = '神社仏閣';
    }
    if($type eq '都市') {
        @table = (
            'シャワーを浴び、浴槽に疲れた身体を沈める。時には、癒しも必要だ。',
            '閑静な住宅街。忍びの世とは関係のない日常が広がっているようにも見えるが……それも錯覚なのかもしれない',
            '橋の上にたたずむ。川の対岸を結ぶ境界点。さて、どちらに行くべきか……？',
            '人気のない公園。野良猫が一匹、遠くからあなたを見つめているような気がする。',
            '至福の一杯。この一杯のために生きている……って、いつも言ってるような気がするなぁ。',
            '無機質な感じのするオフィスビル。それは、まるで都市の墓標のようだ。',
            '古びた劇場。照明は落ち、あなたたちのほかに観客の姿は見えないが……。',
            '商店街を歩く。人ごみに混じって、不穏な気配もちらほら感じるが……。',
            'ビルの谷間を飛び移る。この街のどこかに、「アレ」は存在するはずなのだが……。',
            '見知らぬ天井。いつの間にか眠っていたのだろうか？それにしてもここはどこだ？',
            '廃屋。床には乱雑に壊れた調度品や器具が転がっている。',
        );
    } elsif($type eq '館') {
        @table = (
            'どことも知れぬ暗闇の中。忍びの者たちが潜むには、おあつらえ向きの場所である。',
            '洋館の屋根の上。ここからなら、館の周りを一望できるが……。',
            '美しい庭園。丹精こめて育てられたであろう色とりどりの花。そして、綺麗に刈り込まれた生垣が広がっている。',
            'あなたは階段でふと足を止めた。何者かの足音が近づいているようだ。',
            'あなたに割り当てられた寝室。ベッドは柔らかく、調度品も高級なものばかりだが……。',
            'エントランスホール。古い柱時計の時報が響く中、館の主の肖像画が、あなたを見下ろしている。',
            '食堂。染み一つないテーブルクロスに覆われた長い食卓。その上は年代物の燭台や花で飾られている。',
            '長い廊下の途中。この屋敷は広すぎて、迷子になってしまいそうだ。',
            '戯れに遊戯室へ入ってみた。そこには撞球台やダーツの的、何組かのトランプが散らばっているポーカーテーブルがあった。',
            'かび臭い図書室。歴代の館の主たちの記録や、古今東西の名著が、ぎっしりと棚に並べられている。',
            '一族の納骨堂がある。冷気と瘴気に満ちたその場所に、奇妙な叫びが届く。遠くの鳥のさえずりか？それとも死者の恨みの声か……？',
        );
    } elsif($type eq '出島') {
        @table = (
            '迷宮街。いつから囚われてしまったのだろう？何重にも交差し、曲がりくねった道を歩き続ける。このシーンの登場人物は《記憶術》で判定を行わなければならない。成功すると、迷宮の果てで好きな忍具を一つ獲得する。失敗すると、行方不明の変調を受ける。',
            '幻影城。訪れた者の過去や未来の風景を見せる場所。このシーンの登場人物は、《意気》の判定を行うことができる。成功すると、自分の持っている【感情】を好きな何かに変更することができる。',
            '死者たちの行進。無念の死を遂げた者たちが、仲間を求めて彷徨らっている。このシーンの登場人物は《死霊術》で判定を行わなければならない。失敗すると、ランダムに変調を一つを受ける。',
            'スラム。かろうじて生き延びている人たちが肩を寄せ合い生きているようだ。ここなら辛うじて安心できるかも……。',
            '落書きだらけのホテル。その周囲には肌を露出させた女や男たちが、媚態を浮かべながら立ち並んでいる。',
            '立ち並ぶ廃墟。その影から、人とも怪物ともつかぬ者の影が、あなたの様子をじっとうかがっている。',
            '薄汚い路地裏。巨大な黒犬が何かを貪っている。あなたの気配を感じて黒犬は去るが、そこに遺されていたのは……。',
            '昏い酒場。バーテンが無言でグラスを磨き続けている。あなたの他に客の気配はないが……。',
            '地面を覆う無数の瓦礫。その隙間から暗黒の瘴気が立ち昇る。このシーンの登場人物は《生存術》で判定を行わなければならない。失敗すると、好きな【生命力】を１点失う。',
            '熱気溢れる市場。武器や薬物などを売っているようだ。商人たちの中には、渡来人の姿もある。このシーンの登場人物は、《経済力》で判定を行うことができる。成功すると、好きな忍具を一つ獲得できる。',
            '目の前に渡来人が現れる。渡来人はあなたに興味を持ち、襲い掛かってくる。このシーンの登場人物は《刀術》で判定を行わなければならない。成功すると、渡来人を倒し、好きな忍具を一つ獲得する。失敗すると、３点の接近戦ダメージを受ける。',
        );
    } elsif($type eq 'トラブル') {
        @table = (
            '同行者とケンカしてしまう。うーん、気まずい雰囲気。',
            'バシャ！　同行者のミスでずぶ濡れになってしまう。……冷たい。',
            '敵の気配に身を隠す。……すると、同行者の携帯が着信音を奏で始める。「……えへへへへ」じゃない！',
            '同行者の空気の読めない一言。場が盛大に凍り付く。まずい。何とかしないと。',
            '危機一髪！　同行者を死神の魔手から救い出す。……ここも油断できないな。',
            '同行者が行方不明になる。アイツめ、どこへ逃げたッ！',
            'ずて────ん！　あいたたたた……同行者がつまずいたせいで、巻き込まれて転んでしまった。',
            '同行者のせいで、迷子になってしまう。困った。どこへ行くべきか。',
            '「どこに目つけてんだ、てめぇ！」同行者がチンピラにからまれる。うーん、助けに入るべきか。',
            '！　油断していたら、同行者に自分の恥ずかしい姿を見られてしまう。……一生の不覚！',
            '同行者が不意に涙を流す。……一体、どうしたんだろう？',
        );
    } elsif($type eq '日常') {
        @table = (
            'っくしゅん！　……うーん、風邪ひいたかなあ。お見舞いに来てくれたんだ。ありがとう。',
            '目の前のアイツは、見違えるほどドレスアップしていた。……ゆっくりと大人な時間が過ぎていく。',
            'おいしそうなスイーツを食べることになる。たまには甘いものを食べて息抜き息抜き♪',
            'ふわわわわ、いつの間にか寝ていたようだ。……って、あれ？　お前、いつからそこにいたッ!!',
            '買い物帰りの友人と出会う。方向が同じなので、しばらく一緒に歩いていると、思わず会話が盛り上がる。',
            'コンビニ。商品に手を伸ばしたら、同時にその商品をとろうとした別の人物と手が触れあう。なんという偶然！',
            'みんなで食卓を囲むことになる。鍋にしようか？　それとも焼き肉？　お好み焼きなんかもい～な～♪',
            'どこからか楽しそうな歌声が聞こえてくる。……って、あれ？　何でお前がこんなところに？',
            '野良猫に餌をやる。……猫はのどを鳴らし、すっかりあなたに甘えているようだ。',
            '「……！　……？　……♪」テレビは、なにやら楽しげな場面を映している。あら。もう、こんな時間か。',
            '面白そうなゲーム！　誰かと対戦することになる。GMは、「戦術」からランダムに特技1つを選ぶ。このシーンに登場しているキャラクターは、その特技の判定を行う。成功した場合、同じシーンに登場しているキャラクターを1人を選び、そのキャラクターの自分に対する【感情】を好きなものに変更する（何の【感情】も持っていない場合、好きな【感情】を芽生えさせる）。',
        );
    } elsif($type eq '回想') {
        @table = (
            '闇に蔓延する忍びの気配。あのときもそうだった。手痛い失敗の記憶。今度こそ、うまくやってみせる。',
            '甘い口づけ。激しい抱擁。悲しげな瞳……一夜の過ちが思い返される。',
            '記憶の中でゆらめくセピア色の風景。……見覚えがある。そう、私はここに来たことがあるはずだッ!!',
            '目の前に横たわる死体。地面に広がっていく。あれは、私のせいだったのだろうか……？',
            'アイツとの大切な約束を思い出す。守るべきだった約束。果たせなかった約束。',
            '助けを求める右手が、あなたに向かってまっすぐ伸びる。あなたは、必死でその手を掴もうとするが、あと一歩のところで、その手を掴み損ねる……。',
            'きらきらと輝く笑顔。今はもう喪ってしまった、大事だったアイツの笑顔。',
            '恐るべき一撃！　もう少しで命を落とすところだった……。しかし、あの技はいまだ見切れていない。',
            '幼い頃の記憶。仲の良かったあの子。そういえば、あの子は、どこに行ってしまったのだろう。もしかして……。',
            '「……ッ!!」激しい口論。ひどい別れ方をしてしまった。あんなことになると分かっていたら……。',
            '懐の中のお守りを握りしめる。アイツにもらった、大切な思い出の品。「兵糧丸」を1つ獲得する。',
        );
    } elsif($type eq '東京') {
        @table = (
            'お台場、臨界副都心。デート中のカップルや観光客が溢れている。',
            '靖国神社。東京の中とも思えぬ、緑で満ちた場所だ。今は観光客もおらず、奇妙に静かだ……。',
            '東京大学の本部キャンパス。正門から伸びる銀杏並木の道を学生や教職員がのんびりと歩いている。道の向こうには安田講堂が見える。',
            '山手線の中。乗車率200％を超える、殺人的な通勤ラッシュ真っ最中。この中でできることは限られている……。',
            '霞が関。この場に集う情報は、忍者にとっても価値が高いものだ。道を行く人々の中にも、役人や警察官が目につく。',
            '渋谷駅前の雑踏。大型屋外ヴィジョンが見下ろす中で、大勢の若者たちが行き交っている。',
            '夜の新宿歌舞伎町。酔っぱらったサラリーマン、華やかな夜の蝶、明らかに筋ものと判る男、外国人などの様々な人間と、どこか危険な雰囲気に満ちている。',
            '新宿都庁。摩天楼が林立するビル街の下、背広姿の人々が行き交う。',
            '神田古書街。多くの古書店が軒を連ねている。軒先に積まれた本の山にさえ、追い求める謎や、深遠な知識が埋もれていそうな気がする。',
            '山谷のドヤ街。日雇い労働者が集う管理宿泊施設の多いこの場所は、身を隠すにはうってつけだ。',
            '東京スカイツリーの上。この場所からならば東京の町が一望できる。',
        );
    } elsif($type eq '戦国') {
        @table = (
            '炎上する山城。人々の悲鳴や怒号がこだましている。どうやら、敵対する武将による焼き討ちらしい。今ならば、あるいは……。',
            '荒れ果てた村。カラスの不吉な鳴き声が聞こえてくる中で、やせ細った村人たちが、うつろな瞳でこちらを伺っている。',
            '人気のない山道。ただ鳥の声だけが響いている。通りがかった人を襲うのには、好都合かもしれない。',
            '乾いた骸の転がる合戦後。生き物の姿はなく、草の一本さえも生えていない。落ち武者たちの恨みがましい声が聞こえてきそうだ……。',
            '不気味な気配漂う森の中。何か得体のしれぬものが潜んでいそうだ。',
            '荒れ果てた廃寺。ネズミがカサカサと這いまわる本堂の中を、残された本尊が見下ろしている。',
            '街道沿いの宿場町。戦から逃げてきたらしい町人や、商売の種を探す商人、目つきの鋭い武士などが行き交い、賑わっている。',
            '城の天守閣のさらに上。強く吹く風が、雲を流していく。',
            '館の天井裏。この下では今、何が行われているのか……。',
            '合戦場に設けられた陣内。かがり火がたかれ、武者たちが酒宴を行っている。',
            '戦の真っただ中にある合戦場。騎馬にまたがった鎧武者が駆け抜けていく。勝者となるのは、いずれの陣営だろうか。',
        );
    } elsif($type eq '学校') {
        @table = (
            '清廉な気配が漂う森の中。鳥のさえずりやそよ風が木々を通りすぎる音が聞こえる。',
            '学校のトイレ。……なんだか少しだけ怖い気がする。',
            '誰もいない体育館。バスケットボールがころころと転がっている。',
            '校舎の屋上。一陣の風が吹き、衣服をたなびかせる。',
            '校庭。体操服姿の生徒たちが走っている。',
            '廊下。休憩時間か放課後か。生徒たちが、楽しそうにはしゃいでいる。',
            '学食のカフェテリア。生徒たちがまばらに席につき、思い思い談笑している。',
            '静かな授業中の風景。しかし、忍術を使って一般生徒に気取られない会話をしている忍者たちもいる。',
            '校舎と校舎をつなぐ渡り廊下。あなた以外の気配はないが……。',
            '特別教室。音楽室や理科室にいるのってなんか楽しいよね。',
            'プール。水面が、ゆらゆら揺れている。',
        );
    } elsif($type eq '京都') {
        @table = (
            '夜の街並み。神社仏閣はライトアップされ、にぎやかな酔客が通りを埋める。昼間とはまた違った景色が広がっている。',
            '京都駅ビル。その屋上は、京都市で最も高く、周囲を一望できる。',
            '旅館で一休み。……のはずが、四方山話に花が咲く。',
            '鴨川のあたりを歩いている。カップルが均等に距離を置いて座っているのが面白い。',
            '京都はどこにでもおみやげ物屋があるなぁ。さて、あいつに何を買ってやるべきか……？',
            '「神社仏閣シーン表(JBST)」で決定。',
            '新京極でお買い物。アーケードには、新旧様々な店が建ち並ぶ。',
            '大学が近くにあるのかな？　安い定食屋や古本屋、ゲームセンターなどが軒を連ねる学生街。京都はたくさん大学があるなぁ。',
            '静かな竹林。凛とした気配が漂う。',
            '祇園。時折、しずしずと歩く舞妓さんとすれ違う。雰囲気のある町並みだ。',
            '一般公開された京都御所の中を歩く。昼間だというのに人通りはあまりなく、何だか少し寂しい気持ち。',
        );
    } elsif($type eq '神社仏閣') {
        @table = (
            '清明神社。一条戻り橋を越えたところにある小さな社。陰陽師に憧れる女性たちの姿が目立つ。',
            '東寺。東寺真言宗総本山。密教独特の厳しい気配が漂う。',
            '平安神宮。大鳥居を白無垢の花嫁行列がくぐり抜けていくのが見える。どうやら結婚式のようだ。',
            '慈照寺――通称、銀閣寺。室町後期の東山文化を代表する建築である。錦鏡池を囲む庭園には、物思いにふける観光客の姿が……。',
            '鹿苑寺――通称、金閣寺。室町前期の北山文化を代表する建築である。鏡湖池に映る逆さ金閣には、強力な「魔」を封印していると言うが……？',
            '三十三間堂。荘厳な本堂に立ち並ぶ千一体の千手観音像は圧巻。',
            '清水寺。清水坂を越え、仁王門を抜けると、本堂――いわゆる清水の舞台にたどり着く。そこからは、音羽の滝や子安塔が見える。',
            '八坂神社。祇園さんの名前で知られるにぎやかな神社。舞妓さんの姿もちらほら。',
            '伏見稲荷。全国約四万社の稲荷神社の総本宮。稲荷山に向かって立ち並ぶ約一万基の鳥居は、まるで異界へと続いているかのようだ……。',
            '化野念仏寺。無数の石塔、石仏が立ち並ぶ景色は、どこか荒涼としている……。',
            '六道珍皇寺。小野篁が冥界に通ったとされる井戸のある寺。この辺りは「六道の辻」と呼ばれ、不思議な伝説が数多く残っている。',
        );
    } else {
        @table = (
            '血の臭いがあたりに充満している。何者かの戦いがあった気配。　いや？まだ戦いは続いているのだろうか？',
            'これは……夢か？　もう終わったはずの過去。しかし、それを忘れることはできない。',
            '眼下に広がる街並みを眺める。ここからなら街を一望できるが……。',
            '世界の終わりのような暗黒。暗闇の中、お前達は密やかに囁く。',
            '優しい時間が過ぎていく。影の世界のことを忘れてしまいそうだ。',
            '清廉な気配が漂う森の中。鳥の囀りや、そよ風が樹々を通り過ぎる音が聞こえる。',
            '凄まじい人混み。喧噪。影の世界のことを知らない無邪気な人々の手柄話や無駄話が騒がしい。',
            '強い雨が降り出す。人々は、軒を求めて、大慌てて駆けだしていく。',
            '大きな風が吹き荒ぶ。髪の毛や衣服が大きく揺れる。何かが起こりそうな予感……',
            '酔っぱらいの怒号。客引きたちの呼び声。女たちの嬌声。いつもの繁華街の一幕だが。',
            '太陽の微笑みがあなたを包み込む。影の世界の住人には、あまりにまぶしすぎる。',
        );
    }
    my ($total_n, $dice_dmy) = &roll(2, 6);
    my $tn = $total_n - 2;
    $output = "${nick}: ${type}シーン表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** ファンブル表
sub sinobigami_fumble_table {
    my $output = '1';
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);
    my $type = '';

    @table = (
        '何か調子がおかしい。そのサイクルの間、すべての行為判定にマイナス１の修正がつく。',
        'しまった！　好きな忍具を１つ失ってしまう。',
        '情報が漏れる！　このゲームであなたが獲得した【秘密】は、他のキャラクター全員の知るところとなる。',
        '油断した！　術の制御に失敗し、好きな【生命力】を１点失う。',
        '敵の陰謀か？　罠にかかり、ランダムに選んだ変調１つを受ける。変調は、変調表で決定すること。',
        'ふう。危ないところだった。特に何も起こらない。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "$_[0]: ファンブル表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 感情表
sub sinobigami_emotion_table {
    my $output = '1';
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

    @table = (
        '共感（プラス）／不信（マイナス）',
        '友情（プラス）／怒り（マイナス）',
        '愛情（プラス）／妬み（マイナス）',
        '忠誠（プラス）／侮蔑（マイナス）',
        '憧憬（プラス）／劣等感（マイナス）',
        '狂信（プラス）／殺意（マイナス）',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "$_[0]: 感情表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 変調表
sub sinobigami_wrong_table {
    my $string = $_[0];
    my $output = '1';
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);
    my $type = '';

    if($string =~ /GWT/) {
        $type = '戦国';
        @table = (
            '催眠:戦闘に参加した時、戦闘開始時、もしくはこの変調を受けた時に【生命力】を1点減少しないと、戦闘から脱落する。サイクル終了時に〈意気〉判定し成功すると無効化。',
            '火達磨:ファンブル値が1上昇し、ファンブル時に1点の近接ダメージを受ける。シーン終了時に無効化。',
            '猛毒:戦闘に参加した時、ラウンドの終了時にサイコロを1つ振る(飢餓と共用)。奇数だったら【生命力】を1減少。サイクル終了時に〈毒術〉判定し成功すると無効化。',
            '飢餓:戦闘に参加した時、ラウンドの終了時にサイコロを1つ振る(猛毒と共用)。偶数だったら【生命力】を1減少。サイクル終了時に〈兵糧術〉判定し成功すると無効化。',
            '残刃:回復判定、忍法、背景、忍具の効果による【生命力】回復無効。サイクル終了時に〈拷問術〉判定し成功すると無効化。',
            '野望:命中判定に+1、それ以外の判定に-1。サイクル終了時に〈憑依術〉判定し成功すると無効化。',
            );
    } else {
        @table = (
            '故障:すべての忍具が使用不能。１サイクルの終了時に、《絡繰術》で判定を行い、成功するとこの効果は無効化される。',
            'マヒ:修得済み特技がランダムに１つ使用不能になる。１サイクルの終了時に、《身体操術》で成功するとこの効果は無効化される。',
            '重傷:次の自分の手番に行動すると、ランダムな特技分野１つの【生命力】に１点ダメージ。１サイクルの終了時に、《生存術》で成功すると無効化される。',
            '行方不明:その戦闘終了後、メインフェイズ中に行動不可。１サイクルの終了時に、《経済力》で成功すると無効化される。',
            '忘却:修得済み感情がランダムに１つ使用不能。１サイクルの終了時に、《記憶術》で成功すると無効化される。',
            '呪い:修得済み忍法がランダムに１つ使用不能。１サイクルの終了時に、《呪術》で成功すると無効化される。',
            );
    }
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "$_[1]: ${type}変調表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 戦場表
sub sinobigami_battlefield_table {
    my $output = '1';
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

    @table = (
        '平地:特になし。',
        '水中:海や川や、プール、血の池地獄など。この戦場では、回避判定に-2の修正がつく。',
        '高所:ビルの谷間や樹上、断崖絶壁など。この戦場でファンブルすると1点のダメージを受ける。',
        '悪天候:嵐や吹雪、ミサイルの雨など。この戦場では、すべての攻撃忍法の間合が１上昇する。',
        '雑踏:人混みや教室、渋滞中の車道など。この戦場では、行為判定のとき、2D6の目がプロット値+1以下だとファンブルする。',
        '極地:宇宙や深海、溶岩、魔界など。ラウンドの終わりにＧＭが1D6を振り、経過ラウンド以下なら全員1点ダメージ。ここから脱落したものは変調表を適用する。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "$_[0]: 戦場表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}

####################            サタスペ           ########################
#** 各種表
sub satasupe_table {
    my $string = "\U$_[0]";
    my @output;
    my $counts = 1;
    my $type = "";
    my $name = "";
    if($string =~ /(\D+)(\d*)/) {
        $type = $1;
        $counts = $2 if($2);
    }

    if($game_type eq "Satasupe") {
        #1d6*1d6
        #タグ決定表
        if($type eq "TAGT") {
            my @table = (
                '情報イベント',
                'アブノーマル(サ)',
                'カワイイ(サ)',
                'トンデモ(サ)',
                'マニア(サ)',
                'ヲタク(サ)',
                '音楽(ア)',
                '好きなタグ',
                'トレンド(ア)',
                '読書(ア)',
                'パフォーマンス(ア)',
                '美術(ア)',
                'アラサガシ(マ)',
                'おせっかい(マ)',
                '好きなタグ',
                '家事(マ)',
                'ガリ勉(マ)',
                '健康(マ)',
                'アウトドア(休)',
                '工作(休)',
                'スポーツ(休)',
                '同一タグ',
                'ハイソ(休)',
                '旅行(休)',
                '育成(イ)',
                'サビシガリヤ(イ)',
                'ヒマツブシ(イ)',
                '宗教(イ)',
                '同一タグ',
                'ワビサビ(イ)',
                'アダルト(風)',
                '飲食(風)',
                'ギャンブル(風)',
                'ゴシップ(風)',
                'ファッション(風)',
                '情報ハプニング',
            );
            $name = "タグ決定表:";
            for(my $i = 0; $i < $counts; $i++) {
                my $num1 = int(rand 6);
                my $num2 = int(rand 6);
                push @output, $name.($num1 + 1).($num2 + 1).":".$table[$num1 * 6 + $num2];
            }
        }
        #2d6
        if(! $name) {
            my @table;
            if($type =~ /CrimeIET/i) {
                #情報イベント表／〔犯罪〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '昔やった仕事の依頼人が登場。てがかりをくれる。好きなタグの上位リンク（SL+2）を１つ得る。',
                    '謎のメモを発見……このターゲットについて調べている間、このトピックのタグをチーム全員が所有しているものとして扱う',
                    '謎の動物が亜侠を路地裏に誘う。好きなタグの上位リンクを２つ得る',
                    '偶然、他の亜侠の仕事現場に出くわす。口止め料の代わりに好きなタグの上位リンクを１つ得る',
                    'あまりに適切な諜報活動。コストを消費せず、上位リンクを３つ得る',
                    'その道の権威を紹介される。現在と同じタグの上位リンクを２つ得る',
                    '捜査は足だね。〔肉体点〕を好きなだけ消費する。その値と同じ数の好きなタグの上位リンクを得る',
                    '近所のコンビニで立ち読み。思わぬ情報が手に入る。上位リンクを３つ得る',
                    'そのエリアの支配盟約からメッセンジャーが1D6人。自分のチームがその盟約に敵対していなければ、好きなタグの上位リンクを２つ得る。敵対していれば、メッセンジャーは「盟約戦闘員（p.127）」となる。血戦を行え',
                    '「三下（p.125）」が1D6人現れる。血戦を行え。倒した数だけ、好きなタグの上位リンクを手に入れる',
                );
                $name = "情報イベント表／〔犯罪〕:";
            } elsif($type =~ /LifeIET/i) {
                #情報イベント表／〔生活〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '隣の奥さんと世間話。上位リンクを４つ得る',
                    'ミナミで接待。次の１ターン何もできない代わりに、好きなタグの上位リンク（SL+2）を１つ得る',
                    '息抜きにテレビを見ていたら、たまたまその情報が。好きなタグの上位リンクを１つ得る',
                    '器用に手に入れた情報を転売する。《札巻》を１個手に入れ、上位リンクを３つ得る',
                    '情報を得るついでに軽い営業。〔サイフ〕を１回復させ、上位リンクを３つ得る',
                    '街の有力者からの突然の電話。そのエリアの盟約の幹部NPCの誰かと【コネ】を結ぶことができる',
                    '金をばらまく。〔サイフ〕を好きなだけ消費する。その値と同じ数の任意の上位リンクを得る',
                    '〔表の顔〕の同僚が思いがけないアドバイスをくれる。上位リンクを1D6つ得る',
                    '謎の情報屋チュンさんが、情報とアイテムのトレードを申し出る。DDの指定するアイテムを１つ手に入れると、どこからともなくチュンさんが現れる。そのアイテムをチュンさんに渡せば、情報ゲット！',
                    'ターゲットとは関係ないが、ドデかい情報を掘り当てる。その情報を売って〔サイフ〕が全快する',
                );
                $name = "情報イベント表／〔生活〕:";
            } elsif($type =~ /LoveIET/i) {
                #情報イベント表／〔恋愛〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '恋人との別れ。自分に恋人がいれば、１人を選んで、お互いのトリコ欄から名前を消す。その代わり情報ゲット！',
                    'とびきり美形の情報提供者と遭遇。〔性業値〕判定で律になると、好きなタグの上位リンクを１つ得る',
                    '敵対する亜侠と第一種接近遭遇。キスのあとの濡れた唇から、上位リンクを３つ得る',
                    '昔の恋人がそれに詳しかったはず。その日の深夜・早朝に行動しなければ、好きなタグの上位リンク（SL+2）を１つ得る',
                    '情報はともかくトリコをゲット。データは「女子高生（p.122）」を使用する',
                    '関係者とすてきな時間を過ごす。好きなタグの上位リンクを１つ得る。ただし、次の１ターンは行動できない',
                    '持つべきものは愛の奴隷。自分のトリコの数だけ好きなタグの上位リンクを得る',
                    '自分よりも１０歳年上のイヤなやつに身体を売る。現在と同じタグの上位リンクを１つ得る',
                    '有力者からの突然のご指名。チームの仲間を１人、ランダムに決定する。差し出すなら、そのキャラクターは次の１ターン行動できない代わり、その後にそのキャラクターの〔恋愛〕と同じ数の上位リンクを得る',
                    '愛する人の死。自分に恋人がいれば、１人選んで、そのキャラクターを死亡させる。その代わり情報ゲット！',
                );
                $name = "情報イベント表／〔恋愛〕:";
            } elsif($type =~ /CultureIET/i) {
                #情報イベント表／〔教養〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    'ネットで幻のリンクサイトを発見。すべての種類のタグに上位リンクがはられる',
                    '間違いメールから恋が始まる。ハンドルしか知らない「女子高生（p.122）」と恋人（お互いのトリコ）の関係になる',
                    '新聞社でバックナンバーを読みふける。上位リンクを６つ得る',
                    '巨大な掲示板群から必要な情報をサルベージ。好きなタグの上位リンクを１つ得る',
                    '検索エンジンにかけたらすぐヒット。コストを消費せず、上位リンクを４つ得る',
                    '警察無線を傍受。興味深い。好きなタグの上位リンクを２つ得る',
                    'クールな推理がさえ渡る。〔精神点〕を好きなだけ消費する。その値と同じ数だけ好きなタグの上位リンクを得る',
                    '図書館ロールが貫通。好きなタグの上位リンク（SL+3)を１つ得る',
                    '図書館で幻の書物を発見。上位リンクを８つ得る。キャラクターシートのメモ欄に<クトゥルフ神話知識>、SANと記入し、それぞれ後ろに＋５、－５の数値を書き加える',
                    'アジトに謎の手紙が届く。自分のアジトに戻れば、情報ゲット！',
                );
                $name = "情報イベント表／〔教養〕:";
            } elsif($type =~ /CombatIET/i) {
                #情報イベント表／〔戦闘〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '昔、お前が『更正』させた大幇のチンピラから情報を得る。〔精神点〕を２点減少し、好きなタグの上位リンク（SL+2）を１つ得る。',
                    '大阪市警の刑事から情報リーク。「敵の敵は味方」ということか……？　〔精神点〕を３点減少し、上位リンクを６つ得る。',
                    '無軌道な若者達を拳で『更正』させる。彼等は涙を流しながら情報を差し出した。……情けは人のためならず。好きなだけ〔精神点〕を減少する。減少した値と同じ数だけ、上位リンクを得る。',
                    'クスリ漬けの流氓を拳で『説得』。流氓はゲロと一緒に情報を吐き出した。２点のダメージ（セーブ不可）を受け、好きなタグの上位リンクを１つ得る。',
                    '次から次へと糞どもがやってくる。コストを消費せずに上位リンクを３つ得る。',
                    '自称『善良な一市民』からの情報リークを受ける。オマエの持っている異能の数だけ上位リンクを得る。……罠か！？',
                    'サウナ風呂でくつろぐヤクザから情報収集。ヤクザは歯の折れた口から、弱々しい呻きと共に情報を吐き出した。好きなだけダメージを受ける（セーブ不可）。好きなタグの受けたダメージと同じ値のSLへリンクを１つ得る。',
                    'ゼロ・トレランスオンスロートなラブ＆ウォー。2D6を振り、その値が現在の〔肉体点〕以上であれば、情報をゲット！',
                    'お前達を狙う刺客が冥土の土産に教えてくれる。お前自身かチームの仲間、お前の恋人のいずれかの〔肉体点〕を０点にすれば、情報をゲットできる。',
                    'お前の宿敵（データはブラックアドレス）が1D6体現れる。血戦によって相手を倒せば、情報ゲット。',
                );
                $name = "情報イベント表／〔戦闘〕:";
            } elsif($type =~ /CrimeIHT/i) {
                #情報ハプニング表／〔犯罪〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '警官からの職務質問。一晩拘留される。臭い飯表（p.70）を１回振ること',
                    'だますつもりがだまされる。〔サイフ〕を１点消費',
                    '気のゆるみによる駐車違反。持っている乗物が無くなってしまう',
                    '超えてはならない一線を越える。トラウマを１点受ける',
                    'そのトピックを取りしきる盟約に目をつけられる。このトピックと同じタグのトピックからはリンクをはれなくなる',
                    '過去の亡霊がきみを襲う。自分の修得している異能の中から好きな１つを選ぶ。このセッションでは、その異能が使用不可になる',
                    '敵対する盟約のいざこざに巻き込まれる。〔肉体点〕に1D6点のセーブ不可なダメージを受ける',
                    'スリにあう。〔通常装備〕からランダムにアイテムを１個選び、それを無くす',
                    '敵対する盟約からの妨害工作。この情報は情報収集のルールを使って手に入れることはできなくなる',
                    '頼れる協力者のもとへ行くと、彼（彼女）の無惨な姿が……自分の持っている現在のセッションに参加していないキャラクター１体を選び、〔肉体点〕を０にする。そして、致命傷表(p.61）を振ること',
                );
                $name = "情報ハプニング表／〔犯罪〕:";
            } elsif($type =~ /LifeIHT/i) {
                #情報ハプニング表／〔生活〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '経理の整理に没頭。この日の行動をすべてそれに費やさない限り、このセッションでは買物を行えなくなる',
                    '壮大なる無駄使い。〔サイフ〕を１点消費',
                    '「当たり屋(p.124）」が【追跡】を開始',
                    '留守の間に空き巣が！　〔アジト装備〕からランダムにアイテムが１個無くなる',
                    '「押し売り(p.124）」が【追跡】を開始',
                    '新たな風を感じる。自分の好きな〔趣味〕１つをランダムに変更すること',
                    '貧乏ひまなし。［1D6－自分の〔生活〕］ターンの間、行動できなくなる',
                    '留守の間にアジトが火事に！　〔アジト装備〕がすべて無くなる。明日からどうしよう？',
                    '頼りにしていた有力者が失脚する。しわ寄せがこっちにもきて、〔生活〕が１点減少する',
                    '覚えのない借金の返済を迫られる。〔サイフ〕を1D6点減らす。〔サイフ〕が足りない場合、そのセッション終了時までに不足分を支払わないと【借金大王】(p.119）の代償を得る',
                );
                $name = "情報ハプニング表／〔生活〕:";
            } elsif($type =~ /LoveIHT/i) {
                #情報ハプニング表／〔恋愛〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '一晩を楽しむが相手はちょっと特殊な趣味だった。アブノーマルの趣味を持っていない限り、トラウマを１点受ける。この日はもう行動できない',
                    '一晩を楽しむが相手はちょっと特殊な趣味だった。【両刀使い】の異能を持っていない限り、トラウマを１点受ける。この日はもう行動できない',
                    '一晩を楽しむが相手は年齢を10偽っていた。ロマンス判定のファンブル表を振ること',
                    'すてきな人を見かけ、一目惚れ。DDが選んだNPC１体のトリコになる',
                    '「痴漢・痴女(p.124）」が【追跡】を開始',
                    '手を出した相手が有力者の女（ヒモ）だった。手下どもに袋叩きに会い、1D6点のダメージを受ける（セーブ不可）',
                    '突然の別れ。トリコ欄からランダムに１体を選び、その名前を消す',
                    '乱れた性生活に疲れる。〔肉体点〕と〔精神点〕がともに２点減少する',
                    '性病が伝染る。１日以内に病院に行き、治療（価格４）を行わないと、鼻がもげる。鼻がもげると〔恋愛〕が１点減少する',
                    '生命の誕生。子供ができる',
                );
                $name = "情報ハプニング表／〔恋愛〕:";
            } elsif($type =~ /CultureIHT/i) {
                #情報ハプニング表／〔教養〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    'アヤシイ書物を読み、一時的発狂。この日はもう行動できない。トラウマを１点受ける',
                    '天才ゆえの憂鬱。自分の〔教養〕と同じ値だけ、〔精神点〕を減少させる',
                    '唐突に睡魔が。次から２ターンの間、睡眠しなくてはならない',
                    '間違いメールから恋が始まる。ハンドルしか知らない「女子高生（p.122）」に偽装した「殺人鬼（p.137）」と恋人（お互いのトリコ）の関係になる',
                    '「勧誘員(p.124）」が【追跡】を開始',
                    'OSの不調。徹夜で再インストール。この日はもう行動できない上、「無理」をしてしまう',
                    '場を荒らしてしまう。このトピックと同じタグのトピックからはリンクをはれなくなる',
                    'ボケる。〔教養〕が１点減少する',
                    'クラッキングに遭う。いままで調べていたトピックとリンクをすべて失う',
                    'ネットサーフィンにハマってしまい、ついつい時間が過ぎる。毎ターンのはじめに〔性業値〕判定を行い、律にならないとそのターンは行動できない。この効果は１日続く',
                );
                $name = "情報ハプニング表／〔教養〕:";
            } elsif($type =~ /CombatIHT/i) {
                #情報ハプニング表／〔戦闘〕
                @table = (
                    '謎の情報屋チュンさん登場。ターゲットとなる情報を渡し、いずこかへ去る。情報ゲット！',
                    '悪を憎む心に支配され、一匹の修羅と化す。キジルシの代償から１種類を選び、このセッションの間、習得すること。修得できるキジルシの代償がなければ、あなたはNPCとなる。',
                    '自宅に帰ると、無惨に破壊された君のおたからが転がっていた。「この件から手を引け」という書き置きと共に……。この情報フェイズでは、リンク判定を行ったトピックのタグの〔趣味〕を修得していた場合、それを未修得にする。また、おたからを持っていたなら、このセッション中、そのおたからは利用できなくなる。',
                    '「俺にはもっと別の人生があったんじゃないだろうか……！？」突如、空しさがこみ上げて来る……その日は各ターンの始めに〔性業値〕判定を行う。失敗すると、酒に溺れ、そのターンは行動済みになる。',
                    'クライムファイター仲間からスパイの容疑を受ける……１点のトラウマを追う。',
                    '自宅の扉にメモが……！！　「今ならまだ間に合う」奴等はどこまで知っているんだ！？　このトピックからは、これ以上リンクを伸ばせなくなる。',
                    '大幇とコンビナートの抗争に何故か巻き込まれる。……なんとか生還するが、次のターンの最後まで行動できず、1D6点のダメージを受ける（セーブ不可）',
                    '地獄組の鉄砲玉が君に襲い掛かってきた！！　〔戦闘〕で難易度９の判定に失敗すると、〔肉体点〕が０になる。',
                    '「お前はやり過ぎた」の書きおきと共に、友人の死体が発見される〔戦闘〕で難易度９の判定を行う。失敗すると、ランダムに選んだチームの仲間１人が死亡する。',
                    '宿敵によって深い疵を受ける。自分の修得している異能の中から、１つ選ぶこと。このセッションのあいだ、その異能を使用することができなくなる。',
                    '流氓の男の卑劣な罠にかかり、肥え喰らいの巣に落ちる！！　「掃き溜めの悪魔」1D6体と血戦を行う。戦いに勝たない限り、生きて帰ることはできないだろう……。もちろん血戦に勝ったところで情報は得られない。',
                );
                $name = "情報ハプニング表／〔戦闘〕:";
            } elsif($type =~ /G(eneral)?A(ccident)?T/i) {
                #汎用アクシデント表
                @table = (
                    '痛恨のミス。激しく状況が悪化する。以降のケチャップに関する行為判定の難易度に＋１の修正がつき、あなたが追う側なら逃げる側のコマを２マス進める（逃げる側なら自分を２マス戻す）',
                    '最悪の大事故。ケチャップどころではない！　〔犯罪〕で難易度９の判定を行う。失敗したら、ムーブ判定を行ったキャラクターは3D6天のダメージを受け、ケチャップから脱落する。判定に成功すればギリギリ難を逃れる。特に何もなし。',
                    'もうダメだ……。絶望感が襲いかかってくる。後３ラウンド以内にケリをつけないと、あなたが追う側なら自動的に逃げる側が勝利する（逃げる側なら追う側が勝利する）',
                    'まずい、突発事故だ！　ムーブ判定を行ったキャラクターは、1D6点のダメージを受ける。',
                    '一瞬ひやりと緊張が走る。　ムーブ判定を行ったキャラクターは、〔精神点〕を２点減少する。',
                    'スランプ！　思わず足踏みしてしまう。ムーブ判定を行った者は、ムーブ判定に使用した能力値を使って難易度７の判定を行うこと。失敗したら、ムーブ判定を行ったキャラクターは、ケチャップから脱落。成功しても、あなたが追う側なら逃げる側のコマを１マス進める（逃げる側なら自分を１マス戻す）',
                    'イマイチ集中できない。〔性業値〕判定を行うこと。「激」になると、思わず見とれてしまう。あなたが追う側なら逃げる側のコマを１マス進める（逃げる側なら自分を１マス戻す）',
                    '古傷が痛み出す。以降のケチャップに関する行為判定に修正が＋１つく',
                    'うっかり持ち物を見失う。〔通常装備〕欄からアイテムを１個選んで消す',
                    '苦しい状態に追い込まれた。ムーブ判定を行ったキャラクターは、今後のムーブ判定で成功度が－１される。',
                    '頭の中が真っ白になる。〔精神点〕を1D6減少する。',
                );
                $name = "汎用アクシデント表:";
            } elsif($type =~ /R(omance)?F(umble)?T/i) {
                #ロマンスファンブル表
                @table = (
                    'みんなあいそをつかす。自分のトリコ欄のキャラクターの名前をすべて消すこと',
                    '痴漢として通報される。〔犯罪〕の難易度９の判定に成功しない限り、1D6ターン後に検挙されてしまう',
                    'へんにつきまとわれる。対象は、トリコになるが、ファンブル表の結果やトリコと分かれる判定に成功しない限り、常備化しなくてもトリコ欄から消えることはない',
                    '修羅場！　対象とは別にトリコを所有していれば、そのキャラクターが現れ、あなたと対象に血戦をしかけてくる',
                    '恋に疲れる。自分の〔精神点〕が1D6点減少する',
                    '甘い罠。あなたが対象のトリコになってしまう',
                    '平手うち！　自分の〔肉体点〕が1D6点減少する',
                    '浮気がばれる。恋人関係にあるトリコがいれば、そのキャラクターの名前をあなたのトリコ欄から消す',
                    '無礼な失言をしてしまう。対象はあなたに対し「憎悪（p.120参照）」の反応を抱き、あなたはその対象の名前を書き込んだ【仇敵】の代償を得る',
                    'ショックな一言。トラウマを１点受ける',
                    'トリコからの監視！　このセッションの間、ロマンス判定のファンブル率が自分のトリコの所持数と同じだけ上昇する',
                );
                $name = "ロマンスファンブル表:";
            } elsif($type =~ /FumbleT/i) {
                #命中判定ファンブル表
                @table = (
                    '自分の持ち物がすっぽぬけ、偶然敵を直撃！　持っているアイテムを１つ消し、ジオラマ上にいるキャラクター１人をランダムに選ぶ。そのキャラクターの〔肉体点〕を1D6ラウンドの間０点にし、行動不能にさせる（致命傷表は使用しない）。1D6ラウンドが経過し、行動不能から回復すると、そのキャラクターの〔肉体点〕は、行動不能になる直前の値にまで回復する',
                    '敵の増援！　「三下(p.125）」が1D6体現れて、自分たちに襲いかかってくる（DDは、この処理が面倒だと思ったら、ファンブルしたキャラクターの〔肉体点〕を1D6点減少させてもよい）',
                    'お前のいるマスに「障害物」が出現！　そのマスに障害物オブジェクトを置き、そのマスにいたキャラクターは全員２ダメージを受ける（セーブ不可）',
                    '射撃武器を使っていれば、弾切れを起こす。準備行動を行わないとその武器はもう使えない',
                    '転んでしまう。準備行動を行わないと移動フェイズに行動できず、格闘、射撃、突撃攻撃が行えない',
                    '急に命が惜しくなる。性業値判定をすること。「激」なら戦闘を続行。「律」なら次のラウンドから全力移動を行い、ジオラマから逃走を試みる。「迷」なら次のラウンドは移動・攻撃フェイズに行動できない',
                    '誤って別の目標を攻撃。目標以外であなたに一番近いキャラクターに４ダメージ（セーブ不可）！',
                    '誤って自分を攻撃。３ダメージ（セーブ不可）！',
                    '今使っている武器が壊れる。アイテム欄から使用中の武器を消すこと。銃器を使っていた場合、暴発して自分に６ダメージ！　武器なしの場合、体を傷つけ３ダメージ（共にセーブ不可）！',
                    '「制服警官(p.129）」が１人現れる。その場にいるキャラクターをランダムに攻撃する',
                    '最悪の事態。〔肉体点〕を０にして、そのキャラクターは行動不能に（致命傷表は使用しない）',
                );
                $name = "命中判定ファンブル表:";
            } elsif($type =~ /FatalT/i) {
                #致命傷表（別名１４番表）
                @table = (
                    '死亡。',
                    '死亡。',
                    '昏睡して行動不能。1D6ラウンド以内に治療し、〔肉体点〕を１以上にしないと死亡。',
                    '昏睡して行動不能。1D6ターン以内に治療し、〔肉体点〕を１以上にしないと死亡。',
                    '大怪我で行動不能。体の部位のどこかを欠損してしまう。任意の〔能力値〕１つが１点減少。',
                    '大怪我で行動不能。1D6ターン以内に治療し、〔肉体点〕を１以上にしないと体の部位のどこかを欠損してしまう。任意の〔能力値〕１つが１点減少。',
                    '気絶して行動不能。〔肉体点〕の回復には治療が必要。',
                    '気絶して行動不能。１ターン後、〔肉体点〕が１になる。',
                    '気絶して行動不能。1D6ラウンド後、〔肉体点〕が１になる。',
                    '気絶して行動不能。1D6ラウンド後、〔肉体点〕が1D6回復する。',
                    '奇跡的に無傷。さきほどのダメージを無効に。',
                );
                $name = "致命傷表:";
            } elsif($type =~ /AccidentT/i) {
                #アクシデント表
                @table = (
                    'ゴミか何かが降ってきて、視界を塞ぐ。以降のケチャップに関する判定に修正が＋１つく。あなたが追う側なら逃げる側のコマを２マス進める（逃げる側なら自分を２マス戻す）',
                    '対向車線の車（もしくは他の船、飛行機）に激突しそうになる。運転手は難易度９の〔精神〕の判定を行うこと。失敗したら、乗物と乗組員全員は3D6のダメージを受けた上に、ケチャップから脱落',
                    'ヤバイ、ガソリンがもうない！　後３ラウンド以内にケリをつけないと逃げられ（追いつかれ）ちまう',
                    '露店や消火栓につっこむ。その乗物に1D6ダメージ',
                    '一瞬ひやりと緊張が走る。〔精神点〕を２点減らす',
                    '何かの障害物に衝突する。運転手は難易度７の〔精神〕の判定を行うこと。失敗したら、乗物と乗組員全員は2D6ダメージを受けた上に、ケチャップから脱落。成功しても、あなたが追う側なら逃げる側のコマを１マス進める（逃げる側なら自分を１マス戻す）',
                    '走ってる途中に〔趣味〕に関する何かが目に映る。性業値判定を行うこと。「激」になると思わず見とれてしまう。あなたが追う側なら逃げる側のコマを１マス進める（逃げる側なら自分を１マス戻す）',
                    '軽い故障が起きちまった。以降のケチャップに関する行為判定に修正が＋１つく',
                    'うっかり落し物。〔通常装備〕欄からアイテムを１個選んで消す',
                    'あやうく人にぶつかりそうになる。運転手は難易度９の〔精神〕の判定を行う。失敗したら、その一般人を殺してしまう。あなたが追う側なら逃げる側のコマを１マス進める（逃げる側なら自分を１マス戻す）',
                    '信号を無視しちまったら後ろで事故が起きた。警察のサイレンが鳴り響いてくる。DDはケチャップの最後尾に警察の乗物を加えろ。データは「制服警官（p.129）」のものを使用',
                );
                $name = "アクシデント表:";
            } elsif($type =~ /AfterT/i) {
                #その後表
                @table = (
                    'ここらが潮時かもしれない。2D6を振り、その目が自分の修得している代償未満であれば、そのキャラクターは引退し、二度と使用できない',
                    '苦労の数だけ喜びもある。2D6を振り、自分の代償の数以下の目を出した場合、経験点が追加で１点もらえる',
                    '妙な恨みを買ってしまった。【仇敵】（p.95）を修得する。誰が【仇敵】になるかは、DDが今回登場したNPCの中から１人を選ぶ',
                    '大物の覚えがめでたい。今回のセッションに登場した盟約へ入るための条件を満たしていれば、その盟約に経験点の消費なしで入ることができる',
                    '思わず意気投合。今回登場したNPC１人を選び、そのキャラクターとの【コネ】（p.95）を修得する',
                    '今回の事件で様々な教訓を得る。自分の修得しているアドバンスドカルマの中から、汎用以外のものを好きなだけ選ぶ。そのカルマの異能と代償を、別な異能と代償に変更することができる',
                    '深まるチームの絆。今回のセッションでミッションが成功していた場合、【絆】（p.95）を修得する',
                    '色々な運命を感じる。今回のセッションでトリコができていた場合、経験点の消費なしにそのトリコを常備化することができる。また、自分が誰かのトリコになっていた場合、その人物への【トリコ】(p.95）の代償を得る',
                    'やっぱり亜侠も楽じゃないかも。今回のセッションで何かツラい目にあっていた場合、【日常】（p.95）を取得する',
                    'くそっ！　ここから出せ！！　今回のセッションで逮捕されていたら、【前科】(p.95）の代償を得る',
                    '〔性業値〕が１以下、もしくは１３以上だった場合、そのキャラクターは大阪の闇に消える。そのキャラクターは引退し、二度と使用できない',
                );
                $name = "その後表:";
            }
            if($name) {
                for(my $i = 0; $i < $counts; $i++) {
                    my($dice, $dummy) = &roll(2, 6);
                    push @output, $name.$dice.":".$table[$dice - 2];
                }
            }
        }

        #1d6
        if($type eq "NPCT") {
            #好み／雰囲気表
            my @lmood = (
                'ダークな',
                'お金持ちな',
                '美形な',
                '知的な',
                'ワイルドな',
                'バランスがとれてる',
            );
            #好み／年齢表
            my @lage = (
                '年下が好き。',
                '同い年が好き。',
                '年上が好き。',
            );
            #年齢表
            my @age = (
                '幼年', #6+2D6歳
                '少年', #10+2D6歳
                '青年', #15+3D6歳
                '中年', #25+4D6歳
                '壮年', #40+5D6歳
                '老年', #60+6D6歳
            );
            my @agen = (
                '6+2D6',  #幼年
                '10+2D6', #少年
                '15+3D6', #青年
                '25+4D6', #中年
                '40+5D6', #壮年
                '60+6D6', #老年
            );
            $name = "NPC表:";
            for(my $i = 0; $i < $counts; $i++) {
                my $age_type = int(rand 6);
                my @age_num = split /\+/, $agen[$age_type];
                my ($total, $dummy) = &dice_mul($age_num[1]);
                my $ysold = $total + $age_num[0];
                push @output, $name.$age[$age_type]."(".$ysold."):".$lmood[int(rand 6)].$lage[int(rand 3)];
            }
        }
    }
    return @output;
}

####################         ダークブレイズ        ########################
#** 掘り出し袋表
sub dark_blaze_horidasibukuro_table {
    my $dice = $_[0];
    my $output = '1';
    
    my @material_kind = (   #2D6
        "蟲甲",     #5
        "金属",     #6
        "金貨",     #7
        "植物",     #8
        "獣皮",     #9
        "竜鱗",     #10
        "レアモノ", #11
        "レアモノ", #12
    );
    my @magic_stone = ( #1D3
        "火炎石",
        "雷撃石",
        "氷結石",
    );
    my ($num1, $dmy) = &roll(2, 6);
    my ($num2, $dmy2) = &roll($dice, 6);
    if($num1 <= 4) {
        ($num2, $dmy2) = &roll(1, 6);
        $output = '《'.$magic_stone[int($num2 / 2) - 1].'》を'.$dice.'個獲得';
    } elsif($num1 == 7) {
        $output = '《金貨》を'.$num2.'枚獲得';
    } else {
        my $type = $material_kind[$num1 - 5];
        if($num2 <= 3) {
            $output = '《'.$type.' I》を1個獲得';
        } elsif($num2 <= 5) {
            $output = '《'.$type.' I》を2個獲得';
        } elsif($num2 <= 7) {
            $output = '《'.$type.' I》を3個獲得';
        } elsif($num2 <= 9) {
            $output = '《'.$type.' II》を1個獲得';
        } elsif($num2 <= 11) {
            $output = '《'.$type.' I》を2個《'.$type.' II》を1個獲得';
        } elsif($num2 <= 13) {
            $output = '《'.$type.' I》を2個《'.$type.' II》を2個獲得';
        } elsif($num2 <= 15) {
            $output = '《'.$type.' III》を1個獲得';
        } elsif($num2 <= 17) {
            $output = '《'.$type.' II》を2個《'.$type.' III》を1個獲得';
        } else {
            $output = '《'.$type.' II》を2個《'.$type.' III》を2個獲得';
        }
    }
    $output = "$_[1]: 掘り出し袋表[${num1},${num2}] ＞ $output" if($output ne '1');

    return $output;
}

####################         ガンドッグゼロ        ########################
sub gundogzero_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my @table;
    my $ttype = "";
    my $type = "";
    my $dice = 0;
    my $mod = 0;

    if($game_type eq "GundogZero") {
        # ダメージペナルティ表
        if($string =~ /(\w)DPT([\+\-\d]*)/i) {
            $ttype = 'ダメージペナルティー';
            my $sel = $1;
            $mod = parren_killer("(0".$2.")") if($2);
            if($sel eq "S") {
                $type = '射撃';
            } elsif($sel eq "M") {
                $type = '格闘';
            } elsif($sel eq "V") {
                $type = '車両';
            } elsif($sel eq "G") {
                $type = '汎用';
            } else {
                $type = '射撃'; # 間違ったら射撃扱い
            }
            # 射撃ダメージペナルティー表
            if($type eq "射撃") {
                @table = (
                    '対象は[死亡]',                                     #0
                    '[追加D]4D6/[出血]2D6/[重傷]-30％/[朦朧判定]15',    #1
                    '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]14',    #2
                    '[追加D]3D6/[出血]2D6/[重傷]-20％/[朦朧判定]14',    #3
                    '[追加D]3D6/[出血]1D6/[重傷]-20％/[朦朧判定]12',    #4
                    '[追加D]2D6/[出血]1D6/[重傷]-10％/[朦朧判定]12',    #5
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]10',              #6
                    '[追加D]2D6/[軽傷]-10％/[朦朧判定]10',              #7
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]8',               #8
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]6',               #9
                    '[追加D]2D6/[軽傷]-10％/[朦朧判定]4',               #10
                    '[追加D]1D6/[軽傷]-20％',                           #11
                    '[追加D]1D6/[軽傷]-20％',                           #12
                    '[追加D]1D6/[軽傷]-10％',                           #13
                    '[軽傷]-20％',                                      #14
                    '[軽傷]-10％',                                      #15
                    '[軽傷]-10％',                                      #16
                    '手に持った武器を落とす',                           #17
                    'ペナルティー無し',                                 #18
                );
            }
            # 格闘ダメージペナルティー表
            elsif($type eq "格闘") {
                @table = (
                    '対象は[死亡]',                                     #0
                    '[追加D]3D6/[出血]2D6/[重傷]-30％/[朦朧判定]15',    #1
                    '[追加D]2D6/[出血]2D6/[重傷]-30％/[朦朧判定]14',    #2
                    '[追加D]2D6/[出血]1D6/[重傷]-20％/[朦朧判定]14',    #3
                    '[追加D]3D6/[出血]1D6/[重傷]-10％/[朦朧判定]12',    #4
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]12',              #5
                    '[追加D]2D6/[軽傷]-10％/[朦朧判定]12',              #6
                    '[追加D]2D6/[軽傷]-10％/[朦朧判定]10',              #7
                    '[追加D]1D6/[軽傷]-20％/[朦朧判定]8',               #8
                    '[追加D]1D6/[軽傷]-10％/[朦朧判定]8',               #9
                    '[追加D]1D6/[軽傷]-10％/[朦朧判定]6',               #10
                    '[軽傷]-20％/[朦朧判定]6',                          #11
                    '[軽傷]-10％/[朦朧判定]6',                          #12
                    '[軽傷]-10％/[朦朧判定]4',                          #13
                    '[軽傷]-20％',                                      #14
                    '[軽傷]-10％',                                      #15
                    '[軽傷]-10％',                                      #16
                    '手に持った武器を落とす',                           #17
                    'ペナルティー無し',                                 #18
                );
            }
            # 車両ダメージペナルティー表
            elsif($type eq "車両") {
                @table = (
                    '[クラッシュ]する。[チェイス]から除外',             #0
                    '[乗員D]3D6/[操縦性]-20％/[スピン判定]',            #1
                    '[乗員D]3D6/[操縦性]-20％/[スピン判定]',            #2
                    '[乗員D]2D6/[操縦性]-10％/[スピン判定]',            #3
                    '[乗員D]2D6/[操縦性]-10％/[スピン判定]',            #4
                    '[乗員D]3D6/[スピード]-2/[スピン判定]',             #5
                    '[乗員D]3D6/[スピード]-2/[スピン判定]',             #6
                    '[乗員D]2D6/[スピード]-1/[スピン判定]',             #7
                    '[乗員D]2D6/[スピード]-1/[スピン判定]',             #8
                    '[乗員D]2D6/[操縦判定]-20％',                       #9
                    '[乗員D]2D6/[操縦判定]-20％',                       #10
                    '[乗員D]1D6/[操縦判定]-10％',                       #11
                    '[乗員D]1D6/[操縦判定]-10％',                       #12
                    '[スピン判定]',                                     #13
                    '[スピン判定]',                                     #14
                    '乗員に[ショック]-20％',                            #15
                    '乗員に[ショック]-10％',                            #16
                    '乗員に[ショック]-10％',                            #17
                    'ペナルティー無し',                                 #18
                );
            }
            # 汎用ダメージペナルティー表
            elsif($type eq "汎用") {
                @table = (
                    '対象は[死亡]',                                     #0
                    '[追加D]4D6/[出血]2D6/[重傷]-30％/[朦朧判定]18',    #1
                    '[追加D]4D6/[出血]2D6/[重傷]-30％/[朦朧判定]16',    #2
                    '[追加D]3D6/[出血]2D6/[重傷]-20％/[朦朧判定]14',    #3
                    '[追加D]3D6/[出血]2D6/[重傷]-20％/[朦朧判定]14',    #4
                    '[追加D]3D6/[出血]1D6/[重傷]-10％/[朦朧判定]12',    #5
                    '[追加D]2D6/[出血]1D6/[重傷]-10％/[朦朧判定]12',    #6
                    '[追加D]2D6/[軽傷]-30％/[朦朧判定]12',              #7
                    '[追加D]2D6/[軽傷]-30％/[朦朧判定]10',              #8
                    '[追加D]2D6/[軽傷]-30％/[朦朧判定]8',               #9
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]8',               #10
                    '[追加D]2D6/[軽傷]-20％/[朦朧判定]6',               #11
                    '[追加D]2D6/[軽傷]-10％/[朦朧判定]6',               #12
                    '[追加D]1D6/[軽傷]-20％/[朦朧判定]4',               #13
                    '[追加D]1D6/[軽傷]-20％',                           #14
                    '[追加D]1D6/[軽傷]-10％',                           #15
                    '[軽傷]-20％',                                      #16
                    '[軽傷]-10％',                                      #17
                    'ペナルティー無し',                                 #18
                );
            }
        }

        # ファンブル表
        if($string =~ /(\w)FT([\+\-\d]*)/i) {
            $ttype = 'ファンブル';
            my $sel = $1;
            $mod = parren_killer("(0".$2.")") if($2);
            if($sel eq "S") {
                $type = '射撃';
            } elsif($sel eq "M") {
                $type = '格闘';
            } elsif($sel eq "T") {
                $type = '投擲';
            } else {
                $type = '射撃'; # 間違ったら射撃扱い
            }
            # 射撃ファンブル表
            if($type eq "射撃") {
                @table = (
                    '銃器が暴発、自分に命中。[貫通D]',                  #0
                    '銃器が暴発、自分に命中。[非貫通D]',                #1
                    '誤射。ランダムに味方に命中。[貫通D]',              #2
                    '誤射。ランダムに味方に命中。[非貫通D]',            #3
                    '銃器が完全に故障',                                 #4
                    '銃器が完全に故障',                                 #5
                    '故障。〈メカニック〉判定に成功するまで射撃不可',   #6
                    '故障。〈メカニック〉判定に成功するまで射撃不可',   #7
                    '作動不良。[アイテム使用]を2回行って修理するまで射撃不可',  #8
                    '作動不良。[アイテム使用]を2回行って修理するまで射撃不可',  #9
                    '作動不良。[アイテム使用]を行って修理するまで射撃不可', #10
                    '作動不良。[アイテム使用]を行って修理するまで射撃不可', #11
                    '姿勢を崩す。[不安定]',                             #12
                    '姿勢を崩す。[不安定]',                             #13
                    '姿勢を崩す。[ショック]-20％',                      #14
                    '姿勢を崩す。[ショック]-20％',                      #15
                    '姿勢を崩す。[ショック]-10％',                      #16
                    '姿勢を崩す。[ショック]-10％',                      #17
                    'ペナルティー無し',                                 #18
                );
            }
            # 格闘ファンブル表
            elsif($type eq "格闘") {
                @table = (
                    '避けられて[転倒]、[朦朧]状態',                     #0
                    'ランダムに[至近距離]の味方(居なければ自分)に命中。[貫通D]',    #1
                    'ランダムに[至近距離]の味方(居なければ自分)に命中。[貫通D]',    #2
                    '武器が完全に壊れる',                               #3
                    '武器がガタつく。〈手先〉判定に成功するまで使用不可',   #4
                    '武器がガタつく。〈手先〉判定に成功するまで使用不可',   #5
                    '無理な姿勢で筋を伸ばす。[軽傷]-30％',              #6
                    '無理な姿勢で筋を伸ばす。[軽傷]-30％',              #7
                    '無理な姿勢で筋を伸ばす。[軽傷]-20％',              #8
                    '無理な姿勢で筋を伸ばす。[軽傷]-20％',              #9
                    '無理な姿勢で筋を伸ばす。[軽傷]-10％',              #10
                    '無理な姿勢で筋を伸ばす。[軽傷]-10％',              #11
                    '姿勢を崩す。[不安定]',                             #12
                    '姿勢を崩す。[不安定]',                             #13
                    '姿勢を崩す。[ショック]-20％',                      #14
                    '姿勢を崩す。[ショック]-20％',                      #15
                    '姿勢を崩す。[ショック]-10％',                      #16
                    '姿勢を崩す。[ショック]-10％',                      #17
                    'ペナルティー無し',                                 #18
                );
            }
            # 投擲ファンブル表
            elsif($type eq "投擲") {
                @table = (
                    '[転倒]、[朦朧]状態',                               #0
                    '自分に命中。[貫通D]',                              #1
                    '自分に命中。[非貫通D]',                            #2
                    'ランダムに味方(居なければ自分)に命中。[非貫通D]',  #3
                    'ランダムに味方(居なければ自分)に命中。[非貫通D]',  #4
                    '武器が完全に壊れる',                               #5
                    '武器が完全に壊れる',                               #6
                    '腰を痛める。[軽傷]-30％',                          #7
                    '肩を痛める。[軽傷]-20％',                          #8
                    '肩を痛める。[軽傷]-20％',                          #9
                    '肘に違和感。[軽傷]-10％',                          #10
                    '肘に違和感。[軽傷]-10％',                          #11
                    '姿勢を崩す。[不安定]',                             #12
                    '姿勢を崩す。[不安定]',                             #13
                    '姿勢を崩す。[ショック]-20％',                      #14
                    '姿勢を崩す。[ショック]-20％',                      #15
                    '姿勢を崩す。[ショック]-10％',                      #16
                    '姿勢を崩す。[ショック]-10％',                      #17
                    'ペナルティー無し',                                 #18
                );
            }
        }
        if($type) {
            $dice = int(rand 10) + int(rand 10) + $mod;
            $output = "$_[1]: ${type}${ttype}表[${dice}] ＞ ";
            $dice = 0 if($dice < 0);
            $dice = 18 if($dice > 18);
            $output .= $table[$dice];
        }
    }

    return $output;
}

####################              TORG             ########################
sub torg_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my $ttype = "";
    my $value = 0;
    
    if($string =~ /([RITMDB]T)(\d+([\+\-]\d+)*)/i) {
        my$type = $1;
        my $num = $2;
        if($type eq 'RT') {
            $value = parren_killer("(0".$num.")");
            $output = &get_torg_success_level($value);
            $ttype = '一般結果';
        }
        elsif($type eq 'IT') {
            $value = parren_killer("(0".$num.")");
            $output = &get_torg_interaction_result_intimidate_test($value);
            $ttype = '威圧/威嚇';
        }
        elsif($type eq 'TT') {
            $value = parren_killer("(0".$num.")");
            $output = &get_torg_interaction_result_taunt_trick($value);
            $ttype = '挑発/トリック';
        }
        elsif($type eq 'MT') {
            $value = parren_killer("(0".$num.")");
            $output = &get_torg_interaction_result_maneuver($value);
            $ttype = '間合い';
        }
        elsif($type eq 'DT') {
            $value = parren_killer("(0".$num.")");
            if($string =~ /ODT/i) {
                $output = &get_torg_damage_ords($value);
                $ttype = 'オーズダメージ';
            } else {
                $output = &get_torg_damage_posibility($value);
                $ttype = 'ポシビリティ能力者ダメージ';
            }
        }
        elsif($type eq 'BT') {
            my @val_arr = split /\+/, $num;
            $value = shift @val_arr;
            my $mod = parren_killer("(0".(join "+", @val_arr).")");
            $output = &get_torg_bonus($value);
            if($mod) {
                if($mod > 0) {
                    $output = $output."[${value}]+${mod} ＞ ".($output + $mod);
                    $value .= "+".$mod;
                } else {
                    $output = $output."[${value}]${mod} ＞ ".($output + $mod);
                    $value .= $mod;
                }
            }
            $ttype = 'ボーナス';
        }
    }
    if($ttype) {
        $output = "$_[1]: ${ttype}表[${value}] ＞ ${output}";
    }
    return $output;
}

#** 一般結果表 成功度
sub get_torg_success_level {
    my $value = shift(@_);
    
    my @success_table = (
        [0, "ぎりぎり"],
        [1, "ふつう"],
        [3, "まあよい"],
        [7, "かなりよい"],
        [12, "すごい" ]);
    
    return &get_torg_table_result( $value, @success_table );
}

#** 対人行為結果表
# 威圧／威嚇(intimidate/Test)
sub get_torg_interaction_result_intimidate_test {
    my $value = shift(@_);
    
    my @interaction_results_table = (
        [0, "技能なし"],
        [5, "萎縮"],
        [10, "逆転負け"],
        [15, "モラル崩壊"],
        [17, "プレイヤーズコール" ]);
    
    return &get_torg_table_result( $value, @interaction_results_table );
}

# 挑発／トリック(Taunt/Trick)
sub get_torg_interaction_result_taunt_trick {
    my $value = shift(@_);
    
    my @interaction_results_table = (
        [0, "技能なし"],
        [5, "萎縮"],
        [10, "逆転負け"],
        [15, "高揚／逆転負け"],
        [17, "プレイヤーズコール" ]);
    
    return &get_torg_table_result( $value, @interaction_results_table );
}

# 間合い(maneuver)
sub get_torg_interaction_result_maneuver {
    my $value = shift(@_);
    
    my @interaction_results_table = (
        [0, "技能なし"],
        [5, "疲労"],
        [10, "萎縮／疲労"],
        [15, "逆転負け／疲労"],
        [17, "プレイヤーズコール" ]);
    
    return &get_torg_table_result( $value, @interaction_results_table );
}

sub get_torg_table_result {
    my $value = shift(@_);
    my @table = @_;
    
    my $output = '1';
    
    foreach my $item_ref (@table) {
        my @item = @$item_ref;
        my $item_index = $item[0];
        
        if( $item_index > $value ) {
            last;
        }
        
        $output = $item[1];
    }
    
    return $output;
}

#**オーズダメージチャート
sub get_torg_damage_ords {
    my $value = shift;
    
    my @damage_table_ords = (
        [0, "1"],
        [1, "O1"],
        [2, "K1"],
        [3, "O2"],
        [4, "O3"],
        [5, "K3"],
        [6, "転倒 K／O4"],
        [7, "転倒 K／O5"],
        [8, "1レベル負傷  K／O7"],
        [9, "1レベル負傷  K／O9"],
        [10, "1レベル負傷  K／O10"],
        [11, "2レベル負傷  K／O11"],
        [12, "2レベル負傷  KO12"],
        [13, "3レベル負傷  KO13"],
        [14, "3レベル負傷  KO14"],
        [15, "4レベル負傷  KO15"]);

    return get_torg_damage($value,
                           4,
                           "レベル負傷  KO15",
                           @damage_table_ords);
}

#**ポシビリティー能力者ダメージチャート
sub get_torg_damage_posibility {
    my $value = shift;
    
    my @damage_table_posibility = (
        [0, "1"],
        [1, "1"],
        [2, "O1"],
        [3, "K2"],
        [4, "2"],
        [5, "O2"],
        [6, "転倒 O2"],
        [7, "転倒 K2"],
        [8, "転倒 K2"],
        [9, "1レベル負傷  K3"],
        [10, "1レベル負傷  K4"],
        [11, "1レベル負傷  O4"],
        [12, "1レベル負傷  K5"],
        [13, "2レベル負傷  O4"],
        [14, "2レベル負傷  KO5"],
        [15, "3レベル負傷  KO5"]);
        
    return get_torg_damage($value, 
                           3,
                           "レベル負傷  KO5",
                           @damage_table_posibility);
}

sub get_torg_damage {
    my $value = shift;
    my $maxDamage = shift;
    my $maxDamageString = shift;
    my @damage_table = @_;
    
    if( $value < 0 ) {
        return '1';
    }
    
    my $table_max_value = $#damage_table;
    
    if( $value <= $table_max_value ) {
        return &get_torg_table_result( $value, @damage_table );
    }
    
    my $over_kill_damage = int(($value - $table_max_value) / 2);
    return ("" . ($over_kill_damage + $maxDamage) . $maxDamageString);
}

sub get_torg_bonus {
    my $value = shift;
    
    my @bonus_table = (
        [1, -12],
        [2, -10],
        [3, -8],
        [5, -5],
        [7, -2],
        [9, -1],
        [11, 0],
        [13, 1],
        [15, 2],
        [16, 3],
        [17, 4],
        [18, 5],
        [19, 6],
        [20, 7]);
    
    my $bonus = &get_torg_table_result( $value, @bonus_table );
    
    if( $value > 20 ) {
        my $over_value_bonus = int(($value - 20) / 5) + 1;
        $bonus += $over_value_bonus;
    }
    
    return $bonus;
}

####################       ハンターズ・ムーン      ########################
sub huntersmoon_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my $type = "";
    my $total_n = "";

    if($game_type eq "HuntersMoon") {
        # ロケーション表
        my $dummy;
        if($string =~ /CLT/i) {
            $type = '都市ロケーション';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_city_location_table($total_n);
        } elsif($string =~ /SLT/i) {
            $type = '閉所ロケーション';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_small_location_table($total_n);
        } elsif($string =~ /HLT/i) {
            $type = '炎熱ロケーション';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_hot_location_table($total_n);
        } elsif($string =~ /FLT/i) {
            $type = '冷暗ロケーション';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_freezing_location_table($total_n);
        }elsif($string =~ /DLT/i) {
            $type = '部位ダメージ決定';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_hit_location_table($total_n);
        }
        # モノビースト行動表
        elsif($string =~ /MAT/i) {
            $type = 'モノビースト行動';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_monobeast_action_table($total_n);
        }
        # 異形アビリティー表
        elsif($string =~ /SAT(\d*)/i) {
            $type = '異形アビリティー';
            my $count = 1;
            $count = $1 if($1);
            ($output, $total_n) = &hm_strange_ability_table($count);
        }
        # 特技ランダム決定表
        elsif($string =~ /TST/i) {
            $type = '指定特技(社会)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_social_skill_table($total_n);
        }
        elsif($string =~ /THT/i) {
            $type = '指定特技(頭部)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_head_skill_table($total_n);
        }
        elsif($string =~ /TAT/i) {
            $type = '指定特技(腕部)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_arm_skill_table($total_n);
        }
        elsif($string =~ /TBT/i) {
            $type = '指定特技(胴部)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_trunk_skill_table($total_n);
        }
        elsif($string =~ /TLT/i) {
            $type = '指定特技(脚部)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_leg_skill_table($total_n);
        }
        elsif($string =~ /TET/i) {
            $type = '指定特技(環境)';
            ($total_n, $dummy) = &roll(2, 6);
            $output = &hm_environmental_skill_table($total_n);
        }
        # 遭遇表
        elsif($string =~ /ET/i) {
            $type = '遭遇';
            ($total_n, $dummy) = &roll(1, 6);
            $output = &hm_encount_table($total_n);
        }
    }
    if($output ne '1') {
        $output = "$_[1]: ${type}表(${total_n}) ＞ $output";
    }
    return $output;
}
#** ロケーション表
sub hm_city_location_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '住宅街/閑静な住宅街。不意打ちに適しているため、ハンターの攻撃判定に+1の修正をつけてもよい。',
        '学校/夜の学校。遮蔽物が多く入り組んだ構造のため、ハンターはブロック判定によって肩代わりしたダメージを1減少してもよい。',
        '駅/人のいない駅。全てのキャラクターがファンブル時に砂利に突っ込んだり伝染に接触しかけることで1D6のダメージを受ける。',
        '高速道路/高速道路の路上。全てのキャラクターが、ファンブル時には走ってきた車に跳ねられて1D6のダメージを受ける。',
        'ビル屋上/高いビルの屋上。ハンターはファンブル時に屋上から落下して強制的に撤退する。命に別状はない',
        '繁華街/にぎやかな繁華街の裏路地。大量の人の気配が近くにあるため、モノビーストが撤退するラウンドが1ラウンド早くなる。決戦フェイズでは特に効果なし。',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
sub hm_small_location_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '地下倉庫/広々とした倉庫。探してみれば色々なものが転がっている。ハンターは戦闘開始時に好きなアイテムを一つ入手してもよい。',
        '地下鉄/地下鉄の線路上。全てのキャラクターが、ファンブル時にはなぜか走ってくる列車に撥ねられて1D6ダメージを受ける。',
        '地下道/暗いトンネル。車道や照明の落ちた地下街。ハンターは、ファンブル時にアイテムを一つランダムに失くしてしまう。',
        '廃病院/危険な廃物がたくさん落ちているため、誰もここで戦うのは好きではない。キャラクター全員の【モラル】を3点減少してから戦闘を開始する。',
        '下水道/人が２人並べるくらいの幅の下水道。メンテナンス用の明かりしかなく、非常に視界が悪いため、ハンターの攻撃判定に-1の修正がつく。',
        '都市の底/都市の全てのゴミが流れ着く場所。広い空洞にゴミが敷き詰められている。この敵対的な環境では、ハンターの攻撃判定に-1の修正がつく。さらにハンターは攻撃失敗時に2ダメージを受ける。',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
sub hm_hot_location_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '温室/植物が栽培されている熱く湿った場所。生命に満ち溢れた様子は、戦闘開始時にハンターの【モラル】を1点増加する。',
        '調理場/調理器具があちこちに放置された、アクションには多大なリスクをともなう場所。全てのキャラクターは、ファンブル時に良くない場所に手をついたり刃物のラックをひっくり返して1D6ダメージを受ける。',
        'ボイラー室/モノビーストは蒸気機関の周囲を好む傾向があるが、ここはうるさくて気が散るうえに暑い。全てのキャラクターは、感情属性が「怒り」の場合、全てのアビリティの反動が1増加する。',
        '機関室/何らかの工場。入り組みすぎて周りを見通せないうえ、配置がわからず出たとこ勝負を強いられる。キャラクター全員が戦闘開始時に「妨害」の変調を発動する。',
        '火事場/事故現場なのかモノビーストの仕業か、あたりは激しく燃え盛っている。ハンターはファンブル時に「炎上」の変調を発動する。',
        '製鉄所/無人ながら稼働中の製鉄所。安全対策が不十分で、溶けた金属の周囲まで近づくことが可能だ。ハンターは毎ラウンド終了時に《耐熱》で行為判定をし、これに失敗すると「炎上」の変調を発動する。',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
sub hm_freezing_location_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '冷凍保管室/食品が氷漬けにされている場所。ここではモノビーストは氷に覆われてしまう。モノビーストは戦闘開始時に「捕縛」の変調を発動する。',
        '墓地/死んだ人々が眠る場所。ここで激しいアクションを行うことは冒涜的だ。全てのキャラクターは感情属性が恐怖の場合、全てのアビリティの反動が１増加する。',
        '魚市場/発泡スチロールの箱に鮮魚と氷が詰まり、コンクリートの床は濡れていて滑りやすい。ハンターはファンブル時に転んで1D6ダメージを受ける。',
        '博物館/すっかり静まり返った博物館で、モノビーストは動物の剥製の間に潜んでいる。紛らわしい展示物だらけであるため、ハンターは攻撃判定に-1の修正を受ける。',
        '空き地/寒風吹きすさぶ空き地。長くいると凍えてしまいそうだ。ハンターはファンブル時に身体がかじかみ、「重傷」の変調を発動する。',
        '氷室/氷で満たされた洞窟。こんな場所が都市にあったとは信じがたいが、とにかくひどく寒い。ハンターは毎ラウンド終了時に《耐寒》で判定し、失敗すると「重傷」の変調を発動する。',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
#** 遭遇表
sub hm_encount_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '獲物/恐怖/あなたはモノビーストの獲物として追い回される。満月の夜でないと傷を負わせることができない怪物相手に、あなたは逃げ回るしかない。',
        '暗闇/恐怖/あの獣は暗闇の中から現れ、暗闇の中へ消えていった。どんなに振り払おうとしても、あの恐ろしい姿の記憶から逃れられない。',
        '依頼/怒り/あなたはモノビーストの被害者の関係者、あるいはハンターや魔術師の組織から、モノビーストを倒す依頼を受けた。',
        '気配/恐怖/街の気配がどこかおかしい。視線を感じたり、物音が聞こえたり・・・だが、獣の姿を捉えることはできない。漠然とした恐怖があなたの心をむしばむ。',
        '現場/怒り/あなたはモノビーストが獲物を捕食した現場を発見した。派手な血の跡が目に焼きつく。こんなことをする奴を生かしてはおけない。',
        '賭博/怒り/あなたの今回の獲物は、最近ハンターの間で話題になっているモノビーストだ。次の満月の夜にあいつを倒せるか、あなたは他のハンターと賭けをした。',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
#** 
sub hm_monobeast_action_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '社会/モノビーストは時間をかけて逃げ続けることで、ダメージを回復しようとしているようだ。部位ダメージを自由に一つ回復する。部位ダメージを受けていない場合、【モラル】が1D6回復する。',
        '頭部/モノビーストはハンターを撒こうとしている。次の戦闘が日暮れ、もしくは真夜中である場合、モノビーストは１ラウンド少ないラウンドで撤退する。次の戦闘が夜明けである場合、【モラル】が2D6増加する。',
        '腕部/モノビーストは若い犠牲者を選んで捕食しようとしている。どうやら力を増そうとしているらしい。セッション終了までモノビーストの攻撃によるダメージは+1の修正がつく。',
        '胴部/モノビーストは別のハンターと遭遇し、それを食べて新しいアビリティを手に入れる！　ランダムに異形アビリティを一つ決定し、修得する。',
        '脚部/モノビーストはハンターを特定の場所に誘導しているようだ。ロケーション表を振り、次の戦闘のロケーションを変更する。そのロケーションで次の戦闘が始まった場合、モノビーストは最初のラウンドに追加行動を１回得る。',
        '環境/モノビーストは移動中に人間の団体と遭遇し、食い散らかす。たらふく食ったモノビーストは【モラル】を3D6点増加させる',
    );
    $output = $table[$num - 1] if($table[$num - 1]);
    return $output;
}
#** 部位ダメージ決定表
sub hm_hit_location_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '脳',
        '利き腕',
        '利き脚',
        '消化器',
        '感覚器',
        '攻撃したキャラクターの任意の部分',
        '口',
        '呼吸器',
        '逆脚',
        '逆腕',
        '心臓',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 異形アビリティー表
sub hm_strange_ability_table {
    my $num = shift;
    my $output = '';
    my $dice = '';
    for(my $i = 0; $i < $num; $i++) {
        my $dice1 = int(rand 6) + 1;
        my $dice2 = int(rand 6) + 1;
        my $sat = &hm_sat($dice1, $dice2);
        if($sat ne '1') {
            $output .= $sat.'/';
            $dice .= $dice1.$dice2.",";
        }
    }
    if($output) {
        chop $output;
        chop $dice;
    } else {
        $output = '1' ;
    }
    return ($output, $dice);
}
sub hm_sat {
    my ($num1, $num2 ) = @_;
    my $output = '1';
    my $num = ($num1 - 1) * 6 + ($num2 - 1);
    my @table = (
        '大牙',
        '大鎌',
        '針山',
        '大鋏',
        '吸血根',
        '巨大化',
        '瘴気',
        '火炎放射',
        '鑢',
        'ドリル',
        '絶叫',
        '粘液噴射',
        '潤滑液',
        '皮膚装甲',
        '器官生成',
        '翼',
        '四肢複製',
        '分解',
        '異言',
        '閃光',
        '冷気',
        '悪臭',
        '化膿歯',
        '気嚢',
        '触手',
        '肉瘤',
        '暗視',
        '邪視',
        '超振動',
        '酸分泌',
        '結晶化',
        '裏腹',
        '融合',
        '嘔吐',
        '腐敗',
        '変色',
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}
#** 指定特技ランダム決定(社会)
sub hm_social_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '怯える',
        '考えない',
        '話す',
        '黙る',
        '売る',
        '伝える',
        '作る',
        '憶える',
        '脅す',
        '騙す',
        '怒る',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 指定特技ランダム決定(頭部)
sub hm_head_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '聴く',
        '感覚器',
        '見つける',
        '反応',
        '閃く',
        '脳',
        '考える',
        '予感',
        '叫ぶ',
        '口',
        '噛む',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 指定特技ランダム決定(腕部)
sub hm_arm_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '操作',
        '殴る',
        '斬る',
        '利き腕',
        '撃つ',
        '掴む',
        '投げる',
        '逆腕',
        '刺す',
        '振る',
        '締める',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 指定特技ランダム決定(胴部)
sub hm_trunk_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '塞ぐ',
        '呼吸器',
        '止める',
        '動かない',
        '受ける',
        '心臓',
        '逸らす',
        'かわす',
        '落ちる',
        '消化器',
        '耐える',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 指定特技ランダム決定(脚部)
sub hm_leg_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '迫る',
        '走る',
        '蹴る',
        '利き脚',
        '跳ぶ',
        '仕掛ける',
        'しゃがむ',
        '逆脚',
        '滑る',
        '踏む',
        '歩く',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#** 指定特技ランダム決定(環境)
sub hm_environmental_skill_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '耐熱',
        '休む',
        '待つ',
        '捕らえる',
        '隠れる',
        '追う',
        'バランス',
        '現れる',
        '追い込む',
        '休まない',
        '耐寒',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

####################         迷宮キングダム        ########################
sub mayokin_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my $type = "";
    my $total_n = "";

    my $dummy;
    # 名前表
    if($string =~ /NAME(\d*)/i) {
        $type = '名前';
        my $count = 1;
        $count = $1 if($1);
        my $names = "";
        for(my $i=0 ; $i < $count; $i++) {
            my ($name, $dice) = &mk_name_table;
            $names .= "[".$dice."]".$name." ";
        }
        $output = $names;
        $total_n = $count;
    }
    # 地名決定表
    elsif($string =~ /PNT(\d*)/i) {
        my $count = 1;
        $count = $1 if($1);
        $type = '地名';
        $output = &mk_pn_decide_table($count);
        $total_n = $count;
    }
    # 風景決定表
    elsif($string =~ /MLT(\d*)/i) {
        my $count = 1;
        $count = $1 if($1);
        $type = '地名';
        $output = &mk_ls_decide_table($count);
        $total_n = $count;
    }
    # デバイスファクトリー
    elsif($string =~ /DFT(\d*)/i) {
        my $count = 1;
        $count = $1 if($1);
        $type = 'デバイスファクトリー';
        $output = &mk_device_factory_table($count);
        $total_n = $count;
    }
    # 散策表(2d6)
    elsif($string =~ /LRT/i) {
        $type = '生活散策';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_life_research_table($total_n);
    } elsif($string =~ /ORT/i) {
        $type = '治安散策';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_order_research_table($total_n);
    } elsif($string =~ /CRT/i) {
        $type = '文化散策';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_calture_research_table($total_n);
    } elsif($string =~ /ART/i) {
        $type = '軍事散策';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_army_research_table($total_n);
    } elsif($string =~ /FRT/i) {
        $type = 'お祭り';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_festival_table($total_n);
    }
    # 休憩表(2D6)
    elsif($string =~ /TBT/i) {
        $type = '才覚休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_talent_break_table($total_n);
    } elsif($string =~ /CBT/i) {
        $type = '魅力休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_charm_break_table($total_n);
    } elsif($string =~ /SBT/i) {
        $type = '探索休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_search_break_table($total_n);
    } elsif($string =~ /VBT/i) {
        $type = '武勇休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_valor_break_table($total_n);
    } elsif($string =~ /FBT/i) {
        $type = 'お祭り休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_festival_break_table($total_n);
    }
    # ハプニング表(2D6)
    elsif($string =~ /THT/i) {
        $type = '才覚ハプニング';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_talent_happening_table($total_n);
    } elsif($string =~ /CHT/i) {
        $type = '魅力ハプニング';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_charm_happening_table($total_n);
    } elsif($string =~ /SHT/i) {
        $type = '探索ハプニング';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_search_happening_table($total_n);
    } elsif($string =~ /VHT/i) {
        $type = '武勇ハプニング';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_valor_happening_table($total_n);
    }
    # お宝表
    elsif($string =~ /MPT/i) {
        $type = '相場';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_market_price_table($total_n);
    } elsif($string =~ /T1T/i) {
        $type = 'お宝１';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_treasure1_table($total_n);
    } elsif($string =~ /T2T/i) {
        $type = 'お宝２';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_treasure2_table($total_n);
    } elsif($string =~ /T3T/i) {
        $type = 'お宝３';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_treasure3_table($total_n);
    } elsif($string =~ /T4T/i) {
        $type = 'お宝４';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_treasure4_table($total_n);
    } elsif($string =~ /T5T/i) {
        $type = 'お宝５';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_treasure5_table($total_n);
    }
    # アイテム表
    elsif($string =~ /RWIT/i) {
        $type = 'レア武具アイテム';
        $total_n = &d66(1);
        $output = &mk_rare_weapon_item_table($total_n);
    } elsif($string =~ /RUIT/i) {
        $type = 'レア一般アイテム';
        $total_n = &d66(1);
        $output = &mk_rare_item_table($total_n);
    } elsif($string =~ /WIT/i) {
        $type = '武具アイテム';
        $total_n = &d66(2);
        $output = &mk_weapon_item_table($total_n);
    } elsif($string =~ /LIT/i) {
        $type = '生活アイテム';
        $total_n = &d66(2);
        $output = &mk_life_item_table($total_n);
    } elsif($string =~ /RIT/i) {
        $type = '回復アイテム';
        $total_n = &d66(2);
        $output = &mk_rest_item_table($total_n);
    } elsif($string =~ /SIT/i) {
        $type = '探索アイテム';
        $total_n = &d66(2);
        $output = &mk_search_item_table($total_n);
    } elsif($string =~ /IFT/i) {
        $type = 'アイテム特性';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_item_features_table($total_n);
    } elsif($string =~ /IDT/i) {
        $type = 'アイテムカテゴリ決定';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_item_decide_table($total_n);
    }
    # ランダムエンカウント表
    elsif($string =~ /1RET/i) {
        $type = '1Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount1_table($total_n);
    } elsif($string =~ /2RET/i) {
        $type = '2Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount2_table($total_n);
    } elsif($string =~ /3RET/i) {
        $type = '3Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount3_table($total_n);
    } elsif($string =~ /4RET/i) {
        $type = '4Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount4_table($total_n);
    } elsif($string =~ /5RET/i) {
        $type = '5Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount5_table($total_n);
    } elsif($string =~ /6RET/i) {
        $type = '6Lvランダムエンカウント';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_random_encount6_table($total_n);
    }
    
    # その他表
    elsif($string =~ /KDT/i) {
        $type = '王国災厄';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_kingdom_disaster_table($total_n);
    } elsif($string =~ /KCT/i) {
        $type = '王国変動';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_kingdom_change_table($total_n);
    } elsif($string =~ /KMT/i) {
        $type = '王国変動失敗';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_kingdom_mischange_table($total_n);
    } elsif($string =~ /CAT/i) {
        $type = '痛打';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_critical_attack_table($total_n);
    } elsif($string =~ /FWT/i) {
        $type = '致命傷';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_fatal_wounds_table($total_n);
    } elsif($string =~ /CFT/i) {
        $type = '戦闘ファンブル';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_combat_fumble_table($total_n);
    } elsif($string =~ /TT/i) {
        $type = '道中';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_travel_table($total_n);
    } elsif($string =~ /NT/i) {
        $type = '交渉';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &mk_negotiation_table($total_n);
    } elsif($string =~ /ET/i) {
        $type = '感情';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &mk_emotion_table($total_n);
    }

    if($output ne '1') {
        $output = "$_[1]: ${type}表(${total_n}) ＞ $output";
    }
    return $output;
}

#**生活散策表(2d6)
sub mk_life_research_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "ハグルマ資本主義神聖共和国から使者が現れる。受け入れる場合［生活レベル／９］に成功すると(1d6)ＭＧ獲得。この判定の難易度は、ハグルマとの関係が険悪なら＋２、敵対なら＋４される。使者を受け入れない場合、ハグルマとの関係が１段階悪化する。すでに関係が敵対なら、領土１つを失う",
        "王国の活気にやる気がでる。《気力》+1、もう一度王国フェイズに行動できる",
        "この国の評判を聞いて、旅人がやってくる。このゲームのシナリオの目的を果たしたら、終了フェイズに《民》＋(2d6)人",
        "旅の商人に出会い、昨今の相場を聞く。(2d6)を振り、メモしておく。終了フェイズの収支報告のタイミングに、2d6を振る代わりにその目が出たことにして相場を決定する",
        "主婦たちの井戸端会議によると、生活用品が不足しているらしい。ゲーム中に「革」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「革」を獲得出来ないと、維持費＋１ＭＧ",
        "食料に対する不安を漏らす民の姿を見かける。ゲーム中に「肉」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「肉」を獲得出来ないと、維持費＋１ＭＧ",
        "散策の途中、様々な施設が老朽化しているのを発見する。ゲーム中に「木」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「木」を獲得出来ないと、維持費＋１ＭＧ",
        "お腹の大きくなった女性が、無事戻ったら赤子の名付け親になって欲しいと言う。このゲームのシナリオの目的を果たしたら、終了フェイズに《民》＋(2d6)人",
        "王国内で民とともに汗を流す。［生活レベル／９］の判定に成功すると、（生産施設の数×１）ＭＧを獲得する",
        "「これ、便利だと思うんですけど」　［生活レベル／１１］の判定に成功すると、価格が自国の［生活レベル］以下の生活アイテム１個を１Lvで獲得できる",
        "突然王国に旅人が訪れ、王国の食料庫が乏しくなってくる。［生活レベル／１１］に成功すると、他国から補給を呼んで《民》＋(2d6)人。失敗すると《民》－(2d6)人",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**治安散策表(2d6)
sub mk_order_research_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "メトロ汗国から使者が現れる。受け入れる場合、［治安レベル／９］に成功すると《民》＋(2d6)人。失敗すると《民》－(2d6)人。この判定の難易度は、汗国との関係が険悪なら＋２、敵対なら＋４される。使者を受け入れない場合、汗国との関係が１段階悪化する。すでに関係が敵対なら、領土１つを失う",
        "「つまらないものですが、これを冒険に役立ててください……」相場表でランダムに素材１種を選び、それを(1d6)個獲得する",
        "民たちが自分らで、王国を守る相談をしている。この気０無のシナリオの目的を果たしたら、好きなレベルのある施設１軒を選び、その隣の部屋に同じ施設１軒を建設する",
        "毎日の散歩の成果が出て、体の調子が良い。このゲーム中、《ＨＰ》の最大値＋５し、《ＨＰ》５点回復する",
        "王国の民たちが、ランドメイカーの留守を守る人間が少ないことを心配している。ゲーム中に逸材１人を獲得するたびに《民の声》＋１。終了フェイズまでに１人も逸材を獲得出来ないと、維持費＋１ＭＧ",
        "王国周辺の迷宮化が進んでいる。対迷宮化結界を強化せねば…。ゲーム中に「魔素」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「魔素」を獲得出来ないと、維持費＋１ＭＧ",
        "王国内の施設の稼働率が下がっている。整備が必要そうだ。ゲーム中に「機械」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「機械」を獲得出来ないと、維持費＋１ＭＧ",
        "周辺諸国の噂を聞く。王国シートの既知の土地欄の中から、関係が同盟・良好・中立の他国があれば、ランダムに国１つを選ぶ、相場表でランダムに素材１種類を選ぶ。その国の相場はその素材となる",
        "王国の平和な光景を見て、手応えを感じる。［治安レベル／９」の判定に成功すると、［公共施設の数×１］ＭＧを獲得する",
        "「迷宮のごかごがありますように……」　［治安レベル／１１］の判定に成功すると、価格が自国の［生活レベル］以下の探索アイテム１個を１Lvで獲得できる",
        "王国の中で不満分子たちがなにやら不穏な話をしているのを耳にする。［治安レベル／１１］の判定に成功すると、あなたは留守中の準備をしておくことができる。そのゲーム中、一度だけ王国災厄表の結果を無効にすることができる。失敗すると、ランダムに施設１軒を選び、それが破壊される",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**文化散策表(2d6)
sub mk_calture_research_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "千年王朝から使者が現れる。受け入れる場合、［文化レベル／９］に成功すると《民の声》＋(1d6)、失敗するとすると《民の声》－(1d6)。この判定の難易度は、千年王朝との関係が険悪なら＋２、敵対なら＋４される。使者を受け入れない場合、千年王朝との関係が１段階悪化する。すでに関係が敵対なら、領土１つを失う",
        "民が祭りの準備を進めている。シナリオの目的を果たしていれば、収支報告の時に［収支報告時の《民の声》－ゲーム開始時の《民の声》］ＭＧを獲得できる。ただし、数値がマイナスになった場合は、その分維持費が上昇する",
        "都会に出て行った幼馴染から手紙がくる。王国の様子を知りたがっているようだ。シナリオの目的を果たしたら、終了フェイズにランダムなジョブの逸材１人を獲得する",
        "他のランドおメイカーの噂を聞く。宮廷から好きなキャラクター１人を選び、そのキャラクターに対する《好意》＋１",
        "若者たちの有志が、街を発展させるため諸外国のことを勉強したいと言い出した。ゲーム中に「情報」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「情報」を獲得出来ないと、維持費＋１ＭＧ",
        "若い娘たちが、流行の衣装について楽しそうに話している。ゲーム中に「衣料」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「衣料」を獲得出来ないと、維持費＋１ＭＧ",
        "民たちが、君のうわさ話をしている。ゲーム中にあなたにたいして「恋人」「忠義」「親友」の人間関係が成立するたびに《民の声》＋２。終了フェイズの収支報告までに１回も人間関係が成立できないと、維持費＋１ＭＧ",
        "あなたに熱い視線が注がれているのを感じる。宮廷から好きなキャラクター１人を選び、そのキャラクターの自分に対する《好意》＋１",
        "王国内を訪れる旅人たちを見かける。［文化レベル／９］の判定に成功すると、［憩いの施設の数×１］ＭＧを獲得する",
        "「ご無事をお祈りしております……」　［文化レベル／１１］の判定に成功すると、価格が自国の［生活レベル］以下の回復アイテム１個を１Lvで獲得できる",
        "王国の中の民たちの表情に制裁がない。暗い迷宮生活に倦んでいるようだ。［文化レベル／１１］の判定に成功すると民を盛り上げる祭りを開き、《民の声》＋(1d6)。失敗すると維持費＋(1d6)",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**軍事散策表(2d6)
sub mk_army_research_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "ダイナマイト帝国から使者が現れる。受け入れる場合、［軍事レベル／９］に成功すると(1d6)ＭＧ獲得、失敗すると維持費＋(1d6)ＭＧ。この判定の難易度は、ダイナマイトとの関係が険悪なら＋２、敵対なら＋４される。使者を受け入れない場合、ダイナマイトとの関係が１段階悪化する。すでに関係が敵対なら、領土１つを失う",
        "長老から迷宮の昔話を聞く。このゲーム中、自分のレベル以下のモンスターを倒すと、そのモンスターをモンスターの《民》にすることができる。この効果は、そのゲーム中に１度だけ使用できる",
        "冒険に向かう君に期待の声がかかる。民たちの期待に、気持ちが引き締まる。このゲーム中、《器》が１点上昇する",
        "くだらないことで口論になる。宮廷の中から１人を選び、互いに対する《敵意》＋１",
        "兵士たちの訓練の様子を見るが、武装がやや乏しい。ゲーム中に「牙」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「牙」を獲得出来ないと、維持費＋１ＭＧ",
        "旅人から隣国が軍備を拡張していると言う噂を聞く。ゲーム中に「鉄」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「鉄」を獲得出来ないと、維持費＋１ＭＧ",
        "近隣で凶悪なモンスターたちが大量発生していると言う。ゲーム中に「火薬」５個を獲得するたびに《民の声》＋１。終了フェイズの収支報告までに１個も「火薬」を獲得出来ないと、維持費＋１ＭＧ",
        "周辺諸国で戦争が勃発する。王国シートの既知の土地欄から２つの国を選び、両国間で戦争を行う。それぞれ「領土数＋(1d6)」が戦力。大きい方が勝利して領土１つを獲得し、負けた方の国は領土を１つ失う。どちらかに援軍を送ることができる。［軍事レベル／９＋戦う相手の領土数］の判定に成功すると戦力＋(1d6)。勝敗に関係なく援軍を送った国との関係が１段階友好になり、戦った相手の国との関係が１段階悪化する",
        "隣国からの貢物が届く。［軍事レベル／１１］の判定に成功すると、収支報告の時に価格の（）内の数字が［領土の数×１］以下のレアアイテム１個を獲得する",
        "「こんなものを用意してみました」　［軍事レベル／１１］の判定に成功すると、価格が自国の［生活レベル］以下の武具アイテム１個を１Lvで獲得できる",
        "あなたが他の出発を察知して、何者かが国を襲う！［軍事レベル／１１］の判定に成功するとあなたが他の武勇に歓声が上がり宮廷全員の気力＋(1d6)。失敗すると、宮廷全員の《ＨＰ》と《配下》が(1d6)減少する",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**才覚休憩表（2d6）
sub mk_talent_break_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "民との会話の中、経費節約のアイデアが沸く。［才覚/11］の判定に成功すると、維持費が（1d6）MG減少する",
        "嫌いなものが出てくる夢を見て心寂しくなったところに仲間が来てくれる。好きな宮廷内のキャラクター１人への《好意》＋１",
        "好きなものの夢を見る。シチュエーションを表現し、幸せそうだと感じるプレイヤーが居たら《気力》＋２",
        "国に残した家族を心配する民を励ます。［才覚/11］の判定に成功すると、《民の声》＋２",
        "あらん限りの声を力を込めて檄を飛ばす。［才覚/9］の判定に成功すると、宮廷全員のあなたに対する《好意》の合計だけ、《民の声》が回復する",
        "休憩中も休み無く働いていると、配下がお茶を入れてくれる。《民の声》＋１",
        "今後の冒険について口角泡を飛ばして議論する。好きな宮廷内のキャラクター１人を選び、そのキャラの自分に対する《敵意》を好きなだけ上昇させる。上昇した《敵意》と等しい値だけ《民の声》が回復する",
        "たまには料理をしようと思い立つ。【お弁当】か【フルコース】の効果を使用して、食事を取ることが出来る。使用した場合、（1d6）を振る。奇数が出たら料理は美味だった、《民の声》＋１。偶数が出たら料理は非道い味になった、宮廷全員のあなたに対する《敵意》＋１",
        "年若い配下に冒険譚をせがまれる。［才覚/現在の《民の声》の値+3］の判定に成功すると、《民の声》＋（1d6）。失敗すると次の１クォーター行動できない",
        "迷宮に囚われた人々を見つける。助けたいが、食料がやや心配だ。［才覚/9］の判定に成功すると、自分の《配下》＋（1d6）",
        "この迷宮は一筋縄ではいかないようだ。今こそ、用意していたアレが役に立つだろう。自分の習得しているスキル１種を未修得にし、同じスキルグループのスキル１種を修得してもよい。この効果は永続する。",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**魅力休憩表（2d6）
sub mk_charm_break_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "妖精のワイン倉を発見し、酒盛りが始まる。宮廷全員の《気力》＋１。［魅力/9］の判定に失敗すると、あなたは脱ぎ出す。（1d6）を振り、奇数なら宮廷全員のあなたに対する《好意》＋１、偶数なら《敵意》＋１",
        "休憩中、意外な寝言を言ってしまう。自分を除く宮廷全員は自分に対する《好意》と《敵意》を入れ替えることが出来る。また、その属性を自由に変更することができる",
        "床の冷たさから、ぬくもりを求めて身体を寄せ合う。あなたに《好意》を持っているキャラの数だけ《気力》と《HP》が回復する",
        "こっそり二人で抜け出して良い雰囲気に。その部屋の中に、好きなものが同じキャラが居ればそのキャラ１体を選び、互いに対する《好意》＋１",
        "星の灯りがあなたの顔をロマンチックに照らし出す。その部屋にいる好きなキャラ１体を選び、［魅力/そのキャラのあなたに対する《好意》+9］の判定に成功すると、そのキャラのあなたに対する《好意》＋１",
        "あいつと目が合う。［魅力/9］の判定に成功したら、宮廷内からランダムに１体選び、そのキャラから自分への《好意》か、または自分のそのキャラへの《好意》いづれかが＋１される",
        "うたた寝をしていると誰かが毛布を掛けてくれた。ランダムにキャラを選び、自分のそのキャラへの《好意》＋１",
        "たき火を囲みながら会話を楽しむ。GMの左隣にいるプレイヤーから順番に、自分のPCが《好意》を持っているキャラ１体を選ぶ。選ばれたキャラは《気力》＋１。誰からも選ばれなかったキャラは《気力》－１、ランダムに選んだ宮廷内のキャラへの《敵意》＋１",
        "着替えを覗かれる。宮廷内からランダムに１体選び、（1d6）を振る。奇数なら大声をだしてしまい宮廷全員のそのキャラに対する《敵意》＋１、偶数ならそのキャラとあなたの互いの《好意》＋１",
        "食べ物の匂いにつられたモンスターと遭遇する。ランダムエンカウント表でモンスターを決定する。［魅力/モンスターの中で最も高いレベル+3］の判定に成功した場合、そのモンスターたちと取引できる。失敗した場合戦闘に突入する",
        "ふとした拍子に唇が触れあう。好きなキャラ１体を選ぶ。そのキャラの自分以外への《好意》の合計を全て自分に対する《好意》に加える。その後、自分以外への《好意》を０にする",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**探索休憩表（2d6）
sub mk_search_break_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "一休みの前に道具の手入れ。ランダムに自分のアイテムスロット１つを選ぶ。そのスロットにレベルがあるアイテムがあった場合、そのアイテムのレベルが１上がる",
        "寝床を探していたらアルコープの奥の宝箱を見つける。［探索/11］の判定に成功したら好きな素材１種類を（1d6）個手に入れる",
        "一眠りしたら夢の中で…。［探索/11］の判定に成功したら、好きな部屋のモンスターの名前とトラップの数をGMから教えてもらえる",
        "配下が眠りにつき、静寂が訪れると隣の部屋から妙な物音が聞こえてきた。隣接する好きな部屋を選ぶ。［探索/10］の判定に成功すると、その部屋にモンスターがいるかどうか、いる場合はモンスターの種類と数が分かる",
        "一休みしようと持ったら、モンスターの墓場を発見した。好きな素材を１種類えらび、宮廷全員のあなたにたいする《好意》の合計に等しい個数だけその素材を入手する",
        "この部屋はなぜか落ち着く。もしもその部屋の中にあなたの好きなものがあれば《気力》を（1d6）点回復することができる",
        "壁に書かれた奇妙な壁画が、あなたを見つめている気がする…。［探索/9］の判定に成功したら、【エレベータ】を発見する",
        "白骨化した先客の死体が見つかる。使えそうな装備はありがたく頂戴しておこう。［探索/11］の判定に成功したら、コモンアイテムのカテゴリの中から好きなものを１つ選び、そのカテゴリのアイテムをランダムで１個手に入れる",
        "星の灯りで地図を眺める…部屋の構造からして、この辺りに何かありそうだ。［探索/10］の判定に成功すると、この部屋に仕掛けられたイベント型のトラップを全て発見する",
        "休んでいる間にトイレにいきたくなった。［探索/11］の判定に成功すると、迷宮のほころびを見つける。このゲームの間、この部屋から迷宮の外へ帰還することができる",
        "こ、これは秘密の扉？［探索/11］の判定に成功すると、この部屋に隣接する好きな部屋に通路を延ばすことができる",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**武勇休憩表（2d6）
sub mk_valor_break_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "時が満ちるにつれ、闘志が高まる。現在の経過ターン数と等しい数だけ《気力》が回復する",
        "もっと敵と戦いたい、血に飢えた自分を発見する。［武勇/11］の判定に成功すると《気力》が１点、《ＨＰ》が（1d6）点回復する",
        "部屋の片隅にうち捨てられた亡骸を発見する。このマップの支配者の名前が分かっていれば、宮廷全員は支配者への《敵意》を１点上昇させることができる",
        "部屋の隅に隠れていた怪物が襲いかかってきた。［武勇/10］の判定に成功すると怪物を追い払い《民の声》＋１。失敗すると自分の《配下》－（1d6）、《民の声》－１",
        "あいつの短剣がきみの横をかすめて毒蛇を追い払う。好きなキャラ１体を選び、そのキャラに対する《敵意》の分だけ《好意》を上昇させ、その後《敵意》を０にする",
        "実力を付けてきたアイツへとドス黒い気持ちがわき上がる。好きなキャラ１体を選び、そのキャラへの《敵意》＋１",
        "ちょっとした行き違いから軽い口論になる。宮廷内からランダムにキャラ１体を選び、そのキャラとあなたの互いへの《敵意》＋１",
        "ライバルの活躍が気になる。宮廷全員の中で、最も高いあなたに対する《敵意》の値と同じ数だけ《気力》を獲得する",
        "休むべきときにしっかり休む。《ＨＰ》を（2d6）点回復することができる",
        "怪物のいた痕跡を発見する。［武勇/11］の判定を行い、成功するとＧＭからこのゲームで遭遇する予定の、まだ種類の分かっていないモンスターを１種類教えてもらえる",
        "殺気に反応し飛び起きた！ランダムエンカウント表でモンスターを決定し戦闘を行う。そのモンスターを倒した後、ランダムにレアアイテム１個を手に入れる",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**お祭り休憩表(2D6)
sub mk_festival_break_table {
    my $num = shift;
    my @table = (
[ 2, 'お祭りに向かう旅人たちとすれ違う。1D6MGが手に入る【宿屋】か【夜店】があれば、さらにもう1D6MGが手に入る' ],
[ 3, 'なんでこんなときに、ダンジョンに行かなきゃいけないんだ！　「あ、電報でーす」このマップの支配者から、お祭りによせて祝辞の電報がやってくる。そうか、おまえのせいかッ!!　マップの支配者の名前が分かり、そのキャラクターへの《敵意》が1D6点上がる' ],
[ 4, '「そういえば、国のみんなが何かいってたなぁ……」回想シーン。好きな散策表を1つ選び、2D6を振る。表に照らし合わせた結果を処理する' ],
[ 5, 'あー。早く帰って、お祭りを楽しみたーい！　この時点でキャンプを終了し、すぐに次の部屋へ移動すれば、このクォーターは、時間の経過が起こらない' ],
[ 6, 'どこからか美味しそうな匂いが漂ってくる。「あ、うまそう」死んだふりをしていた民が起き上がる。今回の冒険で消費していた《配下》が1D6人回復する' ],
[ 7, '雰囲気がいつもと違うせいかな。なんかあの人がステキに見える。好きなキャラクター1人を選ぶ。そのキャラクターへの《好意》を1点上げる' ],
[ 8, 'あ、こんなところにまで屋台が！　あてくじ屋さんだ。1MG減らして、好きなアイテムカテゴリを選び、さらにそのカテゴリの中からランダムにアイテム1個を選ぶ。そのアイテムをもらえる（レアアイテムは飾ってあるが、絶対当たらない）' ],
[ 9, 'お祭りを目指す交易商人と出会う。「あ、王様。これから王国行くんすよ」宮廷の持つ好きな素材を何個でも、同じ数の別の素材と交換してくれる' ],
[ 10, 'せっかくお祭りなんだし、肩肘はってないで、ノリノリでGO!!　このゲーム中は食事をするたびに《民の声》が1点回復する' ],
[ 11, '「あ、この歌は……」祭囃子がキミの封印されていたモンスターにまつわる過去の記憶を呼び戻す。好きなモンスター1種類を選ぶ。そのモンスター全般への《敵意》が1点上がる' ],
[ 12, 'みんなのワクワクがアイテムに乗り移った？　ランダムに自分のアイテムスロット1つを選ぶ。そこにレベルのあるアイテムがあった場合、そのレベルが1上がる' ],
    );
    return &get_table_by_number($num, @table);
}

#**お祭り表(2D6)
sub mk_festival_table {
    my $num = shift;
    my @table = (
[ 2, '祈願祭。国や重要人物の無病息災を祈ったり、戦いの勝利などを祈る祭り。災害や飢饉、流行り病が起こった付近で行われる。シナリオの目的をクリアしていれば、《民》が1D6人上昇する' ],
[ 3, '血祭り。戦いに向け、士気を向上させる祭り。戦争だけでなく、迷宮探索に向けて行われることも多い。生贄の血を軍神に捧げたりする。このゲームの間、戦闘に勝利すると《民の声》を1点獲得し、逃走すると《民の声》が1点失われる' ],
[ 4, '記念日。建国記念日や領土獲得などの記念日のお祝い。簡単につくることができるが、気がつくと記念日だらけで、何の記念だったかを忘れてしまう。ほどほどに。このゲームの間、行為判定の目で3でも絶対失敗、11でも絶対成功になる（「呪い」のバッドステータスを受けたものは4でも絶対失敗、【必殺】を使った命中判定なら10でも絶対成功）' ],
[ 5, '星祭。季節のお祭り。冬至や夏至などの祭りや、七夕、お花見、雪祭りなどが含まれる。季節感の少ない迷宮では、殊更にその風情を楽しもうとやたら盛り上がる。宮廷全員、好きなキャラクター1人を選び、そのキャラクターに対する《好意》を1点上げる' ],
[ 6, '民衆の宴。民が自発的に開くお祭り、イベント。アキハバラ電気祭りに餃子祭り、コミックマーケットなど、文化や地域の活性化と結びつくものが多い。このゲームの間、好きな施設1つを選んで、その施設の施設レベルを1上げる' ],
[ 7, '誕生日。ランドメイカーや逸材、国の重要人物の誕生日。聖誕祭や花祭りなど、国教の聖人などを祝う国も多い。現王の誕生日を「父の日」、后の誕生日を「母の日」とする国も多い。そのゲームの間、ケーキやおにぎり、缶ジュースなど、1人分が明確な食べ物を食べきったとき、自分のPCが《気力》1点を獲得する' ],
[ 8, '冠婚葬祭。国の重要人物の元服（成人）、婚礼、葬儀、祖先の慰霊などの儀式。格式の高い王国では、もっとも重要な祭礼である。このゲームの間、国力を使った判定の達成値を1上昇させる' ],
[ 9, '感謝祭。豊漁や豊作などがあったときに自然（迷宮）や精霊、信仰対象など、偉大なるものへの感謝を捧げるお祭り。獲物の毛の一部を切りとって迷宮に感謝する毛祭りや瀬祭り、豊饒を祝う新嘗祭などがある。終了フェイズに「木」や「革」、「肉」のいずれかを1つ消費すると、王国変動表の結果を±1の範囲でずらすことができる' ],
[ 10, '鬼祭り。お正月に旧年の悪を正す修正会、豆をまいて福を呼び込む追儺の儀式、怪物に仮装した子供たちが夜の王国をねり歩くハロウィーンなど、悪魔や悪霊を払うお祭り。モンスター除けに行われる。このゲームの間、ランダムエンカウントの戦闘後に使用するお宝表が1段階、高いレベルのものを使用する' ],
[ 11, '舞踏会。最高の音楽と芸術的な食事、そしてとびきりの衣装で臨む社交界の華。身分や素性を隠してパートナーを探す仮面舞踏会も人気は高い。ちなみに仮面舞踏会では、女性の側から男性をダンスに誘うのが礼儀だぞ。宮廷全員、ランダムにキャラクター1人を選び、そのキャラクターに対する《好意》を1点上げる' ],
[ 12, '競技会。国をあげて、スポーツや芸術、ゲームなど、さまざまなジャンルの一番を決めるお祭り、大会。オリンピックや料理勝負、歌合戦などがある。ランダムに能力値1つを選び、宮廷全員で難易度15の判定を行う。このとき成功した中で、もっとも達成値が高かったキャラクターは、シナリオ終了後、終了フェイズの探索会議で決定されるキャラクターとは別に、勲章を得る' ],
    );
    return &get_table_by_number($num, @table);
}

#**王国災厄表（2d6）
sub mk_kingdom_disaster_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "王国の悪い噂が蔓延する。既知の土地にある他国との関係が全て１段階悪化する",
        "自国のモンスターが凶暴化する。自国のモンスターの《民》からランダムに１種類選び、そのレベルと等しいだけ《民》が減少する。その後、その種類のモンスターの《民》は全ていなくなる",
        "疫病が大流行する。《民》－（2d6）",
        "自国の迷宮化が進行する。自国の領土のマップ数と等しい値だけ維持費が上昇する",
        "敵国のテロが横行する。［治安レベル/敵対国数×２＋険悪国数＋９］の判定に失敗すると、ランダムに施設を１軒失う",
        "敵国襲来！［軍事レベル/敵対国数×２＋険悪国数＋９］の判定に失敗すると、ランダムに自国の領土を１つ失う",
        "敵国の陰謀。［文化レベル/敵対国数×２＋険悪国数＋９］の判定に失敗すると、ランダムに逸材を１人失う",
        "食糧危機。《民》－（2d6）。王国にある「肉」の素材を１個消費する度に、《民》の減少を１人抑えることができる",
        "住民の不満が爆発する。［生活レベル/敵対国数×２＋険悪国数＋９］の判定に失敗すると《民の声》－１",
        "局地的な迷宮津波が発生。ランダムに自国の領土１つを選び、既知の土地の中からランダムに選んだ場所と場所を入れ替える",
        "敵国の勢力が強大化する。ＧＭは、関係が敵対の国全てについて、その国の領土に接する土地を１つ選び、その土地をその国の領土にする",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**才覚ハプニング表（2d6）
sub mk_talent_happening_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "自分に王国を導くことなどできるのだろうか…。【お酒】を消費することができなければ、このゲーム中［才覚］－１",
        "国王の威信が問われる。（2d6）を振り、その安宅委が［《民の声》＋宮廷全員の国王に対する《好意》の合計］以下の場合、《民の声》－（1d6）し、さらに才覚ハプニング表を振る",
        "思考に霧の帳が降りる。「散漫」のバッドステータスを受ける",
        "重大な裏切りを犯してしまう。あなたに対する《好意》が最も高いキャラを１人選ぶ。そのキャラに対する《好意》の分だけそのキャラへの《敵意》を上昇させ、その後《好意》を０にする",
        "この人についていっていいのだろうか…？宮廷全員のあなたに対する《好意》－１（最低０）。その結果、誰かの《好意》が０になると《民の声》－１",
        "宮廷のスキャンダルが暴露される。宮廷全員のあなたに対する《敵意》のうち最も高いものと同じだけ《民の声》が減少する",
        "あなたの失策が噂になる。近隣の国の中からランダムで１つ選ぶ。その国との関係が１段階悪化する",
        "王国の経済に破綻の危機が。［生活レベル/９＋現在の経過ターン数］の判定に失敗すると維持費＋（1d6）ＭＧ",
        "この区画一体の迷宮化が激しくなる。１クォーターが経過する",
        "逸材の賃上げ要求が始まる。終了フェイズの予算会議の時、［今回使用した逸材の数×１］ＭＧだけ維持費が上昇する",
        "今の自分に自信が持てなくなる。生まれ表からランダムにジョブを１つ選び、現在のジョブをそのジョブに変更する",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**魅力ハプニング表（2d6）
sub mk_charm_happening_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "民同士の諍いに心を痛め、頭髪にもダメージが！【お酒】を消費することができなければ、このゲーム中［魅力］－１",
        "何気ない一言が不和の種に…。好きなキャラ１人を選び、宮廷全員のそのキャラに対する《敵意》＋１",
        "あなたの美しさに嫉妬した迷宮が、あなたの姿を変える。「呪い」のバッドステータスを受ける",
        "かわいさ余って憎さ百倍。あなたに対する《好意》が最も高いキャラを１人選ぶ。そのキャラに対する《好意》の分だけそのキャラへの《敵意》を上昇させ、その後《好意》を０にする",
        "あなたを巡って不穏な空気が。宮廷全員のあなたに対する「愛情」の《好意》を比べ、高い順に２人選ぶ。その２人の互いに対する《敵意》＋１",
        "いがみ合う宮廷を見て民の士気が減少する。宮廷全員のあなたに対する《敵意》の中で最も高い値と同じだけ《配下》が減少する",
        "宮廷に嫉妬の嵐が巻き起こる。宮廷の中で、あなたに対して愛情を持つキャラクターの数を数える。このゲームの間、行為判定を行うとき、ダイス目の合計がこの値以下なら絶対失敗となる（最低２）",
        "愛想を尽かされる。宮廷全員のあなたに対する《好意》－１（最低０）",
        "あなたの指揮に疑問の声が。［魅力/自分の《配下》の数］の判定に失敗すると［難易度－達成値］人だけ《配下》が減少する",
        "あなたの恋人だという異性が現れる。宮廷全員のあなたに対する《好意》を比べ、最も高いキャラ１人を選ぶ。あなたはそのキャラの［武勇］と同じだけ《ＨＰ》を減少させる",
        "他人が信用できなくなる。このゲームの間、協調行動を行えなくなり、人間関係のルールも使用できなくなる",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**探索ハプニング表（2d6）
sub mk_search_happening_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "指の震えが止まらない。【お酒】を消費することができなければ、このゲーム中［探索］－１",
        "流れ星に直撃。《ＨＰ》－（1d6）",
        "敵の過去を知り、同情してしまう。あなたのこのマップの支配者に対する《好意》＋１。このゲームの間、《好意》を持ったキャラに対して攻撃を行い、絶対失敗した場合そのキャラへの《好意》と同じだけ《気力》が減少する",
        "昨日の友は今日の敵。あなたに対する《好意》が最も高いキャラを１人選ぶ。そのキャラに対する《好意》の分だけそのキャラへの《敵意》を上昇させ、その後《好意》を０にする",
        "うっかりアイテムを落として壊す。ランダムにアイテムスロットを１つ選び、そこにアイテムが入っていればそれを全て破壊する",
        "カーネルが活性化しトラップが強化される。このゲームの間、トラップを解除するための難易度＋１",
        "友情にヒビが！宮廷全員のあなたに対する《好意》－１（最低０）、《敵意》＋１",
        "敵の迷宮化攻撃！宮廷全員は［探索/11］を行い、失敗したキャラは（2d6）点のダメージを受ける",
        "つい出来心から国費に手を出してしまう。ＧＭは好きなコモンアイテム１つを選ぶ。あなたはそのアイテムを手に入れるが、維持費＋（1d6）ＭＧ、《民の声》－１。同じ部屋のＰＣは《希望》１点を消費して［探索/９］の判定に成功すれば、それを止めることができる",
        "封印されていたトラップを発動させてしまう。ランダムに災害系トラップから１つを選び、それを発動させる",
        "あなたを憎む迷宮支配者が賞金をかけた。このゲームの間、モンスターの攻撃やトラップの目標をランダムに決める場合、その目標はかならずあなたになる。（この効果を複数人が受けた場合、その中からランダムで決定する）",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**武勇ハプニング表（2d6）
sub mk_valor_happening_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "つい幼児退行を起こしそうになる。【お酒】を消費することができなければ、このゲーム中［武勇］－１",
        "不意打ちを食らう。ランダムエンカウントが発生し、奇襲扱いで戦闘を行う",
        "配下の期待が、あなたの重荷となる。［現在の《民の声》－（1d6）］だけ《気力》が減少する",
        "配下があなたをかばう。自分の《配下》が（1d6）人減少する",
        "ムカついたので思わず殴る。自分の《敵意》が最も高いキャラからランダムに１体選び、そのキャラの《ＨＰ》が自分の［武勇］と同じだけ減少する",
        "決闘だっ！宮廷全員のあなたに対する《敵意》の中で、最も高い値と同じだけあなたの《ＨＰ》が減少する",
        "豚どもめ…。宮廷全員に対する《敵意》＋１",
        "古傷が痛み出す。このゲームの間、戦闘で、あなたに対する敵の攻撃が成功すると、常に余分に１点ダメージを受ける",
        "不意に絶望と虚無感が襲い、心が折れる。宮廷全員の《気力》－１",
        "あなたを親の敵と名乗るものたちが現れた。このゲーム中に倒したモンスターからランダムに１種類を選び、そのモンスター（1d6）体と戦闘を行う",
        "自分の失敗が許せない。このゲームの間、《器》が１点減少したものとして扱う",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**王国変動表(2d6)
sub mk_kingdom_change_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "列強のプロパガンダが現れる。(1d6)を振り、その目が現在の《民の声》以下で、現在列強の属国になっていたら属国から抜けることができる。上回っていたら、ランダムに列強を１つ選びその属国になる",
        "冒険の成功を祝う民たちが出迎えてくれる。《民の声》＋２。この結果を出したプレイヤー（以下、当ＰＬ）以外の全員は、今回の冒険を振り返り当PLのPCが《好意》を得るとしたら誰が一番ふさわしいかを協議する。決定したキャラへの当PLのPCの《好意》＋１",
        "何者かによる唐突な奇襲攻撃。未知の土地に面している領土からランダムに１つを選ぶ。［軍事レベル/敵対国数×２＋険悪国数＋９］の判定に成功すると返り討ちにして(1d6)ＭＧを得る。失敗するとその領土は施設ごと失われる",
        "民の労働の結果が明らかに。［生活レベル/敵対国数×２＋険悪国数＋９］の判定に成功すると《予算》が自国の領土のマップ数と同じだけ増える。失敗したら《予算》が同じだけ減る",
        "民は領土を渇望していた。５ＭＧを支払えば、隣接する未知の土地１つを領土にできる。(1d6)を振り、その数だけ通路を引くことができる。通路でつながっていない部屋は自国の領土として扱わない",
        "王国の子どもたちが宮廷をあなた方を見て成長する。《民》が［王国に残した《民》の数÷10＋治安レベル］人増える",
        "あなたの活躍を耳にした者たちがやってくる。シナリオの目的を満たしている場合、関係が良好・同盟の国の数だけ(1d6)を振り、［合計値＋治安レベル］人だけ《民》が増える",
        "街の機能に異変が！？［治安レベル/敵対国数×２＋険悪国数＋９］の判定に成功すると、自国の好きな施設１軒を選び、その施設の隣でかつ通路がつながっている部屋に同じ種類の施設がもう１軒できる。失敗したら、自国のタイプ：部屋の施設を１軒選び、破壊する",
        "王国同士の交流が行われた。［文化レベル/敵対国数×２＋険悪国数＋９］の判定に成功すると、生まれ表でランダムにジョブを決めた逸材が１人増え、好きな国１つとの関係を１段階良好にする。失敗すると、自国の逸材１人を選んで失い、ランダムに決めた国１つとの関係が１段階悪化する",
        "ただ、無為に時が過ぎていたわけではない。迷宮フェイズで過ごした１ターンにつき《予算》が１ＭＧ増える",
        "民の意識が大きく揺れる。(1d6)を振り、その目が現在の《民の声》以下だったら、好きな国力が１点上昇する。上回っていたら、好きな国力が１点減少する",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**王国変動失敗表(2d6)
sub mk_kingdom_mischange_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "列強のプロパガンダが現れる。(1d6)を振り、その目が現在の《民の声》を上回っていたら、ランダムに列強１つを選びその属国になる",
        "新たな勢力が勃発する。王国シートの基地の土地欄の中から１つ、未知の土地を選ぶ。(1d6)を振り、その結果をその土地に記入する。１：敵対関係の国。２：険悪関係の国。３：凶暴な怪物の巣。４：人間嫌いのダンジョンマスターの庵。５：迷宮化の進んだ大迷宮。６：列強の飛び地",
        "何者かによる唐突な奇襲攻撃。未知の土地に面している領土からランダムに１つを選ぶ。［軍事レベル/敵対国数×２＋険悪国数＋９］の判定に失敗するとその領土は施設ごと失われる",
        "民の労働の結果が明らかに。［生活レベル/敵対国数×２＋険悪国数＋９］の判定に失敗したら《予算》が自国の領土のマップ数と同じだけ減る",
        "他国の使者がやってくる。基地の土地欄の中からランダムに自国以外の国を１つ選ぶ。その国の領土のマップ数を等しい《予算》を消費するとその国との関係が１段階よくなる。消費しないと１段階悪くなる",
        "民の声は離れ、この国を去る者たちがいた。《民》が(1d6)人減少する",
        "過ぎゆく時が王政を帰る。基地の土地欄の中から、経過したターン数と等しい数までランダムに他国を選ぶ。GMは、その国に面する未知の土地１つを選び、それをその国の新たな領土とする。（周囲に未知の土地がない場合は増やせない）",
        "街の機能に異変が！？［治安レベル/敵対国数×２＋険悪国数＋９］の判定に失敗したら、自国のタイプ：部屋の施設を１軒選び、破壊する",
        "王国同士の交流が行われた。［文化レベル/敵対国数×２＋険悪国数＋９］の判定に失敗すると、自国の逸材１人を選んで失い、ランダムに決めた国１つとの関係が１段階悪化する",
        "ただ、無為に時が過ぎていたわけではない。迷宮フェイズで過ごした１ターンにつき《予算》が１ＭＧ増える",
        "民の意識が大きく揺れる。(1d6)を振り、その目が現在の《民の声》を上回っていたら、好きな国力が１点減少する",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**痛打表（2d6）
sub mk_critical_attack_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "攻撃の手応えが武器に刻まれる。その攻撃に使用した武具アイテムにレベルがあれば、そのレベルが１点上昇する",
        "電光石火の一撃。攻撃の処理が終了したあと、もう一度行動できる",
        "相手の姿形を変えるほどの一撃。攻撃目標に「呪い」のバッドステータスを与える",
        "乾坤一擲！攻撃の威力が２倍になる",
        "相手を吹き飛ばす一撃。攻撃目標を好きなエリアに移動させる",
        "会心の一撃！攻撃の威力＋（1d6）",
        "相手の勢いを利用した一撃。攻撃の威力が攻撃目標のレベルと同じだけ上昇する",
        "あと１歩まで追いつめる。ダメージを与える代わりに、攻撃目標の残り《ＨＰ》を（1d6）点にすることができる",
        "敵の技を封じる。攻撃目標のスキルを１種選び、その戦闘の間、そのスキルを未修得の状態にする",
        "怒りの一撃！攻撃の威力＋（2d6）",
        "急所をとらえ一撃で切り伏せる。攻撃目標の《ＨＰ》を０にする",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**致命傷表（2d6）
sub mk_fatal_wounds_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "圧倒的一撃で急所を貫かれた。死亡する",
        "致命的な一撃が頭をかすめる。［探索/受けたダメージ+5］の判定に失敗すると死亡する",
        "出血多量で昏睡する。行動不能になる。この戦闘が終了するまでに《ＨＰ》を１以上にしないと死亡する",
        "頭を打ちつけ昏睡する。行動不能になる。このクォーターが終了するまでに《ＨＰ》を１以上にしないと死亡する",
        "重傷を負い昏睡する。行動不能になる。（1d6）クォーターが経過するまでに《ＨＰ》を１以上にしないと死亡する",
        "意識を失う。行動不能になる",
        "偶然アイテムに身を守られる。ランダムにアイテムを選び、そのアイテムを破壊してダメージを無効化する。破壊できるアイテムを１個も装備していない場合、行動不能になる",
        "《民》たちが身を挺して庇う。自分の《配下》を（2d6）人減少させ、ダメージを無効化する。《配下》が１人も居ない場合行動不能になる",
        "根性で跳ね返す。［探索/９－現在の《ＨＰ》］の判定に成功すると《ＨＰ》が１になる。失敗すると行動不能になる",
        "精神力だけで耐える。［武勇/９－現在の《ＨＰ》］の判定に成功すると《ＨＰ》が１になる。失敗すると行動不能になる",
        "幸運にもダメージを免れる。ダメージを無効化するが、代わりにランダムにバッドステータス１種を受ける",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**道中表（2d6）
sub mk_travel_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "道中の時間が愛を育む。全員、好きなキャラ１体を選びそのキャラに対する《好意》＋１",
        "何かの死体を見つけた。好きな素材１種類を（1d6）手に入れる",
        "辺りが闇に包まれる。宮廷の中からランダムにキャラを選ぶ。そのキャラが【星の欠片】を持っていたら、それが１個破壊される",
        "道に迷いそうになる。全員［才覚/9］の判定を行い、（1d6-成功したキャラ数）クォーター（最低０）、時間が経過する",
        "トラップに引っかかる。全員［探索/9］の判定にを行い、失敗したキャラは《ＨＰ》が（1d6）点減少する",
        "未知の土地の場合、何も起こらない。既知の土地の場合、その土地固有のイベントがある場合はそれが起こる",
        "モンスターの襲撃を受けた。全員［武勇/9］の判定を行い、失敗したキャラは《ＨＰ》が（1d6）点減少する",
        "恐ろしげな咆哮が響き渡る。全員［魅力/9］の判定を行い、失敗したキャラは《配下》が（1d6）人逃走し、自国へ帰る",
        "周辺の迷宮化が進む。宮廷全員は、既知の土地の中からランダムに選んだ土地へ移動する",
        "何かを拾う。コモンアイテムをランダムに１個選び、それを入手する",
        "１ＭＧ拾う",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**交渉表（2d6）
sub mk_negotiation_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "中立的な態度は偽装だった。不意を打たれ、奇襲扱いで戦闘を行う",
        "交渉は決裂した。戦闘を行う",
        "交渉は決裂した。戦闘を行う",
        "生け贄を要求された。モンスターの中で最もレベルが高いもののレベルと同じだけ《配下》を減少させれば友好的になる。ただし、《民の声》－（1d6）。《配下》を減らさなければ戦闘を行う",
        "趣味を聞かれた。好きな単語表１つを選びD66を振る。宮廷の中に、その項目を好きなものに指定しているキャラがいれば友好的になる。居なければ戦闘を行う",
        "物欲しそうにこちらを見ている。「肉」の素材（1d6）個か、【お弁当】または【フルコース】１個を消費すれば友好的になる。しなければ戦闘を行う",
        "値踏みするようにこちらを見ている。維持費を（1d6）ＭＧ上昇させれば友好的になる。させなければ戦闘を行う",
        "「何かいいもの」を要求された。モンスターの中で最もレベルが高いもののレベル以上の価格のアイテムを消費すれば友好的になる。レアアイテムは価格を＋１０して扱う。しなければ戦闘を行う",
        "面白い話を要求された。プレイヤー達はモンスター達が興味を引きそうな話をすること。ＧＭがそれを面白いと判断したら［魅力/9］の判定を行い、成功すれば。友好的になる。さもなければ戦闘を行う",
        "一騎打ちを申し込んできた。宮廷の中から代表を１名選び、モンスターの中で最もレベルの高いものと１対１で戦闘を行う（配置は互いに前列）。勝利すれば友好的になる。敗北すれば、再び交渉するか戦闘するかを決断する。この一騎打ちに外野がスキルやアイテムで干渉すると全員で戦闘になる",
        "運命の出会い。モンスター達の宮廷の代表に対する《好意》＋１、友好的になる",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**戦闘ファンブル表（2d6）
sub mk_combat_fumble_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "敵に援軍が現れる。敵軍の中で最もレベルの低いモンスターが（1d6）体増える。モンスター側がこの結果になった場合、好きなＰＣの《配下》＋（1d6）",
        "敵の士気が大いに揺らぐ。自軍のキャラは全員１マス後退する",
        "勢い余って仲間を攻撃！自分の居るエリアからランダムに自軍のキャラを１体選び、そのキャラに使用している武器と同じ威力のダメージを与える",
        "つい仲間と口論になる。自軍の未行動キャラの中からランダムに１体選び、行動済みにする",
        "魔法の効果が消える。自軍のキャラが使用したスキルやアイテムの効果で、戦闘中持続するものが全て無効になる",
        "自分を傷つけてしまう。自分に（1d6）ダメージ",
        "攻撃の勢いを逆に利用される。自分の《ＨＰ》を現在値の半分にする",
        "アイテムを落とした。自分が装備しているアイテムからランダムに１個選び、破壊する。モンスター側の場合、自分に（1d6）ダメージ",
        "カーネルが活性化する。戦闘系とラップからランダムに１種類選び、それがその場に配置される",
        "空を切った攻撃に絶望する。自分と、自分に対して１点以上《好意》を持ったキャラ全員の《気力》－１。モンスター側の場合、自分に（1d6）ダメージ",
        "武器がすっぽ抜ける。攻撃に使用していたアイテムが破壊される。モンスター側の場合、自分に（1d6）ダメージ。その後、バトルフィールドにいるキャラの中からランダムに１体選び、そのキャラの《ＨＰ》を１点にする",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**感情表（1d6）
sub mk_emotion_table {
    my $num = shift;
    $num = int(($num - 1) / 2);
    my $output = '1';
    my @table = (
        "忠誠／怒り",
        "友情／不信",
        "愛情／侮蔑",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**相場表（2d6）
sub mk_market_price_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        "無し",
        "肉",
        "牙",
        "鉄",
        "魔素",
        "機械",
        "衣料",
        "木",
        "火薬",
        "情報",
        "革",
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**お宝表１（1d6）
sub mk_treasure1_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        "何も無し",
        "何も無し",
        "そのモンスターの素材欄の中から、好きな素材１個",
        "そのモンスターの素材欄の中から、好きな素材２個",
        "そのモンスターの素材欄の中から、好きな素材３個",
        "【お弁当】１個",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表２（1d6）
sub mk_treasure2_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        "そのモンスターの素材欄の中から、好きな素材３個",
        "そのモンスターの素材欄の中から、好きな素材４個",
        "そのモンスターの素材欄の中から、好きな素材５個",
        "ランダムに回復アイテム１個",
        "ランダムに武具アイテム１個。レベルがあるアイテムなら１レベルのものが手に入る",
        "ランダムにレア一般アイテム１個",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表３（1d6）
sub mk_treasure3_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        "そのモンスターの素材欄の中から、好きな素材５個",
        "そのモンスターの素材欄の中から、好きな素材７個",
        "そのモンスターの素材欄の中から、好きな素材１０個",
        "好きなコモンアイテムのカテゴリ１種を選び、そのカテゴリからランダムにアイテム１個。レベルがあるアイテムなら１レベルのものが手に入る",
        "ランダムにレア一般アイテム１個。レベルがあるアイテムなら１レベルのものが手に入る",
        "ランダムにレア武具アイテム１個",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表４（1d6）
sub mk_treasure4_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        "そのモンスターの素材欄の中から、好きな素材５個",
        "そのモンスターの素材欄の中から、好きな素材１０個",
        "好きなコモンアイテムのカテゴリ１種を選び、そのカテゴリからランダムにアイテム１個。レベルがあるアイテムなら２レベルのものが手に入る",
        "好きなコモンアイテムのカテゴリ１種を選び、そのカテゴリからランダムにアイテム１個。レベルがあるアイテムなら３レベルのものが手に入る",
        "ランダムにレア一般アイテム１個。レベルのあるアイテムなら２レベルのものが手に入る",
        "ランダムにレア武具アイテム１個。レベルのあるアイテムなら１レベルのものが手に入る",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表５（1d6）
sub mk_treasure5_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        "そのモンスターの素材欄の中から、好きな素材１０個",
        "そのモンスターの素材欄の中から、好きな素材１５個",
        "好きなコモンアイテムのカテゴリ１種を選び、そのカテゴリからランダムにアイテム１個。レベルがあるアイテムなら４レベルのものが手に入る",
        "ランダムにレア一般アイテム１個。レベルのあるアイテムなら３レベルのものが手に入る",
        "ランダムにレア武具アイテム１個。レベルのあるアイテムなら２レベルのものが手に入る",
        "好きなレアアイテム１個",
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**名前表
sub mk_name_table {
    my $output = '1';
    # 名前表
    my $name_n = int(rand(6) + 1);
    my $d1 = &d66(2);
    my $d2 = &d66(2);
    
    if($name_n <= 1) {
        # 名前表A＋二つ名表A
        $output = &mk_nick_a_table(&mk_name_a_table($d1), $d2);
    } elsif($name_n <= 2) {
        # 名前表B＋二つ名表A
        $output = &mk_nick_a_table(&mk_name_b_table($d1), $d2);
    } elsif($name_n <= 3) {
        # 名前表エキゾチック＋二つ名表A
        $output = &mk_nick_a_table(&mk_name_ex_table($d1), $d2);
    } elsif($name_n <= 4) {
        # 名前表A＋二つ名表B
        $output = &mk_nick_b_table(&mk_name_a_table($d1), $d2);
    } elsif($name_n <= 5) {
        # 名前表B＋二つ名表B
        $output = &mk_nick_b_table(&mk_name_b_table($d1), $d2);
    } else {
        # 名前表ファンタジー＋二つ名表B
        $output = &mk_nick_b_table(&mk_name_fa_table($d1), $d2);
    }
    my $dice = $name_n.",".$d1.",".$d2;
    return ($output, $dice);
}

#**二つ名表A(D66)
sub mk_nick_a_table {
    my $output = shift;
    my $num = shift;
    my @table = (
        [11, "“災い転じて福となす”"],
        [12, "“七転び八起きの”"],
        [13, "“冗談にも程がある”"],
        [14, "“虎の尾を踏む”"],
        [15, "“石橋を叩いて渡る”"],
        [16, "“一を聞いて十を知る”"],
        [22, "“喉から手が出る”"],
        [23, "“据え膳食わぬは男の恥の”"],
        [24, "“天につば吐く”"],
        [25, "“風に柳の”"],
        [26, "“目に入れても痛くない”"],
        [33, "“とかく浮世は色と酒の”"],
        [34, "“当たるも八卦、当たらぬも八卦の”"],
        [35, "“泣く子も黙る”"],
        [36, "“天上天下唯我独尊”"],
        [44, "“虫も殺さぬ”"],
        [45, "“花も恥じらう”"],
        [46, "“触らぬ神に祟り無しの”"],
        [55, "“両手に花の”"],
        [56, "“（ゲーム会場の地名）でも一、二を争う”"],
    );
    if($num < 66) {
        $output = &get_table_by_number($num, @table).$output;
    } else {
        $output .= int(rand(6) + 1)."世";
    }

    return $output;
}
#**二つ名表B(D66)
sub mk_nick_b_table {
    my $output = shift;
    my $num = shift;
    my @table = (
        [11, "“身も蓋もない”"],
        [12, "“七人の敵がいる”"],
        [13, "“ドラゴンも裸足で逃げ出す”"],
        [14, "“われらが”"],
        [15, "“機会攻撃を誘発する”"],
        [16, "“佳人薄命”"],
        [22, "“すねに傷持つ”"],
        [23, "“湯上りは親でも惚れる”"],
        [24, "“叶わぬ時の神頼みの”"],
        [25, "“果報は寝て待つ”"],
        [26, "“清濁併せ呑む”"],
        [33, "“かゆいところに手が届く”"],
        [34, "“酒池肉林の”"],
        [35, "“蛇の道は蛇の”"],
        [36, "“口から先に生まれた”"],
        [44, "“柔よく剛を制す”"],
        [45, "“死人に口なしの”"],
        [46, "“噂をすれば”"],
        [55, "“ミスター／ミス”"],
        [56, "“（好きな名前表）の子”"],
        [66, "“（好きな単語表）の父／母”"],
    );
    $output = &get_table_by_number($num, @table).$output;

    return $output;
}

#**名前表A(D66)
sub mk_name_a_table {
    my $num = shift;
    my @table = (
        [11, "オレンジ／ジャスミン"],
        [12, "ホウズキ／アサガオ"],
        [13, "クローバー／ダチュラ"],
        [14, "ダフニ／キノコ"],
        [15, "クラナーダ／プリムローズ"],
        [16, "ラディッシュ／マリーゴールド"],
        [22, "サイプレス／マグノリア"],
        [23, "バンブー／オリーブ"],
        [24, "クラウド／クリマ"],
        [25, "タオ／スノウ"],
        [26, "アヴァランチ／エクレール"],
        [33, "ビバシータ／メトロノーム"],
        [34, "カノン／ファゴット"],
        [35, "オーボエ／アルモニカ"],
        [36, "チューバ／オルガノ"],
        [44, "ナン／クッキー"],
        [45, "ウイロウ／カシュカシュ"],
        [46, "スコーン／クスクス"],
        [55, "フラスコ／クリップ"],
        [56, "クラバドーラ／クレヨン"],
        [66, "ソープ／プルーム"],
    );

    return &get_table_by_number($num, @table);
}

#**名前表B(D66)
sub mk_name_b_table {
    my $num = shift;
    my @table = (
        [11, "エイジ／ウェンズデイ"],
        [12, "ジョルノ／ノエル"],
        [13, "タスク／マニャーナ"],
        [14, "ウィンター／ジュノー"],
        [15, "ハイラン／ブランカ"],
        [16, "ウォルナット／ルージュ"],
        [22, "グレイ／スカーレット"],
        [23, "シュバルツ／モエギ"],
        [24, "スロット／キリエ"],
        [25, "ジョーカー／ダイス"],
        [26, "ジグソウ／ドミノ"],
        [33, "バックギャモン／マーブル"],
        [34, "シーガロ／ココア"],
        [35, "スピーチカ／オレンジペコー"],
        [36, "ジッポ／ショコラ"],
        [44, "ナインビンズ／ルチャ"],
        [45, "デカスロン／ラクロス"],
        [46, "カバディ／ピンポン"],
        [55, "ボンド／ヴェルベット"],
        [56, "ルーブル／コットン"],
        [66, "シリング／シルク"],
    );

    return &get_table_by_number($num, @table);
}

#**名前表エキゾチック(D66)
sub mk_name_ex_table {
    my $num = shift;
    my @table = (
        [11, "モアイ／スイショウドクロ"],
        [12, "チュパカプラ／ムペンペ"],
        [13, "カンフー／インヤン"],
        [14, "ブシドー／ミヤコ"],
        [15, "チャンピオン／バービー"],
        [16, "ウパニシャッド／ゾルゲ"],
        [22, "デスマーチ／インテル"],
        [23, "ゴッホ／ヴィクトリア"],
        [24, "ゾンビ／オニャンコポン"],
        [25, "ケロッパ／カルメン"],
        [26, "オーバーキル／サシミ"],
        [33, "ブッチャー／デヴィ"],
        [34, "ブロンソン／マドンナ"],
        [35, "ガイギャックス／エロイカ"],
        [36, "好きな星の名前"],
        [44, "好きな武器の名前"],
        [45, "好きな動物の名前"],
        [46, "好きな鉱物の名前"],
        [55, "好きな言葉＋ドラゴン"],
        [56, "好きな単語表で決定する"],
        [66, "プレイヤーと同じ名前"],
    );

    return &get_table_by_number($num, @table);
}

#**名前表ファンタジー(D66)
sub mk_name_fa_table {
    my $num = shift;
    my @table = (
        [11, "アダム／イヴ"],
        [12, "ジャック／モモ"],
        [13, "オズ／アリス"],
        [14, "コナン／レダ"],
        [15, "アーサー／イシス"],
        [16, "エルリック／グローリアーナ"],
        [22, "ギルガメッシュ／アマテラス"],
        [23, "マハラジャ／クリシュナ"],
        [24, "カゲオトコ／クロトカゲ"],
        [25, "オルフェウス／ヴィーナス"],
        [26, "ソロモン／サロメ"],
        [33, "ワタリガラス／ディードリット"],
        [34, "ニャルラトホテプ／バースト"],
        [35, "アンナタール／フォルトゥナ"],
        [36, "ザナドゥ／ヨミ"],
        [44, "アルビオン／ラピュタ"],
        [45, "ゼンダ／ゴーメンガースト"],
        [46, "インスマウス／イース"],
        [55, "フウヌイム／ヤプー"],
        [56, "ザンス／ナルニア"],
        [66, "カレワラ／イーハトープ"],
    );

    return &get_table_by_number($num, @table);
}

#**デバイスファクトリー(1D6)
sub mk_device_factory_table {
    my $num = shift;
    my $output = &mk_item_decide_table(int(rand(6)+1));

    $num = 1;
    for(my $i=0; $i < $num; $i++) {
        my($dice, $dummy) = &roll(2, 6);
        $output .= ' / '.&mk_item_features_table($dice);
    }
    return $output;
}

#**アイテムカテゴリ決定表(1D6)
sub mk_item_decide_table {
    my $num = shift;

    my @table = (
[ 1, &mk_weapon_item_table(&d66(2)) ],
[ 2, &mk_life_item_table(&d66(2)) ],
[ 3, &mk_rest_item_table(&d66(2)) ],
[ 4, &mk_search_item_table(&d66(2)) ],
[ 5, &mk_rare_weapon_item_table(&d66(1)) ],
[ 6, &mk_rare_item_table(&d66(1)) ],
    );

    return &get_table_by_number($num, @table);
}

#**武具アイテム表(D66)
sub mk_weapon_item_table {
    my $num = shift;
    my @table = (
[ 11, 'だんびら' ],
[ 12, 'だんびら' ],
[ 13, 'ダガー' ],
[ 14, '戦斧' ],
[ 15, '盾' ],
[ 16, '鑓' ],
[ 22, '籠手（だんびら）' ],
[ 23, '手裏剣' ],
[ 24, '石弓' ],
[ 25, '甲冑' ],
[ 26, '戦鎚' ],
[ 33, '大弓（だんびら）' ],
[ 34, '爆弾' ],
[ 35, '鉄砲' ],
[ 36, '大剣' ],
[ 44, '拳銃（だんびら）' ],
[ 45, 'ホウキ' ],
[ 46, '徹甲弾' ],
[ 55, 'だんびら' ],
[ 56, '大砲' ],
[ 66, 'だんびら' ],
    );

    return &get_table_by_number($num, @table);
}

#**生活アイテム表(D66)
sub mk_life_item_table {
    my $num = shift;
    my @table = (
[ 11, 'バックパック' ],
[ 12, 'バックパック' ],
[ 13, '鍋' ],
[ 14, 'クラッカー' ],
[ 15, 'がまぐち' ],
[ 16, 'マント' ],
[ 22, '法衣（バックパック）' ],
[ 23, 'カード' ],
[ 24, 'エプロン' ],
[ 25, '住民台帳' ],
[ 26, '携帯電話' ],
[ 33, '召喚鍵（バックパック）' ],
[ 34, '肖像画' ],
[ 35, '衣装' ],
[ 36, '山吹色のお菓子' ],
[ 44, 'バックパック' ],
[ 45, '眼鏡' ],
[ 46, 'クレジットカード' ],
[ 55, 'バックパック' ],
[ 56, '魔道書' ],
[ 66, 'バックパック' ],
    );

    return &get_table_by_number($num, @table);
}

#**回復アイテム表(D66)
sub mk_rest_item_table {
    my $num = shift;
    my @table = (
[ 11, 'お弁当' ],
[ 12, 'お弁当' ],
[ 13, '特効薬' ],
[ 14, '保存食' ],
[ 15, '担架' ],
[ 16, '珈琲' ],
[ 22, '軟膏（お弁当）' ],
[ 23, 'チョコレート' ],
[ 24, 'お酒' ],
[ 25, 'フルコース' ],
[ 26, 'ポーション' ],
[ 33, 'お弁当' ],
[ 34, '救急箱' ],
[ 35, '強壮剤' ],
[ 36, '迷宮保険' ],
[ 44, 'お弁当' ],
[ 45, '科学調味料' ],
[ 46, '惚れ薬' ],
[ 55, 'お弁当' ],
[ 56, '復活薬' ],
[ 66, 'お弁当' ],
    );

    return &get_table_by_number($num, @table);
}

#**探索アイテム表(D66)
sub mk_search_item_table {
    my $num = shift;
    my @table = (
[ 11, '星の欠片' ],
[ 12, '星の欠片' ],
[ 13, '旗' ],
[ 14, 'お守り' ],
[ 15, '拷問具' ],
[ 16, 'パワーリスト' ],
[ 22, '工具（星の欠片）' ],
[ 23, 'テント' ],
[ 24, '楽器' ],
[ 25, '使い魔' ],
[ 26, '乗騎' ],
[ 33, '迷宮迷彩（星の欠片）' ],
[ 34, '罠百科' ],
[ 35, '迷宮防護服' ],
[ 36, '地図' ],
[ 44, '星の欠片' ],
[ 45, '時計' ],
[ 46, 'もぐら棒' ],
[ 55, '星の欠片' ],
[ 56, 'カボチャの馬車' ],
[ 66, '星の欠片' ],
    );

    return &get_table_by_number($num, @table);
}

#**レア武具アイテム表(1D6+1D6)
sub mk_rare_weapon_item_table {
    my $num = shift;
    my @table = (
[ 11, '虚弾' ],
[ 12, '怪物毒' ],
[ 13, '小鬼の襟巻' ],
[ 14, '喇叭銃' ],
[ 15, '蛍矢' ],
[ 16, '大盾' ],
[ 21, 'まわし' ],
[ 22, '怪物毒' ],
[ 23, 'しゃべる剣' ],
[ 24, '小麦粉' ],
[ 25, '王笏' ],
[ 26, '服従の鞭' ],
[ 31, 'ぬいぐるみ' ],
[ 32, '魔杖' ],
[ 33, '怪物毒' ],
[ 34, '星衣' ],
[ 35, '聖印' ],
[ 36, '獣の毛皮' ],
[ 41, '日傘' ],
[ 42, 'チェインソード' ],
[ 43, '邪眼' ],
[ 44, '怪物毒' ],
[ 45, '徒手空拳' ],
[ 46, 'バカには見えない鎧' ],
[ 51, 'ビキニアーマー' ],
[ 52, '輝く者' ],
[ 53, '貪る者' ],
[ 54, '滅ぼす者' ],
[ 55, '機械の体' ],
[ 56, '破城槌' ],
[ 61, '刈り取る者' ],
[ 62, '貫く者' ],
[ 63, '黄金の鶴嘴' ],
[ 64, 'ムラサマ' ],
[ 65, '蒸気甲冑' ],
[ 66, '王剣' ],
    );

    return &get_table_by_number($num, @table);
}

#**レア一般アイテム表(1D6+1D6)
sub mk_rare_item_table {
    my $num = shift;
    my @table = (
[ 11, 'ブルーリボン' ],
[ 12, '聖痕' ],
[ 13, '剥製' ],
[ 14, '愚者の冠' ],
[ 15, '名刺' ],
[ 16, '種籾' ],
[ 21, '香水' ],
[ 22, '守りの指輪（名刺）' ],
[ 23, '煙玉' ],
[ 24, '悪名' ],
[ 25, '藁人形' ],
[ 26, 'パワー餌' ],
[ 31, '王妃の鏡' ],
[ 32, '蓄音機' ],
[ 33, '無限の心臓（名刺）' ],
[ 34, '星籠' ],
[ 35, '水晶球' ],
[ 36, '転ばぬ先の杖' ],
[ 41, '悟りの書' ],
[ 42, '操りロープ' ],
[ 43, '盗賊の七つ道具' ],
[ 44, '携帯算術機（名刺）' ],
[ 45, '棺桶' ],
[ 46, 'カメラ' ],
[ 51, '不思議なたまご' ],
[ 52, 'ブーケ' ],
[ 53, '露眼鏡' ],
[ 54, '災厄王の遺物' ],
[ 55, '経験値' ],
[ 56, '鞍' ],
[ 61, '視肉' ],
[ 62, '玉璽' ],
[ 63, '衛星帯' ],
[ 64, '軍配' ],
[ 65, '聖杯' ],
[ 66, '愛' ],
    );

    return &get_table_by_number($num, @table);
}

#**アイテムの特性決定表(2D6)
sub mk_item_features_table {
    my $num = shift;
    my $output = "";
    my($dice, $dummy) = &roll(2, 6);
    if($num <= 2) {
        $output = '「'.&mk_item_power_table(int(rand(6))+1).'」の神力を宿す';
    }
    elsif($num <= 3) {
        $output = '寿命を持つ。寿命の値を決定する。'."\n";
        $output .= 'さらに、'.&mk_item_features_table($dice);
    }
    elsif($num <= 4) {
        $output = '境界障壁を持つ。《HP》の値を決定する。';
    }
    elsif($num <= 5) {
        $output = '銘を持つ。銘を決定する。';
    }
    elsif($num <= 6) {
        $output = '合成具である。もう1つの機能は「'.&mk_item_decide_table(int(rand(6))+1).'」である。';
    }
    elsif($num <= 7) {
        $output = 'そのアイテムにレベルがあれば、レベルを1点上昇する。'."\n";
        $output .='レベルが設定されていなければ、'.&mk_item_features_table($dice);
    }
    elsif($num <= 8) {
        $output = '「'.&mk_item_jyumon_table($dice).'」の呪紋を持つ。';
    }
    elsif($num <= 9) {
        $output = '「'.&mk_item_jyuka_table(int(rand(6))+1).'」の呪禍を持つ。'."\n";
        $output .='さらに、'.&mk_item_features_table($dice);
    }
    elsif($num <= 10) {
        $output = '高価だ。価格を設定する。';
    }
    elsif($num <= 11) {
        $output = '「条件：'.&mk_item_aptitude_table(int(rand(6))+1).'」の適性を持つ。'."\n";
        $output .='さらに、'.&mk_item_features_table($dice);
    }
    else {
        $output = '「'.&mk_item_attribute_table(int(rand(6))+1).'」の属性を持つ。';
    }
    return '特性['.$num.']：'.$output;
}

#**神力決定表(1D6)
sub mk_item_power_table {
    my $num = shift;
    my @table = (
[ 1, '〔才覚〕' ],
[ 2, '〔魅力〕' ],
[ 3, '〔探索〕' ],
[ 4, '〔武勇〕' ],
[ 5, '〈器〉' ],
[ 6, '〈回避値〉' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

#**呪紋決定表(2D6)
sub mk_item_jyumon_table {
    my $num = shift;
    my @table = (
[ 2, 'モンスタースキル' ],
[ 3, '便利スキル' ],
[ 4, '芸能スキル' ],
[ 5, '迷宮スキル' ],
[ 6, '星術スキル' ],
[ 7, '一般スキル' ],
[ 8, '召喚スキル' ],
[ 9, '科学スキル' ],
[ 10, '交渉スキル' ],
[ 11, '神官のクラススキル' ],
[ 12, 'ジョブスキル' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

#**呪禍表(1D6)
sub mk_item_jyuka_table {
    my $num = shift;
    my @table = (
[ 1, '「呪い」のバッドステータス' ],
[ 2, '「肥満」のバッドステータス' ],
[ 3, '「愚か」のバッドステータス' ],
[ 4, 'サイクルの終了時に《HP》が1点減少する' ],
[ 5, '条件を満たしても誰とも人間関係を結べない' ],
[ 6, '〈器〉が1点減少する' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

#**適正表(1D6)
sub mk_item_aptitude_table {
    my $num = shift;
    my @table = (
[ 1, 'ランダムなクラス1種' ],
[ 2, &mk_family_business_table(&d66(2)) ],
[ 3, &mk_gender_table(int(rand 6)+1).'性' ],
[ 4, '上級ジョブ' ],
[ 5, 'モンスタースキルを修得' ],
[ 6, '童貞、もしくは処女' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

#**属性表(1D6)
sub mk_item_attribute_table {
    my $num = shift;
    my @table = (
[ 1, '自然の力' ],
[ 2, '幻夢の力' ],
[ 3, '星炎の力' ],
[ 4, '暗黒の力' ],
[ 5, '聖なるの力' ],
[ 6, '災厄の力' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

sub mk_gender_table {
    my $num = shift;
    my $output = '1';
    
    if($num % 2) {
        $output = '男';
    } else {
        $output = '女';
    }
    
    return $output;
}

#**生まれ表(D66)
sub mk_family_business_table {
    my $num = shift;
    my @table = (
[ 11, '星術師' ],
[ 12, '魔道師' ],
[ 13, '召喚師' ],
[ 14, '博士' ],
[ 15, '医者' ],
[ 16, '貴族' ],
[ 22, '宦官' ],
[ 23, '武人' ],
[ 24, '処刑人' ],
[ 25, '衛視' ],
[ 26, '商人' ],
[ 33, '迷宮職人' ],
[ 34, '亭主' ],
[ 35, '料理人' ],
[ 36, '寿ぎ屋' ],
[ 44, '働きもの' ],
[ 45, '狩人' ],
[ 46, '冒険者' ],
[ 55, '怠け者' ],
[ 56, '盗賊' ],
[ 66, '生まれ表の中から、好きなジョブ1つを選ぶ' ],
    );

    return "[${num}]".&get_table_by_number($num, @table);
}

#**1レベルランダムエンカウント表(1D6)
sub mk_random_encount1_table {
    my $num = shift;
    my @table = (
[ 1, '『守って守って突撃ゴー！』　前衛：ごんぎつね×宮廷の人数、後衛：ノコギリ猪×1' ],
[ 2, '『じわじわ削る、カボチャの舞』　前衛：焔虫×宮廷の人数、本陣：カボチャ頭×宮廷の人数の半分' ],
[ 3, '『ものすごくジャマな人たち。』　前衛：小人さん×宮廷の人数、取り替え子×宮廷の人数の半分' ],
[ 4, '『何かやってくれるかも……』　前衛：兵隊エルフ×宮廷の人数' ],
[ 5, '『【かばう】で延命しつつ【鉄の勇気】』　前衛：キンギョ×宮廷の人数、本陣：イカロス×宮廷の人数の半分' ],
[ 6, '『英雄で指示してシュシュシュシュ～～～～ト!!』　前衛：小鬼×宮廷の人数、後衛：小鬼×宮廷の人数、本陣：小鬼大砲×1、小鬼英雄×1' ],
    );

    return &get_table_by_number($num, @table);
}

#**2レベルランダムエンカウント表(1D6)
sub mk_random_encount2_table {
    my $num = shift;
    my @table = (
[ 1, '『作戦判定に負けてもOK、そして強い』　前衛：ガーゴイル×宮廷の人数' ],
[ 2, '『吸い殺せ！　ドレインしまくれ！』　後衛：塚人×宮廷の人数の半分' ],
[ 3, '『ゴールデンコンビ結成。指揮と【鉄腕】＋【範囲攻撃】で大暴れ』　前衛：牛頭×宮廷の人数の半分、後衛：山羊頭×宮廷の人数の半分' ],
[ 4, '『クピドは野放しにできないが、ハルキュオネは殺せない。このジレンマが……』　前衛：ハルキュオネ×宮廷の人数、後衛：ハルキュオネ×宮廷の人数、本陣：クピド×宮廷の人数の半分' ],
[ 5, '『眠りコンボ』　前衛：グレムリン×宮廷の人数、本陣：眠りの精×1' ],
[ 6, '『回避を減らしてみみずの範囲攻撃』　前衛：みみず×宮廷の人数、本陣：大喰らい×宮廷の人数の半分' ],
    );

    return &get_table_by_number($num, @table);
}

#**3レベルランダムエンカウント表(1D6)
sub mk_random_encount3_table {
    my $num = shift;
    my @table = (
[ 1, '『魅了→木霊ハメ』　後衛：淫魔×1、本陣：レーシィ×宮廷の人数' ],
[ 2, '『素早く【多勢に無勢】をしかけ……たい』　前衛：階賊×宮廷の人数、本陣：抜け忍×1' ],
[ 3, '『倒しても嬉しくない人柱をどうぞ』　前衛：人柱×宮廷の人数、本陣：恋のぼり×宮廷の人数の半分' ],
[ 4, '『位置を調整して【抱擁】してみよう』　後衛：霧妾×宮廷の人数、本陣：お化けシーツ×宮廷の人数' ],
[ 5, '『クリティカルヒットしたい（希望）』　後衛：ヴォーパルバニー×宮廷の人数、本陣：二面人×1' ],
[ 6, '『なんとか特攻したい（願望）』　前衛：穴人×宮廷の人数、ゴーレム×1' ],
    );

    return &get_table_by_number($num, @table);
}

#**4レベルランダムエンカウント表(1D6)
sub mk_random_encount4_table {
    my $num = shift;
    my @table = (
[ 1, '『増やして治す。ド外道タッグが嵐を呼ぶぜ』　前衛：闇双子×1、本陣：坊主子牛×宮廷の人数の半分' ],
[ 2, '『カリスマ的存在＋平和の使者→エセNGOみたいな？』　前衛：ワリアヒラ×宮廷の人数、後衛：妖精騎士×1' ],
[ 3, '『【星戦】→攻撃、【星界】→【ベアハッグ】』　前衛：洞窟熊×宮廷の人数、本陣：星人×宮廷の人数の半分' ],
[ 4, '『さりげなく先攻を取りつつ《民》をバイドバイパー作戦』　前衛：大目玉×宮廷の人数、本陣：笛吹き男×宮廷の人数の半分' ],
[ 5, '『アンデッドチーム、がんばれ！』　前衛：墓暴き×宮廷の人数、本陣：吸血鬼×1' ],
[ 6, '『まよセレ、このゲームの代名詞（？）。こいつは欠かせない！』　後衛：マヨネーズキング・ピュアセレクト×宮廷の人数、本陣：メイクイーン×1' ],
    );

    return &get_table_by_number($num, @table);
}

#**5レベルランダムエンカウント表(1D6)
sub mk_random_encount5_table {
    my $num = shift;
    my @table = (
[ 1, '『「死ぬが良い」最終鬼畜兵器岸降臨』　前衛：暗黒騎士×1' ],
[ 2, '『割と痛い。さりげなく魔王が分裂する』　前衛：カミツキ魔王×宮廷の人数の半分、本陣：雷鳥×1' ],
[ 3, '『ハマると死ぬ。5人パーティだと3体出てザマーミロ』　前衛：ヴァララカール×宮廷の人数の半分' ],
[ 4, '『不意打ちされたらデンジャー。ひそかにワイヴァーンで先手を取る』　前衛：睨み毒蛇×宮廷の人数の半分、後衛：ワイヴァーン×1' ],
[ 5, '『ゾンビスペシャル……で、がんばりたい』　前衛：死にぞこない×宮廷の人数の半分、後衛：死にぞこない×宮廷の人数の半分、本陣：屍術師×1' ],
[ 6, '『とにかく殴れ！　単純明快パワーチーム』　前衛：鮫人×宮廷の人数、夜這い海星×1' ],
    );

    return &get_table_by_number($num, @table);
}

#**6レベルランダムエンカウント表(1D6)
sub mk_random_encount6_table {
    my $num = shift;
    my @table = (
[ 1, '『死んでください。【外皮】か【甲冑】がないと相当ヤバい』　本陣：死告天使×宮廷の人数' ],
[ 2, '『ド迫力。ブレス連発。3体出ちゃったらカーニバル』　本陣：ドラゴン×宮廷の人数の半分' ],
[ 3, '『死霊のボス。スキル次第でヤバい。GMの悪意が閃くときだ』　本陣：骨龍×1、推奨スキル【不滅の炎】、【困惑】、【ヤバチョンガー】など' ],
[ 4, '『《好意》を消して【魅了】に持ち込む』　後衛：愛染明王×宮廷の人数' ],
[ 5, '『真の狙いは【蜘蛛の群れ】』　前衛：アラクネ×宮廷の人数、本陣：蜘蛛の王×1' ],
[ 6, '『お約束。まあこいつは出るだろうみたいな』　前衛：魔蟹×1、帳魚×1' ],
    );

    return &get_table_by_number($num, @table);
}

#**地名決定表
sub mk_pn_decide_table {
    my $num = shift;
    my $output = '';
    my $d1 = int(rand 6)+1;
    my $d2 = int(rand 6)+1;
    
    for(my $i = 0; $i < $num; $i++) {
        $output .= "「".&mk_decoration_table(int($d1 / 2)).&mk_placename_table(int($d2 / 2))."」";
    }
    return $output;
}

#**修飾決定表(1D6)
sub mk_decoration_table {
    my $num = shift;
    
    my @table = (
[ 1, &mk_basic_decoration_table(&d66(2)) ],
[ 2, &mk_spooky_decoration_table(&d66(2)) ],
[ 3, &mk_katakana_decoration_table(&d66(2)) ],
    );
    return &get_table_by_number($num, @table);
}

#**地名決定表(1D6)
sub mk_placename_table {
    my $num = shift;
    my @table = (
[ 1, &mk_passage_placename_table(&d66(2)) ],
[ 2, &mk_natural_placename_table(&d66(2)) ],
[ 3, &mk_artifact_placename_table(&d66(2)) ],
    );
    return &get_table_by_number($num, @table);
}

#**基本表(D66)
sub mk_basic_decoration_table {
    my $num = shift;
    my @table = (
[ 11, '欲望（よくぼう）' ],
[ 12, '漂流（ひょうりゅう）' ],
[ 13, '黄金（おうごん）' ],
[ 14, '火達磨（ひだるま）' ],
[ 15, '災厄（さいやく）' ],
[ 16, '三日月（みかづき）' ],
[ 22, '絡繰り（からくり）' ],
[ 23, '流星（りゅうせい）' ],
[ 24, '棘々（とげとげ）' ],
[ 25, '鏡（かがみ）' ],
[ 26, '銀鱗（ぎんりん）' ],
[ 33, '螺旋（らせん）' ],
[ 34, '七色（なないろ）' ],
[ 35, '殉教（じゅんきょう）' ],
[ 36, '水晶（すいしょう）' ],
[ 44, '氷結（ひょうけつ）' ],
[ 45, '忘却（ぼうきゃく）' ],
[ 46, '幸福（こうふく）' ],
[ 55, '妖精（ようせい）' ],
[ 56, '霧雨（きりさめ）' ],
[ 66, '夕暮れ（ゆうぐれ）' ],
    );
    return &get_table_by_number($num, @table);
}

#**不気味表(D66)
sub mk_spooky_decoration_table {
    my $num = shift;
    my @table = (
[ 11, '赤錆（あかさび）' ],
[ 12, '串刺し（くしざし）' ],
[ 13, '鬼蜘蛛（おにぐも）' ],
[ 14, '蠍（さそり）' ],
[ 15, '幽霊（ゆうれい）' ],
[ 16, '髑髏（どくろ）' ],
[ 22, '血溜まり（ちだまり）' ],
[ 23, '臓物（ぞうもつ）' ],
[ 24, '骸（むくろ）' ],
[ 25, '鉤爪（かぎづめ）' ],
[ 26, '犬狼（けんろう）' ],
[ 33, '奈落（ならく）' ],
[ 34, '大蛇（おろち）' ],
[ 35, '地獄（じごく）' ],
[ 36, '蚯蚓（みみず）' ],
[ 44, '退廃（たいはい）' ],
[ 45, '土竜（もぐら）' ],
[ 46, '絶望（ぜつぼう）' ],
[ 55, '夜泣き（よなき）' ],
[ 56, '緑林（りょくりん）' ],
[ 66, 'どん底（どんぞこ）' ],
    );
    return &get_table_by_number($num, @table);
}

#**カタカナ表(D66)
sub mk_katakana_decoration_table {
    my $num = shift;
    my @table = (
[ 11, 'マヨネーズ' ],
[ 12, 'ダイナマイト' ],
[ 13, 'ドラゴン' ],
[ 14, 'ボヨヨン' ],
[ 15, 'モケモケ' ],
[ 16, 'マヌエル' ],
[ 22, 'ダイス' ],
[ 23, 'ロマン' ],
[ 24, 'ウクレレ' ],
[ 25, 'エップカプ' ],
[ 26, 'カンパネルラ' ],
[ 33, 'マンチキン' ],
[ 34, 'バロック' ],
[ 35, 'ミサイル' ],
[ 36, 'ドッキリ' ],
[ 44, 'ブラック' ],
[ 45, '好きなモンスターの名前' ],
[ 46, '好きなトラップの名前' ],
[ 55, '好きな単語表で' ],
[ 56, '好きな名前決定表で' ],
[ 66, '好きな数字の組み合わせ' ],
    );
    return &get_table_by_number($num, @table);
}

#**通路系地名表(D66)
sub mk_passage_placename_table {
    my $num = shift;
    my @table = (
[ 11, '門（ゲート）' ],
[ 12, '回廊（コリドー）' ],
[ 13, '通り（ストリート）' ],
[ 14, '小路（アレイ）' ],
[ 15, '大路（アベニュー）' ],
[ 16, '街道（ロード）' ],
[ 22, '鉄道（ライン）' ],
[ 23, '迷宮（メイズ）' ],
[ 24, '坑道（トンネル）' ],
[ 25, '坂（スロープ）' ],
[ 26, '峠（パス）' ],
[ 33, '運河（カナル）' ],
[ 34, '水路（チャネル）' ],
[ 35, '河（ストリーム）' ],
[ 36, '堀（モート）' ],
[ 44, '溝（ダイク）' ],
[ 45, '階段（ステア）' ],
[ 46, '辻（トレイル）' ],
[ 55, '橋（ブリッジ）' ],
[ 56, '穴（ホール）' ],
[ 66, '柱廊（ストア）' ],
    );
    return &get_table_by_number($num, @table);
}

#**自然系地名表(D66)
sub mk_natural_placename_table {
    my $num = shift;
    my @table = (
[ 11, '砂漠（デザート）' ],
[ 12, '丘陵（ヒル）' ],
[ 13, '海（オーシャン）' ],
[ 14, '森（フォレスト）' ],
[ 15, '沼（ポンド）' ],
[ 16, '海岸（コースト）' ],
[ 22, '密林（ジャングル）' ],
[ 23, '湖（レイク）' ],
[ 24, '山脈（マウンテンズ）' ],
[ 25, '平原（プレイン）' ],
[ 26, 'ヶ原（ランド）' ],
[ 33, '荒野（ヒース）' ],
[ 34, '渓谷（ヴァレー）' ],
[ 35, '島（アイランド）' ],
[ 36, '連峰（ピークス）' ],
[ 44, '火山（ヴォルケイノ）' ],
[ 45, '湿原（ウェットランド）' ],
[ 46, '星雲（ネビュラ）' ],
[ 55, '星（スター）' ],
[ 56, 'ヶ淵（プール）' ],
[ 66, '雪原（スノウズ）' ],
    );
    return &get_table_by_number($num, @table);
}

#**人工系地名表(D66)
sub mk_artifact_placename_table {
    my $num = shift;
    my @table = (
[ 11, '城（キャッスル）' ],
[ 12, '壁（ウォール）' ],
[ 13, '砦（フォート）' ],
[ 14, '地帯（ゾーン）' ],
[ 15, '室（ルーム）' ],
[ 16, 'の間（チャンバー）' ],
[ 22, '浴室（バス）' ],
[ 23, '畑（ファーム）' ],
[ 24, '館（ハウス）' ],
[ 25, '座（コンスティレィション）' ],
[ 26, '遺跡（ルイン）' ],
[ 33, 'ヶ浜（ビーチ）' ],
[ 34, '塔（タワー）' ],
[ 35, '墓場（グレイブ）' ],
[ 36, '洞（ケイヴ）' ],
[ 44, '堂（バジリカ）' ],
[ 45, '野（フィールド）' ],
[ 46, '書院（スタディ）' ],
[ 55, '駅前（ステイション）' ],
[ 56, '房（クラスター）' ],
[ 66, '腐海（ケイオスシー）' ],
    );
    return &get_table_by_number($num, @table);
}

#**迷宮風景決定表
sub mk_ls_decide_table {
    my $num = shift;
    my $output = '';
    for(my $i = 0; $i < $num; $i++) {
        $output .= "「".&mk_landscape_table(int(rand 6)+1)."」";
    }
    return $output;
}

#**迷宮風景表(1D6)
sub mk_landscape_table {
    my $num = shift;
    my $dice = &d66(2);
    my @table = (
[ 1, &mk_artifact_landscape_table($dice) ],
[ 2, &mk_cave_landscape_table($dice) ],
[ 3, &mk_natural_landscape_table($dice) ],
[ 4, &mk_waterside_landscape_table($dice) ],
[ 5, &mk_skyrealm_landscape_table($dice) ],
[ 6, &mk_strange_place_landscape_table($dice) ],
    );
    return &get_table_by_number($num, @table);
}

#**人工風景表(D66)
sub mk_artifact_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '石組みの部屋' ],
[ 12, '巨大な縦穴に刻まれた螺旋階段' ],
[ 13, '埃だらけの古い図書館' ],
[ 14, '古びた、素朴な祭壇' ],
[ 15, '歯車やピストンがやかましい動力室' ],
[ 16, '石組みの巨大な階段' ],
[ 22, '太い丸太で組まれた部屋' ],
[ 23, '作りかけの製品が放置された工房' ],
[ 24, '錆びた武器や骨が散らばる古戦場' ],
[ 25, '石組みのトイレ' ],
[ 26, '高い天井の厨房' ],
[ 33, 'レンガで組まれた部屋' ],
[ 34, '静まりかえった劇場' ],
[ 35, 'がらくたが散らばっているゴミ捨て場' ],
[ 36, '切り出し途中で放棄された巨大な石像' ],
[ 44, '壁画やタペストリーが残る大広間' ],
[ 45, 'メトロ汗国の線路' ],
[ 46, '絵画や彫刻が展示してあるギャラリー' ],
[ 55, '石棺が並ぶ墓' ],
[ 56, '錆びついた扉が残る巨大な門' ],
[ 66, '放置された牢獄' ],
    );
    return &get_table_by_number($num, @table);
}

#**洞窟風景表(D66)
sub mk_cave_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '岩肌がむき出しの洞穴' ],
[ 12, 'コウモリや羽蟲が飛び交う洞穴' ],
[ 13, '放置された坑道' ],
[ 14, '誰かのキャンプ跡' ],
[ 15, '岩だらけで見通しのきかない空洞' ],
[ 16, '煙が吹きぬける洞穴' ],
[ 22, 'どこからか水音が響く鍾乳洞' ],
[ 23, '光の衰えた星がまたたく幻想的な空洞' ],
[ 24, '流砂が流れる洞穴' ],
[ 25, '生物が掘った、つるつるした洞穴' ],
[ 26, '冷えきった氷の洞穴' ],
[ 33, '巨大な岩の隙間' ],
[ 34, '動物や狩を描いた素朴な壁画が続く洞穴' ],
[ 35, '巨大な空洞にかけられた自然の橋' ],
[ 36, '埋まりかけで天井すれすれの洞穴' ],
[ 44, '奈落と断崖絶壁' ],
[ 45, '壁がうごめく蟲でおおわれた洞穴' ],
[ 46, '無数の化石が埋まっている洞穴' ],
[ 55, '熱気を放つ溶岩が流れる空洞' ],
[ 56, '水晶でできた洞穴' ],
[ 66, '骨が散らばるなにものかの住処' ],
    );
    return &get_table_by_number($num, @table);
}

#**自然風景表(D66)
sub mk_natural_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '苔むした部屋' ],
[ 12, '動物の声が響き渡る密林' ],
[ 13, 'つる草でできた通路' ],
[ 14, '空洞いっぱいのお花畑' ],
[ 15, '壁から木の根が突き出している部屋' ],
[ 16, '空洞に広がる耕作地' ],
[ 22, '折り重なって繁茂する森林' ],
[ 23, '垂直の空洞にえんえんと伸びる大木の幹' ],
[ 24, '空洞中に広がるアザラシの営巣地' ],
[ 25, 'カビで壁がねとつく部屋' ],
[ 26, 'サボテンが点在する部屋' ],
[ 33, '巨大キノコの群生地' ],
[ 34, '真ん中に大木が一本そびえ立っている空洞' ],
[ 35, '通路いっぱいに進む野生ウマトカゲの大群' ],
[ 36, '落ち葉がうずたかく積もった部屋' ],
[ 44, '植え込みで作られた迷宮庭園' ],
[ 45, '生い茂る竹林' ],
[ 46, '松ぼっくりが転がる部屋' ],
[ 55, '丈の長い草が生い茂る部屋' ],
[ 56, '枯れた森林' ],
[ 66, '大木の空洞内のような通路や部屋' ],
    );
    return &get_table_by_number($num, @table);
}

#**水域風景表(D66)
sub mk_waterside_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '轟々と流れる川にかかった橋' ],
[ 12, '色とりどりの珊瑚の中' ],
[ 13, '腰高まで水に浸かった部屋' ],
[ 14, '澄んだ水が流れる噴水と水飲み場' ],
[ 15, '沸騰する湖' ],
[ 16, '地面が干潟化した部屋' ],
[ 22, '水をたたえた貯水池' ],
[ 23, '熱い蒸気がたちこめる部屋' ],
[ 24, '空洞に広がる沼地' ],
[ 25, '樽や鎖が放置されている船の中' ],
[ 26, '水槽が並ぶ水族館' ],
[ 33, '悪臭を放つ下水道' ],
[ 34, '底に遺跡が見える水没した空洞' ],
[ 35, '桟橋と船着き場' ],
[ 36, '筏やハシケが浮かぶ湖' ],
[ 44, '巨大な縦穴と滝' ],
[ 45, 'かつて建設された上水道の中' ],
[ 46, 'ペンギンの右往左往する氷結した湖' ],
[ 55, '湯気を立てる温泉' ],
[ 56, '奇怪な彫刻が施された古井戸' ],
[ 66, '壁に貝やフジツボがはりついた部屋' ],
    );
    return &get_table_by_number($num, @table);
}

#**天空風景表(D66)
sub mk_skyrealm_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '雨が降る部屋' ],
[ 12, 'チーズにうがたれた洞穴' ],
[ 13, '中空に何層にも重なる空中庭園' ],
[ 14, '無限に連なる真っ白な洗濯物' ],
[ 15, '天空に向かって伸びる豆の木' ],
[ 16, '巨大な縦穴にぶら下がる縄ばしごや鎖' ],
[ 22, '強風の吹き荒れる部屋' ],
[ 23, '雲の上。なぜか、その上を歩くことができる' ],
[ 24, '濃霧に覆われた空洞' ],
[ 25, '無重量でふわふわ浮く部屋' ],
[ 26, '雪がしんしんと降り積もる部屋' ],
[ 33, '時空がねじ曲がった空中回廊' ],
[ 34, '怪物よけの風車が音を立てる通路' ],
[ 35, '天井に遺跡が見える空洞' ],
[ 36, '轟々と音を立てる巨大排気孔' ],
[ 44, '時折稲妻の走る部屋' ],
[ 45, '鳥の羽毛が舞い落ちる部屋' ],
[ 46, '青空が壁面いっぱいに描かれた空洞' ],
[ 55, '一面、鏡でできた部屋' ],
[ 56, 'オーロラがゆらめく空洞' ],
[ 66, '重力方向がばらばらの部屋' ],
    );
    return &get_table_by_number($num, @table);
}

#**異界風景表(D66)
sub mk_strange_place_landscape_table {
    my $num = shift;
    my @table = (
[ 11, '古びた六畳間' ],
[ 12, 'せせこましいカラオケボックス' ],
[ 13, '時の止まった街' ],
[ 14, 'ボールが一個転がっている体育館' ],
[ 15, '毛が生えている部屋' ],
[ 16, 'なにかの待合室' ],
[ 22, '生物の粘液したたる体内' ],
[ 23, 'ブランコやすべり台のある小公園' ],
[ 24, '安っぽいユニットバス' ],
[ 25, '上の住人がうるさい部屋' ],
[ 26, '人骨で組まれている部屋' ],
[ 33, '呼吸している部屋' ],
[ 34, '斜めに傾いた部屋' ],
[ 35, 'ラブホテルの一室' ],
[ 36, 'ときどきなにかが覗いていく部屋' ],
[ 44, 'がやがやと話し声が聞こえる部屋' ],
[ 45, '触手が生えている部屋' ],
[ 46, '机と椅子が置いてある取調室' ],
[ 55, '静まりかえった教室' ],
[ 56, '天井に巨大な人の顔がある部屋' ],
[ 66, '常に揺れている部屋' ],
    );
    return &get_table_by_number($num, @table);
}




####################        エムブリオマシン       ########################
sub em_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my $type = "";
    my $total_n = "";

    my $dummy;
    if($string =~ /HLT/i) {
        $type = '命中部位';
        ($total_n, $dummy) = &roll(2, 10);
        $output = &em_hit_location_table($total_n);
    } elsif($string =~ /SFT/i) {
        $type = '射撃ファンブル';
        ($total_n, $dummy) = &roll(2, 10);
        $output = &em_shoot_fumble_table($total_n);
    } elsif($string =~ /MFT/i) {
        $type = '白兵ファンブル';
        ($total_n, $dummy) = &roll(2, 10);
        $output = &em_melee_fumble_table($total_n);
    }

    if($output ne '1') {
        $output = "$_[1]: ${type}表(${total_n}) ＞ $output";
    }
    return $output;
}

#** 命中部位表
sub em_hit_location_table {
    my $num = shift;
    my @table = (
        [ 4, '頭'],
        [ 7, '左脚'],
        [ 9, '左腕'],
        [12, '胴'],
        [14, '右腕'],
        [17, '右脚'],
        [20, '頭'],
    );

    return &get_table_by_number($num, @table);
}

#** ファンブル表
sub em_shoot_fumble_table { # 射撃攻撃ファンブル表
    my $num = shift;
    my $output = '1';
    my $dc = 2;
    my @table = (
        '暴発した。使用した射撃武器が搭載されている部位に命中レベルAで命中する。',
        'あまりに無様な誤射をした。パイロットの精神的負傷が2段階上昇する。',
        '誤射をした。自機に最も近い味方機体に命中レベルAで命中する。',
        '誤射をした。対象に最も近い味方機体に命中レベルAで命中する。',
        '武装が暴発した。使用した射撃武器が破損する。ダメージは発生しない。',
        '転倒した。次のセグメントのアクションが待機に変更される。',
        '弾詰まりを起こした。使用した射撃武器は戦闘終了まで使用できなくなる。',
        '砲身が大きく歪んだ。使用した射撃武器による射撃攻撃の命中値が戦闘終了まで-3される。',
        '熱量が激しく増大した。使用した射撃武器の消費弾薬が戦闘終了まで+3される。',
        '暴発した。使用した射撃武器が搭載されている部位に命中レベルBで命中する。',
        '弾薬が劣化した。使用した射撃武器の全てのダメージが戦闘終了まで-2される。',
        '無様な誤射をした。パイロットの精神的負傷が1段階上昇する。',
        '誤射をした。対象に最も近い味方機体に命中レベルBで命中する。',
        '誤射をした。自機に最も近い味方機体に命中レベルBで命中する。',
        '砲身が歪んだ。使用した射撃武器による射撃攻撃の命中値が戦闘終了まで-2される。',
        '熱量が増大した。使用した射撃武器の消費弾薬が戦闘終了まで+2される。',
        '砲身がわずかに歪んだ。使用した射撃武器による射撃攻撃の命中値が戦闘終了まで-1される。',
        '熱量がやや増大した。使用した射撃武器の消費弾薬が戦闘終了まで+1される。',
        '何も起きなかった。',
    );
    $output = $table[$num - $dc] if($table[$num - $dc]);
    return $output;
}
sub em_melee_fumble_table { # 白兵攻撃ファンブル表
    my $num = shift;
    my $output = '1';
    my $dc = 2;
    my @table = (
        '大振りしすぎた。使用した白兵武器が搭載されている部位の反対の部位(右腕に搭載されているなら左側)に命中レベルAで命中する。',
        '激しく頭を打った。パイロットの肉体的負傷が2段階上昇する。',
        '過負荷で部位が爆発した。使用した白兵武器が搭載されている部位が全壊する。ダメージは発生せず、搭載されている武装も破損しない。',
        '大振りしすぎた。使用した白兵武器が搭載されている部位の反対の部位(右腕に搭載されているなら左側)に命中レベルBで命中する。',
        '武装が爆発した。使用した白兵武器が破損する。ダメージは発生しない。',
        '部分的に機能停止した。使用した白兵武器は戦闘終了まで使用できなくなる。',
        '転倒した。次のセグメントのアクションが待機に変更される。',
        '激しい刃こぼれを起こした。使用した白兵武器の全てのダメージが戦闘終了まで-3される。',
        '地面の凹凸にはまった。次の2セグメントは移動を行うことができない。',
        '刃こぼれを起こした。使用した白兵武器の全てのダメージが戦闘終了まで-2される。',
        '大振りしすぎた。使用した白兵武器が搭載されている部位の反対の部位(右腕に搭載されているなら左側)に命中レベルCで命中する。',
        '頭を打った。パイロットの肉体的負傷が1段階上昇する。',
        '駆動系が損傷した。移動力が戦闘終了まで-2される(最低1)。',
        '間合いを取り損ねた。隣接している機体(複数の場合は1機をランダムに決定)に激突する。',
        '機体ごと突っ込んだ。機体が向いている方角へ移動力をすべて消費するまで移動する。',
        '制御系が損傷した。回避値が戦闘終了まで-1される(最低1)。',
        '踏み誤った。機体が向いている方角へ移動力の半分を消費するまで移動する。',
        'たたらを踏んだ。機体が向いている方角へ1の移動力で移動する。',
        '何も起きなかった。',
    );
    $output = $table[$num - $dc] if($table[$num - $dc]);
    return $output;
}

sub em_hit_level_table {
    my $num = shift;
    my @table = (
        [ 6, '命中レベルC'],
        [ 9, '命中レベルB'],
        [10, '命中レベルA'],
    );

    return &get_table_by_number($num, @table);
}

####################      ゲヘナ・アナスタシス    ########################
sub ga_ma_chit_table {
    my $num = shift;
    my @table = (
        [ 6, '1'],
        [13, '2'],
        [18, '3'],
        [22, '4'],
        [99, '5'],
    );

    return &get_table_by_number($num, @table);
}

####################          マギカロギア         ########################
#** 表振り分け
sub magicalogia_table {
    my ($string, $nick) = @_;
    my $output = '1';
    
    if($game_type eq "MagicaLogia") {
        if($string =~ /((\w)*BGT)/i) {   # 経歴表
            $output = &magicalogia_background_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*DAT)/i) {   # 初期アンカー表
            $output = &magicalogia_defaultanchor_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*FAT)/i) {   # 運命属性表
            $output = &magicalogia_fortune_attribution_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*WIT)/i) {   # 願い表
            $output = &magicalogia_wish_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*ST)/i) {  # シーン表
            $output = &magicalogia_scene_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*FT)/i) {   # ファンブル表
            $output = &magicalogia_fumble_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*WT)/i) {   # 変調表
            $output = &magicalogia_wrong_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*(FC|C)T)/i) {   # 運命変転表
            $output = &magicalogia_fortunechange_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*AT)/i) {   # 事件表
            $output = &magicalogia_accident_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)*RTT)/i) {   # ランダム特技決定表
            $output = &magicalogia_random_skill_table("\U$1", "$nick");
        }
    }
    return $output;
}

#** シーン表
sub magicalogia_scene_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my $type = "";
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

#    if($string =~ /CST/i) {
#        $type = '都市';
#    }
    if($type eq '都市') {
    }
    else {
        @table = (
            '魔法で作り出した次元の狭間。ここは時間や空間から切り離された、どこでもあり、どこでもない場所だ。',
            '夢の中。遠く過ぎ去った日々が、あなたの前に現れる。',
            '静かなカフェの店内。珈琲の香りと共に、優しく穏やかな雰囲気が満ちている。',
            '強く風が吹き、雲が流されていく。遠く、雷鳴が聞こえた。どうやら、一雨きそうだ。',
            '無人の路地裏。ここならば、邪魔が入ることもないだろう。',
            '周囲で〈断章〉が引き起こした魔法災厄が発生する。ランダムに特技一つを選び、判定を行うこと。成功すると、好きな魔素が一個発生する。失敗すると「運命変転表」を使用する。',
            '夜の街を歩く。暖かな家々の明かりが、遠く見える。',
            '読んでいた本を閉じる。そこには、あなたが知りたがっていたことが書かれていた。なるほど、そういうことか。',
            '大勢の人々が行き過ぎる雑踏の中。あなたを気に掛ける者は誰もいない。',
            '街のはるか上空。あなたは重力から解き放たれ、自由に空を飛ぶ。',
            '未来の予感。このままだと起きるかもしれない出来事の幻が現れる。',
        );
    }
    my ($total_n, $dice_dmy) = &roll(2, 6);
    my $tn = $total_n - 2;
    $output = "${nick}: ${type}シーン表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** ファンブル表
sub magicalogia_fumble_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

    @table = (
        '魔法災厄が、あなたのアンカーに降りかかる。「運命変転」が発生する。',
        '魔法災厄が、あなたの魔素を奪い取る。チャージしている魔素の中から、好きな組み合わせで2点減少する。',
        '魔法の制御に失敗してしまう。【魔力】が1点減少する。',
        '魔法災厄になり、そのサイクルが終了するまで、行為判定にマイナス1の修正が付く。',
        '魔法災厄が、直接あなたに降りかかる。変調表を振り、その変調を受ける。',
        'ふぅ、危なかった。特に何も起こらない。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: ファンブル表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 変調表
sub magicalogia_wrong_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

#   if($string =~ /GWT/) {
#       $type = ''
#   }
    if($type eq '都市') {
    }
    else {
        @table = (
            '『封印』自分の魔法(習得タイプが装備以外)からランダムに一つ選ぶ。選んだ魔法のチェック欄をチェックする。その魔法を使用するには【魔力】を2点消費しなくてはいけない。',
            '『綻び』魔法戦の間、各ラウンドの終了時に自分の【魔力】が1点減少する。',
            '『虚弱』【攻撃力】が1点減少する。',
            '『病魔』【防御力】が1点減少する。',
            '『遮蔽』【根源力】が1点減少する',
            '『不運』1D6→2D6と振ってランダムに特技を一つ選ぶ。選んだ特技のチェック欄をチェックする。その特技が使用不能になり、その分野の特技が指定特技になった判定を行うとき、マイナス1の修正が付く。',
            );
    }
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: ${type}変調表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 運命変転表
sub magicalogia_fortunechange_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

#   if($string =~ /GCT/) {
#       $type = ''
#   }
    @table = (
        '『挫折』そのキャラクターは、自分にとって大切だった夢を諦める。',
        '『別離』そのキャラクターにとって大切な人――親友や恋人、親や兄弟などを失う。',
        '『大病』そのキャラクターは、不治の病を負う。',
        '『借金』そのキャラクターは、悪人に利用され多額の借金を負う。',
        '『不和』そのキャラクターは、人間関係に失敗し深い心の傷を負う。',
        '『事故』そのキャラクターは交通事故にあい、取り返しのつかない怪我を負う。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: ${type}運命変転表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 事件表
sub magicalogia_accident_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my $type = "";
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

#    if($string =~ /CST/i) {
#        $type = '都市';
#    }
    if($type eq '都市') {
    }
    else {
        @table = (
            '不意のプレゼント、素晴らしいアイデア、悪魔的な取引……あなたは好きな魔素を1つ獲得するか【魔力】を1D6点回復できる。どちらかを選んだ場合、その人物に対する【運命】が1点上昇する。【運命】の属性は、ゲームマスターが自由に決定できる。',
            '気高き犠牲、真摯な想い、圧倒的な力……その人物に対する【運命】が1点上昇する。【運命】の属性は「尊敬」になる。',
            '軽い口論、殴り合いの喧嘩、魔法戦……互いに1D6を振り、低い目を振った方が、高い目を振った方に対して【運命】が1点上昇する。【運命】の属性は「尊敬」になる。',
            '裏切り、策謀、不幸な誤解……その人物に対する【運命】が1点上昇する。【運命】の属性は「宿敵」になる。',
            '意図せぬ感謝、窮地からの救済、一生のお願いを叶える……その人物に対する【運命】が1点上昇する。【運命】の属性は「支配」になる。',
            '生ける屍の群れ、地獄の業火、迷宮化……魔法災厄に襲われる。ランダムに特技一つを選んで判定を行う。失敗すると、その人物に対し「運命変転表」を使用する。',
            '道路の曲がり角、コンビニ、空から落ちてくる……偶然出会う。その人物に対する【運命】が1点上昇する。【運命】の属性は「興味」になる。',
            '魂のひらめき、愛の告白、怪しい抱擁……その人物に対する【運命】が1点上昇する。【運命】の属性は「恋愛」になる。',
            '師弟関係、恋人同士、すれ違う想い……その人物との未来が垣間見える。たがいに対する【運命】が1点上昇する。',
            '懐かしい表情、大切な思い出、伴侶となる予感……その人物に対する【運命】が1点上昇する。【運命】の属性は「血縁」になる。',
            '献身的な看護、魔法的な祝福、奇跡……その人物に対する【運命】が1点上昇する。【運命】の属性は自由に決定できる。もしも関係欄に疵があれば、その疵を1つ関係欄から消すことができる。',
        );
    }
    my ($total_n, $dice_dmy) = &roll(2, 6);
    my $tn = $total_n - 2;
    $output = "${nick}: ${type}事件表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 魔素獲得チェック
sub magicalogia_check_gain_ME {
    my ($dice1, $dice2) = @_;
    my $output = "";
    
    if ($dice1 == $dice2) {
        # ゾロ目
        my @table = ('星','獣','力','歌','夢','闇',);
        $output = " ＞ " .$table[$dice1 - 1] ."の魔素2が発生";
    }
    return $output;
}
#** 経歴表
sub magicalogia_background_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

    @table = (
        '書警／ブックウォッチ',
        '司書／ライブラリアン',
        '書工／アルチザン',
        '訪問者／ゲスト',
        '異端者／アウトサイダー',
        '外典／アポクリファ',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: 経歴表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 初期アンカー表
sub magicalogia_defaultanchor_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my $type = "";
    my @table = ('1','1','1','1','1','1','1','1','1','1','1',);

    @table = (
        '『恩人』あなたは、困っているところを、そのアンカーに助けてもらった。',
        '『居候』あなたかアンカーは、どちらかの家や経営するアパートに住んでいる。',
        '『酒友』あなたとアンカーは、酒飲み友達である。',
        '『常連』あなたかアンカーは、その仕事場によくやって来る。',
        '『同人』あなたは、そのアンカーと同じ趣味を楽しむ同好の士である。',
        '『隣人』あなたは、そのアンカーの近所に住んでいる。',
        '『同輩』あなたはそのアンカーと仕事場、もしくは学校が同じである。',
        '『文通』あなたは、手紙やメール越しにそのアンカーと意見を交換している。',
        '『旧友』あなたは、そのアンカーと以前に、親交があった。',
        '『庇護』あなたは、そのアンカーを秘かに見守っている。',
        '『情人』あなたは、そのアンカーと肉体関係を結んでいる。',
    );
    my ($total_n, $dice_dmy) = &roll(2, 6);
    my $tn = $total_n - 2;
    $output = "${nick}: ${type}初期アンカー表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 運命属性表
sub magicalogia_fortune_attribution_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

    @table = (
        '『血縁』自分や、自分が愛した者の親類や家族。',
        '『支配』あなたの部下になることが運命づけられた相手。',
        '『宿敵』何らかの方法で戦いあい、競い合う不倶戴天の敵。',
        '『恋愛』心を奪われ、相手に強い感情を抱いている存在。',
        '『興味』とても稀少だったり、不可解だったりして研究や観察をしたくなる対象。',
        '『尊敬』その才能や思想、姿勢に対し畏敬や尊敬を抱く人物。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: 運命属性表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 願い表
sub magicalogia_wish_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = '';

    @table = (
        '自分以外の特定の誰かを助けてあげて欲しい。',
        '自分の大切な人や憧れの人に会わせて欲しい。',
        '自分をとりまく不幸を消し去って欲しい。',
        '自分のなくした何かを取り戻して欲しい。',
        '特定の誰かを罰して欲しい。',
        '自分の欲望（金銭欲、名誉欲、肉欲、知識欲など）を満たして欲しい。',
        );
    my ($total_n, $dice_dmy) = &roll(1, 6);
    my $tn = $total_n - 1;
    $output = "${nick}: 願い表(${total_n}) ＞ $table[$tn]" if($table[$tn] ne '1');
    return $output;
}
#** 指定特技ランダム決定表
sub magicalogia_random_skill_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my @table = ('1','1','1','1','1','1');
    my $type = 'ランダム';

    my ($total_n, $dice_dmy) = &roll(1, 6);
    my ($total_n2, $dice_dmy2) = &roll(2, 6);
    my $tn = $total_n - 1;
    my $tn2 = $total_n2 - 2;
    
    @table = ('星','獣','力','歌','夢','闇',);
    my @table2 = (
        ['黄金', '大地', '森', '道', '海', '静寂', '雨', '嵐', '太陽', '天空', '異界'],           # 星
        ['肉', '蟲', '花', '血', '鱗', '混沌', '牙', '叫び', '怒り', '翼', 'エロス'],             # 獣
        ['重力', '風', '流れ', '水', '波', '自由', '衝撃', '雷', '炎', '光', '円環'],             # 力
        ['物語', '旋律', '涙', '別れ', '微笑み', '想い', '勝利', '恋', '情熱', '癒し', '時'],     # 歌
        ['追憶', '謎', '嘘', '不安', '眠り', '偶然', '幻', '狂気', '祈り', '希望', '未来'],       # 夢
        ['深淵', '腐敗', '裏切り', '迷い', '怠惰', '歪み', '不幸', 'バカ', '悪意', '絶望', '死'], # 闇
    );
    
    $output = "${nick}: ${type}指定特技表(${total_n},${total_n2}) ＞ 『$table[$tn]』$table2[$tn][$tn2]" if($table[$tn] ne '1');
    return $output;
}

####################           ネクロニカ         ########################
sub nechronica_hit_location_table {
    my $dice = shift;
    my $output = '1';
    
    my $idx = 0;
    if($dice > 5) {
        $output = "";
        my @table = (
            '防御側任意',
            '脚（なければ攻撃側任意）',
            '胴（なければ攻撃側任意）',
            '腕（なければ攻撃側任意）',
            '頭（なければ攻撃側任意）',
            '攻撃側任意',
        );
        $idx = $dice - 6;
        if($dice > 10) {
            $idx = 5;
            $output = "(追加ダメージ".($dice - 10).")";
        }
        $output = $table[$idx].$output;
    }

    return $output;
}

####################           迷宮デイズ          ########################
sub mayoday_table {
    my $string = "\U$_[0]";
    my $output = '1';
    my $type = "";
    my $total_n = "";

    my $dummy;
    # 散策表(2d6)
    if($string =~ /DRT/i) {
        $type = '散策';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_research_table($total_n);
    # 休憩表(2D6)
    } elsif($string =~ /DBT/i) {
        $type = '休憩';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_break_table($total_n);
    # ハプニング表(2D6)
    } elsif($string =~ /DHT/i) {
        $type = 'ハプニング';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_happening_table($total_n);
    # お宝表
    } elsif($string =~ /MPT/i) {
        $type = '相場';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_market_price_table($total_n);
    } elsif($string =~ /T1T/i) {
        $type = 'お宝１';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &md_treasure1_table($total_n);
    } elsif($string =~ /T2T/i) {
        $type = 'お宝２';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &md_treasure2_table($total_n);
    } elsif($string =~ /T3T/i) {
        $type = 'お宝３';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &md_treasure3_table($total_n);
    } elsif($string =~ /T4T/i) {
        $type = 'お宝４';
        ($total_n, $dummy) = &roll(1, 6);
        $output = &md_treasure4_table($total_n);
    # 因縁表
    } elsif($string =~ /DCT/i) {
        $type = '因縁';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_connection_table($total_n);
    } elsif($string =~ /MCT/i) {
        $type = '怪物因縁';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_monster_connection_table($total_n);
    } elsif($string =~ /PCT/i) {
        $type = 'PC因縁';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_pc_connection_table($total_n);
    } elsif($string =~ /LCT/i) {
        $type = 'ラブ因縁';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_love_connection_table($total_n);
    # 戦闘系
    } elsif($string =~ /CAT/i) {
        $type = '痛打';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_critical_attack_table($total_n);
    } elsif($string =~ /FWT/i) {
        $type = '致命傷';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_fatal_wounds_table($total_n);
    } elsif($string =~ /CFT/i) {
        $type = '戦闘ファンブル';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_combat_fumble_table($total_n);
    # そのほか
    } elsif($string =~ /DNT/i) {
        $type = '交渉';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_negotiation_table($total_n);
    } elsif($string =~ /APT/i) {
        $type = '登場';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_appearance_table($total_n);
    } elsif($string =~ /KST/i) {
        $type = 'カーネル停止';
        ($total_n, $dummy) = &roll(2, 6);
        $output = &md_kernel_stop_table($total_n);
    }

    if($output ne '1') {
        $output = "$_[1]: ${type}表(${total_n}) ＞ $output";
    }
    return $output;
}

#**散策表(2d6)
sub md_research_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '次に挑む迷宮の迷宮支配者を倒さなければ人類文明が滅ぶことを偶然知ってしまう。《気力》を最大値まで回復する。',
        '同じ迷宮を対象とする違う依頼を受ける。シナリオの目的を果たしたときに、追加で1d6MCの報酬を得られるようになる。',
        '他の迷宮屋の評判を耳にする。パーティから好きなキャラクター1人を選び、そのキャラクターに対する《好意》が1点上昇する。',
        '毎日の散歩の成果が出て、体の調子が良い。このゲーム中、《HP》の最大値が5点上昇し、《HP》が5点回復する。',
        'メディアの取材を受ける。《民の声》を2点得る。',
        '近所からおすそ分けをもらう。【回復薬】を6個手に入れる。',
        '近所の人がきみの噂話をしている。ゲーム中に自分が対象に入った「恋人」「親友」「忠誠」の人間関係を成立させるたび、《民の声》を2点得る。',
        '似たような迷宮に挑んだことがある迷宮屋から話を聞いた。迷宮フェイズでの情報収集の難易度が2下がる。',
        '武具の安売りを見つける。ランダムな武具アイテム1つを半分の値段で購入することができる。',
        '他の迷宮屋と喧嘩になる。パーティの中からランダムに1人を選び、お互いの《敵意》を1点上昇させる。',
        '迷宮屋志望の見習が、1d6人ほど配下として加わる。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**休憩表（2d6）
sub md_break_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        'アイテムの改善案を出し合ってみる。各キャラクターは、好きなキャラクター1体を選び、1d6を振ってそのキャラクターのアイテムスロットから1つをランダムに選ぶ。出た目のアイテムにレベルがあれば、1上昇する。',
        '何気ない雑談が腹の探り合いに発展する。各キャラクターは、好きなキャラクターに対する《好意》と《敵意》を入れ替え、その属性を自由に変更することができる。',
        '好きな単語表からランダムに単語を1つ選ぶ。その部屋にはそれに関係したものがたくさん置いてあるため、出た単語が「好きなもの」に入っているキャラクターは、《気力》を2点得る。',
        '嫌いな人の話題で盛り上がる。各キャラクターは同じキャラクターに《敵意》を持っている人を1人選び、その人への《好意》を1点上昇させる。',
        '窓の外から報道のヘリコプターがこちらを撮影しているのが見える。格好よく見せるために、各キャラクターは〔魅力〕で難易度13の判定を行う。誰かが成功するたびに《民の声》が1点増加する。',
        '雑談や休息など、思い思いに時間を過ごす。各キャラクターは、好きなキャラクター1体への《好意》を1点上昇させる。',
        '通路の片隅で素材が山を作っているのを見つけた。各キャラクターは〔探索〕で難易度11の判定を行う。誰かが成功するたびに、好きな素材を1種類選び、それを1d6個手に入れる。',
        'チームワークの確認。各プレイヤーは打ち合わせをせずに、一斉にじゃんけんを行う。いちばん出した人が多かった手を出したプレイヤーのPCは、《気力》を2点得る。',
        '仮眠をとって休憩。各キャラクターは〔才覚〕で難易度9の判定を行う。成功すれば《HP》が最大値まで回復する。',
        '各キャラクターは、迷宮化現象に巻き込まれ、身動きがとれない普通の人を1人見つけた。《配下》に加えることができる。',
        '各キャラクターは1d6を振る。出た目の上位2名が唐突に恋に落ちる。同じ目が出て2名をうまく割り出せない場合は、GMの左隣に近い方を優先する。恋に落ちた2人、相手以外に対する《好意》を合計し、その値に対する《好意》に加える。その後、相手以外に対する《好意》をすべて0にする。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**交渉表（2d6）
sub md_negotiation_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '中立的な態度は偽装だった。彼らは不意打ちを行う。奇襲扱いで戦闘を開始すること。',
        '交渉は決裂！　戦闘を行うこと。',
        '交渉は決裂！　戦闘を行うこと。',
        '「贄をささげれば話を聞こう」モンスターの中で最もレベルが高いもののレベルと等しい数だけ何らかの素材を減少すれば、友好的になる。減少させない場合、戦闘を開始すること。',
        '「……お前の趣味、なに？」好きな単語表一個を選び、D66を振る。パーティの中に、その項目を好きなものにしているキャラクターがいれば、友好的になる。そうでなければ戦闘を開始すること。',
        '怪物たちは物欲しそうにこちらを見ている。「肉」の素材をモンスターの数だけ消費するか、【お弁当】【フルコース】1個を消費すれば友好的になる。消費しなければ、戦闘を開始すること。',
        '怪物たちは値踏みするようにこちらを見ている。現金で1d6MC支払えば友好的になる。そうでない場合、戦闘を開始すること。',
        '「何かいいもんよこせ」モンスターの中で最もレベルの高いもののレベル以上の価格のアイテムを消費すれば友好的になる。そうでない場合、戦闘を開始すること。',
        '「面白い話を聞かせろよ」プレイヤーたちは面白い話をすること。GMは面白いと思えばモンスターは友好的になる。面白くなかった場合は戦闘を開始する。',
        '「俺に勝てたら話を聞いてやろう」怪物が力比べを挑んできた。モンスターの中で最もレベルが高いものと、パーティの代表がそれぞれ〔武勇〕で判定を行う。パーティの代表の達成値がモンスター以上であれば友好的になる。負けた場合、もう一度交渉するか戦闘するかを決定すること。',
        '運命の出会い。一目見た瞬間に打ち解けあい、友好的になる。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}



#**ハプニング表（2d6）
sub md_happening_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '急に絶望に襲われる。【お酒】を消費することが出来なければ、このゲーム中、最も高い能力値が1点減少する。',
        '思考に靄がかかってしまう。「散漫」のバッドステータスを受ける。',
        '気がついたら太っていた。「肥満」のバッドステータスを受ける。',
        '無残な失敗に愛想を尽かした配下が2d6人ほど去って行ってしまう。',
        '微妙な空気を読み切れず、パーティ全員の《気力》が1点減少する。',
        '事故だか故意だかで、仲間を殴ってしまう。ランダムに選んだパーティメンバー1名の《HP》を自分の〔武勇〕と同じ値だけ減少させる。',
        '期待が大きければ失望も大きい。あなたに対して《好意》を持っているキャラクター全員は、あなたに対する《好意》を1点減らす。',
        'アイテムを粗末に扱ってしまう。持ち物の中からランダムにアイテムを1つ決定する。そのアイテムにレベルがある場合、レベルが1下がる。',
        '失敗のショックのせいで知的な行動をとれなくなる。「愚か」のバッドステータスを受ける。',
        '過去の行状のせいで人に呪われる。「呪い」のバッドステータスを受ける。',
        '自分の失敗が許せない。このゲームの間、《器》が1点減少したものとして扱う。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**カーネル停止表（2d6）
sub md_kernel_stop_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        'カーネルが肉体に致命的な迷宮化を引き起こす！致命傷表を振ること。カーネルはまだ停止しない。',
        '〔才覚〕で難易度9の判定を行う。失敗すると記憶が迷宮化を起こし、銀行口座の暗証番号を忘れてしまう。口座に入っているMCはすべて失われる。カーネルは停止しない。',
        '迷宮化エネルギーが装備を直撃。素早く避けるため〔武勇〕で難易度9の判定を行う。失敗した場合、持っているアイテムからランダムに1つを選ぶ。そのアイテムは激しい迷宮化を起こし破壊される。カーネルは停止しない。',
        '正体不明のエネルギーが部屋中を駆け巡る。パーティ全員は1d6ダメージを受ける。カーネルは停止しない。',
        '心象が迷宮化していく。〔魅力〕で難易度9の判定を行う。失敗すると人間関係が迷宮化を起こし、持っている感情値がすべて1点減少する。カーネルは停止しない。',
        '激しい迷宮化に曝され、1d6点のダメージを受ける。〔探索〕で難易度11の判定を行う。成功すれば、怪我を負いながらもカーネルを停止させることに成功する。',
        'パーティ全員は軽い迷宮化に曝され1ダメージを受ける。パーティを統率する為に〔魅力〕で難易度11の判定を行うこと。成功すれば、カーネルは停止する。',
        '素早い一撃でカーネルの息の根を止めるために〔武勇〕で難易度9の判定を行う。成功すれば見事にカーネルを停止させることに成功する。',
        'カーネルの構造を感じ取り、一瞬にして停止させることに成功。さらに迷宮化の副産物としてランダムなレアアイテム1つを入手する。',
        'カーネルは停止した。そして持っているアイテムの中からランダムに1つを選ぶ。そのアイテムにレベルがあれば、いつのまにかレベルが1上昇している。',
        '鮮やかにカーネルを停止させ、傷一つないまま保存することに成功した。このカーネルの売却価格が3d6MC上昇する。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}


#**痛打表（2d6）
sub md_critical_attack_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '武器の伝説がまた一つ増えた。攻撃に使用した武具アイテムにレベルがあれば、そのレベルが1点上昇する。',
        '偶然ながら敵の弱点をつく。敵の《HP》を現在の半分の値にする。',
        '攻撃が終わった後、攻撃の勢いを利用して、自分を好きなエリアに移動させることができる。',
        '素晴らしい手ごたえに自分でも感動し、自分の《HP》が全快する。',
        '叙事詩的な一撃。《民の声》を1点増やす。',
        'クリーンヒット。攻撃の威力が2d6点上昇する。',
        '敵の動きを封じた。攻撃目標の《回避値》を戦闘終了まで2下げる。この効果は累積する。',
        '敵の勢いを利用し大ダメージ。攻撃の威力が、攻撃目標のレベルと同じだけ上昇する。',
        '敵の技を封じる。攻撃目標のスキル1種類を選び、戦闘中はそのスキルを使用できなくする。',
        '敵の急所をとらえ致命傷を与える。攻撃目標の《HP》を0にする。',
        '戦いの中、武具もまた成長する。持っているアイテムをランダムに1選ぶ。そのアイテムにレベルがあれば、1点上昇する。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**致命傷表（2d6）
sub md_fatal_wounds_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '重要器官を粉砕される。キャラクターは即座に死亡する。',
        '傍目にも分かる致命傷。キャラクターは次の自分の行動処理が終わった時点で死亡する。《HP》の回復でこの死亡を防ぐことはできない。',
        '全身に強い衝撃をうける。〔武勇〕で難易度[5+受けたダメージ]の判定に成功すると、行動不能になる。判定に失敗すると死亡する。',
        '出血多量で意識不明。行動不能になる。この戦闘が終了するまでに《HP》を1以上にしないと、キャラクターは死亡する。',
        '重傷を負い昏睡状態。行動不能になる。このクォーターが終了するまでに《HP》を1以上にしないと、キャラクターは死亡する。',
        '攻撃で負った傷により意識を失う。行動不能になる。',
        '緊急回避！　〔探索〕で難易度[7-現在の《HP》]の判定を行う。成功すると、ランダムなバッドステータス1つを受けたうえで攻撃が無効になる。失敗すると、ランダムなバッドステータス1つを受けたうえで行動不能になる。',
        '最後の一撃を見切ることができるかもしれない。〔才覚〕で難易度[9-現在の《HP》]の判定を行う。成功すると《HP》が1になる。失敗すると行動不能になる。',
        'まだここで死ぬ運命ではないのかもしれない。〔魅力〕で難易度[9-現在の《HP》]の判定を行う。成功すると《HP》が1になる。失敗すると行動不能になる。',
        'カウンター！　攻撃をしてきた敵に対して、割り込んで好きな武器またはスキルを使った反撃をすることができる。これらの判定が成功した場合、ダメージやスキルの効果のあとで《HP》が1になる。失敗した場合、ただ行動不能になる。',
        '致命傷を受けたような気がしたが、気のせいだった。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**戦闘ファンブル表（2d6）
sub md_combat_fumble_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        'ぶざまな失敗に熱くなる。攻撃の目標のキャラクターに対して《敵意》を4点得る。',
        '急にお腹が痛くなる！　何か回復アイテムを使うまで攻撃を行えなくなる。モンスターの場合、そのラウンドの終わりに未行動にならなくなる。',
        'アイテムが壊れた！　自分が持っているアイテムの中からランダムに1つを選び、そのアイテムが失われる。モンスターの場合、1d6ダメージを受ける。',
        '敵がいい気になる。行動不能になっていない敵軍キャラクター全ての《HP》を6点回復する。',
        '自分に攻撃が命中！　使用した武器のダメージを自分に与える。',
        'なんというか、やる気をなくす。《気力》を1点失う。モンスターの場合、1d6ダメージを受ける。',
        '仲間に攻撃が命中！　使用した武器の射程内の味方から、ランダムに1人を選ぶ。そのキャラクターに武器のダメージを与える。',
        '仲間の邪魔をしてしまう。未行動の自軍キャラクター1体を選び、行動済みにする。',
        'スキルを忘れてしまった！　習得しているスキルからランダムに1種類を選ぶ。そのスキルは戦闘が終了するまで使用できない。',
        '位置取りに失敗してとんでもない場所に。敵陣営プレイヤーまたはGMが、ファンブルしたキャラクターを好きな位置に移す。',
        'ピンチがチャンスに！　《HP》が現在値の半分になり、《気力》が最大値まで貯まる。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**登場表（2d6）
sub md_appearance_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '「ここから先に行かせるわけにはいかん」急ぐ途中に敵が立ちふさがる。〔武勇〕で難易度11の判定を行う。成功すればバトルフィールドの好きなエリアにそのキャラクターを配置することができる。失敗した場合、《HP》を1にした状態でバトルフィールドの好きなエリアにそのキャラクターを配置することができる。',
        '「待たせたな！」バトルフィールドの好きなエリアにそのキャラクターを配置することができる。',
        'おっと鉢合わせ！　バトルフィールドの敵軍の本陣に、そのキャラクターを配置すること。',
        '全力で駆けつける！　《HP》を2d6点減少すれば、バトルフィールドの好きなエリアにそのキャラクターを配置することができる。',
        'あいつらはこの先に行ったはず！　GMはそのキャラクターをバトルフィールドの好きなエリアに配置する。',
        'あの聞き覚えのある音は……！　そのキャラクターが【乗騎】を装備していれば、GMはそのキャラクターをバトルフィールドの好きなエリアに配置する。',
        '……間に合ったみたいだな。バトルフィールドの中に、そのキャラクターに対する《好意》が1点以上あるキャラクターがいれば、同じエリアにそのキャラクターを配置することができる。',
        'を！　これはこれは。好きな素材を1個拾う。',
        'いかん！　迷ってしまった。〔探索〕で難易度11の判定を行うこと。成功すればもう一度登場表を振り、結果を適用することができる。',
        'むむむむ？　ここは一度来た道のような……？　疲労して《気力》が1点減少。',
        '……いや、しかしそれどころではない！　そのキャラクターは、この戦闘に登場することはできない。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**因縁表（2d6）
sub md_connection_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '対象はあなたの父、もしくは母である。幼い頃に家庭を捨てて失踪した対象を、あなたはずっと憎んでいた。対象への《敵意》が1点上昇する。また、対象を戦闘で倒した際に、経験点10点を得ることができる。',
        '対象は、あなたの小学校時代の恩師である。懐かしい顔にこんな形で会うことになろうとは。対象への《好意》もしくは《敵意》が1点上昇する。',
        '対象は、過去にあなたと戦い、あなたの体に古傷を残している。今でもときどき傷は代償を求めて疼く。対象への《敵意》が1点上昇する。',
        'あなたは対象に憧れているが、全く相手にされていない。たとえ敵としてでも対象に認めてもらうことがあなたの願いだ。彼または彼女への《敵意》が1点上昇し、「ライバル」の人間関係を結ぶことが出来れば経験点を10得られるようになる。',
        'あなたは過去、対象のせいで、思い出したくもない大失敗をしたことがある。嫌いなものに絡んだ大失敗を設定すること。対象への《敵意》が1点上昇する。',
        'あなたは対象に手酷く敗北したことがある。あなたは屈辱を晴らすためにできる限りのことをする気でいる。対象への《敵意》が1点上昇する。',
        '対象はあなたの親族を殺した。あなたはいつか訪れる復讐の日を信じて、鍛錬を続けてきた。対象への《敵意》が1点上昇する。',
        '対象は、過去のあなたの仲間だ。意見の違いで袂を分かったが、ここまで対立することになるとは考えてもいなかった。対象への《敵意》が1点上昇する。',
        '対象とあなたは、前世があなたの妻/夫であった。幸せな生涯の記憶が蘇る。対象への《好意》が1点上昇する。',
        'あなたは対象とあなたの通勤・通学路でぶつかったことがあり、そこで一目惚れしている。恋を幸せに成就させるため、もしくは不幸な恋を対象の死によって終わらせるため、あなたは迷宮にめぐる。対象への愛情の《好意》4点と、「片思い」の人間関係を得る。',
        'あなたは過去に対象の恋人であった。対象のどこが好きだったのかは、自分の好きなものからランダムに単語を決め、それに関連した話をでっち上げること。対象への愛情の《好意》4点と、「恋人」の人間関係を得る。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#**怪物因縁表（2d6）
sub md_monster_connection_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '対象はあなたの故郷を滅ぼした。そこは、もうペンペン草すら生えない廃墟となっている。対象への《敵意》が4点上昇する。',
        '対象はあなたのDNA情報をもとに某国が作り出したものである。GMは対象にあなたのスキルから1つを任意に選んで修得させる。対象への《敵意》が1点上昇する。',
        'あなたはかつて対象の同族を絶滅させた。しかし、奴らは死んではいなかったのだ。対象への《敵意》が1点上昇する。',
        'あなたは幼いころに対象と遭遇したが、一顧だにされず見逃された。対象への《敵意》が1点上昇する。',
        '何年も前に死んだ、あなたの親しい人は、ちょうど対象の攻撃手段と同じ方法で殺されている。対象への《敵意》が1点上昇する。',
        '対象はなんとなくあなたが嫌いな特徴をそなえている。嫌いなものに関連した特徴を設定すること。対象への《敵意》が1点上昇する。',
        'あなたは過去に対象と戦い、完敗を喫している。対象への《敵意》が1点上昇する。対象との戦闘に勝利した場合、経験点10点を得る。',
        '対象はあなたの好きなものを穢したり貶めたことがある。好きなものにちなんだ出来事を設定すること。対象への《敵意》が1点上昇する。',
        'あなたは、対象が同族のなかでも強力な個体であることを知っている。対象への《敵意》が2点上昇する。対象の《HP》と威力を6点ずつ上昇させる。',
        '対象はあなたが昔飼っていた生き物や持っていたものが変化したものである。対象への《好意》と《敵意》が1点ずつ上昇する。交渉によって対象との戦闘を終わらせた場合、経験点10点を得る。',
        'かつてあなたは対象と同族であった。対象への《好意》と《敵意》が1点ずつ上昇する。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#**PC因縁表（2d6）
sub md_pc_connection_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        '対象はあなたが追い求めていた敵だった。なぜ敵なのか設定すること。対象への《敵意》が4点上昇する。対象を殺害すると経験点100点を得る。',
        '対象は、あなたがあなたのクラスになるきっかけを作った人物である。1分以内に詳細を設定できれば対象への好きな感情値を2点上昇させてよい。',
        '対象と共通の知人がいることが発覚する。好きなものにちなんだ知人を設定すること。対象への《好意》が1点上昇する。',
        '対象と同じ場所に住んでいたり、通っていたことが分かる。対象への《好意》が1点上昇する。',
        'あなたは何らかの種類の迷宮屋ランキングで対象に負けている。対象への《敵意》が1点上昇する。終了フェイズで対象に（何でもいいので）負けを認めさせれば、経験点を1点獲得する。',
        '対象は、なんとなくあなたの好きな特徴を備えているような気がする。好きなものにちなんだ特徴を1つ設定し、対象のプレイヤーの了解をとること。チャンスは１回だ。ＯＫなら対象への《好意》が1点上昇する。',
        '対象は何らかの媒体で、あなたに対して好意的でないコメントを出したことがあるような気がする。コメントの詳細はあなたが決定すること。対象への《敵意》が１点上昇する。',
        'あなたは対象に関する良い噂を聞いたことがある。噂の内容を決定したうえで、対象への《好意》が1点上昇する。',
        '対象は実は幼馴染だったことが明らかになる。容姿の変化などで気付かなかったのだ。対象への《好意》が1点上昇する。',
        '対象が実は兄弟であったことが明らかになる。家庭の事情を1分で考えだせれば、対象への《好意》が1点上昇する。',
        'あなたと対象は、今まで隠していたが実はつきあっている。対象のプレイヤーの了解を15秒以内にとることができれば、お互いへの愛情の《好意》を4点上昇させることができる。',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}
#**ラブ因縁表（2d6）
sub md_love_connection_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        'あなたは対象と過去にいい友人だった。対象への《好意》が2点上昇するが、その属性は友情に変化する。',
        'あなたは対象を本来とは別の性別だと思い込んで片思いしていた。対象への《敵意》が2点、または《好意》が1点上昇する。',
        'あなたはかつて親友であった対象に恋人を奪われたことがある。対象への《敵意》が1点上昇する。',
        '対象は、あなたの好きなものによく似ている。好きなものから１つを選んで、どう似ているか説明できたら、対象への《好意》が1点上昇する。',
        '対象をよく見たらけっこう可愛いような気がしてきた。対象への《好意》が1点上昇し、対象への《好意》をすべて愛情に変換する。',
        'あなたは対象と過去につきあっていたことがある。現在はどうだか分からないが、あのころは本気だった。対象への《好意》が1点上昇する。',
        '対象は、むかしあなたが好きだった人と印象がよく似ている。対象への《好意》が1点上昇する。',
        'あなたは対象に助けられたり、命を救われたことがある。１分以内に設定を作り上げられれば、対象への《好意》が1点上昇する。',
        'あなたは対象に振られ、失意のあまり自殺しようとしたことがある。対象への《好意》と《敵意》が1点上昇する。',
        'あなたは昔から、対象を独占したいと思っていた。対象があなた以外と関わるたびに怒りを募らせていたのだ。対象への《好意》と《敵意》が2点ずつ上昇する。',
        'なんだか良く分からないが、とにかく好きでたまらない。対象への《好意》が3点上昇し、対象への《好意》をすべて愛情に変換する。'
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**相場表（2d6）
sub md_market_price_table {
    my $num = shift;
    my $output = '1';
    my @table = (
        'なし',
        '肉',
        '牙',
        '鉄',
        '魔素',
        '機械',
        '衣料',
        '木',
        '火薬',
        '情報',
        '革',
    );
    $output = $table[$num - 2] if($table[$num - 2]);
    return $output;
}

#**お宝表１（1d6）
sub md_treasure1_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        '何もなし。',
        '何もなし。',
        'そのモンスターの素材欄の中から、好きな素材を1個。',
        'そのモンスターの素材欄の中から、好きな素材を2個。',
        'そのモンスターの素材欄の中から、好きな素材を3個。',
        '【お弁当】1個。',
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表２（1d6）
sub md_treasure2_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        'そのモンスターの素材欄の中から、好きな素材を3個。',
        'そのモンスターの素材欄の中から、好きな素材を4個。',
        'そのモンスターの素材欄の中から、好きな素材を5個。',
        'ランダムな回復アイテム1個。',
        'ランダムな武具アイテム1個。そのアイテムにレベルがあれば、レベル1のアイテムとなる。',
        'ランダムなレアアイテム1個。',
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表３（1d6）
sub md_treasure3_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        'そのモンスターの素材欄の中から、好きな素材を5個。',
        'そのモンスターの素材欄の中から、好きな素材を7個。',
        'そのモンスターの素材欄の中から、好きな素材を10個。',
        '好きなコモンアイテムのカテゴリ1種を選ぶ。そのカテゴリの中からランダムなアイテム1個。そのアイテムにレベルがあれば、レベル1のアイテムとなる。',
        'ランダムなレアアイテム1個',
        'ランダムなレアアイテム1個。そのアイテムにレベルがあれば、レベル1のアイテムとなる。',
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

#**お宝表４（1d6）
sub md_treasure4_table {
    my $num = shift;
    $num = $num - 1;
    my $output = '1';
    my @table = (
        'そのモンスターの素材欄の中から、好きな素材を5個。',
        'そのモンスターの素材欄の中から、好きな素材を10個。',
        '好きなコモンアイテムのカテゴリ1種を選ぶ。そのカテゴリの中からランダムなアイテム1個。そのアイテムにレベルがあれば、レベル2のアイテムとなる。',
        '好きなコモンアイテムのカテゴリ1種を選ぶ。そのカテゴリの中からランダムなアイテム1個。そのアイテムにレベルがあれば、レベル3のアイテムとなる。',
        'ランダムなレアアイテム1個。そのアイテムにレベルがあれば、レベル1のアイテムとなる。',
        'ランダムなレアアイテム1個。そのアイテムにレベルがあれば、レベル2のアイテムとなる。',
    );
    $output = $table[$num] if($table[$num]);
    return $output;
}

####################           ピーカブー          ########################
#** 表振り分け
sub peekaboo_table {
    my ($string, $nick) = @_;
    my $output = '1';
    
    if($game_type eq "Peekaboo") {
        if($string =~ /((\w)+ET)/i) {       # イベント表
            $output = &pk_event_table("\U$1", "$nick");
        }
        elsif($string =~ /((\w)+BT)/i) {    # バタンキュー表
            $output = &pk_batankyu_table("\U$1", "$nick");
        }
    }
    return $output;
}

#** イベント表
sub pk_event_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my $type = "";

    my ($total_n, $dice_dmy) = &roll(2, 6);
    if($string =~ /PSET/i) {
        $type = '個別学校';
        $output = &pk_private_school_event_table($total_n);
    }
    elsif($string =~ /SET/i) {
        $type = '学校';
        $output = &pk_school_event_table($total_n);
    }
    elsif($string =~ /OET/i) {
        $type = 'お化け屋敷';
        $output = &pk_obakeyashiki_event_table($total_n);
    }
    $output = "${nick}: ${type}イベント表(${total_n}) ＞ $output" if($output ne '1');
    return $output;
}
#** 学校イベント表
sub pk_school_event_table {
    my $num = shift;
    my @table = (
        [ 2, '持ち物検査が行われる！　イノセント全員は、《隠れる/不良9》の判定を行うこと。失敗したキャラクターは、GMがアイテム1個を選んで没収することができる（セッション終了時に返してもらえる）' ],
        [ 3, 'クラスで流行っている遊びに誘われる。GMは、「遊び」の分野の中からランダムに特技一つを選ぶ。イノセント全員は、その判定を行う。失敗したキャラクターは、【眠気】が1d6点増える。' ],
        [ 4, 'とても退屈な授業が始まった。イノセント全員は、《いねむり/不良3》の判定を行う。失敗したキャラクターは、【眠気】が1d6+1点増える。' ],
        [ 5, '明日までの宿題を出される。イノセント全員は、明日までに宿題を終わらせないといけない。宿題をやるためには、《宿題/勉強7》の判定に成功しなければならない。宿題を次の日の学校フェイズまでに終わらせることができなかった場合は居残り勉強させられる。その日の放課後フェイズの最初のサイクルは、1回休み。' ],
        [ 6, '今日も今日とて楽しい授業。GMは、「勉強」の分野の中からランダムに特技1つを選ぶ。イノセント全員は、その判定を行う。失敗したキャラクターは【眠気】が1d6点増える。' ],
        [ 7, '特に変わったこともなく、おだやかな一日だった。イノセント全員は、【眠気】が1点増える。' ],
        [ 8, '今日の体育の時間はハードだった！　GMは、「運動」の分野の中からランダムに特技1つを選ぶ。イノセント全員は、その判定を行う。失敗したキャラクターは、【眠気】が1d6点増える。' ],
        [ 9, '自習の時間だ！　GMは、「勉強」の分野の中からランダムに特技1つを選ぶ。イノセント全員は、その判定を行う。成功したキャラクターは、1回だけ自由行動ができる。' ],
        [ 10, '抜き打ちテストだ！　GMは、「勉強」の分野の中からランダムに特技1つを選ぶ。イノセント全員は、-2の修正をつけて、その特技の判定を行う。成功したキャラクターはよい点をゲット！家にかえってそれを親に見せるとおこづかいを1個もらえる。失敗したキャラクターは、親にこっぴどく怒られ、【眠気】が1d6点増えるうえに、それ以降「みんなで遊ぶ」ことが出来なくなる。' ],
        [ 11, '体操服や水着、宿題に提出物などなど、今日は学校に持ってこないといけないものがあったはず！《計画性/大人7》で判定を行う。失敗すると、先生に怒られてしょんぼり。【眠気】が1d6点増える。' ],
        [ 12, 'それぞれに色々なことがあった。イノセントは、各自1回ずつ2d6を振り、個別学校イベント表の指示に従うこと。' ],
    );

    return &get_table_by_number($num, @table);
}
#** 個別学校イベント表
sub pk_private_school_event_table {
    my $num = shift;
    my @table = (
        [ 2, 'クラスの中に気になるコが現れる。《恋愛/大人11》の判定を行う。成功すると、その子と仲良くなって経験値を1点獲得する。' ],
        [ 3, 'お腹の調子が悪くなり、トイレに行きたくなる。《がまん/友達5》か《隠れる/不良9》の判定を行うこと。失敗すると、不名誉なあだ名をつけられ、それ以降、「友達」の分野の判定に-1の修正を受ける。' ],
        [ 4, '今日の給食には、どうしても苦手な食べ物が出てきた。《勇気/友達9》で判定を行うこと。成功すると、苦手な食べ物を克服し、気分爽快！【眠気】を1d6点回復するか、【元気】を1点回復することができる。' ],
        [ 5, '友達から遊ぼうと誘われる。その日の放課後フェイズに、クラスメイト1d6人と「みんなで遊ぶ」ことができる。これを断る場合は、《優しさ/友達4》で判定を行うこと。失敗するとこれ以降、「みんなで遊ぶ」を行うとき、友達を誘うことが出来なくなる。' ],
        [ 6, '今日はクラブ活動があった。次のサイクルは行動できなくなる。その代わり、好きな特技1つを選ぶ。このセッションの間、その特技の判定を行うとき+1の修正がつく。' ],
        [ 7, '授業中、先生がとても難しい問題を出してくる。GMは、「勉強」の分野からランダムに特技を1つ選ぶ。その判定を行うこと。成功すると、経験値を1点獲得する。' ],
        [ 8, 'クラスでオバケの噂を耳にする。《うわさ話/友達3》の判定に成功すると、GMからそのセッションで出てくるオバケの外見や情報を教えてもらうことができる。' ],
        [ 9, '校庭や体育館など、自分達の遊び場が他のグループに占拠されている。《けんか/不良12》で判定を行うこと。成功すると、それ以降「友達」の分野の判定に+1の修正を受ける。失敗すると遊び場を失ってしまう。1ダメージを受け、それ以降、「友達と遊ぶ」ことができなくなってしまう。' ],
        [ 10, 'いじめの現場に出くわす！　《勇気/友達10》の判定に成功すると、いじめっこを撃退することができる。いじめられていた子が、お礼にお菓子を1個くれる。失敗すると1点のダメージを受ける。' ],
        [ 11, '今日は全校集会があった。《がまん/友達5》で判定を行う。失敗すると貧血で倒れ次のサイクルは行動できなくなる。' ],
        [ 12, '図書室で面白そうな本を発見する。《読書/遊び8》で判定を行うこと。成功すると、経験値を1点獲得する。' ],
    );

    return &get_table_by_number($num, @table);
}
#** お化け屋敷イベント表
sub pk_obakeyashiki_event_table {
    my $num = shift;
    my @table = (
        [ 2, '謎かけ守護者が門を護っている。未行動のキャラクターは、《クイズ/遊び10》の判定を行うことができる。判定したキャラクターは行動済みになる。失敗したキャラクターは、1点のダメージを受ける。誰かが成功すれば、イベントはクリアできる。' ],
        [ 3, '天井から血の雨が降ってくる！　この雨に触れると火傷しちゃうみたいだ！【防御力】が0のスプーキーとイノセントは、《かけっこ/運動7》の判定を行う。失敗すると、イノセントは1ダメージ、スプーキーは1d6ダメージを受ける。成功・失敗にかかわらず、イベントはクリアできる。' ],
        [ 4, 'トンガリ族の妖精がいる。彼は、先へ行くための通行料として、アイテムを要求してくる。何か好きなアイテム1個を渡すか、未行動のキャラクターは、《お話づくり/遊び9》の判定を行うことができる。判定したキャラクターは行動済みになる。誰かが判定に成功するか、アイテムを渡すかしたら、イベントはクリアできる。' ],
        [ 5, '行き止まりだ。先に進む方法が分からない。未行動のキャラクターは、《推理/大人6》の判定を行うことができる。判定したキャラクターは行動済みになる。誰かが成功したら、イベントはクリアできる。' ],
        [ 6, 'まっくらで、何も見えない部屋だ。一行は不安におちいる。未行動のキャラクターは、《仕切る/友達11》の判定を行うことができる。判定したキャラクターは行動済みになる。誰かが成功すれば、イベントはクリアできる。' ],
        [ 7, 'ジメジメした通路だ。特に何もしなくても、イベントはクリアだ。誰かがのぞむなら、自由行動を1回行うことができるぞ。' ],
        [ 8, '通路が途中で途切れて崖のようになっている。誰かが飛ぶことが出来れば、向こう岸にあるはしごを断崖にかけられそうだけど……。未行動のキャラクターは、《とぶ/運動6》の判定を行うことができる。判定したキャラクターは行動済みになる。誰かが成功すれば、イベントはクリアできる。' ],
        [ 9, 'まぼろしの部屋だ。各キャラクターの大好物のまぼろしがつぎつぎ現れる。未行動のキャラクターは、《がまん/友達5》の判定を行うことができる。判定したキャラクターは行動済みになる。誰かが成功したら、イベントはクリアできる。' ],
        [ 10, '通路がいくつにも分岐している……。未行動のキャラクターのうち1人が《地理/勉強11》、もしくは《絵/遊び5》の判定を行う。判定したキャラクターは行動済みになる。失敗すると、そのオバケ屋敷の部屋数が1d6点上昇する。成功失敗にかかわらず、イベントはクリアできる。' ],
        [ 11, 'シャドウが見回りをしている。未行動のキャラクターのうち1人が、《隠れる/不良9》の判定を行う。成功すれば、イベントはクリアできる。失敗すると、プレイヤーと同じ人数のシャドウと戦闘を行うこと。勝利すればイベントはクリアできる。' ],
        [ 12, '足下からシャドウが現れ、みんなに襲いかかる！　プレイヤーと同じ人数のシャドウと戦闘を行うこと。勝利すればイベントはクリアできる。' ],
    );

    return &get_table_by_number($num, @table);
}

#** バタンキュー表
sub pk_batankyu_table {
    my ($string, $nick) = @_;
    my $output = '1';
    my $type = "";

    my ($total_n, $dice_dmy) = &roll(1, 6);
    if($string =~ /IBT/i) {
        $type = 'イノセント用';
        $output = &pk_innocent_batankyu_table($total_n);
    }
    if($string =~ /SBT/i) {
        $type = 'スプーキー用';
        $output = &pk_spooky_batankyu_table($total_n);
    }
    $output = "${nick}: ${type}バタンキュー！表(${total_n}) ＞ $output" if($output ne '1');
    return $output;
}
#** イノセント用バタンキュー！表
sub pk_innocent_batankyu_table {
    my $num = shift;
    my @table = (
        [ 1, '悲しい別れ。病院につれていくことができれば、1d6日入院したあとに目覚めます。その間は、行動不能です。目覚めたときに【眠気】も【元気】もすべて回復しますが、スプーキーを見ることができなくなっています。そのキャラクターはスプーキーと一緒に冒険を続けることはできません……。' ],
        [ 2, '大けがをして昏睡状態。病院につれていくことができれば、1d6日入院したあとに目覚めます。その間は、行動不能です。目覚めたときに【眠気】はすべて回復し、【元気】が3点回復します。' ],
        [ 3, '気絶しちゃった！　1d6サイクル後に目覚めます。気絶している間は、行動不能です。目覚めたときに【眠気】が1d6点、【元気】が1点回復します。' ],
        [ 4, '体が動かない！　何かを見たり、話したりといった簡単な行動ならできますが、自由行動や戦闘行動といった通常の行動は行えません。1d6サイクル後に【元気】が1点回復し、通常通り行動できるようになります。' ],
        [ 5, 'かろうじて意識はあるものの、朦朧としてきた。【眠気】が2d6点増えます。それで行動不能になっていなければ、【元気】が1点回復します。そうでなければ、気絶してしまい、1d6サイクル後に目覚めます。気絶している間は、行動不能です。目覚めたときに【眠気】が1d6点減少し、【元気】が1点回復します。' ],
        [ 6, 'なんという幸運！　アイテムがキミを護ってくれた。もし持ち物にアイテムがあった場合、それが1個破壊され、受けたダメージを無効化します。アイテムがなければ行動不能になります。' ],
    );

    return &get_table_by_number($num, @table);
}
#** スプーキー用バタンキュー！表
sub pk_spooky_batankyu_table {
    my $num = shift;
    my @table = (
        [ 1, '封印状態！　オバケは封印されてしまいます。1d6*1年後になれば、そのオバケは復活します。それまでは、イノセントと一緒に冒険することはできません。できたとしても、そのときイノセントはあなたを見ることができなくなっているかもしれませんが……。' ],
        [ 2, '休眠状態！　オバケは休眠状態になります。1d6日が経過すると目覚めます。その間は、行動不能です。目覚めたときに【魔力】はすべて回復しています。' ],
        [ 3, 'コバケ状態！　体は小さく縮んてしまい、重戦闘も戦闘行動も行うことはできません。【魔力】が1点以上になると、通常通り行動できるようになります。' ],
        [ 4, '混沌変化！　自分のリングのからだリストを使って、ランダムにからだを1つ選びます。自分のからだが、それに変化します。1d6サイクルの間、行動不能になります。その後、【魔力】が1d6点回復して通常通り行動できるようになります。' ],
        [ 5, '魔力変質！　自分のリングの衣装リストを使って、ランダムに衣装を1つ選びます。自分の衣装1つが、それに変化します。そして、1d6サイクルの間、行動不能になります。その後、【魔力】が1d6点回復して通常通り行動できるようになります。' ],
        [ 6, '魔法暴発！　自分の持っている魔法をランダムに1つ選んで、その効果が発動します。魔法の対象が選べる場合は、スプーキーのプレイヤーが選んで構いません。そして、1d6サイクルの間、行動不能になります。その後、【魔力】が1d6点回復して通常通り行動できるようになります。' ],
    );

    return &get_table_by_number($num, @table);
}

####################        バルナ・クロニカ      ########################
#** 命中部位表
sub barna_kronika_hit_location_table {
    my $num = shift;
    my @table = (
        [ 1, '頭部' ],
        [ 2, '右腕' ],
        [ 3, '左腕' ],
        [ 4, '右脚' ],
        [ 5, '左脚' ],
        [ 6, '胴体' ],
    );
    
    return &get_table_by_number($num, @table);
}


#==========================================================================
#**                            その他の機能
#==========================================================================
sub choise_random {
    my $string = $_[0];
    my $output = "1";

    if($string =~ /(^|\s)((S)?choise\[([^,]+(,[^,]+)+)\])($|\s)/i) {
        $string = $2;
        if($4) {
            my @elem_arr = split /,/, $4;
            $output = "$_[1]: (${string}) ＞ ".$elem_arr[int(rand scalar @elem_arr)];
        }
    }
    return $output;
}

#==========================================================================
#**                            結果判定関連
#==========================================================================
sub cp_f {  # 不等号の整列
    my $ulflg = $_[0];

    if($ulflg =~ /(<=|=<)/) {
        $ulflg = "<=";
    } elsif($ulflg =~ /(>=|=>)/) {
        $ulflg = ">=";
    } elsif($ulflg =~ /(<>)/) {
        $ulflg = "<>";
    } elsif($ulflg =~ /[<]+/) {
        $ulflg = "<";
    } elsif($ulflg =~ /[>]+/) {
        $ulflg = ">";
    } elsif($ulflg =~ /[=]+/) {
        $ulflg = "=";
    }
    return $ulflg;
}
sub check_hit { # 成功数判定用
    my $dice_now = $_[0];
    my $ulflg    = $_[1];
    my $diff     = $_[2];
    my $suc = 0;

    if($diff =~ /\d/) {
        if($ulflg =~ /(<=|=<)/) {
            if($dice_now <= $diff) {
                $suc++;
            }
        } elsif($ulflg =~ /(>=|=>)/) {
            if($dice_now >= $diff) {
                $suc++;
            }
        } elsif($ulflg =~ /(<>)/) {
            if($dice_now != $diff) {
                $suc++;
            }
        } elsif($ulflg =~ /[<]+/) {
            if($dice_now < $diff) {
                $suc++;
            }
        } elsif($ulflg =~ /[>]+/) {
            if($dice_now > $diff) {
                $suc++;
            }
        } elsif($ulflg =~ /[=]+/) {
            if($dice_now == $diff) {
                $suc++;
            }
        }
    }
    return($suc);
}


####################       ゲーム別成功度判定      ########################
sub check_suc { # ゲーム別成功度判定
    my @check_param = @_ ;
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @check_param;
    my $output = "";

    if($total_n =~ /([\d]+)[)]?$/) {
        $total_n = $1;
        if($game_type ne "") {  # 成功判定処理
            if(($dice_max == 100) && ($dice_cnt == 1)) {    # 1D100判定
                $output = &check_1D100(@check_param);
            } elsif(($dice_max == 20) && ($dice_cnt == 1)) {    # 1d20判定
                $output = &check_1D20(@check_param);
            } elsif($dice_max == 10) {  # d10ベース判定
                $output = &check_nD10(@check_param);
            } elsif($dice_max == 6) {   # d6ベース判定
                if($dice_cnt == 2) {    # 2d6判定
                    $output = &check_2D6(@check_param);
                }
                if($output eq "") { # xD6判定
                    $output = &check_nD6(@check_param);
                }
            }
        }

        if(($output eq "") && ($ulflg ne "")) { # どれでもないけど判定するとき
            $output = &check_nDx(@check_param);
        }
    }
    return $output;
}
sub check_1D100 {   # ゲーム別成功度判定(1d100)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if(($game_type eq "Cthulhu") && ($ulflg eq "<=")) {
        if(($total_n <= $diff) && ($total_n < 100)) {
            if($total_n <= 5) {
                $output .= " ＞ 決定的成功";
                if($total_n <= ($diff / 5)) {
                    $output .= "/スペシャル";
                }
            } elsif($total_n <= ($diff / 5)) {
                $output .= " ＞ スペシャル";
            } else {
                $output .= " ＞ 成功";
            }
        } elsif(($total_n >= 96) && ($diff < 100)) {
            $output .= " ＞ 致命的失敗";
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type eq "Hieizan") && ($ulflg eq "<=")) {
        if($total_n <= 1) { # 1は自動成功
            if($total_n <= ($diff / 5)) {
                $output .= " ＞ 大成功";    # 大成功 > 自動成功
            } else {
                $output .= " ＞ 自動成功";
            }
        } elsif(($total_n >= 100)) {
            $output .= " ＞ 大失敗";    # 00は大失敗(大失敗は自動失敗でもある)
        } elsif(($total_n >= 96)) {
            $output .= " ＞ 自動失敗";  # 96-00は自動失敗
        } else {
            if(($total_n <= $diff)) {
                if($total_n <= ($diff / 5)) {
                    $output .= " ＞ 大成功";    # 目標値の1/5以下は大成功
                } else {
                    $output .= " ＞ 成功";
                }
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif(($game_type eq "Elric!") && ($ulflg eq "<=")) {
        if($total_n <= 1) { # 1は常に貫通
            $output .= " ＞ 貫通";
        } elsif($total_n >= 100) {  # 100は常に致命的失敗
            $output .= " ＞ 致命的失敗";
        } elsif($total_n <= ($diff / 5 + 0.9)) {
            $output .= " ＞ 決定的成功";
        } elsif($total_n <= $diff) {
            $output .= " ＞ 成功";
        } elsif(($total_n >= 99) && ($diff < 100)) {
            $output .= " ＞ 致命的失敗";
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type eq "RuneQuest") && ($ulflg eq "<=")) {
        if(($total_n <= 1) || ($total_n <= ($diff / 20 + 0.5))) {   # 1は常に決定的成功
            $output .= " ＞ 決定的成功";
        } elsif($total_n >= 100) {  # 100は常に致命的失敗
            $output .= " ＞ 致命的失敗";
        } elsif($total_n <= ($diff / 5 + 0.5)) {
            $output .= " ＞ 効果的成功";
        } elsif($total_n <= $diff) {
            $output .= " ＞ 成功";
        } elsif($total_n >= (95 + ($diff / 20 + 0.5))) {
            $output .= " ＞ 致命的失敗";
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type eq "Chill") && ($ulflg eq "<=")) {
        if($total_n >= 100) {
            $output .= " ＞ ファンブル"
        } elsif($total_n <= $diff) {
            if($total_n >= ($diff * 0.9)) {
                $output .= " ＞ Ｌ成功";
            } elsif($total_n >= ($diff / 2)) {
                $output .= " ＞ Ｍ成功";
            } elsif($total_n >= ($diff / 10)) {
                $output .= " ＞ Ｈ成功";
            } else {
                $output .= " ＞ Ｃ成功";
            }
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type =~ /Gundog/) && ($ulflg eq "<=")) {
        if($total_n >= 100) {
            $output .= " ＞ ファンブル"
        } elsif($total_n <= 1) {
            $output .= " ＞ 絶対成功(達成値1+SL)"
        } elsif($total_n <= $diff) {
            my $dig10 = int($total_n / 10);
            my $dig1 = ($total_n) - $dig10 * 10;
            $dig10 = 0 if($dig10 >= 10);
            $dig1 = 0 if($dig1 >= 10);  # 条件的にはあり得ない(笑
            if($dig1 <= 0) {
                $output .= " ＞ クリティカル(達成値20+SL)";
            } else {
                $output .= " ＞ 成功(達成値".($dig10 + $dig1)."+SL)";
            }
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type eq "Warhammer") && ($ulflg eq "<=")) {
        if($total_n <= $diff) {
            $output .= ' ＞ 成功(成功度'.int(($diff - $total_n)/10).')';
        } else {
            $output .= ' ＞ 失敗(失敗度'.int(($total_n - $diff)/10).')';
        }
    }
    return $output;
}
sub check_1D20 {    # ゲーム別成功度判定(1d20)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if(($game_type eq "Pendragon") && ($ulflg eq "<=")) {
        if($total_n <= $diff) {
            if(($total_n >= (40 - $diff)) || ($total_n == $diff)) {
                $output .= " ＞ クリティカル";
            } else {
                $output .= " ＞ 成功";
            }
        } else {
            if($total_n == 20) {
                $output .= " ＞ ファンブル";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif(($game_type eq "Infinite Fantasia") && ($ulflg eq "<=")) {
        if($total_n <= $diff) {
            if($total_n <= ($diff / 32)) {
                $output .= " ＞ 32レベル成功(32Lv+)";
            } elsif($total_n <= ($diff / 16)) {
                $output .= " ＞ 16レベル成功(16LV+)";
            } elsif($total_n <= ($diff / 8)) {
                $output .= " ＞ 8レベル成功";
            } elsif($total_n <= ($diff / 4)) {
                $output .= " ＞ 4レベル成功";
            } elsif($total_n <= ($diff / 2)) {
                $output .= " ＞ 2レベル成功";
            } else {
                $output .= " ＞ 1レベル成功";
            }
            if($total_n <= 1) {
                $output .= "/クリティカル";
            }
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif(($game_type eq "PhantasmAdventure") && ($ulflg eq "<=")) {
        # 技能値の修正を計算する
        my $skill_mod = 0;
        if($diff < 1) {
            $skill_mod = $diff - 1;
        } elsif($diff > 20) {
            $skill_mod = $diff - 20;
        }
        my $fumble = 20 + $skill_mod;
        $fumble = 20 if($fumble > 20);
        my $critical = 1 + $skill_mod;
        my ($dice_now, $dice_str) = &roll(1, 20);
        if($total_n >= $fumble || $total_n >= 20) {
            my $fum_num = $dice_now - $skill_mod;
            $fum_num = 20 if($fum_num > 20);
            $fum_num = 1 if($fum_num < 1);
            if($modeflg > 1) {
                my $fum_str = "${dice_now}";
                if($skill_mod < 0) {
                    $fum_str .= "+".-$skill_mod."=${fum_num}";
                } else {
                    $fum_str .= "-${skill_mod}=${fum_num}";
                }
                $output .= " ＞ 致命的失敗(".$fum_str.")";
            } else {
                $output .= " ＞ 致命的失敗(".$fum_num.")";
            }
        } elsif($total_n <= $critical || $total_n <= 1) {
            my $crit_num = $dice_now + $skill_mod;
            $crit_num = 20 if($crit_num > 20);
            $crit_num = 1 if($crit_num < 1);
            if($skill_mod < 0) {
                $output .= " ＞ 成功";
            } else {
                if($modeflg > 1) {
                    $output .= " ＞ 決定的成功(${dice_now}+${skill_mod}=".$crit_num.")";
                } else {
                    $output .= " ＞ 決定的成功(".$crit_num.")";
                }
            }
        } elsif($total_n <= $diff) {
            $output .= " ＞ 成功";
        } else {
            $output .= " ＞ 失敗";
        }
    }
    return $output;
}
sub check_1D10 {    # ゲーム別成功度判定(1D10)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if($game_type eq "ArsMagica") {
        if($ulflg eq ">=") {
            if($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    }
    return $output;
}
sub check_nD10 {    # ゲーム別成功度判定(nD10)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if($game_type eq "CthulhuTech") {
        if($ulflg eq ">=") {    # 通常のテスト
            if($n1 >= int($dice_cnt / 2 + 0.9)) {
                $output .= " ＞ ファンブル";
            } elsif($total_n >= $diff) {
                if($total_n >= $diff + 10) {
                    $output .= " ＞ クリティカル";
                } else {
                    $output .= " ＞ 成功";
                }
            } else {
                $output .= " ＞ 失敗";
            }
        }
        if($ulflg eq ">") { # コンバットテスト
            if($n1 >= int($dice_cnt / 2 + 0.9)) {
                $output .= " ＞ ファンブル";
            } elsif($total_n > $diff) {
                if($total_n >= $diff + 10) {
                    $output .= " ＞ クリティカル";
                } else {
                    $output .= " ＞ 成功";
                }
                my $damage_dice = int(($total_n - $diff) / 5 + 0.9);
                $output .= "(${damage_dice}d10)";   # ダメージダイスの表示
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "DoubleCross" && $ulflg eq ">=") {
        if($n1 >= $dice_cnt) {
            $output .= " ＞ ファンブル";
        } elsif($total_n >= $diff) {
            $output .= " ＞ 成功";
        } else {
            $output .= " ＞ 失敗";
        }
    } elsif($game_type eq "ArsMagica") {
        if($ulflg eq ">=") {
            if($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "EmbryoMachine") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ ファンブル";
            } elsif($dice_n >= 20) {
                $output .= " ＞ クリティカル";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "Nechronica") {
        if($ulflg eq ">=") {
            if($total_n >= 11) {
                $output .= " ＞ 大成功";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                if($n1 > 0) {
                    $output .= " ＞ 大失敗";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    }
    return $output;
}
sub check_2D6 { # ゲーム別成功度判定(2D6)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if($game_type =~ /^SwordWorld/i) {
        if($dice_n >= 12) {
            $output .= " ＞ 自動的成功";
        } elsif($dice_n <=2) {
            $output .= " ＞ 自動的失敗";
        } elsif($ulflg eq ">=") {
            if($diff ne "?") {
                if($total_n >= $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    } elsif($game_type eq "Chaos Flare") {
        if($dice_n <= 2) {
            $total_n -= 20;
            $output .= " ＞ ファンブル(-20)";
        }
        if($ulflg eq ">=") {
            if($total_n >= $diff) {
                $output .= " ＞ 成功";
                if($total_n > $diff) {
                    $output .= " ＞ 差分値".int($total_n-$diff);
                }
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "WARPS") {
        if($dice_n <= 2) {
            $output .= " ＞ クリティカル";
        } elsif($dice_n >= 12) {
            $output .= " ＞ ファンブル";
        } elsif($ulflg eq "<=") {
            if($diff ne "?") {
                if($total_n <= $diff) {
                    $output .= " ＞ ".int($diff-$total_n)."成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    } elsif($game_type eq "Tunnels & Trolls") {
        if($ulflg eq ">=") {
            if($dice_n == 3) {
                $output .= " ＞ 自動失敗";
            } elsif($diff eq "?") {
                my $sucLv = 1;
                while($total_n >= $sucLv*5+15) { $sucLv += 1; }
                $sucLv -= 1;
                if($sucLv <= 0) {
                    $output .= " ＞ 失敗 ＞ 経験値".(1 * $dice_n);
                } else {
                    $output .= " ＞ ".$sucLv."Lv成功 ＞ 経験値".(1 * $dice_n);
                }
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功 ＞ 経験値".(($diff-15)/5*$dice_n);
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "ShinobiGami") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ ファンブル";
            } elsif($dice_n >= 12) {
                $output .= " ＞ スペシャル(生命点1点か変調1つ回復)";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "NightWizard") {
        if($ulflg eq ">=") {
            if($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "HuntersMoon") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ ファンブル(モノビースト追加行動+1)";
            } elsif($dice_n >= 12) {
                $output .= " ＞ スペシャル(変調1つ回復orダメージ+1D6)";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "MeikyuKingdom") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ 絶対失敗";
            } elsif($dice_n >= 12) {
                $output .= " ＞ 絶対成功";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "MagicaLogia") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ ファンブル";
            } elsif($dice_n >= 12) {
                $output .= " ＞ スペシャル(魔力1D6点か変調1つ回復)";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "MeikyuDays") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ 絶対失敗";
            } elsif($dice_n >= 12) {
                $output .= " ＞ 絶対成功";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    } elsif($game_type eq "Peekaboo") {
        if($ulflg eq ">=") {
            if($dice_n <= 2) {
                $output .= " ＞ ファンブル(【眠気】が1d6点上昇)";
            } elsif($dice_n >= 12) {
                $output .= " ＞ スペシャル(【魔力】あるいは【眠気】が1d6点回復)";
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    }
    return $output;
}
sub check_nD6 { # ゲーム別成功度判定(nD6)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    if($game_type eq "Arianrhod") {
        if($n1 >= $dice_cnt) {  # 全部１の目ならファンブル
            $output .= " ＞ ファンブル";
        } elsif($n_max >= 2) {  # ２個以上６の目があったらクリティカル
            $output .= " ＞ クリティカル(+" . "$n_max" . "D6)";
        } elsif($ulflg eq ">=") {
            if($diff ne "?") {
                if($total_n >= $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    }
    elsif($game_type eq "Demon Parasite" || $game_type eq "ParasiteBlood") {
        if($n1 >= 2) {  # １の目が２個以上ならファンブル
            $output .= " ＞ 致命的失敗";
        } elsif($n_max >= 2) {  # ６の目が２個以上あったらクリティカル
            $output .= " ＞ 効果的成功";
        } elsif($ulflg eq ">=") {
            if($diff ne "?") {
                if($total_n >= $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        } elsif($ulflg eq ">") {
            if($diff ne "?") {
                if($total_n > $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    }
    elsif($game_type eq "NightmareHunterDeep") {
        if($ulflg eq ">=") {
            if($diff eq "?") {
                my $sucLv = 1;
                my $sucNL = 0;
                while($total_n >= $sucLv*5-1) { $sucLv += 1; }
                while($total_n >= $sucNL*5+5) { $sucNL += 1; }
                $sucLv -= 1;
                $sucNL -= 1;
                if($sucLv <= 0) {
                    $output .= " ＞ 失敗";
                } else {
                    $output .= " ＞ Lv".$sucLv."/NL".$sucNL."成功";
                }
            } elsif($total_n >= $diff) {
                $output .= " ＞ 成功";
            } else {
                $output .= " ＞ 失敗";
            }
        }
    }
    elsif($game_type eq "TokumeiTenkousei") {
        if($ulflg eq ">=") {
            if($diff ne "?") {
                if($total_n >= $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    }
    elsif ($game_type eq "DarkBlaze") {
        if($ulflg eq ">=") {
            if($diff ne "?") {
                if($total_n >= $diff) {
                    $output .= " ＞ 成功";
                } else {
                    $output .= " ＞ 失敗";
                }
            }
        }
    }
    return $output;
}
sub check_nDx { # ゲーム別成功度判定(ダイスごちゃ混ぜ系)
    my($total_n, $dice_n, $ulflg, $diff, $dice_cnt, $dice_max, $n1, $n_max) = @_ ;
    my $output = "";

    my($suc) = &check_hit($total_n, $ulflg, $diff);
    if($suc >= 1) {
        $output .= " ＞ 成功";
    } else {
        $output .= " ＞ 失敗";
    }
    return $output;
}

#=========================================================================
#**                       汎用ポイントカウンタ
#=========================================================================

####################          カウンタ操作         ########################
#削除

#==========================================================================
#**                         カード関係
#==========================================================================
#削除

###########################################################################
#**                              出力関連
###########################################################################
sub broadmsg {
    my($self, $output_msg, $nick) = @_;

    if($output_msg ne "1") {
        if(!$DodontoFlg) {
            &send_msg($self,$nick, $output_msg);
        } else {
            $self->privmsg("", encode($IRC_CODE, $output_msg));
        }
    }
}
sub send_msg {
    my($self, $to ,$msgs) = @_;

    if(length($msgs) > $SEND_STR_MAX) {         # 長すぎる出力はイタズラと見なす
        $msgs = '結果が長くなりすぎました';
    }
    my @msg_arr = split "\n", $msgs;
    foreach my $msg1 (@msg_arr) {
        &debug_out("$to [$nick] ${msgs}\n");
        if($NOTICE_SW) {
            $self->notice(encode($IRC_CODE ,$to), encode($IRC_CODE ,$msg1));        # noticeで送信
        } else {
            $self->privmsg(encode($IRC_CODE ,$to), encode($IRC_CODE ,$msg1));       # privmsgで送信
        }
    }
}
sub debug_out {
    if(!$DodontoFlg) {
        if(scalar @_ > 1) {
            printf @_ ;
        } else {
            print @_ ;
        }
    }
}
####################         テキスト前処理        ########################
sub parren_killer {
    my($string) = @_;

    while($string =~ /^(.*?)\[(\d+[Dd]\d+)\](.*)/) {
        my $str_before = "";
        my $str_after = "";
        my $dice_cmd = $2;
        $str_before = $1 if($1);
        $str_after = $3 if($3);
        my ($rolled, $dmy) = &dice_mul($dice_cmd);
        $string = "${str_before}${rolled}${str_after}";
    }
    while($string =~ /^(.*?)\[(\d+)[.]{3}(\d+)\](.*)/) {
        my $str_before = "";
        my $str_after = "";
        $str_before = $1 if($1);
        my $rand_s = $2;
        my $rand_e = $3;
        $str_after = $4 if($4);
        if($rand_s < $rand_e) {
            my ($rolled, $dmy) = &roll(1, int($rand_e - $rand_s + 1));
            $rolled += $rand_s - 1;
            $string = "${str_before}${rolled}${str_after}";
        }
    }
    while($string =~ /^(.*?)(\([\d\/*+-]+?\))(.*)/) {
        my $str_b = "";
        my $str_a = "";
        $str_b = $1 if($1);
        my $par_i = $2;
        $str_a = $3 if($3);
        my $par_o = paren_k($par_i);
        if($par_o != 0) {
            if($par_o < 0) {
                if($str_b =~ /(.+?)(\+)$/) {
                    $str_b = $1;
                } elsif($str_b =~ /(.+?)(-)$/) {
                    $str_b = "$1+";
                    $par_o =~ /([\d]+)/;
                    $par_o = $1;
                }
            }
            $string = "$str_b$par_o$str_a";
        } else {
            if($str_a =~ /^([DBRUdbru][\d]+)(.*)/) {
                $str_a = $2;
            }
            $string = "${str_b}0${str_a}";
        }
    }

    # ゲーム特有のダイス表記の読み替え処理
    if($game_type =~ /^SwordWorld/i) {
        if($string =~ /(^|\s)(K[\d]+)/i) {
            $string =~ s/\[(\d+)\]/c\[${1}\]/ig;
            $string =~ s/\@(\d+)/c\[${1}\]/ig;
            $string =~ s/\$([\+\-]?[\d]+)/m\[${1}\]/ig;
        }
    }
    elsif($game_type eq "Tunnels & Trolls") {
        if($string =~ /(\d+)LV/i) {
            my $level_diff = ($1) * 5 + 15;
            $string =~ s/(\d+)LV/$level_diff/i;
        }
        if($string =~ /BS/i){
            $string =~ s/(\d+)HBS([^\d\s][\+\-\d]+)/${1}R6${2}[H]/ig;
            $string =~ s/(\d+)HBS/${1}R6[H]/ig;
            $string =~ s/(\d+)BS([^\d\s][\+\-\d]+)/${1}R6${2}/ig;
            $string =~ s/(\d+)BS/${1}R6/ig;
        }
    }
    elsif($game_type eq "NightmareHunterDeep") {
        if($string =~ /^(.+?)Lv(\d+)(.*)/i) {
            $string = $1.($2 * 5 - 1).$3;
        }
        if($string =~ /^(.+?)NL(\d+)(.*)/i) {
            $string = $1.($2 * 5 + 5).$3;
        }
    }
    elsif($game_type eq "ShadowRun4") {
        if($string =~ /(\d+)S6/i) {
            $string =~ s/(\d+)S6/${1}B6/ig;
        }
    }
    elsif($game_type eq "DoubleCross") {
        if($string =~ /(\d+)DX/i) {
            $string =~ s/(\d+)DX(\d*)([^\d\s][\+\-\d]+)/${1}R10${3}[${2}]/ig;
            $string =~ s/(\d+)DX(\d+)/${1}R10[${2}]/ig;
            $string =~ s/(\d+)DX([^\d\s][\+\-\d]+)/${1}R10${2}/ig;
            $string =~ s/(\d+)DX/${1}R10/ig;
            if($string =~ /\@(\d+)/) {
                my $crit = $1;
                $string =~ s/\[\]/\[${crit}\]/;
                $string =~ s/\@(\d+)//;
            }
            $string =~ s/\[\]//g;
        }
    }
    elsif($game_type eq "ArsMagica") {
        if($string =~ /ArS/i) {
            $string =~ s/ArS(\d+)([^\d\s][\+\-\d]+)/1R10${2}[${1}]/ig;
            $string =~ s/ArS([^\d\s][\+\-\d]+)/1R10${1}/ig;
            $string =~ s/ArS(\d+)/1R10[${1}]/ig;
            $string =~ s/ArS/1R10/ig;
        }
    }
    elsif($game_type eq "DarkBlaze") {
        if($string =~ /DB/i) {
            $string =~ s/DB(\d),(\d)/DB${1}${2}/ig;
            $string =~ s/DB\@(\d)\@(\d)/DB${1}${2}/ig;
            $string =~ s/DB(\d)(\d)(#([\d][\+\-\d]*))/3R6+${4}[${1},${2}]/ig;
            $string =~ s/DB(\d)(\d)(#([\+\-\d]*))/3R6${4}[${1},${2}]/ig;
            $string =~ s/DB(\d)(\d)/3R6[${1},${2}]/ig;
        }
    }
    elsif($game_type eq "NightWizard") {
        if($string =~ /NW/i) {
            $string =~ s/(\d+)NW\+?([\-\d]+)@([,\d]+)#([,\d]+)/2R6m[${1},${2}]c[${3}]f[${4}]/ig;
            $string =~ s/(\d+)NW\+?([\-\d]+)/2R6m[${1},${2}]/ig;
            $string =~ s/(\d+)NW/2R6m[${1},0]/ig;
        }
    }
    elsif($game_type eq "TORG") {
        $string =~ s/Result/RT/ig;
        $string =~ s/(Intimidate|Test)/IT/ig;
        $string =~ s/(Taunt|Trick|CT)/TT/ig;
        $string =~ s/Maneuver/MT/ig;
        $string =~ s/(ords|odamage)/ODT/ig;
        $string =~ s/damage/DT/ig;
        $string =~ s/(bonus|total)/BT/ig;
        $string =~ s/TG(\d+)/1R20+${1}/ig;
        $string =~ s/TG/1R20/ig;
    }
    elsif($game_type eq "MeikyuKingdom") {
        $string =~ s/(\d+)MK6/${1}R6/ig;
        $string =~ s/(\d+)MK/${1}R6/ig;
    }
    elsif($game_type eq "EmbryoMachine") {
        $string =~ s/EM(\d+)([\+\-][\+\-\d]+)(@(\d+))(#(\d+))/2R10${2}>=${1}[${4},${6}]/ig;
        $string =~ s/EM(\d+)([\+\-][\+\-\d]+)(#(\d+))/2R10${2}>=${1}[20,${4}]/ig;
        $string =~ s/EM(\d+)([\+\-][\+\-\d]+)(@(\d+))/2R10${2}>=${1}[${4},2]/ig;
        $string =~ s/EM(\d+)([\+\-][\+\-\d]+)/2R10${2}>=${1}[20,2]/ig;
        $string =~ s/EM(\d+)(@(\d+))(#(\d+))/2R10>=${1}[${3},${5}]/ig;
        $string =~ s/EM(\d+)(#(\d+))/2R10>=${1}[20,${3}]/ig;
        $string =~ s/EM(\d+)(@(\d+))/2R10>=${1}[${3},2]/ig;
        $string =~ s/EM(\d+)/2R10>=${1}[20,2]/ig;
    }
    elsif($game_type eq "GehennaAn") {
        $string =~ s/(\d+)GA(\d+)([\+\-][\+\-\d]+)/${1}R6${3}>=${2}[1]/ig;
        $string =~ s/(\d+)GA(\d+)/${1}R6>=${2}[1]/ig;
        $string =~ s/(\d+)G(\d+)([\+\-][\+\-\d]+)/${1}R6${3}>=${2}[0]/ig;
        $string =~ s/(\d+)G(\d+)/${1}R6>=${2}[0]/ig;
    }
    elsif($game_type eq "Nechronica") {
        $string =~ s/(\d+)NC(10)?([\+\-][\+\-\d]+)/${1}R10${3}[0]/ig;
        $string =~ s/(\d+)NC(10)?/${1}R10[0]/ig;
        $string =~ s/(\d+)NA(10)?([\+\-][\+\-\d]+)/${1}R10${3}[1]/ig;
        $string =~ s/(\d+)NA(10)?/${1}R10[1]/ig;
    }
    elsif($game_type eq "MeikyuDays") {
        $string =~ s/(\d+)MD6/${1}R6/ig;
        $string =~ s/(\d+)MD/${1}R6/ig;
    }
    elsif($game_type eq "BarnaKronika") {
        $string =~ s/(\d+)BKC(\d)/${1}R6[0,${2}]/ig;
        $string =~ s/(\d+)BAC(\d)/${1}R6[1,${2}]/ig;
        $string =~ s/(\d+)BK/${1}R6[0,0]/ig;
        $string =~ s/(\d+)BA/${1}R6[1,0]/ig;
    }
    elsif($game_type eq "RokumonSekai2") {
        $string =~ s/(\d+)RS([\+\-][\+\-\d]+)<=(\d+)/3R6${2}<=${3}[${1}]/ig;
        $string =~ s/(\d+)RS<=(\d+)/3R6<=${2}[${1}]/ig;
    }


    $string =~ s/([\d]+[dD])([^\d]|$)/${1}6${2}/g;

    return $string;
}
sub paren_k {
    my($string) = @_;
    my $kazu_o = 0;

    if($string =~ /([\d\/*+-]+)/) {
        $string = $1;
        my @KAZU_P = split(/\+/, $string);
        foreach my $kazu_a (@KAZU_P) {
            my $work = 0;
            my $dec_p = "";
            if($kazu_a =~ /(.*?)(-)(.*)/) {
                $kazu_a = $1;
                $dec_p = $3;
            }
            my $mul = 1;
            my $dev = 1;
            while($kazu_a =~ /(.*?)(\*[\d]+)(.*)/) {
                my $par_b = $1;
                my $par_a = $3;
                my $par_c = $2;
                $kazu_a = "$par_b$par_a";
                if($par_c =~ /([\d]+)/) {
                    $mul = $mul * $1;
                }
            }
            while($kazu_a =~ /(.*?)(\/[\d]+)(.*)/) {
                my $par_b = $1;
                my $par_a = $3;
                my $par_c = $2;
                $kazu_a = "$par_b$par_a";
                if($par_c =~ /([\d]+)/) {
                    $dev = $dev * $1;
                }
            }
            if($kazu_a =~ /([\d]+)/) {
                $work = ($1) * $mul;
                if($round_flg == 1){
                    $kazu_o += int($work / $dev + 0.999) if($dev);
                } elsif($round_flg >= 2){
                    $kazu_o += int($work / $dev + 0.5) if($dev);
                } else {
                    $kazu_o += int($work / $dev) if($dev);
                }
            }
            if($dec_p ne "") {
                my @KAZU_M = split(/-/, $dec_p);
                foreach my $kazu_s (@KAZU_M) {
                    $mul = 1;
                    $dev = 1;
                    while($kazu_s =~ /(.*?)(\*[\d]+)(.*)/) {
                        my $par_b = $1;
                        my $par_a = $3;
                        my $par_c = $2;
                        $kazu_s = "$par_b$par_a";
                        if($par_c =~ /([\d]+)/) {
                            $mul = $mul * $1;
                        }
                    }
                    while($kazu_s =~ /(.*?)(\/[\d]+)(.*)/) {
                        my $par_b = $1;
                        my $par_a = $3;
                        my $par_c = $2;
                        $kazu_s = "$par_b$par_a";
                        if($par_c =~ /([\d]+)/) {
                            $dev = $dev * $1;
                        }
                    }
                    if($kazu_s =~ /([\d]+)/) {
                        $work = ($1) * $mul;
                        if($round_flg == 1){
                            $kazu_o -= int($work / $dev + 0.999) if($dev);
                        } elsif($round_flg >= 2){
                            $kazu_o -= int($work / $dev + 0.5) if($dev);
                        } else {
                            $kazu_o -= int($work / $dev) if($dev);
                        }
                    }
                }
            }
        }
    }
    return $kazu_o;
}

###########################################################################
#**                        ゲーム設定関連
###########################################################################
#削除

sub game_clear {
    $upperinf = 0;      #上方無限
    $upper_dice = 0;    #無限ロールのダイス
    $max_dice = 0;      #最大値表示
    $min_dice = 0;      #最小値表示
    $reroll_cnt = 0;    #振り足し回数上限
    $reroll_n = 0;      #振り足しする条件
    $d66_on = 0;        #d66の差し替え
    $sort_flg = 0;      #ソート設定
    $double_up = 0;     #ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
    $suc_def = "";      #目標値が空欄の時の目標値
    $round_flg = 0;     #端数の処理(0=切り捨て, 1=切り上げ, 2=四捨五入)
    $double_type = 0;   #ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
    $modeflg = $SEND_MODE;
#    &c_set_default;
#削除(カード関連処理)
}

sub game_set {  # 各種ゲームモードの設定
    my $tnick = $_[0];

    if($tnick =~ /(^|\s)((Cthulhu)|(COC))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Cthulhu";
        return('Game設定をCall of Cthulhu(BRP)に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Hieizan)|(COCH))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = 'Hieizan';
        return('Game設定を比叡山炎上(CoC)に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Elric!)|(EL))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = 'Elric!';
        return('Game設定をElric!に設定しました');
    }
    elsif($tnick =~ /(^|\s)((RuneQuest)|(RQ))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "RuneQuest";
        return('Game設定をRuneQuestに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Chill)|(CH))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Chill";
        return('Game設定をChillに設定しました');
    }
    elsif($tnick =~ /(^|\s)((RoleMaster)|(RM))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "RoleMaster";
        $upperinf = 96;
        $upper_dice = 100;
        return('Game設定をRoleMasterに設定しました');
    }
    elsif($tnick =~ /(^|\s)((ShadowRun)|(SR))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "ShadowRun";
        $upperinf = 6;
        $upper_dice = 6;
        $sort_flg = 3;
        return('Game設定をShadowRunに設定しました');
    }
    elsif($tnick =~ /(^|\s)((ShadowRun4)|(SR4))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "ShadowRun4";
        $sort_flg = 3;
        $reroll_n = 6;      #振り足しする出目
        $suc_def = ">=5";   #目標値が空欄の時の目標値
        return('Game設定をShadowRun4版に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Pendragon)|(PD))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Pendragon";
        return('Game設定をPendragonに設定しました');
    }
    elsif($tnick =~ /(^|\s)((SwordWorld)|(SW))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "SwordWorld";
        $rating_table = 0;  # レーティング表を文庫版モードに
        return('Game設定をソードワールドに設定しました');
    }
    elsif($tnick =~ /(^|\s)((SwordWorld)\s*2\.0|(SW)\s*2\.0)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "SwordWorld2.0";
        $rating_table = 2;
        return('Game設定をソードワールド2.0に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Arianrhod)|(AR))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Arianrhod";
        $modeflg = 2;
        $d66_on = 1;
        $sort_flg = 1;
        return('Game設定をアリアンロッドに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Infinite[\s]*Fantasia)|(IF))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Infinite Fantasia";
        return('Game設定を無限のファンタジアに設定しました');
    }
    elsif($tnick =~ /(^|\s)(WARPS)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "WARPS";
        return('Game設定をWARPSに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Demon[\s]*Parasite)|(DP))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Demon Parasite";
        $modeflg = 2;
        $d66_on = 1;
        $sort_flg = 1;
        return('Game設定をデモンパラサイト/鬼御魂に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Parasite\s*Blood)|(PB))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "ParasiteBlood";
        $modeflg = 2;
        $d66_on = 1;
        $sort_flg = 1;
        return('Game設定をパラサイトブラッドに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Gun[\s]*Dog)|(GD))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Gundog";
        return('Game設定をガンドッグに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Gun[\s]*Dog[\s]*Zero)|(GDZ))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "GundogZero";
        return('Game設定をガンドッグゼロに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Tunnels[\s]*&[\s]*Trolls)|(TuT))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Tunnels & Trolls";
        $modeflg = 2;
        $sort_flg = 1;
        $double_up = 1;
        return('Game設定をトンネルズ＆トロールズに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Nightmare[\s]*Hunter[=\s]*Deep)|(NHD))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "NightmareHunterDeep";
        $modeflg = 2;
        $sort_flg = 1;
        return('Game設定をナイトメアハンター・ディープに設定しました');
    }
    elsif($tnick =~ /(^|\s)((War[\s]*Hammer(FRP)?)|(WH))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Warhammer";
        $modeflg = 2;
        $round_flg = 1;
        return('Game設定をウォーハンマーFRPに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Phantasm[\s]*Adventure)|(PA))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "PhantasmAdventure";
        $modeflg = 2;
        return('Game設定をファンタズムアドベンチャーに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Chaos[\s]*Flare)|(CF))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Chaos Flare";
#削除(カード関連処理)
        return('Game設定をカオスフレアに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Cthulhu[\s]*Tech)|(CT))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "CthulhuTech";
        $modeflg = 2;
        $sort_flg = 1;
        return('Game設定をクトゥルフ・テックに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Tokumei[\s]*Tenkousei)|(ToT))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "TokumeiTenkousei";
        $modeflg = 2;
        $sort_flg = 1;
        $double_up = 1;
        $double_type = 2;
        return('Game設定を特命転攻生に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Shinobi[\s]*Gami)|(SG))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "ShinobiGami";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        return('Game設定を忍神に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Double[\s]*Cross)|(DX))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "DoubleCross";
        $modeflg = 2;
        $sort_flg = 2;
        $reroll_n = 10;     #振り足しする条件
        $upperinf = 10;     #上方無限
        $upper_dice = 10;   #無限ロールのダイス
        $max_dice = 1;      #最大値表示
        return('Game設定をダブルクロス3に設定しました');
    }
    elsif($tnick =~ /(^|\s)((Sata[\s]*Supe)|(SS))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Satasupe";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        return('Game設定をサタスペに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Ars[\s]*Magica)|(AM))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "ArsMagica";
        $modeflg = 2;
        return('Game設定をArsMagicaに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Dark[\s]*Blaze)|(DB))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "DarkBlaze";
        $modeflg = 2;
        return('Game設定をダークブレイズに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Night[\s]*Wizard)|(NW))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "NightWizard";
        $modeflg = 2;
        return('Game設定をナイトウィザードに設定しました');
    }
    elsif($tnick =~ /(^|\s)TORG$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "TORG";
        $modeflg = 2;
        return('Game設定をTORGに設定しました');
    }
    elsif($tnick =~ /(^|\s)(hunters\s*moon|HM)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "HuntersMoon";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        $round_flg = 1;     # 端数切り上げに設定
        return('Game設定をハンターズ・ムーンに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Meikyu\s*Kingdom|MK)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "MeikyuKingdom";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        return('Game設定を迷宮キングダムに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Earth\s*Dawn|ED)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "EarthDawn";
        $modeflg = 2;
        $sort_flg = 1;
        return('Game設定をEarthDawnに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Embryo\s*Machine|EM)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "EmbryoMachine";
        $modeflg = 2;
        $sort_flg = 1;
        return('Game設定をエムブリオマシンに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Gehenna\s*An|GA)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "GehennaAn";
        $modeflg = 3;
        $sort_flg = 3;
        return('Game設定をゲヘナ・アナスタシアに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Magica[\s]*Logia)|(ML))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "MagicaLogia";
        $modeflg = 2;
        $sort_flg = 3;
        $d66_on = 2;
        return('Game設定をマギカロギアに設定しました');
    }
    elsif($tnick =~ /(^|\s)((Nechronica)|(NC))$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Nechronica";
        $suc_def = "6";      #目標値が空欄の時の目標値
        $modeflg = 2;
        $sort_flg = 3;
        return('Game設定をネクロニカに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Meikyu\s*Days|MD)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "MeikyuDays";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        return('Game設定を迷宮デイズに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Peekaboo|PK)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "Peekaboo";
        $modeflg = 2;
        $sort_flg = 1;
        $d66_on = 2;
        $round_flg = 1;     # 端数切り上げに設定
        return('Game設定をピーカブーに設定しました');
    }
    elsif($tnick =~ /(^|\s)(Barna\sKronika|BK)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "BarnaKronika";
        $modeflg = 2;
        $sort_flg = 3;
#カード関連のため削除
        $card_place = 0;    #手札の他のカード置き場
        $can_tap = 0;       #場札のタップ処理の必要があるか？
        return('Game設定をバルナ・クロニカに設定しました');
    }
    elsif($tnick =~ /(^|\s)(RokumonSekai2|RS2)$/i) {
        &game_clear;        # 諸設定のクリア
        $game_type = "RokumonSekai2";
        $modeflg = 2;
        $sort_flg = 1;
        return('Game設定を六門世界2nd.に設定しました');
    }
    elsif($tnick =~ /(^|\s)(None)$/i || $tnick eq "") {   # ゲーム設定を解除する
        &game_clear;        # 諸設定のクリア
        $game_type = "";
        return('Game設定を解除しました');
    } else {
        return('そのゲームは未実装です');
    }
}

#==========================================================================
#**                    ランダムヒロインジェネレータ
#==========================================================================
####################            読み込み           ########################
sub set_random_heroin {
    my @src_arr = (
        #'竹流ちゃん',
        'takeruchan',
        '年齢,乳児,幼児,小児,1D20,1D100,1D10+10,2D10+5,5D6+5,成人,中年,老人,年齢不詳',
        '性別,♀,女性,男の娘,おにゃのこ,未確認,たぶん女の子,未設定,性別：竹流ちゃん',
        '身長,ちっちゃい,ちまい,ちいさい,(1D100+70)cm,(5D6+120)cm,120cm,140cm,160cm,でかい,PC１の身長-20cm,12ｍ,全長16.7Ｍ',
        '体重,軽い,重い,(2D10+28)kg,(4D10+30)kg,(身長-110)kg,(身長m×身長m×(20+1D6))kg,PC1とPC2の平均kg,3ｔ,冒涜的な重さ,存在の耐えられない軽さ,ひ・み・つ',
        '体格,普通,やせ気味,やせすぎ,やせている,太り気味,太りすぎ,太っている,つるぺた,ずんどう,むっちり,ぷにぷに,ムキムキ,グラマー,巨乳,貧乳,スレンダー,幼児体型',
        '一人称,あたし,わたし,あたい,うち,ぼく,ボク,俺,オレ,ミー,わっち,拙者,拙僧,自分,私,わたくし,あたち,それがし,竹流ちゃん',
        '口調,普通,ですます調,～ござる,語尾を伸ばす,～じゃ,～でちゅ,怪しい中国人風,怪しい西洋人風,～でございます,常に命令口調,～やんす,乱暴な男の子口調,聞き取れない,筆談,９割がボディーランゲージ,東北訛り,関西弁,九州訛り,北海道弁,２進数,お嬢様　～ですわ,お嬢様　わがまま,16進数,Ruby,ツンデレ,ハキハキ,スロー,まくし立て',
        '肌の色,白,黄,褐色,黒,青白い,黄緑,深緑,鱗,病的な白',
        '髪（長さ）,ショート,ミディアム,セミロング,ロング,兜(帽子)のため不明,自分で髪の毛を踏むくらいのロング,ベリーショート,アーミーカット',
        '髪（色）,黒色,茶色,金色,銀色,赤色,灰色,青色,緑色,紫色,メッシュ（任意）,RGB各256階調をダイスで,ピンク,水色,黄色',
        '髪（スタイル）,ボブ,ポニーテール,三つ編み,ストレート,ウェーブ,ツインテール,縦ロール,ボサボサ,アフロ,姫カット,兜(帽子)のため不明,お団子,逆モヒカン,モヒカン,クワッドテール,アホ毛,リボン,カチューシャ,バッテン髪留め',
        '服装,素肌の上に白衣＋メガネ,キャミソールの上に白衣＆メガネ,白衣を模した機械式装甲+メガネ型メインカメラ,白衣に見える外套と、誘惑するようなタイトスカート,白衣とめがねの代わりにゴーグル,肌色のタイツの上にコート,白衣の下にガクラン＋下駄',
        '雰囲気,博士,お嬢様,妹系,電波,毒電波,ヤンデレ,名状しがたきオーラ,見るだにツンツン,小動物,病弱,理系なのに活動的,勝ち気,ハイテンション,物静か,気まぐれ,真面目,脳天気',
        '',
        #'ヒロイン',
        'heroine',
        '年齢,10+2d6',
        '性別,女性',
        '身長,130+年齢+2d6',
        '体重,(身長m×身長m×(18.5+1d6))kg',
        '体格,普通,筋肉質,ぽっちゃり',
        '一人称,あたし,わたし,あたい,うち,私（わたくし）,ボク',
        '口調,普通,元気,ていねい,ボソボソと呟く,ぶっきらぼう',
        '肌の色,白,黄,褐色,黒',
        '髪（長さ）,ベリーショート,ショート,ミディアム,セミロング,ロング',
        '髪（色）,黒色,茶色,金色',
        '髪（スタイル）,ボブ,ポニーテール,三つ編み,ストレート,ウェーブ,常に帽子',
        '服装,学生服,カジュアル,ギャル系,B系',
        '雰囲気,普通,おっとり,勝ち気,恥ずかしがり屋,おせっかい',
        '',
        #'ヒロイン？',
        'heroine?',
        '年齢,5d6歳',
        '性別,女性,男性,不詳',
        '身長,(125+8d6)cm',
        '体重,(身長m×身長m×(15+2d6))kg',
        '体格,普通,筋肉質,ぽっちゃり',
        '一人称,あたし,わたし,あたい,うち,私（わたくし）,ボク,オレ,（自分の下の名前）',
        '口調,普通,元気,ていねい,ボソボソと呟く,ぶっきらぼう,お嬢様,筆談,強い地方訛り',
        '肌の色,白,黄,褐色,黒,病的な白さ',
        '髪（長さ）,ベリーショート,ショート,ミディアム,セミロング,ロング',
        '髪（色）,黒色,茶色,金色,白色,桃色,青色,緑色',
        '髪（スタイル）,ボブ,ポニーテール,三つ編み,ストレート,ウェーブ,常に帽子,ボサボサ,アフロ,ツインテール',
        '服装,学生服,カジュアル,ギャル系,B系,スポーツウェア,和服,ドレス,バイトの制服,ブランド物オンリー,ゴスロリ,ジーンズ,ワンピース,白衣,チャイナ,アオザイ',
        '雰囲気,普通,おっとり,勝ち気,恥ずかしがり屋,おせっかい,高飛車,電波系,小動物系,ハイテンション,物静か,気まぐれ,ミステリアス,シリアス,真面目,脳天気',
    );
    my $name = "";
    foreach my $string (@src_arr) {
        if($string ne '') {
            my @param = split /,/, $string;
            my $kind = shift @param;
            if(scalar @param) {
                my $para_str = join ",", @param;
                $rnd_heroine{$name.','.$kind} = $para_str;
                $rnd_heroine{$name} .= "${kind},";
            } else {
                $rnd_heroine{$name} =~ s/,$//i if(exists $rnd_heroine{$name});
                $name = $kind;
            }
        }
    }
    $rnd_heroine{$name} =~ s/,$//i;
}

####################              表示             ########################
sub random_heroine_generator {
    my $string = shift;
    my $output = '1';
    
    if($string =~ /(^|\s+)${RND_GNR_PREFIX}(.+)(\s|$)/i) {
        my $heroine = $2;
        if(exists $rnd_heroine{$heroine}) {
            my @param_list = split(/,/,$rnd_heroine{$heroine});
            $output = $heroine." ＞ ";
            foreach my $kind (@param_list) {
                my @data = split(/,/, $rnd_heroine{"${heroine},${kind}"});
                $output .= $kind.":".$data[int(rand scalar @data)].", ";
            }
        }
    }
    return $output;
}


###########################################################################
#**                             IRC起動
###########################################################################
&debug_out("Installing handler routines...");
$conn->add_handler('cping',   \&on_ping);
$conn->add_handler('crping',  \&on_ping_reply);
$conn->add_handler('msg',     \&on_msg);
#$conn->add_handler('public',  \&on_public);
$conn->add_handler('caction', \&on_action);
$conn->add_handler('join',    \&on_join);
$conn->add_handler('part',    \&on_part);
$conn->add_handler('topic',   \&on_topic);
$conn->add_handler('notopic', \&on_topic);
$conn->add_handler('invite',  \&on_invite);
$conn->add_handler('kick',    \&on_kick);

$conn->add_global_handler([ 251,252,253,254,302,255 ], \&on_init);
$conn->add_global_handler('disconnect', \&on_disconnect);
$conn->add_global_handler([ 376,422 ], \&on_connect);   # 376 = EndofMOTD, 422 = no MOTD
$conn->add_global_handler(433, \&on_nick_taken);
$conn->add_global_handler(353, \&on_names);
&debug_out(" done.\n");
&debug_out("starting...\n");
#$irc->start;

#print("##>customBot END<##");


if( $isTestDiceBot ) {
    open(TEST_DICEBOT_RESULT_FILE, '> testData.txt');
}

sub recordTestResult {
    my $text = shift;
    print TEST_DICEBOT_RESULT_FILE $text;
}


sub createTestDataOne {
    my $input = shift;
    my $game = shift;
    
    recordTestResult("============================\n"
                     . "input:${input}\t${game}\n"
                     . "output:");
    
    $game_type = $game;
    &game_set($game_type);
    $irc->init();
    $irc->setInputData($input, $game);
    # $irc->start;
    &on_public($irc, $input);
    
    recordTestResult("\n"
		     . "rand:" . join(",", @randomResults) . "\n");
    @randomResults = ();
}


sub createTestDataByInputs {
    my $defaultCount = shift;
    
    unless( $defaultCount ) {
        $defaultCount = 10;
    }
    
    open(FILE, 'inputs.txt');
    my @buffer = <FILE>;
    close(FILE);
    
    my $game = "";
    foreach my $line (@buffer) {
        chop $line;
        
        if( $line eq "") {
            next;
        }
        
        if( $line =~ /^(.+):$/ ) {
            $game = $1;
            next;
        }
        
        my( $input, $count ) = split("\t", $line);
        
        next if( $line =~ /^;/ );
        
        if( ! $count ) {
            $count = $defaultCount;
        }
        
        for(my $i = 0 ; $i < $count ; $i++) {
            createTestDataOne($input, $game);
        }
    }
}

&createTestDataByInputs($ARGV[0]);
