package IRC;

#use strict; Barewords
use warnings;

use constant {
    # Locations
    TOWN   => 0,
    WORK   => 1,
    FOREST => 2,

    # Classes/Abilities
    BARBARIAN => 'b',
    PALADIN   => 'p',
    ROGUE     => 'r',
    WIZARD    => 'w',
};

my %options = (
    quest => {
               'players'   => 'questplayers',
               'min-level' => 'questminlevel',
             },
);

our $primnick = $Options::opts{botnick};

my $lastreg = 0;
my $registrations = 0;
my $conn_tries = 0;
my $outbytes = 0;
my $inbytes = 0;
my $freemessages = 4;
my %prev_online;
my %split;
our %auto_login;
our $lasttime = 1;
our %onchan;
our $sock;
our @queue;
our $sel;

sub connect {

IRC::createSocket();

if (!$IRC::sock) {
    Bot::debug("Failed to connect to all servers\r\n");
    exit 1;
}

$sel = IO::Select->new($IRC::sock);
IRC::sts("PASS $Options::opts{password}");
IRC::sts("NICK $Options::opts{botnick}");
IRC::sts("USER $Options::opts{botnick} 0 0 :$Options::opts{botnick}");

}


sub createSocket {
 while (!$sock && $conn_tries < 2*@{$Options::opts{servers}}) {
    Bot::debug("Connecting to: $Options::opts{servers}->[0]\r\n");
    my %sockinfo = (PeerAddr => $Options::opts{servers}->[0]);
    if ($Options::opts{localaddr}) {
        $sockinfo{LocalAddr} = $Options::opts{localaddr};
    }
    if ($Options::opts{ipv6}) {
        $sock = IO::Socket::INET6->new(%sockinfo);
    }
    else {
        $sock = IO::Socket::INET->new(%sockinfo);
    }

    ++$conn_tries;

    if (!$sock) {
        Bot::debug("Socket closed; Moving server to end of list\r\n");
        push(@{$Options::opts{servers}},shift(@{$Options::opts{servers}}));
    }
 }

}

sub sts {
    my($text,$skipq) = @_;
    if ($skipq) {
        if ($sock) {
            Bot::debug("sts(): $text\r\n");
            print $sock "$text\r\n";
            $outbytes += length($text) + 2;
        }
        else {
            Bot::debug("sts(): clear queue\r\n");
            undef(@queue);
            return;
        }
    }
    else {
        Bot::debug("sts(): queue: $text\r\n");
        push(@queue,$text);
    }
}

sub fq {
    if (!@queue) {
        ++$freemessages if $freemessages < 4;
        return undef;
    }
    my $sentbytes = 0;
    for (0..$freemessages) {
        last() if !@queue;
        my $line=shift(@queue);
        if ($_ != 0 && (length($line)+$sentbytes) > 768) {
            Bot::debug("fq(): dequeue: $line\r\n");
            unshift(@queue,$line);
            last();
        }
        if ($sock) {
            --$freemessages if $freemessages > 0;
            Bot::debug("fq(): $line\r\n");
            print $sock "$line\r\n";
            $sentbytes += length($line) + 2;
        }
        else {
            Bot::debug("fq(): clear queue\r\n");
            undef(@queue);
            last();
        }
        $outbytes += length($line) + 2;
    }
}

sub chanmsg {
    my $msg = shift or return undef;
    privmsg($msg, $Options::opts{botchan}, shift);
}

sub privmsg {
    my $msg = shift or return undef;
    my $target = shift or return undef;
    my $force = shift;

    while (length($msg)) {
        sts("PRIVMSG $target :".substr($msg,0,450),$force);
        substr($msg,0,450)="";
    }
}

sub notice {
    my $msg = shift or return undef;
    my $target = shift or return undef;
    my $force = shift;

    while (length($msg)) {
        sts("NOTICE $target :".substr($msg,0,450),$force);
        substr($msg,0,450)="";
    }
}

sub parse {
    my($in) = shift;
    $inbytes += length($in);
    $in =~ s/[\r\n]//g;
    Bot::debug("parse(): $in\r\n");
    my @arg = split(/\s/,$in);
    my $usernick = substr((split(/!/,$arg[0]))[0],1);
    my $username = finduser($usernick);
    if (lc($arg[0]) eq 'ping') { IRC::sts("PONG $arg[1]",1); }
    elsif (lc($arg[0]) eq 'error') {
        $Simulation::rps{$_}{online}=1 for keys(%auto_login);
        Database::writejsondb(\%Simulation::rps);
        return;
    }
    $arg[1] = lc($arg[1]);
    if ($arg[1] eq '433' && $Options::opts{botnick} eq $arg[3]) {
        $Options::opts{botnick} .= int(rand(999));
        IRC::sts("NICK $Options::opts{botnick}");
    }
    elsif ($arg[1] eq 'join') {
        $onchan{$usernick}=time();
        if ($Options::opts{botnick} eq $usernick) {
            IRC::sts("WHO $Options::opts{botchan}");
            $lasttime = time();
        }
    }
    elsif ($arg[1] eq 'quit') {
        Level::penalize($username,"quit");
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'nick') {
        if ($usernick eq $Options::opts{botnick}) {
            $Options::opts{botnick} = substr($arg[2],1);
        }
        else {
            Level::penalize($username,"nick",$arg[2]);
            $onchan{substr($arg[2],1)} = delete($onchan{$usernick});
        }
    }
    elsif ($arg[1] eq 'part') {
        Level::penalize($username,"part");
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'kick') {
        $usernick = $arg[3];
        Level::penalize(finduser($usernick),"kick");
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'notice' && $arg[2] ne $Options::opts{botnick}) {
        Level::penalize($username,"notice",length("@arg[3..$#arg]")-1);
    }
   elsif ($arg[1] eq 'privmsg' && $arg[2] eq $Options::opts{botchan}) {
        Level::penalize($username,"privmsg",length("@arg[3..$#arg]")-1);
    }
    elsif ($arg[1] eq '001') {
        IRC::sts("MODE $Options::opts{botnick} :$Options::opts{botmodes}");
        IRC::sts("JOIN $Options::opts{botchan}");
        $Options::opts{botchan} =~ s/ .*//;
    }
    elsif ($arg[1] eq '315') {
        Quests::loadquestfile();
    }
    elsif ($arg[1] eq '005') {
        if ("@arg" =~ /MODES=(\d+)/) { $Options::opts{modesperline}=$1; }
    }
    elsif ($arg[1] eq '352') {
        my $user;
        $onchan{$arg[7]}=time();
        if (exists($prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]})) {
            $Simulation::rps{$prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]}}{online} = 1;
            $auto_login{$prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]}}=1;
        }
    }
    elsif ($arg[1] eq 'privmsg') {
        $arg[0] = substr($arg[0],1);
        if (lc($arg[2]) eq lc($Options::opts{botnick})) {
            $arg[3] = lc(substr($arg[3],1));
            if ($arg[3] eq "version") {
                IRC::privmsg("VERSION IRPG bot v$main::version by raz.",$usernick); ###raz### ;^)-~~
            }
            elsif ($arg[3] eq "peval" && $Options::opts{peval}) {
                if (!ha($username) || ($Options::opts{ownerpevalonly} && $Options::opts{owner} ne $username)) {
                    IRC::privmsg("You don't have access to PEVAL.", $usernick);
                }
                else {
                   my @peval = eval "@arg[4..$#arg]";
                    if (@peval >= 4 || length("@peval") > 1024) {
                        IRC::privmsg("Command produced too much output to send outright; queueing ".length("@peval").
                                " bytes in ".scalar(@peval)." items. Use CLEARQ to clear queue if needed.",$usernick,1);
                        IRC::privmsg($_,$usernick) for @peval;
                    }
                    else { IRC::privmsg($_,$usernick, 1) for @peval; }
                    IRC::privmsg("EVAL ERROR: $@", $usernick, 1) if $@;
                }
            }
            elsif ($arg[3] eq "register") {
                if (defined $username) {
                    IRC::privmsg("Sorry, you are already online as $username.",$usernick);
                }
                else {
                    if ($#arg < 7 || $arg[7] eq "") {
                        IRC::privmsg("Try: REGISTER <char name> <password> <ability> <class>",$usernick);
                    }
                    elsif ($Simulation::pausemode) {
                        IRC::privmsg("Sorry, new accounts may not be registered right now.",$usernick);
                    }
                    elsif (exists $Simulation::rps{$arg[4]} || ($Options::opts{casematters} && scalar(grep { lc($arg[4]) eq lc($_) } keys(%Simulation::rps)))) {
                        IRC::privmsg("Sorry, that character name is already in use.",$usernick);
                    }
                    elsif (lc($arg[4]) eq lc($Options::opts{botnick}) || lc($arg[4]) eq lc($primnick)) {
                        IRC::privmsg("Sorry, that character name cannot be registered.",$usernick);
                    }
                    elsif (!exists($onchan{$usernick})) {
                        IRC::privmsg("Sorry, you're not in $Options::opts{botchan}.",$usernick);
                    }
                    elsif (length($arg[4]) > 16 || length($arg[4]) < 1) {
                        IRC::privmsg("Sorry, character names must be < 17 and > 0 chars long.", $usernick);
                    }
                    elsif ($arg[4] =~ /^#/) {
                        IRC::privmsg("Sorry, character names may not begin with #.",$usernick);
                    }
                    elsif ($arg[4] =~ /\001/) {
                        IRC::privmsg("Sorry, character names may not include character \\001.",$usernick);
                    }
                    elsif ($arg[4] =~ /[[:^print:]]/ || "@arg[7..$#arg]" =~ /[[:^print:]]/) {
                        IRC::privmsg("Sorry, neither character names nor classes may include non-printable chars.",$usernick);
                    }
                    elsif (!lc($arg[6]) eq "barbarian" || !lc($arg[6]) eq "wizard" || !lc($arg[6]) eq "paladin" || !lc($arg[6]) eq "rogue") {
                        IRC::privmsg("Sorry, character abilities are one of: Barbarian, Wizard, Paladin or Rogue.",$usernick);
                    }
                    elsif (length("@arg[7..$#arg]") > 30) {
                        IRC::privmsg("Sorry, character classes must be < 31 chars long.",$usernick);
                    }
                    elsif (time() == $lastreg) {
                        IRC::privmsg("Wait 1 second and try again.",$usernick);
                    }
                    else {
                        my $ThisAbility =  lc($arg[6]);
                        if ($ThisAbility eq BARBARIAN || $ThisAbility eq WIZARD || $ThisAbility eq PALADIN || $ThisAbility eq ROGUE) {
                            my $Ability;
                            if ($ThisAbility eq BARBARIAN) {
                                $Ability = "Barbarian";
                            }
                            elsif ($ThisAbility eq WIZARD) {
                                $Ability = "Wizard";
                            }
                            elsif ($ThisAbility eq PALADIN) {
                                $Ability = "Paladin";
                            }
                            elsif ($ThisAbility eq ROGUE) {
                                $Ability = "Rogue";
                            }
                            ++$registrations;
                            $lastreg = time();
                            $Simulation::rps{$arg[4]}{next} = $Options::opts{rpbase};
                            $Simulation::rps{$arg[4]}{class} = "@arg[7..$#arg]";
                            $Simulation::rps{$arg[4]}{level} = 0;
                            $Simulation::rps{$arg[4]}{online} = 1;
                            $Simulation::rps{$arg[4]}{nick} = $usernick;
                            $Simulation::rps{$arg[4]}{userhost} = $arg[0];
                            $Simulation::rps{$arg[4]}{created} = time();
                            $Simulation::rps{$arg[4]}{last_login} = time();
                            $Simulation::rps{$arg[4]}{pass} = crypt($arg[5],Database::mksalt());
                            $Simulation::rps{$arg[4]}{pos_x} = int(rand($Options::opts{mapx}));
                            $Simulation::rps{$arg[4]}{pos_y} = int(rand($Options::opts{mapy}));
                            $Simulation::rps{$arg[4]}{alignment}="n";
                            $Simulation::rps{$arg[4]}{admin} = 0;
                            for my $item ("ring","amulet","charm","weapon","helm","tunic","gloves","shield","leggings","boots") {
                                $Simulation::rps{$arg[4]}{item}{$item} = 0;
                            }
                            $Simulation::rps{$arg[4]}{gold} = 500;
                            $Simulation::rps{$arg[4]}{ability} = $ThisAbility;
                            $Simulation::rps{$arg[4]}{life} = 100;
                            for my $pen ("pen_mesg","pen_nick","pen_part","pen_kick","pen_quit","pen_quest","pen_logout") {
                                $Simulation::rps{$arg[4]}{$pen} = 0;
                            }
                            for my $ThisField ("ffight","bwon","blost","badd","bminus","powerpotion","status","gems","upgrade",
                                "rt","dm","cl","pw","aw","lw","alw","tt","bt","regentm","dragontm","mana","lotto11","lotto12","lotto13","lotto21","lotto22","lotto23",
                                "lotto31","lotto32","lotto33","experience","lottowins","lottosumwins","aligntime","Worktime","Towntime","Foresttime",
                                "Special01","Special02","Special03","ExpertItem01","ExpertItem02","ExpertItem03","EndPlayer","EmptyField") {
                                $Simulation::rps{$arg[4]}{$ThisField} = 0;
                            }
                            IRC::chanmsg("Welcome $usernick\'s new $Ability $arg[4], the @arg[7..$#arg]! Next level in ".
                                    Simulation::duration($Options::opts{rpbase}).".");
                            IRC::privmsg("Success! Account $arg[4] created. You have $Options::opts{rpbase} seconds until level 1. ", $usernick);
                        }
                        else {
                            IRC::privmsg("Abilities are as follow: Barbariab=b, Wizard=w, Paladin=p or Rogue=r. ", $usernick);
                        }
                    }
                }
            }
            elsif ($arg[3] eq "delold") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to DELOLD.", $usernick);
                }
                elsif ($arg[4] !~ /^[\d\.]+$/) {
                    IRC::privmsg("Try: DELOLD <# of days>", $usernick, 1);
                }
                else {
                    my @oldaccounts = grep { (time()-$Simulation::rps{$_}{last_login}) > ($arg[4] * 86400) && !$Simulation::rps{$_}{online} } keys(%Simulation::rps);
                    delete(@Simulation::rps{@oldaccounts});
                    IRC::chanmsg(scalar(@oldaccounts)." accounts not accessed in the last $arg[4] days removed by $arg[0].");
                }
            }
            elsif ($arg[3] eq "del") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to DEL.", $usernick);
                }
                elsif (!defined($arg[4])) {
                   IRC::privmsg("Try: DEL <char name>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    delete($Simulation::rps{$arg[4]});
                    IRC::chanmsg("Account $arg[4] removed by $arg[0].");
                }
            }
            elsif ($arg[3] eq "mkadmin") {
                if (!ha($username) || ($Options::opts{owneraddonly} && $Options::opts{owner} ne $username)) {
                    IRC::privmsg("You don't have access to MKADMIN.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: MKADMIN <char name>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{admin}=1;
                    IRC::privmsg("Account $arg[4] is now a bot admin.",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "deladmin") {
                if (!ha($username) || ($Options::opts{ownerdelonly} && $Options::opts{owner} ne $username)) {
                    IRC::privmsg("You don't have access to DELADMIN.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: DELADMIN <char name>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such account $arg[4].", $usernick, 1);
                }
                elsif ($arg[4] eq $Options::opts{owner}) {
                    IRC::privmsg("Cannot DELADMIN owner account.", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{admin}=0;
                    IRC::privmsg("Account $arg[4] is no longer a bot admin.",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "hog") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to HoG.", $usernick);
                }
                else {
                    hog();
                }
            }
            elsif ($arg[3] eq "calamity") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CALAMITY.", $usernick);
                }
                else {
                    IRC::chanmsg("$usernick has summoned Lucifer.");
                    Events::calamity();
                }
            }
            elsif ($arg[3] eq "hunt") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to HUNT.", $usernick);
                }
                else {
                    IRC::chanmsg("$usernick has called a monster hunt.");
                    Events::monst_hunt();
                }
            }
            elsif ($arg[3] eq "monst") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to MONST.", $usernick);
                }
                else {
                    IRC::chanmsg("$usernick has summoned a monster.");
                    Events::monst_attack();
                }
            }
            elsif ($arg[3] eq "lottery") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to Lottery.", $usernick);
                }
                else {
                    IRC::chanmsg("$usernick has started the Lottery.");
                    Events::lottery();
                }
            }
            elsif ($arg[3] eq "top") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to top.", $usernick);
                }
                elsif (!$arg[4] || $arg[4] !~ /^\d+$/o) {
                    IRC::privmsg("Try: TOP <number>", $usernick, 1);
                }
                elsif ($arg[4] && $arg[4] =~ /^\d+$/o) {
                    my @u = sort { $Simulation::rps{$b}{level} <=> $Simulation::rps{$a}{level} || $Simulation::rps{$a}{next} <=> $Simulation::rps{$b}{next} } keys(%Simulation::rps);

                    my $n = $#u + 1;
                       $n = $arg[4] if($arg[4] < $n);

                    IRC::chanmsg("Idle RPG Top $n Players:") if @u;
                    for my $i (0..$arg[4]-1) {
                        last if(!defined $u[$i] || !defined $Simulation::rps{$u[$i]}{level});

                        my $tempsum = Equipment::itemsum($u[$i],0);

                        IRC::chanmsg("#" .($i + 1). " $u[$i]".
                        " | Lvl $Simulation::rps{$u[$i]}{level} | TTL " .(Simulation::duration($Simulation::rps{$u[$i]}{next})).
                        " | Align $Simulation::rps{$u[$i]}{alignment} | Ability $Simulation::rps{$u[$i]}{ability}".
                        " | Life $Simulation::rps{$u[$i]}{life} | Sum $tempsum");
                    }
                }
            }
            elsif ($arg[3] eq "challenge") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHALLENGE.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: CHALLENGE <char name>", $usernick, 1);
                }

                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    PVP::challenge_opp($arg[4]);
                }
            }
            elsif ($arg[3] eq "godsend") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to GODSEND.", $usernick);
                }
                else {
                    Events::godsend();
                }
            }
            elsif ($arg[3] eq "evilness") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to EVILNESS.", $usernick);
                }
                else {
                    Events::evilness();
                    Events::evilnessOffline();
                }
            }
            elsif ($arg[3] eq "goodness") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to GOODNESS.", $usernick);
                }
                else {
                    Events::goodness();
                }
            }
            elsif ($arg[3] eq "item") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to ITEM.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: ITEM <char name>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    Equipment::find_item($arg[4]);
                }
            }
            elsif ($arg[3] eq "rehash") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to REHASH.", $usernick);
                }
                else {
                    readconfig();
                    IRC::privmsg("Reread config file.",$usernick,1);
                    $Options::opts{botchan} =~ s/ .*//;
                }
            }
            elsif ($arg[3] eq "chpass") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHPASS.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: CHPASS <char name> <new pass>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{pass} = crypt($arg[5],Database::mksalt());
                    IRC::privmsg("Password for $arg[4] changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chnick") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHNICK.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: CHNICK USERNAME NICK", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{nick} = $arg[5];
                    IRC::privmsg("NICK for $arg[4] has been changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chhost") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHHOST.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: CHHOST USER NICK!IDENT AT HOST", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{userhost} = $arg[5];
                    IRC::privmsg("USERHOST for $arg[4] has been changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chuser") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHUSER.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: CHUSER <char name> <new char name>",$usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                elsif (exists($Simulation::rps{$arg[5]})) {
                    IRC::privmsg("Username $arg[5] is already taken.", $usernick,1);
                }
                else {
                    $Simulation::rps{$arg[5]} = delete($Simulation::rps{$arg[4]});
                    IRC::privmsg("Username for $arg[4] changed to $arg[5].",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "chclass") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to CHCLASS.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: CHCLASS <char name> <new char class>",$usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $Simulation::rps{$arg[4]}{class} = "@arg[5..$#arg]";
                    IRC::privmsg("Class for $arg[4] changed to @arg[5..$#arg].",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "push") {
                if (!ha($username)) {
                    IRC::privmsg("You don't have access to PUSH.", $usernick);
                }
                elsif ($arg[5] !~ /^\-?\d+$/) {
                    IRC::privmsg("Try: PUSH <char name> <seconds>", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such username $arg[4].", $usernick, 1);
                }
                elsif ($arg[5] > $Simulation::rps{$arg[4]}{next}) {
                    IRC::privmsg("Level time for $arg[4] ($Simulation::rps{$arg[4]}{next}s) is lower than $arg[5]; Resetting to 0.",$usernick, 1);
                    IRC::chanmsg("$usernick has pushed $arg[4] $Simulation::rps{$arg[4]}{next} seconds toward level ".($Simulation::rps{$arg[4]}{level}+1));
                    $Simulation::rps{$arg[4]}{next}=0;
                }
                else {
                    $Simulation::rps{$arg[4]}{next} -= $arg[5];
                     IRC::chanmsg("$usernick has pushed $arg[4] $arg[5] seconds toward level ".($Simulation::rps{$arg[4]}{level}+1).". ".
                        "$arg[4] reaches next level in ".Simulation::duration($Simulation::rps{$arg[4]}{next}).".");
                }
            }
            elsif ($arg[3] eq "fight") {
                if (!defined($username)) {
                    IRC::privmsg("FIGHT Request Denied: You are not logged in.", $usernick);
                }
                elsif ($arg[4] && $arg[4] eq "allow-lower-level") {
                    if (!ha($username)) {
                        IRC::privmsg("FIGHT Request Denied: You don't have access to options.", $usernick, 1);
                    }
                    elsif (!$arg[5] || $arg[5] !~ /^(?:1|0|true|false|on|off|status)$/io) {
                        IRC::privmsg("Try: FIGHT allow-lower-level <on|off|status>", $usernick, 1);
                    }
                    elsif ($arg[5] && $arg[5] =~ /^status$/io) {
                        my $on_off = $Options::opts{fightlowerlevel} ? 'on' : 'off';

                        IRC::privmsg("FIGHT allow-lower-level is $on_off", $usernick, 1);
                    }
                    else {
                        my $on_off = $arg[5] =~ /^(?:1|on|true)$/ ? 1 : 0;

                        $Options::opts{fightlowerlevel} = $on_off;

                        $on_off = $Options::opts{fightlowerlevel} ? 'on' : 'off';

                        IRC::privmsg("FIGHT allow-lower-level is $on_off", $usernick, 1);
                    }
                }
                elsif ($Simulation::rps{$username}{level} < 25) {
                    IRC::privmsg("FIGHT Request Denied: Command available to level 25+ users only.", $usernick, 1);
                }
                elsif (!exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("FIGHT Request Denied: No such account $arg[4].", $usernick, 1);
                }
                elsif ($Simulation::rps{$arg[4]}{online} < 1) {
                    IRC::privmsg("FIGHT Request Denied: Please select an online apponent.", $usernick, 1);
                }
                elsif ($arg[4] eq $username) {
                    IRC::privmsg("FIGHT Request Denied: Cannot FIGHT yourself.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{level} > $Simulation::rps{$arg[4]}{level} && !$Options::opts{fightlowerlevel}) {
                    IRC::privmsg("FIGHT Request Denied: You can only Fight users with the same or higher level than yourself.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{ffight} > 4) {
                    IRC::privmsg("FIGHT Request Denied: You have had your 5 FIGHTS on this level.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{life} < 1) {
                    IRC::privmsg("FIGHT Request Denied: You are either dead or a Zombie.", $usernick, 1);
                }
                else {
                    PVP::BattlePlayers($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "attack") {
                if (!defined($username)) {
                    IRC::privmsg("ATTACK Request Denied: You are not logged in.", $usernick);
                }
                                                                                                        elsif ($Simulation::rps{$username}{level} < 15) {
                    IRC::privmsg("ATTACK Request Denied: Command available to level 15+ users only.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{life} < 10) {
                    IRC::privmsg("ATTACK Request Denied: You need to rest to regain Life.", $usernick, 1);
                }
                elsif (!exists($PVE::monster{$arg[4]})) {
                    IRC::privmsg("ATTACK Request Denied: No such creep.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{regentm} > time()) {
                    my $regentm = $Simulation::rps{$username}{regentm}-time();
                    IRC::privmsg("You are not recovered from your last fight, wait ".Simulation::duration($regentm).".", $usernick, 1);
                }
                else {
                    PVE::monster_fight($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "slay") {
                if (!defined($username)) {
                    IRC::privmsg("SLAY Request Denied: You are not logged in.", $usernick);
                }
                elsif ($Simulation::rps{$username}{level} < 30) {
                    IRC::privmsg("SLAY Request Denied: Command available to level 30+ users only.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{life} < 10) {
                    IRC::privmsg("SLAY Request Denied: You need to rest to regain Life.", $usernick, 1);
                }
                elsif (!exists($PVE::dragon{$arg[4]})) {
                    IRC::privmsg("SLAY Request Denied: No such dragon.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{dragontm} > time()) {
                    my $dragontm = $Simulation::rps{$username}{dragontm}-time();
                    IRC::privmsg("You are not recovered from your last slay, wait ".Simulation::duration($dragontm).".", $usernick, 1);
                }
                else {
                    PVE::dragon_fight($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "rest") {
                Store::rest("$username");
            }

            elsif ($arg[3] eq "buy") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif ($Simulation::rps{$username}{level} < 15) {
                    IRC::privmsg("Shop available to 15+ users only.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Welcome to the shop. To buy any item type /msg $Options::opts{botnick} buy <itemtype> <level>", $usernick);
                }
                elsif ($arg[4] eq "powerpotion") {
                    Store::buy_pots("$username");
                }
                elsif ($arg[4] eq "experience") {
                    Store::buy_experience("$username");
                }
                elsif ($arg[4] eq "upgrade") {
                    Store::buy_upgrade("$username");
                }
                elsif ($arg[4] eq "mana") {
                    Store::buy_mana("$username");
                }
                elsif ($arg[4] eq "life") {
                    Store::rest("$username");    
                }
                elsif (!defined($arg[5])) {
                    if($arg[4] eq "help") {
                        IRC::privmsg("The items are as follows: ring, amulet, charm, weapon, helm, tunic, gloves".
                            ", leggings, shield, boots, life. ", $usernick);
                        IRC::privmsg("To buy any item type /msg $Options::opts{botnick} buy <itemtype> [level]", $usernick);
                        IRC::privmsg("The [level] option is only for items.", $usernick);
                    }
                    elsif($arg[4] eq "prices") {
                        IRC::privmsg("The prices for item are 3 * Level_of_item_you_are_buying.", $usernick);
                    }
                    else {
                        IRC::privmsg("Try /msg $Options::opts{botnick} buy help or /msg $Options::opts{botnick} buy prices.", $usernick);
                    }
                }
                elsif ($arg[5] !~ /\D/) {
                    Store::buy_item("$username", "$arg[4]", "$arg[5]");
                }
                else {
                    IRC::privmsg("You did not type a valid level.", $usernick);
                }
            }
            elsif ($arg[3] eq "get") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: get number gems", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: get number gems", $usernick, 1);
                }
                else {
                    Store::buy_gems("$username", $arg[4]);
                }
            }
            elsif ($arg[3] eq "toss") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: toss NAME_OF_STONE", $usernick, 1);
                }
                else {
                    if ($arg[4] eq $Simulation::rps{$username}{Special01} || $arg[4] eq $Simulation::rps{$username}{Special02}
                        || $arg[4] eq $Simulation::rps{$username}{Special03}) {
                        Equipment::item_special_toss("$username", $arg[4]);
                    }
                    else {
                        IRC::privmsg("You don't have a $arg[4] Stone!", $usernick);
                    }

                }
            }
            ### lotto 1
            elsif ($arg[3] eq "lotto1") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif ($Simulation::rps{$username}{gold} < 500) {
                    IRC::privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    IRC::privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto11} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 1, 1", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto12} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 1, 2", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto13} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 1, 3", $usernick, 1);
                }
                else {
                    $Simulation::rps{$username}{lotto11} = int($arg[4]);
                    $Simulation::rps{$username}{lotto12} = int($arg[5]);
                    $Simulation::rps{$username}{lotto13} = int($arg[6]);
                    $Simulation::rps{$username}{gold} -= 500;
                    IRC::privmsg("Your lotto numbers set 1 are $Simulation::rps{$username}{lotto11}, $Simulation::rps{$username}{lotto12} and $Simulation::rps{$username}{lotto13}.",$usernick);
                }
            }
            ### lotto 2
            elsif ($arg[3] eq "lotto2") {
                if (!defined($username)) {
                IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif ($Simulation::rps{$username}{gold} < 500) {
                    IRC::privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    IRC::privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto21} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 2, 1", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto22} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 2, 2", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto23} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 2, 3", $usernick, 1);
                }
                else {
                    $Simulation::rps{$username}{lotto21} = int($arg[4]);
                    $Simulation::rps{$username}{lotto22} = int($arg[5]);
                    $Simulation::rps{$username}{lotto23} = int($arg[6]);
                    $Simulation::rps{$username}{gold} -= 500;
                    IRC::privmsg("Your lotto numbers set 2 are $Simulation::rps{$username}{lotto21}, $Simulation::rps{$username}{lotto22} and $Simulation::rps{$username}{lotto23}.",$usernick);
                }
            }
            ### lotto 3
            elsif ($arg[3] eq "lotto3") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif ($Simulation::rps{$username}{gold} < 500) {
                    IRC::privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    IRC::privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    IRC::privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    IRC::privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    IRC::privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto31} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 3, 1", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto32} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 3, 2", $usernick, 1);
                }
                elsif ($Simulation::rps{$username}{lotto33} ne "0") {
                    IRC::privmsg("You already have a lotto ticket set 3, 3", $usernick, 1);
                }
                else {
                    $Simulation::rps{$username}{lotto31} = int($arg[4]);
                    $Simulation::rps{$username}{lotto32} = int($arg[5]);
                    $Simulation::rps{$username}{lotto33} = int($arg[6]);
                    $Simulation::rps{$username}{gold} -= 500;
                    IRC::privmsg("Your lotto numbers set 3 are $Simulation::rps{$username}{lotto31}, $Simulation::rps{$username}{lotto32} and $Simulation::rps{$username}{lotto33}.",$usernick);
                }
            }
            elsif ($arg[3] eq "goto") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4]) || $arg[4] eq "" || (lc($arg[4]) ne "work" && lc($arg[4]) ne "town" && lc($arg[4]) ne "forest")) {
                    IRC::privmsg("Try: goto <town|work|forest>", $usernick);
                }
                elsif (lc($arg[4]) eq 'town' && $Simulation::rps{$username}{status} == TOWN) {
                    IRC::privmsg("You are already in the town.", $usernick);
                }
                elsif (lc($arg[4]) eq 'work' && $Simulation::rps{$username}{status} == WORK) {
                    IRC::privmsg("You are already at work.", $usernick);
                }
                elsif (lc($arg[4]) eq 'forest' && $Simulation::rps{$username}{status} == FOREST) {
                    IRC::privmsg("You are already in the forest.", $usernick);
                }
                else {
                    World::change_location($usernick, $username, lc($arg[4]));
                }
            }
            elsif ($arg[3] eq "logout") {
                if (defined($username)) {
                    Level::penalize($username,"logout");
                }
                else {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
            }
            elsif ($arg[3] eq "quest") {
                if ($arg[4] && $arg[4] eq "options") {
                    if (!ha($username)) {
                        IRC::privmsg("You don't have access to options.", $usernick, 1);
                    }
                    elsif (!exists $options{$arg[3]}) {
                        IRC::privmsg("QUEST has no options.", $usernick, 1);
                    }
                    else {
                        foreach my $option (sort keys %{$options{$arg[3]}}) {
                            IRC::privmsg("QUEST $option $Options::opts{$options{$arg[3]}{$option}}", $usernick, 1);
                        }
                    }
                }
                elsif ($arg[4] && exists $options{$arg[3]}{$arg[4]}) {
                    if (!ha($username)) {
                        IRC::privmsg("You don't have access to options.", $usernick, 1);
                    }
                    elsif (!$arg[5] || $arg[5] !~ /^(?:\d+|status)$/io) {
                        IRC::privmsg("Try: QUEST $arg[4] <number|status>", $usernick, 1);
                    }
                    elsif ($arg[5] && $arg[5] =~ /^status$/io) {
                        my $option = $options{$arg[3]}{$arg[4]};

                        IRC::privmsg("QUEST $arg[4] is $Options::opts{$option}", $usernick, 1);
                    }
                    else {
                        my $option = $options{$arg[3]}{$arg[4]};

                        $Options::opts{$option} = $arg[5];

                        IRC::privmsg("QUEST $arg[4] is $Options::opts{$option}", $usernick, 1);
                    }
                }
                elsif ($arg[4] && $arg[4] eq 'now') {
                    if (!ha($username)) {
                        IRC::privmsg("You can't start a quest.", $usernick, 1);
                    }
                    else {
                        $Quests::quest{qtime} = time();
                    }
                }
                elsif (!@{$Quests::quest{questers}}) {
                    IRC::privmsg("There is no active quest.",$usernick);
                }
                elsif ($Quests::quest{type} == 1) {
                    IRC::privmsg(join(", ",(@{$Quests::quest{questers}})[0..$Options::opts{questplayers}-2]).", and ".
                        "$Quests::quest{questers}->[$Options::opts{questplayers}-1] are on a quest to $Quests::quest{text}. Quest to complete in ".
                        Simulation::duration($Quests::quest{qtime}-time()).".",$usernick);
                }
                elsif ($Quests::quest{type} == 2) {
                    IRC::privmsg(join(", ",(@{$Quests::quest{questers}})[0..$Options::opts{questplayers}-2]).", and ".
                        "$Quests::quest{questers}->[$Options::opts{questplayers}-1] are on a quest to $Quests::quest{text}. Participants must first reach ".
                        "[$Quests::quest{p1}->[0],$Quests::quest{p1}->[1]], then [$Quests::quest{p2}->[0],$Quests::quest{p2}->[1]].".
                        ($Options::opts{mapurl}?" See $Options::opts{mapurl} to monitor their journey's progress.":""),$usernick);
                }
            }
            elsif ($arg[3] eq "status") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                elsif ($arg[4] && !exists($Simulation::rps{$arg[4]})) {
                    IRC::privmsg("No such user.",$usernick);
                }
                elsif ($arg[4]) {
                    IRC::privmsg("$arg[4]: Level $Simulation::rps{$arg[4]}{level} ".
                        "$Simulation::rps{$arg[4]}{class}; Status: O".($Simulation::rps{$arg[4]}{online}?"n":"ff")."line; ".
                        "TTL: ".Simulation::duration($Simulation::rps{$arg[4]}{next})."; Idled: ".Simulation::duration($Simulation::rps{$arg[4]}{idled}).
                        "; Item sum: ".Equipment::itemsum($arg[4]),$usernick);
                }
                else {
                    IRC::privmsg("$username: Level $Simulation::rps{$username}{level} ".
                        "$Simulation::rps{$username}{class}; Status: O".($Simulation::rps{$username}{online}?"n":"ff")."line; ".
                        "TTL: ".Simulation::duration($Simulation::rps{$username}{next})."; Idled: ".Simulation::duration($Simulation::rps{$username}{idled})."; ".
                        "Item sum: ".Equipment::itemsum($username),$usernick);
                }
            }
            elsif ($arg[3] eq "whoami") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                else {
                    IRC::privmsg("You are $username, the level ".
                        $Simulation::rps{$username}{level}." $Simulation::rps{$username}{class}. ".
                        "Next level in ".Simulation::duration($Simulation::rps{$username}{next}),$usernick);
                    my $tempsum = Equipment::itemsum($username,0);
                    IRC::privmsg("Items: ring[".($Simulation::rps{$username}{item}{ring})."], ".
                        "amulet[".($Simulation::rps{$username}{item}{amulet})."], ".
                        "charm[".($Simulation::rps{$username}{item}{charm})."], ".
                        "weapon[".($Simulation::rps{$username}{item}{weapon})."], ".
                        "helm[".($Simulation::rps{$username}{item}{helm})."], ".
                        "tunic[".($Simulation::rps{$username}{item}{tunic})."], ".
                        "gloves[".($Simulation::rps{$username}{item}{gloves})."], ".
                        "leggings[".($Simulation::rps{$username}{item}{leggings})."], ".
                        "shield[".($Simulation::rps{$username}{item}{shield})."], ".
                        "boots[".($Simulation::rps{$username}{item}{boots})."] ".
                        "Total sum: $tempsum. ".
                        "| Gold: $Simulation::rps{$username}{gold}. ".
                        "Upgrade level: $Simulation::rps{$username}{upgrade}. ".
                        "Gems: $Simulation::rps{$username}{gems}. ".
                        "Ability: $Simulation::rps{$username}{ability}. ".
                        "XP: $Simulation::rps{$username}{experience}. ".
                        "Life: $Simulation::rps{$username}{life}. ".
                        "Alignment: $Simulation::rps{$username}{alignment}. ", $usernick);
#                        "Potions: power: $Simulation::rps{$username}{powerpotion}. "
                    IRC::privmsg("Lotto 1: $Simulation::rps{$username}{lotto11}, $Simulation::rps{$username}{lotto12} and $Simulation::rps{$username}{lotto13}. ".
                        "Lotto 2: $Simulation::rps{$username}{lotto21}, $Simulation::rps{$username}{lotto22} and $Simulation::rps{$username}{lotto23}. ".
                        "Lotto 3: $Simulation::rps{$username}{lotto31}, $Simulation::rps{$username}{lotto32} and $Simulation::rps{$username}{lotto33}. ".
                        "| Stone 1: $Simulation::rps{$username}{Special01}. ".
                        "Stone 2: $Simulation::rps{$username}{Special02}. ".
                        "Stone 3: $Simulation::rps{$username}{Special03}. ".
                        "| Expert 1: $Simulation::rps{$username}{ExpertItem01}. ".
                        "Expert 2: $Simulation::rps{$username}{ExpertItem02}. ".
                        "Expert 3: $Simulation::rps{$username}{ExpertItem03}.", $usernick);
                    my $NextCreep = $Simulation::rps{$username}{regentm} - time();
                    if ($NextCreep > 0) {
                        $NextCreep = Simulation::duration($NextCreep);
                    }
                    else {
                        $NextCreep = "0 days, 0:00:00";
                    }
                    my $NextDragon = $Simulation::rps{$username}{dragontm} - time();
                    if ($NextDragon > 0) {
                        $NextDragon = Simulation::duration($NextDragon);
                    }
                    else {
                        $NextDragon = "0 days, 0:00:00";
                    }
                    my $TournyRec = $Simulation::rps{$username}{tt} - time();
                    if ($TournyRec > 0) {
                        $TournyRec = Simulation::duration($TournyRec);
                    }
                    else {
                        $TournyRec = "0 days, 0:00:00";
                    }
                    my $BattleRec = $Simulation::rps{$username}{bt} - time();
                    if ($BattleRec > 0) {
                        $BattleRec = Simulation::duration($BattleRec);
                    }
                    else {
                        $BattleRec = "0 days, 0:00:00";
                    }
                    IRC::privmsg("Next Creep Attack: $NextCreep. Next Dragon Slay: $NextDragon. ".
                        "Tournament Recover: $TournyRec. Battle Recover: $BattleRec.", $usernick);
                }
            }
            elsif ($arg[3] eq "newpass") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick)
                }
                elsif (!defined($arg[4])) {
                    IRC::privmsg("Try: NEWPASS <new password>", $usernick);
                }
                else {
                    $Simulation::rps{$username}{pass} = crypt($arg[4],Database::mksalt());
                    IRC::privmsg("Your password was changed.",$usernick);
                }
            }
            elsif ($arg[3] eq "backup") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to BACKUP.", $usernick);
                }
                else {
                    backup();
                    IRC::privmsg("$Options::opts{dbfile} was backed up.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "align") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick)
                }
                elsif (!defined($arg[4]) || (lc($arg[4]) ne "good" && lc($arg[4]) ne "neutral" && lc($arg[4]) ne "evil")) {
                    IRC::privmsg("Try: ALIGN <good|neutral|evil>", $usernick);
                }
                elsif (($arg[4] eq 'neutral') && ($Simulation::rps{$username}{alignment} eq "n")) {
                    IRC::privmsg("You are already neutral.", $usernick);
                }
                elsif (($arg[4] eq 'evil') && ($Simulation::rps{$username}{alignment} eq "e")) {
                    IRC::privmsg("You are already evil.", $usernick);
                }
                elsif (($arg[4] eq 'good') && ($Simulation::rps{$username}{alignment} eq "g")) {
                    IRC::privmsg("You are already good", $usernick);
                }
                elsif ($Simulation::rps{$username}{aligntime} > time()) {
                    my $aligntime = $Simulation::rps{$username}{aligntime}-time();
                    IRC::privmsg("To change alignment again, please wait ".Simulation::duration($aligntime).".", $usernick, 1);
                }
                else {
                    for my $ALWtourney (@Tournaments::alignwar) {
                      if ($ALWtourney eq $username) {
                         IRC::chanmsg("$username changed alignment during the Alignment Battle! Their TTL is doubled.");
                         my $ThisTTL = $Simulation::rps{$username}{next} * 2;
                         $Simulation::rps{$username}{next} = $ThisTTL;
                       }
                    }
                    $Simulation::rps{$username}{alignment} = substr(lc($arg[4]),0,1);
                    $Simulation::rps{$username}{aligntime} = 86400+time();
                    IRC::chanmsg("$username has changed alignment to: ".lc($arg[4]).".");
                }
            }
            elsif ($arg[3] eq "blackbuy") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                if (!defined($arg[4])) {
                    IRC::privmsg("blackbuy what?", $usernick);
                }
                else {
                    if ($arg[4] eq "scroll") {
                        Store::blackbuy_scroll("$username", "$arg[4]");
                    }
                    else {
                        if (!defined($arg[5])) {
                            IRC::privmsg("blackbuy $arg[4] how many times?", $usernick);
                        }
                        elsif ($arg[5] < 1) {
                            IRC::privmsg("blackbuy $arg[4] how many times (greater than 0)?", $usernick);
                        }
                        else {
                            Store::blackbuy_item("$username", "$arg[4]", "$arg[5]");
                        }
                    }
                }
            }
            elsif ($arg[3] eq "xpget") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick);
                }
                else {
                    if (!defined($arg[4])) {
                        IRC::privmsg("xpget what?", $usernick);
                    }
                    elsif ($arg[4] eq "scroll") {
                        Store::xpget_scroll("$username", "scroll");
                    }
                    else {
                        if (!defined($arg[5])) {
                            IRC::privmsg("You must specify an amount (i.e. xpget $arg[4] 20).", $usernick);
                        }
                        else {
                            Store::xpget_item("$username", "$arg[4]", "$arg[5]");
                        }
                    }
                }
            }
            elsif ($arg[3] eq "removeme") {
                if (!defined($username)) {
                    IRC::privmsg("You are not logged in.", $usernick)
                }
                else {
                    IRC::chanmsg("$arg[0] removed their account, $username, the $Simulation::rps{$username}{class}.");
                    delete($Simulation::rps{$username});
                }
            }
            elsif ($arg[3] eq "help") {
                if (!ha($username)) {
                    IRC::privmsg("For information on IRPG bot commands, see $Options::opts{helpurl}", $usernick);
                }
                else {
                    IRC::privmsg("Help URL is $Options::opts{helpurl}", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "die") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to DIE.", $usernick);
                }
                else {
                    $Options::opts{reconnect} = 0;
                    Database::writejsondb(\%Simulation::rps);
                    IRC::sts("QUIT :DIE from $arg[0]",1);
                }
            }
            elsif ($arg[3] eq "reloaddb") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to RELOADDB.", $usernick);
                }
                elsif (!$Simulation::pausemode) {
                    IRC::privmsg("ERROR: Can only use LOADDB while in PAUSE mode.",$usernick, 1);
                }
                else {
                    Database::loadjsondb();
                    IRC::privmsg("Reread player database file; ".scalar(keys(%Simulation::rps))." accounts loaded.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "pause") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to PAUSE.", $usernick);
                }
                else {
                    $Simulation::pausemode = $Simulation::pausemode ? 0 : 1;
                    IRC::privmsg("PAUSE_MODE set to $Simulation::pausemode.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "restart") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to RESTART.", $usernick);
                }
                else {
                    Database::writejsondb(\%Simulation::rps);
                    IRC::sts("QUIT :RESTART from $arg[0]",1);
                    close($IRC::sock);
                    exec("perl $0");
                }
            }
            elsif ($arg[3] eq "clearq") {
                if (!ha($username)) {
                    IRC::privmsg("You do not have access to CLEARQ.", $usernick);
                }
                else {
                    undef(@queue);
                    IRC::chanmsg("Outgoing message queue cleared by $arg[0].");
                }
            }
            elsif ($arg[3] eq "stats") {
                my $statstown;
                my $statswork;
                my $statsforest;
                my $Barbarian;
                my $Wizard;
                my $Paladin;
                my $Rogue;
                    $statstown = scalar(grep { $Simulation::rps{$_}{status} == TOWN && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $statswork = scalar(grep { $Simulation::rps{$_}{status} == WORK && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $statsforest = scalar(grep { $Simulation::rps{$_}{status} == FOREST && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $Barbarian = scalar(grep { $Simulation::rps{$_}{ability} eq BARBARIAN && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $Wizard = scalar(grep { $Simulation::rps{$_}{ability} eq WIZARD && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $Paladin = scalar(grep { $Simulation::rps{$_}{ability} eq PALADIN && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                    $Rogue = scalar(grep { $Simulation::rps{$_}{ability} eq ROGUE && $Simulation::rps{$_}{online} } keys %Simulation::rps);
                IRC::privmsg("Online players : there are $statstown players in town, $statswork at work and ".
                    "$statsforest in the forest. We have $Barbarian Barbarians, $Wizard Wizards, $Paladin Paladins ".
                    "and $Rogue Rogues.", $usernick);
            }
            elsif ($arg[3] eq "info") {
                my $info;
                if (!ha($username) && $Options::opts{allowuserinfo}) {

                    $info = "IdleRPG for Slack $main::version by dhyrule, based on IdleRPG by raz.".  

                    "On via server: ".$Options::opts{servers}->[0].". Admins online: ".
                    join(", ", map { $Simulation::rps{$_}{nick} }
                        grep { $Simulation::rps{$_}{admin} && $Simulation::rps{$_}{online} } keys(%Simulation::rps)).".";
                    IRC::privmsg($info, $usernick);
                }
                elsif (!ha($username) && !$Options::opts{allowuserinfo}) {
                    IRC::privmsg("You do not have access to INFO.", $usernick);
                }
                else {
                    my $queuedbytes = 0;
                    $queuedbytes += (length($_)+2) for @queue; # +2 = \r\n
                    $info = sprintf(
                        "%.2fkb sent, %.2fkb received in %s. %d IRPG users ".
                        "online of %d total users. %d accounts created since ".
                        "startup. PAUSE_MODE is %d, SILENT_MODE is %d. ".
                        "Outgoing queue is %d bytes in %d items. On via: %s. ".
                        "Admins online: %s.",
                        $outbytes/1024,
                        $inbytes/1024,
                        Simulation::duration(time()-$^T),
                        scalar(grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps)),
                        scalar(keys(%Simulation::rps)),
                        $registrations,
                        $Simulation::pausemode,
                        $queuedbytes,
                        scalar(@queue),
                        $Options::opts{servers}->[0],
                        join(", ",map { $Simulation::rps{$_}{nick} }
                          grep { $Simulation::rps{$_}{admin} && $Simulation::rps{$_}{online} }
                          keys(%Simulation::rps)));
                    IRC::privmsg($info, $usernick, 1);
                }
            }
            elsif ($arg[3] eq "login") {
                if (!defined($username)) {
                    if ($#arg < 5 || $arg[5] eq "") {
                        IRC::notice("Try: LOGIN <username> <password>", $usernick);
                    }
                    elsif (!exists $Simulation::rps{$arg[4]}) {
                        IRC::notice("Sorry, no such account name. Account names are case sensitive.",$usernick);
                    }
                    elsif (!exists $onchan{$usernick}) {
                        IRC::notice("Sorry, you're not in $Options::opts{botchan}.",$usernick);
                    }
                    elsif ($Simulation::rps{$arg[4]}{pass} ne crypt($arg[5],$Simulation::rps{$arg[4]}{pass})) {
                        IRC::notice("Wrong password.", $usernick);
                    }
                    else {
                        $Simulation::rps{$arg[4]}{online} = 1;
                        $Simulation::rps{$arg[4]}{nick} = $usernick;
                        $Simulation::rps{$arg[4]}{userhost} = $arg[0];
                        $Simulation::rps{$arg[4]}{last_login} = time();
                        IRC::chanmsg("$arg[4], the level $Simulation::rps{$arg[4]}{level} $Simulation::rps{$arg[4]}{class}, is now online from ".
                            "nickname $usernick. Next level in ".Simulation::duration($Simulation::rps{$arg[4]}{next}).".");
                    }
                }
            }
        }
    }
}

sub finduser {
    my $nick = shift;
    return undef if !defined($nick);
    for my $user (keys(%Simulation::rps)) {
        next unless $Simulation::rps{$user}{online};
        if ($Simulation::rps{$user}{nick} eq $nick) { return $user; }
    }
    return undef;
}

sub ha {
    my $user = shift;
    if (!defined($user)) {
        return 0;
    }
    if (!exists($Simulation::rps{$user})) {
        return 0;
    }
    return $Simulation::rps{$user}{admin};
}

1;
