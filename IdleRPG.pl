#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket;
use IO::Select;
use Data::Dumper;
use Getopt::Long;
use Tie::SubstrHash;
use File::Slurp;
use Encode;
use JSON;

my $version = "6.4";
my $SlayTime = 43200;
my %opts = (
             help            => 0,
             verbose         => 0,
             debug           => 0,
             debugfile       => 'dbg.txt',
             pidfile         => '.irpg.pid',
             conffile        => '.irpg.conf',
             dbfile          => 'irpg.db',
             modsfile        => 'modifiers.txt',
             ipv6            => 0,
             localaddr       => '127.0.0.1',
             servers         => [],
             botnick         => 'Idlerpgbot',
             botuser         => 'idlerpgbot',
             botrlnm         => 'idlerpgbot',
             botchan         => '#idlerpg',
             botident        => 'idlerpg',
             botmodes        => '+i',
             botopcmd        => '',
             botghostcmd     => '',
             helpurl         => 'http://idlerpg/help.php',
             mapurl          => 'http://idlerpg/quests.php',
             doban           => 0,
             okurl           => [],
             silentmode      => 0,
             writequestfile  => 0,
             questfilename   => 'questinfo.txt',
             questplayers    => 8,
             questminlevel   => 40,
             voiceonlogin    => 0,
             noccodes        => 0,
             nononp          => 0,
             statuscmd       => 0,
             reconnect       => 0,
             reconnect_wait  => 30,
             self_clocks     => 2,
             casematters     => 0,
             detectsplits    => 0,
             splitwait       => 600,
             allowuserinfo   => 0,
             noscale         => 0,
             owner           => '',
             owneraddonly    => 0,
             ownerdelonly    => 0,
             ownerpevalonly  => 0,
             peval           => 0,
             senduserlist    => 0,
             limitpen        => 0,
             mapx            => 700,
             mapy            => 700,
             modesperline    => 12,
             eventsfile      => 'events.txt',
             monstfile       => 'monsters.txt',
             rpbase          => 600,
             rpstep          => 1.16,
             rppenstep       => 1.14,
             tournylvl       => 16,
             fightlowerlevel => 0,
           );

readconfig();

GetOptions(\%opts,
    "help|h",
    "verbose|v",
    "debug",
    "debugfile=s",
    "pidfile=s",
    "conffile=s",
    "dbfile|irpgdb|db|d=s",
    "modsfile=s",
    "ipv6",
    "localaddr=s",
    "servers|s=s@",
    "botnick|n=s",
    "botuser|u=s",
    "botrlnm|r=s",
    "botchan|c=s",
    "botident|p=s",
    "botmodes|m=s",
    "botopcmd|o=s",
    "botghostcmd|g=s",
    "helpurl=s",
    "mapurl=s",
    "doban",
    "okurl|k=s@",
    "silentmode=i",
    "writequestfile",
    "questfilename=s",
    "questplayers=i",
    "questminlevel=i",
    "voiceonlogin",
    "noccodes",
    "nononp",
    "statuscmd",
    "reconnect",
    "reconnect_wait=i",
    "self_clock=i",
    "casematters",
    "detectsplits",
    "splitwait=i",
    "allowuserinfo",
    "noscale",
    "owner=s",
    "owneraddonly",
    "ownerdelonly",
    "ownerpevalonly",
    "peval",
    "senduserlist",
    "limitpen=i",
    "mapx=i",
    "mapy=i",
    "modesperline=i",
    "eventsfile=s",
    "monstfile=s",
    "rpbase=i",
    "rpstep=f",
    "rppenstep=f",
    "tournylvl=i",
    "fightlowerlevel",
);

sub help {
    print "Usage: perl $0 [OPTIONS]\n\n";
    print "Options:\n";
    print "--help, -h                   Display this usage information\n";
    print "--verbose, -v                Print debug output to log file\n";
    print "--debug                      Print debug output to log file\n";
    print "--debugfile <PATH>           Path to debug log file\n";
    print "--pidfile <PATH>             Path to PID file for bot process\n";
    print "--conffile <PATH>            Path to bot configuration file\n";
    print "--dbfile, --irpgdb <PATH>    Path to database file\n";
    print "--db, -d <PATH>              Path to database file\n",
    print "--eventsfile <PATH>          Path to events file\n";
    print "--monstfile <PATH>           Path to monsters file\n";
    print "--writequestfile             Enable writing to the quest file\n";
    print "--questfilename <PATH>       Path to quest file\n";
    print "--questplayers <NUMBER>      Minimum players required for quests\n";
    print "--questminlevel <NUMBER>     Minimum level required for quests\n";
    print "--modsfile <PATH>            Path to moderator log file of channel messages\n";
    print "--casematters                Enable case sensitive character names\n";
    print "--ipv6                       Enable IPv6 support\n";
    print "--localaddr <ADDRESS>        Use specified source IP address\n";
    print "--servers, -s <ADDRESS>...   IRC server address(es) to connect to\n";
    print "--botnick, -n <NICKNAME>     Nickname for bot\n";
    print "--botuser, -u <USERNAME>     Username for bot\n";
    print "--botrlnm, -r <REAL NAME>    Realname for bot\n";
    print "--botchan, -c <CHANNEL>      Channel for bot\n";
    print "--botident, -p <IDENT>       Ident for bot\n";
    print "--botmodes, -m <MODES>       Modes for bot\n";
    print "--botopcmd, -o <COMMAND>     Operator command for bot\n";
    print "--botghostcmd, -g <STRING>   Ghost command for bot\n";
    print "--helpurl <URL>              URL to bot help page\n";
    print "--mapurl <URL>               URL to quest map\n";
    print "--doban                      Ban users for posting links\n";
    print "--okurl, -k <URL>,[URL]      Don't ban users for posting these links\n";
    print "--noccodes                   Forbid control codes in character names and classes\n";
    print "--nononp                     Forbid non-printable chars in character names and classes\n";
    print "--statuscmd                  Enable the status command\n";
    print "--reconnect                  Enable automatic reconnection\n";
    print "--reconnect_wait <SECONDS>   Seconds to wait before reconnecting\n";
    print "--self_clock <CYCLES>        Number of play cycles\n";
    print "--detectsplits               Enable net split detection\n";
    print "--splitwait <SECONDS>        Time to wait for hosts after split\n";
    print "--silentmode <1|2|3>         Select silent mode\n";
    print "--voiceonlogin               Set voice mode for auto login users\n";
    print "--modesperline <LIMIT>       Maximum number of modes per line\n";
    print "--noscale                    Don't scale event chances to number of online players\n";
    print "--owner <USERNAME>           Username for bot owner\n";
    print "--owneraddonly               Allow mkadmin command for bot owner only\n";
    print "--ownerdelonly               Allow deladmin command for bot owner only\n";
    print "--ownerpevalonly             Allow peval command for bot owner only\n";
    print "--peval                      Enable peval command for bot\n";
    print "--allowuserinfo              Allow info command for normal (non-admin) users\n";
    print "--senduserlist               Display the user list for auto login instead of summary\n";
    print "--limitpen <PENALTY>         Enable and set maximum penalty\n";
    print "--mapx <SIZE>                Map width\n";
    print "--mapy <SIZE>                Map height\n";
    print "--rpbase <INTEGER>           TTL calulation base size\n";
    print "--rpstep <FLOAT>             TTL calulation step size\n";
    print "--rppenstep <FLOAT>          TTL caluatlion step size for penalties\n";
    print "--tournylvl <PLAYERS>        Minimum number of player for tournaments\n";
    print "--fightlowerlevel            Allow fights against lower level players\n";
}

$opts{help} and do { help(); exit 0; };

my $TournyLvl = $opts{tournylvl};
my $outbytes = 0;
my $primnick = $opts{botnick};
my $inbytes = 0;
my %onchan;
my %rps;
my %quest = (
    questers => [],
    p1       => [],
    p2       => [],
    qtime    => time() + int(rand(7200)),
    text     => "",
    type     => 1,
    stage    => 1,
);
my $rpreport = 0;
my $oldrpreport = 0;
my %prev_online;
my %auto_login;
my @bans;
my $pausemode = 0;
my $silentmode = $opts{silentmode} ? $opts{silentmode} : 0;
my @queue;
my $lastreg = 0;
my $registrations = 0;
my $sel;
my $lasttime = 1;
my $buffer;
my $conn_tries = 0;
my $sock;
my %split;
my $freemessages = 4;
my %monster;
my %dragon;

my %options = (
    quest => {
               'players'   => 'questplayers',
               'min-level' => 'questminlevel',
             },
);

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
#### Monsters ####

###$monster{"XXX"}{gain} = 5;
###$monster{"XXX"}{regen} = 2;
###$monster{"XXX"}{goldm} -> $monster{"XXX"}{gold}

$monster{"Roach"}{sum} = 500;
$monster{"Roach"}{gold} = 0;
$monster{"Roach"}{gem} = 1;
$monster{"Spider"}{sum} = 1000;
$monster{"Spider"}{gold} = 250;
$monster{"Spider"}{gem} = 0;
$monster{"Bat"}{sum} = 2000;
$monster{"Bat"}{gold} = 0;
$monster{"Bat"}{gem} = 2;
$monster{"Wolf"}{sum} = 3000;
$monster{"Wolf"}{gold} = 400;
$monster{"Wolf"}{gem} = 0;
$monster{"Goblin"}{sum} = 4000;
$monster{"Goblin"}{gold} = 0;
$monster{"Goblin"}{gem} = 3;
$monster{"Shadow"}{sum} = 5000;
$monster{"Shadow"}{gold} = 500;
$monster{"Shadow"}{gem} = 0;
$monster{"Lich"}{sum} = 6000;
$monster{"Lich"}{gold} = 0;
$monster{"Lich"}{gem} = 4;
$monster{"Skeleton"}{sum} = 7000;
$monster{"Skeleton"}{gold} = 700;
$monster{"Skeleton"}{gem} = 0;
$monster{"Ghost"}{sum} = 8000;
$monster{"Ghost"}{gold} = 0;
$monster{"Ghost"}{gem} = 5;
$monster{"Phantom"}{sum} = 9000;
$monster{"Phantom"}{gold} = 800;
$monster{"Phantom"}{gem} = 0;
$monster{"Troll"}{sum} = 10000;
$monster{"Troll"}{gold} = 0;
$monster{"Troll"}{gem} = 6;
$monster{"Cyclop"}{sum} = 12000;
$monster{"Cyclop"}{gold} = 1000;
$monster{"Cyclop"}{gem} = 0;
$monster{"Mutant"}{sum} = 14000;
$monster{"Mutant"}{gold} = 0;
$monster{"Mutant"}{gem} = 8;
$monster{"Ogre"}{sum} = 17000;
$monster{"Ogre"}{gold} = 1400;
$monster{"Ogre"}{gem} = 0;
$monster{"Phoenix"}{sum} = 21000;
$monster{"Phoenix"}{gold} = 0;
$monster{"Phoenix"}{gem} = 10;
$monster{"Demon"}{sum} = 25000;
$monster{"Demon"}{gold} = 1700;
$monster{"Demon"}{gem} = 0;
$monster{"Centaur"}{sum} = 30000;
$monster{"Centaur"}{gold} = 0;
$monster{"Centaur"}{gem} = 12;
$monster{"Werewolf"}{sum} = 35000;
$monster{"Werewolf"}{gold} = 2000;
$monster{"Werewolf"}{gem} = 0;
$monster{"Giant"}{sum} = 40000;
$monster{"Giant"}{gold} = 0;
$monster{"Giant"}{gem} = 15;
###### END MONSTERS #############
#### Dragons ####

###$dragon{"XXX"}{level}
###$dragon{"XXX"}{gain} = 5;
###$dragon{"XXX"}{regen} = 2;
###$dragon{"XXX"}{goldm}

$dragon{"Blue_Dragon"}{item} = 2;
$dragon{"Blue_Dragon"}{sum} = 5000;
$dragon{"Blue_Dragon"}{gold} = 800;
$dragon{"Blue_Dragon"}{gem} = 3;
$dragon{"Yellow_Dragon"}{item} = 3;
$dragon{"Yellow_Dragon"}{sum} = 7500;
$dragon{"Yellow_Dragon"}{gold} = 1200;
$dragon{"Yellow_Dragon"}{gem} = 5;
$dragon{"Green_Dragon"}{item} = 3;
$dragon{"Green_Dragon"}{sum} = 15000;
$dragon{"Green_Dragon"}{gold} = 2000;
$dragon{"Green_Dragon"}{gem} = 10;
$dragon{"Red_Dragon"}{item} = 4;
$dragon{"Red_Dragon"}{sum} = 25000;
$dragon{"Red_Dragon"}{gold} = 3000;
$dragon{"Red_Dragon"}{gem} = 15;
$dragon{"Black_Dragon"}{item} = 4;
$dragon{"Black_Dragon"}{sum} = 35000;
$dragon{"Black_Dragon"}{gold} = 4000;
$dragon{"Black_Dragon"}{gem} = 20;
$dragon{"White_Dragon"}{item} = 5;
$dragon{"White_Dragon"}{sum} = 40000;
$dragon{"White_Dragon"}{gold} = 5000;
$dragon{"White_Dragon"}{gem} = 25;
$dragon{"Bronze_Dragon"}{item} = 6;
$dragon{"Bronze_Dragon"}{sum} = 50000; #add 10k on fight roll
$dragon{"Bronze_Dragon"}{gold} = 7500;
$dragon{"Bronze_Dragon"}{gem} = 30;
$dragon{"Silver_Dragon"}{item} = 8;
$dragon{"Silver_Dragon"}{sum} = 60000; #add 20k on fight roll
$dragon{"Silver_Dragon"}{gold} = 10000;
$dragon{"Silver_Dragon"}{gem} = 45;
$dragon{"Gold_Dragon"}{item} = 10;
$dragon{"Gold_Dragon"}{sum} = 60000; #add 40k on fight roll
$dragon{"Gold_Dragon"}{gold} = 15000;
$dragon{"Gold_Dragon"}{gem} = 60;
$dragon{"Platinum_Dragon"}{item} = 12;
$dragon{"Platinum_Dragon"}{sum} = 90000; #add 60k on fight roll
$dragon{"Platinum_Dragon"}{gold} = 20000;
$dragon{"Platinum_Dragon"}{gem} = 75;
###### END DRAGONS #############
my @tournament;
my $round;
my $battle;
my $tournamenttime = time() + 5400;
my @deathmatch;
my $sess; # DM round
my $scuff; # DM battle
my $deathmatchtime = time() + 14400;
my @megawar;
my $runda; # MW round
my $lupta; # MW battle
my $megawartime = time() + 10800;
my @powerwar;
my $play; # PW round
my $game; # PW battle
my $powerwartime = time() + 36000;
my @abilitywar;
my $playAW; # AW round
my $gameAW; # AW battle
my $abilitywartime = time() + 5400 + int(rand(3600));
my @locationwar;
my $playLW; # LW round
my $gameLW; # LW battle
my $locationwartime = time() + 5400 + int(rand(3600));
my @alignwar;
my $playALW; # ALW round
my $gameALW; # ALW battle
my $alignwartime = time() + 5400 + int(rand(3600));
my @ENDtournament; # players chosen for the ENDtournament
my $ENDround; # ENDtournament round
my $ENDbattle; # ENDtournament battle
my $ENDtournamenttime = time() + 40; # time to next tourney
my $EndTourny = 0;
my $IsEnding = 0;
my $IsWinner = 0;
my $EndPlayerAmt = 0;

my $selfrestarttime = time() + 43000;
sub daemonize();

if (! -e $opts{dbfile}) {
    $|=1;
    %rps = ();
    print "$opts{dbfile} does not exist enter account name for admin access [$opts{owner}]: ";
    chomp(my $uname = <STDIN>);
    $uname =~ s/\s.*//g;
    $uname = length($uname)?$uname:$opts{owner};
    print "Enter an ability (b,w,p,r): ";
    chomp(my $uability = <STDIN>);
    $rps{$uname}{ability} = $uability;
    print "Enter a character desc.: ";
    chomp(my $uclass = <STDIN>);
    $rps{$uname}{class} = substr($uclass,0,30);
    print "Enter a password: ";
    if ($^O ne "MSWin32") {
        system("stty -echo");
    }
    chomp(my $upass = <STDIN>);
    if ($^O ne "MSWin32") {
        system("stty echo");
    }
    $rps{$uname}{pass} = crypt($upass,mksalt());
    $rps{$uname}{admin} = 1;
    $rps{$uname}{next} = $opts{rpbase};
    $rps{$uname}{nick} = "";
    $rps{$uname}{userhost} = "";
    $rps{$uname}{level} = 0;
    $rps{$uname}{online} = 0;
    $rps{$uname}{idled} = 0;
    $rps{$uname}{created} = time();
    $rps{$uname}{last_login} = time();
    $rps{$uname}{pos_x} = int(rand($opts{mapx}));
    $rps{$uname}{pos_y} = int(rand($opts{mapy}));
    $rps{$uname}{alignment} = "n";
    $rps{$uname}{gold} = 500;
    $rps{$uname}{life} = 100;
    for my $item ("ring","amulet","charm","weapon","helm","tunic","gloves","shield","leggings","boots") {
        $rps{$uname}{item}{$item} = 0;
    }
    for my $pen ("pen_mesg","pen_nick","pen_part","pen_kick","pen_quit","pen_quest","pen_logout","pen_logout") {
        $rps{$uname}{$pen} = 0;
    }
    for my $ThisField ("scrolls","ffight","bwon","blost","badd","bminus","powerpotion","status","gems","upgrade",
        "rt","dm","cl","pw","aw","lw","alw","tt","bt","regentm","dragontm","mana","lotto11","lotto12","lotto13","lotto21","lotto22","lotto23",
        "lotto31","lotto32","lotto33","experience","lottowins","lottosumwins","aligntime","Worktime","Towntime","Foresttime",
        "Special01","Special02","Special03","ExpertItem01","ExpertItem02","ExpertItem03","EndPlayer","EmptyField") {
        $rps{$uname}{$ThisField} = 0;
    }
    writedb();
    print "OK, wrote you into $opts{dbfile}.\n";
}

daemonize();
$SIG{HUP} = "readconfig";
CONNECT:
loaddb();



while (!$sock && $conn_tries < 2*@{$opts{servers}}) {
    debug("Connecting to: $opts{servers}->[0]\r\n");
    my %sockinfo = (PeerAddr => $opts{servers}->[0]);
    if ($opts{localaddr}) {
        $sockinfo{LocalAddr} = $opts{localaddr};
    }
    if ($opts{ipv6}) {
        $sock = IO::Socket::INET6->new(%sockinfo)
    }
    else {
        $sock = IO::Socket::INET->new(%sockinfo)
    }

    ++$conn_tries;
	
    if (!$sock) {
        debug("Socket closed; Moving server to end of list\r\n");
        push(@{$opts{servers}},shift(@{$opts{servers}}));
    }
}

if (!$sock) {
    debug("Failed to connect to all servers\r\n");
    exit 1;
}

$conn_tries=0;
$sel = IO::Select->new($sock);
sts("PASS jesusdiedforour.HasHeDValUe");
sts("NICK $opts{botnick}");
sts("USER $opts{botuser} 0 0 :$opts{botrlnm}");

while (1) {
    my($readable) = IO::Select->select($sel,undef,undef,0.5);
    if (defined($readable)) {
        my $fh = $readable->[0];
        my $buffer2;
        $fh->recv($buffer2,512,0);
        if (length($buffer2)) {
            $buffer .= $buffer2;
            while (index($buffer,"\n") != -1) {
                my $line = substr($buffer,0,index($buffer,"\n")+1);
                $buffer = substr($buffer,length($line));
                parse($line);
            }
        }
        else {
            $rps{$_}{online}=1 for keys(%auto_login);
            writedb();

            close($fh);
            $sel->remove($fh);

            if ($opts{reconnect}) {
                undef(@queue);
                undef($sock);
                debug("Socket closed; Cleared queue. Waiting $opts{reconnect_wait}s to connect.");
                sleep($opts{reconnect_wait});
                goto CONNECT;
            }
            else { debug("Socket closed; disconnected.",1); }
        }
    }
    else { select(undef,undef,undef,1); }
    if ((time()-$lasttime) >= $opts{self_clock}) { rpcheck(); }
}

sub parse {
    my($in) = shift;
    $inbytes += length($in);
    $in =~ s/[\r\n]//g;
    debug("parse(): $in\r\n");
    my @arg = split(/\s/,$in);
    my $usernick = substr((split(/!/,$arg[0]))[0],1);
    my $username = finduser($usernick);
    if (lc($arg[0]) eq 'ping') { sts("PONG $arg[1]",1); }
    elsif (lc($arg[0]) eq 'error') {
        $rps{$_}{online}=1 for keys(%auto_login);
        writedb();
        return;
    }
    $arg[1] = lc($arg[1]);
    if ($arg[1] eq '433' && $opts{botnick} eq $arg[3]) {
        $opts{botnick} .= int(rand(999));
        sts("NICK $opts{botnick}");
    }
    elsif ($arg[1] eq 'join') {
        $onchan{$usernick}=time();
        if ($opts{'detectsplits'} && exists($split{substr($arg[0],1)})) {
            delete($split{substr($arg[0],1)});
        }
        elsif ($opts{botnick} eq $usernick) {
            sts("WHO $opts{botchan}");
            (my $opcmd = $opts{botopcmd}) =~ s/%botnick%/$opts{botnick}/eg;
            sts($opcmd);
            $lasttime = time();
        }
    }
    elsif ($arg[1] eq 'quit') {
        if ($usernick eq $primnick) { sts("NICK $primnick",1); }
        elsif ($opts{'detectsplits'} && "@arg[2..$#arg]" =~ /^:\S+\.\S+ \S+\.\S+$/) {
            if (defined($username)) {
                $split{substr($arg[0],1)}{time}=time();
                $split{substr($arg[0],1)}{account}=$username;
            }
        }
        else {
            penalize($username,"quit");
        }
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'nick') {
        if ($usernick eq $opts{botnick}) {
            $opts{botnick} = substr($arg[2],1);
        }
        elsif ($usernick eq $primnick) { sts("NICK $primnick",1); }
        else {
            penalize($username,"nick",$arg[2]);
            $onchan{substr($arg[2],1)} = delete($onchan{$usernick});
        }
    }
    elsif ($arg[1] eq 'part') {
        penalize($username,"part");
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'kick') {
        $usernick = $arg[3];
        penalize(finduser($usernick),"kick");
        delete($onchan{$usernick});
    }
    elsif ($arg[1] eq 'notice' && $arg[2] ne $opts{botnick}) {
        penalize($username,"notice",length("@arg[3..$#arg]")-1);
    }
    elsif ($arg[1] eq 'privmsg' && $arg[2] eq $opts{botchan}) {
        penalize($username,"privmsg",length("@arg[3..$#arg]")-1);
    }
    elsif ($arg[1] eq '001') {
        sts($opts{botident});
        sts("MODE $opts{botnick} :$opts{botmodes}");
        sts("JOIN $opts{botchan}");
        $opts{botchan} =~ s/ .*//;
    }
    elsif ($arg[1] eq '315') {
        if (keys(%auto_login)) {
            if (length("%auto_login") < 1024 && $opts{senduserlist}) {
                chanmsg(scalar(keys(%auto_login))." users matching ".
                    scalar(keys(%prev_online))." hosts automatically logged in; accounts: ".join(", ",keys(%auto_login)));
                chansay1();
            }
            else {
                chanmsg(scalar(keys(%auto_login))." users matching ".
                    scalar(keys(%prev_online))." hosts automatically logged in.");
            }
            if ($opts{voiceonlogin}) {
                my @vnicks = map { $rps{$_}{nick} }
                    grep { $rps{$_}{level} >= 0 } keys(%auto_login);
                while (scalar @vnicks >= $opts{modesperline}) {
                    sts("MODE $opts{botchan} +".('v' x $opts{modesperline})." ".join(" ",@vnicks[0..$opts{modesperline}-1]));
                    splice(@vnicks,0,$opts{modesperline});
                }
                sts("MODE $opts{botchan} +".('v' x (scalar @vnicks))." ".join(" ",@vnicks));
            }
        }
        else { chanmsg("0 users qualified for auto login."); }
        undef(%prev_online);
        undef(%auto_login);
        loadquestfile();
    }
    elsif ($arg[1] eq '005') {
        if ("@arg" =~ /MODES=(\d+)/) { $opts{modesperline}=$1; }
    }
    elsif ($arg[1] eq '352') {
        my $user;
        $onchan{$arg[7]}=time();
        if (exists($prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]})) {
            $rps{$prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]}}{online} = 1;
            $auto_login{$prev_online{$arg[7]."!".$arg[4]."\@".$arg[5]}}=1;
        }
    }
    elsif ($arg[1] eq 'privmsg') {
        $arg[0] = substr($arg[0],1);
        if (lc($arg[2]) eq lc($opts{botnick})) {
            $arg[3] = lc(substr($arg[3],1));
            if ($arg[3] eq "version") {
                privmsg("VERSION IRPG bot v$version by raz.",$usernick); ###raz### ;^)-~~
            }
            elsif ($arg[3] eq "peval" && $opts{peval}) {
                if (!ha($username) || ($opts{ownerpevalonly} && $opts{owner} ne $username)) {
                    privmsg("You don't have access to PEVAL.", $usernick);
                }
                else {
                    my @peval = eval "@arg[4..$#arg]";
                    if (@peval >= 4 || length("@peval") > 1024) {
                        privmsg("Command produced too much output to send outright; queueing ".length("@peval").
                                " bytes in ".scalar(@peval)." items. Use CLEARQ to clear queue if needed.",$usernick,1);
                        privmsg($_,$usernick) for @peval;
                    }
                    else { privmsg($_,$usernick, 1) for @peval; }
                    privmsg("EVAL ERROR: $@", $usernick, 1) if $@;
                }
            }
            elsif ($arg[3] eq "register") {
                if (defined $username) {
                    privmsg("Sorry, you are already online as $username.",$usernick);
                }
                else {
                    if ($#arg < 7 || $arg[7] eq "") {
                        privmsg("Try: REGISTER <char name> <password> <ability> <class>",$usernick);
                    }
                    elsif ($pausemode) {
                        privmsg("Sorry, new accounts may not be registered right now.",$usernick);
                    }
                    elsif (exists $rps{$arg[4]} || ($opts{casematters} && scalar(grep { lc($arg[4]) eq lc($_) } keys(%rps)))) {
                        privmsg("Sorry, that character name is already in use.",$usernick);
                    }
                    elsif (lc($arg[4]) eq lc($opts{botnick}) || lc($arg[4]) eq lc($primnick)) {
                        privmsg("Sorry, that character name cannot be registered.",$usernick);
                    }
                    elsif (!exists($onchan{$usernick})) {
                        privmsg("Sorry, you're not in $opts{botchan}.",$usernick);
                    }
                    elsif (length($arg[4]) > 16 || length($arg[4]) < 1) {
                        privmsg("Sorry, character names must be < 17 and > 0 chars long.", $usernick);
                    }
                    elsif ($arg[4] =~ /^#/) {
                        privmsg("Sorry, character names may not begin with #.",$usernick);
                    }
                    elsif ($arg[4] =~ /\001/) {
                        privmsg("Sorry, character names may not include character \\001.",$usernick);
                    }
                    elsif ($opts{noccodes} && ($arg[4] =~ /[[:cntrl:]]/ || "@arg[7..$#arg]" =~ /[[:cntrl:]]/)) {
                        privmsg("Sorry, neither character names nor classes may include control codes.",$usernick);
                    }
                    elsif ($opts{nononp} && ($arg[4] =~ /[[:^print:]]/ || "@arg[7..$#arg]" =~ /[[:^print:]]/)) {
                        privmsg("Sorry, neither character names nor classes may include non-printable chars.",$usernick);
                    }
                    elsif (!lc($arg[6]) eq "barbarian" || !lc($arg[6]) eq "wizard" || !lc($arg[6]) eq "paladin" || !lc($arg[6]) eq "rogue") {
                        privmsg("Sorry, character abilities are one of: Barbarian, Wizard, Paladin or Rogue.",$usernick);
                    }
                    elsif (length("@arg[7..$#arg]") > 30) {
                        privmsg("Sorry, character classes must be < 31 chars long.",$usernick);
                    }
                    elsif (time() == $lastreg) {
                        privmsg("Wait 1 second and try again.",$usernick);
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
                            $rps{$arg[4]}{next} = $opts{rpbase};
                            $rps{$arg[4]}{class} = "@arg[7..$#arg]";
                            $rps{$arg[4]}{level} = 0;
                            $rps{$arg[4]}{online} = 1;
                            $rps{$arg[4]}{nick} = $usernick;
                            $rps{$arg[4]}{userhost} = $arg[0];
                            $rps{$arg[4]}{created} = time();
                            $rps{$arg[4]}{last_login} = time();
                            $rps{$arg[4]}{pass} = crypt($arg[5],mksalt());
                            $rps{$arg[4]}{pos_x} = int(rand($opts{mapx}));
                            $rps{$arg[4]}{pos_y} = int(rand($opts{mapy}));
                            $rps{$arg[4]}{alignment}="n";
                            $rps{$arg[4]}{admin} = 0;
                            for my $item ("ring","amulet","charm","weapon","helm","tunic","gloves","shield","leggings","boots") {
                                $rps{$arg[4]}{item}{$item} = 0;
                            }
                            $rps{$arg[4]}{gold} = 500;
                            $rps{$arg[4]}{ability} = $ThisAbility;
                            $rps{$arg[4]}{life} = 100;
                            for my $pen ("pen_mesg","pen_nick","pen_part","pen_kick","pen_quit","pen_quest","pen_logout") {
                                $rps{$arg[4]}{$pen} = 0;
                            }
                            for my $ThisField ("ffight","bwon","blost","badd","bminus","powerpotion","status","gems","upgrade",
                                "rt","dm","cl","pw","aw","lw","alw","tt","bt","regentm","dragontm","mana","lotto11","lotto12","lotto13","lotto21","lotto22","lotto23",
                                "lotto31","lotto32","lotto33","experience","lottowins","lottosumwins","aligntime","Worktime","Towntime","Foresttime",
                                "Special01","Special02","Special03","ExpertItem01","ExpertItem02","ExpertItem03","EndPlayer","EmptyField") {
                                $rps{$arg[4]}{$ThisField} = 0;
                            }
                            if ($opts{voiceonlogin}) {
                                sts("MODE $opts{botchan} +v :$usernick");
                            }
                            chanmsg("Welcome $usernick\'s new $Ability $arg[4], the @arg[7..$#arg]! Next level in ".
                                    duration($opts{rpbase}).".");
                            privmsg("Success! Account $arg[4] created. You have $opts{rpbase} seconds until level 1. ", $usernick);
                        }
                        else {
                            privmsg("Abilities are as follow: Barbariab=b, Wizard=w, Paladin=p or Rogue=r. ", $usernick);
                        }
                    }
                }
            }
            elsif ($arg[3] eq "delold") {
                if (!ha($username)) {
                    privmsg("You don't have access to DELOLD.", $usernick);
                }
                elsif ($arg[4] !~ /^[\d\.]+$/) {
                    privmsg("Try: DELOLD <# of days>", $usernick, 1);
                }
                else {
                    my @oldaccounts = grep { (time()-$rps{$_}{last_login}) > ($arg[4] * 86400) && !$rps{$_}{online} } keys(%rps);
                    delete(@rps{@oldaccounts});
                    chanmsg(scalar(@oldaccounts)." accounts not accessed in the last $arg[4] days removed by $arg[0].");
                }
            }
            elsif ($arg[3] eq "del") {
                if (!ha($username)) {
                    privmsg("You don't have access to DEL.", $usernick);
                }
                elsif (!defined($arg[4])) {
                   privmsg("Try: DEL <char name>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    delete($rps{$arg[4]});
                    chanmsg("Account $arg[4] removed by $arg[0].");
                }
            }
            elsif ($arg[3] eq "mkadmin") {
                if (!ha($username) || ($opts{owneraddonly} && $opts{owner} ne $username)) {
                    privmsg("You don't have access to MKADMIN.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: MKADMIN <char name>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{admin}=1;
                    privmsg("Account $arg[4] is now a bot admin.",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "deladmin") {
                if (!ha($username) || ($opts{ownerdelonly} && $opts{owner} ne $username)) {
                    privmsg("You don't have access to DELADMIN.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: DELADMIN <char name>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such account $arg[4].", $usernick, 1);
                }
                elsif ($arg[4] eq $opts{owner}) {
                    privmsg("Cannot DELADMIN owner account.", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{admin}=0;
                    privmsg("Account $arg[4] is no longer a bot admin.",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "hog") {
                if (!ha($username)) {
                    privmsg("You don't have access to HoG.", $usernick);
                }
                else {                    
                    hog();
                }
            }
            elsif ($arg[3] eq "calamity") {
                if (!ha($username)) {
                    privmsg("You don't have access to CALAMITY.", $usernick);
                }
                else {
                    chanmsg("$usernick has summoned Lucifer.");
                    calamity();
                }
            }
            elsif ($arg[3] eq "hunt") {
                if (!ha($username)) {
                    privmsg("You don't have access to HUNT.", $usernick);
                }
                else {
                    chanmsg("$usernick has called a monster hunt.");
                    monst_hunt();
                }
            }
            elsif ($arg[3] eq "monst") {
                if (!ha($username)) {
                    privmsg("You don't have access to MONST.", $usernick);
                }
                else {
                    chanmsg("$usernick has summoned a monster.");
                    monst_attack();
                }
            }
            elsif ($arg[3] eq "lottery") {
                if (!ha($username)) {
                    privmsg("You don't have access to Lottery.", $usernick);
                }
                else {
                    chanmsg("$usernick has started the 10Lottery.");
                    lottery();
                }
            }
            elsif ($arg[3] eq "top") {
                if (!ha($username)) {
                    privmsg("You don't have access to top.", $usernick);
                }
                elsif (!$arg[4] || $arg[4] !~ /^\d+$/o) {
                    privmsg("Try: TOP <number>", $usernick, 1);
                }
                elsif ($arg[4] && $arg[4] =~ /^\d+$/o) {
                    my @u = sort { $rps{$b}{level} <=> $rps{$a}{level} || $rps{$a}{next} <=> $rps{$b}{next} } keys(%rps);

                    my $n = $#u + 1;
                       $n = $arg[4] if($arg[4] < $n);

                    chanmsg("Idle RPG Top $n Players:") if @u;
                    for my $i (0..$arg[4]-1) {
                        last if(!defined $u[$i] || !defined $rps{$u[$i]}{level});

                        my $tempsum = itemsum($u[$i],0);

                        chanmsg("#" .($i + 1). " $u[$i]".
                        " | Lvl $rps{$u[$i]}{level} | TTL " .(duration($rps{$u[$i]}{next})).
                        " | Align $rps{$u[$i]}{alignment} | Ability $rps{$u[$i]}{ability}".
                        " | Life $rps{$u[$i]}{life} | Sum $tempsum");
                    }
                }
            }
            elsif ($arg[3] eq "opme") {
                if (!ha($username)) {
                    privmsg("You don't have access to OPME.", $usernick);
                }
                else {
                     sts("MODE $opts{botchan} +o :$usernick");
                }
            }
            elsif ($arg[3] eq "deopme") {
                if (!ha($username)) {
                    privmsg("You don't have access to DEOPME.", $usernick);
                }
                else {
                     sts("MODE $opts{botchan} -o :$usernick");
                }
            }
            elsif ($arg[3] eq "challenge") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHALLENGE.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: CHALLENGE <char name>", $usernick, 1);
                }

                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    challenge_opp($arg[4]);
                }
            }
            elsif ($arg[3] eq "godsend") {
                if (!ha($username)) {
                    privmsg("You don't have access to GODSEND.", $usernick);
                }
                else {
                    godsend();
                }
            }
            elsif ($arg[3] eq "evilness") {
                if (!ha($username)) {
                    privmsg("You don't have access to EVILNESS.", $usernick);
                }
                else {
                    evilness();
                    evilnessOffline();
                }
            }
            elsif ($arg[3] eq "goodness") {
                if (!ha($username)) {
                    privmsg("You don't have access to GOODNESS.", $usernick);
                }
                else {
                    goodness();
                }
            }
            elsif ($arg[3] eq "item") {
                if (!ha($username)) {
                    privmsg("You don't have access to ITEM.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: ITEM <char name>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such account $arg[4].", $usernick, 1);
                }
                else {
                    find_item($arg[4]);
                }
            }
            elsif ($arg[3] eq "rehash") {
                if (!ha($username)) {
                    privmsg("You don't have access to REHASH.", $usernick);
                }
                else {
                    readconfig();
                    privmsg("Reread config file.",$usernick,1);
                    $opts{botchan} =~ s/ .*//;
                }
            }
            elsif ($arg[3] eq "chpass") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHPASS.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: CHPASS <char name> <new pass>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{pass} = crypt($arg[5],mksalt());
                    privmsg("Password for $arg[4] changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chnick") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHNICK.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: CHNICK USERNAME NICK", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{nick} = $arg[5];
                    privmsg("NICK for $arg[4] has been changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chhost") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHHOST.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: CHHOST USER NICK!IDENT AT HOST", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{userhost} = $arg[5];
                    privmsg("USERHOST for $arg[4] has been changed.", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "chuser") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHUSER.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: CHUSER <char name> <new char name>",$usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                elsif (exists($rps{$arg[5]})) {
                    privmsg("Username $arg[5] is already taken.", $usernick,1);
                }
                else {
                    $rps{$arg[5]} = delete($rps{$arg[4]});
                    privmsg("Username for $arg[4] changed to $arg[5].",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "chclass") {
                if (!ha($username)) {
                    privmsg("You don't have access to CHCLASS.", $usernick);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: CHCLASS <char name> <new char class>",$usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                else {
                    $rps{$arg[4]}{class} = "@arg[5..$#arg]";
                    privmsg("Class for $arg[4] changed to @arg[5..$#arg].",$usernick, 1);
                }
            }
            elsif ($arg[3] eq "push") {
                if (!ha($username)) {
                    privmsg("You don't have access to PUSH.", $usernick);
                }
                elsif ($arg[5] !~ /^\-?\d+$/) {
                    privmsg("Try: PUSH <char name> <seconds>", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("No such username $arg[4].", $usernick, 1);
                }
                elsif ($arg[5] > $rps{$arg[4]}{next}) {
                    privmsg("Level time for $arg[4] ($rps{$arg[4]}{next}s) is lower than $arg[5]; Resetting to 0.",$usernick, 1);
                    chanmsg("$usernick has pushed $arg[4] $rps{$arg[4]}{next} seconds toward level ".($rps{$arg[4]}{level}+1));
                    $rps{$arg[4]}{next}=0;
                }
                else {
                    $rps{$arg[4]}{next} -= $arg[5];
                     chanmsg("$usernick has pushed $arg[4] $arg[5] seconds toward level ".($rps{$arg[4]}{level}+1).". ".
                        "$arg[4] reaches next level in ".duration($rps{$arg[4]}{next}).".");
                }
            }
            elsif ($arg[3] eq "fight") {
                if (!defined($username)) {
                    privmsg("FIGHT Request Denied: You are not logged in.", $usernick);
                }
                elsif ($arg[4] && $arg[4] eq "allow-lower-level") {
                    if (!ha($username)) {
                        privmsg("FIGHT Request Denied: You don't have access to options.", $usernick, 1);
                    }
                    elsif (!$arg[5] || $arg[5] !~ /^(?:1|0|true|false|on|off|status)$/io) {
                        privmsg("Try: FIGHT allow-lower-level <on|off|status>", $usernick, 1);
                    }
                    elsif ($arg[5] && $arg[5] =~ /^status$/io) {
                        my $on_off = $opts{fightlowerlevel} ? 'on' : 'off';

                        privmsg("FIGHT allow-lower-level is $on_off", $usernick, 1);
                    }
                    else {
                        my $on_off = $arg[5] =~ /^(?:1|on|true)$/ ? 1 : 0;

                        $opts{fightlowerlevel} = $on_off;

                        $on_off = $opts{fightlowerlevel} ? 'on' : 'off';

			privmsg("FIGHT allow-lower-level is $on_off", $usernick, 1);
                    }
                }
                elsif ($rps{$username}{level} < 25) {
                    privmsg("FIGHT Request Denied: Command available to level 25+ users only.", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("FIGHT Request Denied: No such account $arg[4].", $usernick, 1);
                }
                elsif ($rps{$arg[4]}{online} < 1) {
                    privmsg("FIGHT Request Denied: Please select an online apponent.", $usernick, 1);
                }
                elsif ($arg[4] eq $username) {
                    privmsg("FIGHT Request Denied: Cannot FIGHT yourself.", $usernick, 1);
                }
                elsif ($rps{$username}{level} > $rps{$arg[4]}{level} && !$opts{fightlowerlevel}) {
                    privmsg("FIGHT Request Denied: You can only Fight users with the same or higher level than yourself.", $usernick, 1);
                }
                elsif ($rps{$username}{ffight} > 4) {
                    privmsg("FIGHT Request Denied: You have had your 5 FIGHTS on this level.", $usernick, 1);
                }
                elsif ($rps{$username}{life} < 1) {
                    privmsg("FIGHT Request Denied: You are either dead or a Zombie.", $usernick, 1);
                }
                else {
                    BattlePlayers($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "eat") {
                if (!defined($username)) {
                    privmsg("EAT Request Denied: You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{level} < 25) {
                    privmsg("EAT Request Denied: Command available to level 25+ users only.", $usernick, 1);
                }
                elsif (!exists($rps{$arg[4]})) {
                    privmsg("EAT Request Denied: No such account $arg[4].", $usernick, 1);
                }
                elsif ($rps{$arg[4]}{online} < 1) {
                    privmsg("EAT Request Denied: Please select an online apponent.", $usernick, 1);
                }
                elsif ($arg[4] eq $username) {
                    privmsg("EAT Request Denied: Cannot EAT yourself.", $usernick, 1);
                }
                elsif ($rps{$arg[4]}{EndPlayer} > 0) {
                    privmsg("EAT Request Denied: You can not EAT players in the End Tournament.", $usernick, 1);
                }
                elsif ($rps{$arg[4]}{life} < 0) {
                    privmsg("EAT Request Denied: You can not EAT other Zombies!", $usernick, 1);
                }
                elsif ($rps{$username}{life} > -1) {
                    privmsg("EAT Request Denied: You are not a Zombie.", $usernick, 1);
                }
                elsif ($rps{$username}{ffight} > 4) {
                    privmsg("EAT Request Denied: You have EATEN enough.", $usernick, 1);
                }
                elsif ($rps{$username}{EmptyField} > time()) {
                    my $eattm = $rps{$username}{EmptyField}-time();
                    privmsg("EAT Request Denied: You have EATEN enough for the next ".duration($eattm ).".", $usernick, 1);
                }
                else {
                    EatPlayers($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "attack") {
                if (!defined($username)) {
                    privmsg("ATTACK Request Denied: You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{level} < 15) {
                    privmsg("ATTACK Request Denied: Command available to level 15+ users only.", $usernick, 1);
                }
                elsif ($rps{$username}{life} < 10) {
                    privmsg("ATTACK Request Denied: You need to buy life.", $usernick, 1);
                }
                elsif (!exists($monster{$arg[4]})) {
                    privmsg("ATTACK Request Denied: No such creep.", $usernick, 1);
                }
                elsif ($rps{$username}{regentm} > time()) {
                    my $regentm = $rps{$username}{regentm}-time();
                    privmsg("You are not recovered from your last fight, wait ".duration($regentm).".", $usernick, 1);
                }
                else {
                    monster_fight($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "slay") {
                if (!defined($username)) {
                    privmsg("SLAY Request Denied: You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{level} < 30) {
                    privmsg("SLAY Request Denied: Command available to level 30+ users only.", $usernick, 1);
                }
                elsif ($rps{$username}{life} < 10) {
                    privmsg("SLAY Request Denied: You need to buy life.", $usernick, 1);
                }
                elsif (!exists($dragon{$arg[4]})) {
                    privmsg("SLAY Request Denied: No such dragon.", $usernick, 1);
                }
                elsif ($rps{$username}{dragontm} > time()) {
                    my $dragontm = $rps{$username}{dragontm}-time();
                    privmsg("You are not recovered from your last slay, wait ".duration($dragontm).".", $usernick, 1);
                }
                else {
                    dragon_fight($username, $arg[4]);
                }
            }
            elsif ($arg[3] eq "buy") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{level} < 15) {
                    privmsg("Shop available to 15+ users only.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Welcome to the shop. To buy any item type /msg $opts{botnick} buy <itemtype> <level>", $usernick);
                }
                elsif ($arg[4] eq "powerpotion") {
                    buy_pots("$username");    
                }
                elsif ($arg[4] eq "experience") {
                    buy_experience("$username");    
                }
                elsif ($arg[4] eq "upgrade") {
                    buy_upgrade("$username");    
                }
                elsif ($arg[4] eq "mana") {
                    buy_mana("$username");    
                }
                elsif ($arg[4] eq "life") {
                    buy_life("$username");    
                }
                elsif (!defined($arg[5])) {
                    if($arg[4] eq "help") {
                        privmsg("The items are as follows: ring, amulet, charm, weapon, helm, tunic, gloves".
                            ", leggings, shield, boots, life. ", $usernick);
                        privmsg("To buy any item type /msg $opts{botnick} buy <itemtype> [level]", $usernick);
                        privmsg("The [level] option is only for items.", $usernick);
                    }
                    elsif($arg[4] eq "prices") {
                        privmsg("The prices for item are 3 * Level_of_item_you_are_buying.", $usernick);
                    }
                    else {
                        privmsg("Try /msg $opts{botnick} buy help or /msg $opts{botnick} buy prices.", $usernick);
                    }
                }
                elsif ($arg[5] !~ /\D/) {
                    buy_item("$username", "$arg[4]", "$arg[5]");
                }
                else {
                    privmsg("You did not type a valid level.", $usernick);
                }
            }
            elsif ($arg[3] eq "get") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: get number gems", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: get number gems", $usernick, 1);
                }
                else {
                    buy_gems("$username", $arg[4]);
                }
            }
            elsif ($arg[3] eq "toss") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: toss NAME_OF_STONE", $usernick, 1);
                }
                else {
                    if ($arg[4] eq $rps{$username}{Special01} || $arg[4] eq $rps{$username}{Special02} 
                        || $arg[4] eq $rps{$username}{Special03}) {
                        item_special_toss("$username", $arg[4]);
                    }
                    else {
                        privmsg("You don't have a $arg[4] Stone!", $usernick);
                    }
                    
                }
            }
            ### lotto 1
            elsif ($arg[3] eq "lotto1") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{gold} < 500) {
                    privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    privmsg("Try: lotto1  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($rps{$username}{lotto11} ne "0") {
                    privmsg("You already have a lotto ticket set 1, 1", $usernick, 1);
                }
                elsif ($rps{$username}{lotto12} ne "0") {
                    privmsg("You already have a lotto ticket set 1, 2", $usernick, 1);
                }
                elsif ($rps{$username}{lotto13} ne "0") {
                    privmsg("You already have a lotto ticket set 1, 3", $usernick, 1);
                }                
                else {
                    $rps{$username}{lotto11} = int($arg[4]);
                    $rps{$username}{lotto12} = int($arg[5]);
                    $rps{$username}{lotto13} = int($arg[6]);
                    $rps{$username}{gold} -= 500;
                    privmsg("Your lotto numbers set 1 are $rps{$username}{lotto11}, $rps{$username}{lotto12} and $rps{$username}{lotto13}.",$usernick);
                }
            }
            ### lotto 2
            elsif ($arg[3] eq "lotto2") {
                if (!defined($username)) {
                privmsg("You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{gold} < 500) {
                    privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    privmsg("Try: lotto2  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($rps{$username}{lotto21} ne "0") {
                    privmsg("You already have a lotto ticket set 2, 1", $usernick, 1);
                }
                elsif ($rps{$username}{lotto22} ne "0") {
                    privmsg("You already have a lotto ticket set 2, 2", $usernick, 1);
                }
                elsif ($rps{$username}{lotto23} ne "0") {
                    privmsg("You already have a lotto ticket set 2, 3", $usernick, 1);
                }                
                else {
                    $rps{$username}{lotto21} = int($arg[4]);
                    $rps{$username}{lotto22} = int($arg[5]);
                    $rps{$username}{lotto23} = int($arg[6]);
                    $rps{$username}{gold} -= 500;
                    privmsg("Your lotto numbers set 2 are $rps{$username}{lotto21}, $rps{$username}{lotto22} and $rps{$username}{lotto23}.",$usernick);
                }
            }
            ### lotto 3
            elsif ($arg[3] eq "lotto3") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif ($rps{$username}{gold} < 500) {
                    privmsg("You don't have enough gold. You need 500 gold.", $usernick, 1);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif (!defined($arg[5])) {
                    privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif (!defined($arg[6])) {
                    privmsg("Try: lotto3  # # #", $usernick, 1);
                }
                elsif ($arg[4] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] > 20) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[5] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[6] < 1) {
                    privmsg("You have to chose numbers from 1 to 20.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[5]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[4] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($arg[5] > $arg[6]) {
                    privmsg("Numbers must be in order.", $usernick, 1);
                }
                elsif ($rps{$username}{lotto31} ne "0") {
                    privmsg("You already have a lotto ticket set 3, 1", $usernick, 1);
                }
                elsif ($rps{$username}{lotto32} ne "0") {
                    privmsg("You already have a lotto ticket set 3, 2", $usernick, 1);
                }
                elsif ($rps{$username}{lotto33} ne "0") {
                    privmsg("You already have a lotto ticket set 3, 3", $usernick, 1);
                }                
                else {
                    $rps{$username}{lotto31} = int($arg[4]);
                    $rps{$username}{lotto32} = int($arg[5]);
                    $rps{$username}{lotto33} = int($arg[6]);
                    $rps{$username}{gold} -= 500;
                    privmsg("Your lotto numbers set 3 are $rps{$username}{lotto31}, $rps{$username}{lotto32} and $rps{$username}{lotto33}.",$usernick);
                }
            }            
            elsif ($arg[3] eq "goto") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif (!defined($arg[4]) || $arg[4] eq "" || (lc($arg[4]) ne "work" && lc($arg[4]) ne "town" && lc($arg[4]) ne "forest")) {
                    privmsg("Try: goto <town|work|forest>", $usernick);
                }
                elsif (lc($arg[4]) eq 'town' && $rps{$username}{status} == TOWN) {
                    privmsg("You are already in the town.", $usernick);
                }
                elsif (lc($arg[4]) eq 'work' && $rps{$username}{status} == WORK) {
                    privmsg("You are already at work.", $usernick);
                }
                elsif (lc($arg[4]) eq 'forest' && $rps{$username}{status} == FOREST) {
                    privmsg("You are already in the forest.", $usernick);
                }
                else {
                    change_location($usernick, $username, lc($arg[4]));
                }
            }
            elsif ($arg[3] eq "logout") {
                if (defined($username)) {
                    penalize($username,"logout");
                }
                else {
                    privmsg("You are not logged in.", $usernick);
                }
            }
            elsif ($arg[3] eq "quest") {
                if ($arg[4] && $arg[4] eq "options") {
                    if (!ha($username)) {
                        privmsg("You don't have access to options.", $usernick, 1);
                    }
                    elsif (!exists $options{$arg[3]}) {
                        privmsg("QUEST has no options.", $usernick, 1);
                    }
                    else {
                        foreach my $option (sort keys %{$options{$arg[3]}}) {
			    privmsg("QUEST $option $opts{$options{$arg[3]}{$option}}", $usernick, 1);
                        }
                    }
                }
                elsif ($arg[4] && exists $options{$arg[3]}{$arg[4]}) {
                    if (!ha($username)) {
                        privmsg("You don't have access to options.", $usernick, 1);
                    }
                    elsif (!$arg[5] || $arg[5] !~ /^(?:\d+|status)$/io) {
                        privmsg("Try: QUEST $arg[4] <number|status>", $usernick, 1);
                    }
                    elsif ($arg[5] && $arg[5] =~ /^status$/io) {
                        my $option = $options{$arg[3]}{$arg[4]};

                        privmsg("QUEST $arg[4] is $opts{$option}", $usernick, 1);
                    }
                    else {
                        my $option = $options{$arg[3]}{$arg[4]};

                        $opts{$option} = $arg[5];

			privmsg("QUEST $arg[4] is $opts{$option}", $usernick, 1);
                    }
                }
		elsif ($arg[4] && $arg[4] eq 'now') {
                    if (!ha($username)) {
                        privmsg("You can't start a quest.", $usernick, 1);
                    }
                    else {
                        $quest{qtime} = time();
                    }
                }
                elsif (!@{$quest{questers}}) {
                    privmsg("There is no active quest.",$usernick);
                }
                elsif ($quest{type} == 1) {
                    privmsg(join(", ",(@{$quest{questers}})[0..$opts{questplayers}-2]).", and ".
                        "$quest{questers}->[$opts{questplayers}-1] are on a quest to $quest{text}. Quest to complete in ".
                        duration($quest{qtime}-time()).".",$usernick);
                }
                elsif ($quest{type} == 2) {
                    privmsg(join(", ",(@{$quest{questers}})[0..$opts{questplayers}-2]).", and ".
                        "$quest{questers}->[$opts{questplayers}-1] are on a quest to $quest{text}. Participants must first reach ".
                        "[$quest{p1}->[0],$quest{p1}->[1]], then [$quest{p2}->[0],$quest{p2}->[1]].".
                        ($opts{mapurl}?" See $opts{mapurl} to monitor their journey's progress.":""),$usernick);
                }
            }
            elsif ($arg[3] eq "status" && $opts{statuscmd}) {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                elsif ($arg[4] && !exists($rps{$arg[4]})) {
                    privmsg("No such user.",$usernick);
                }
                elsif ($arg[4]) {
                    privmsg("$arg[4]: Level $rps{$arg[4]}{level} ".
                        "$rps{$arg[4]}{class}; Status: O".($rps{$arg[4]}{online}?"n":"ff")."line; ".
                        "TTL: ".duration($rps{$arg[4]}{next})."; Idled: ".duration($rps{$arg[4]}{idled}).
                        "; Item sum: ".itemsum($arg[4]),$usernick);
                }
                else {
                    privmsg("$username: Level $rps{$username}{level} ".
                        "$rps{$username}{class}; Status: O".($rps{$username}{online}?"n":"ff")."line; ".
                        "TTL: ".duration($rps{$username}{next})."; Idled: ".duration($rps{$username}{idled})."; ".
                        "Item sum: ".itemsum($username),$usernick);
                }
            }
            elsif ($arg[3] eq "whoami") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                else {
                    privmsg("You are $username, the level ".
                        $rps{$username}{level}." $rps{$username}{class}. ".
                        "Next level in ".duration($rps{$username}{next}),$usernick);
                    my $tempsum = itemsum($username,0);
                    privmsg("Items: ring[".($rps{$username}{item}{ring})."], ".
                        "amulet[".($rps{$username}{item}{amulet})."], ".
                        "charm[".($rps{$username}{item}{charm})."], ".
                        "weapon[".($rps{$username}{item}{weapon})."], ".
                        "helm[".($rps{$username}{item}{helm})."], ".
                        "tunic[".($rps{$username}{item}{tunic})."], ".
                        "gloves[".($rps{$username}{item}{gloves})."], ".
                        "leggings[".($rps{$username}{item}{leggings})."], ".
                        "shield[".($rps{$username}{item}{shield})."], ".
                        "boots[".($rps{$username}{item}{boots})."] ".
                        "Total sum: $tempsum. ".
                        "| Gold: $rps{$username}{gold}. ".
                        "Upgrade level: $rps{$username}{upgrade}. ".
                        "Gems: $rps{$username}{gems}. ".
                        "Ability: $rps{$username}{ability}. ".
                        "XP: $rps{$username}{experience}. ".
                        "Life: $rps{$username}{life}. ".
                        "Alignment: $rps{$username}{alignment}. ", $usernick);
#                        "Potions: power: $rps{$username}{powerpotion}. "
                    privmsg("Lotto 1: $rps{$username}{lotto11}, $rps{$username}{lotto12} and $rps{$username}{lotto13}. ".
                        "Lotto 2: $rps{$username}{lotto21}, $rps{$username}{lotto22} and $rps{$username}{lotto23}. ".
                        "Lotto 3: $rps{$username}{lotto31}, $rps{$username}{lotto32} and $rps{$username}{lotto33}. ".
                        "| Stone 1: $rps{$username}{Special01}. ".
                        "Stone 2: $rps{$username}{Special02}. ".
                        "Stone 3: $rps{$username}{Special03}. ".
                        "| Expert 1: $rps{$username}{ExpertItem01}. ".
                        "Expert 2: $rps{$username}{ExpertItem02}. ".
                        "Expert 3: $rps{$username}{ExpertItem03}.", $usernick);
                    my $NextCreep = $rps{$username}{regentm} - time();
                    if ($NextCreep > 0) {
                        $NextCreep = duration($NextCreep);
                    }
                    else {
                        $NextCreep = "0 days, 0:00:00";
                    }
                    my $NextDragon = $rps{$username}{dragontm} - time();
                    if ($NextDragon > 0) {
                        $NextDragon = duration($NextDragon);
                    }
                    else {
                        $NextDragon = "0 days, 0:00:00";
                    }
                    my $TournyRec = $rps{$username}{tt} - time();
                    if ($TournyRec > 0) {
                        $TournyRec = duration($TournyRec);
                    }
                    else {
                        $TournyRec = "0 days, 0:00:00";
                    }
                    my $BattleRec = $rps{$username}{bt} - time();
                    if ($BattleRec > 0) {
                        $BattleRec = duration($BattleRec);
                    }
                    else {
                        $BattleRec = "0 days, 0:00:00";
                    }
                    privmsg("Next Creep Attack: $NextCreep. Next Dragon Slay: $NextDragon. ".
                        "Tournament Recover: $TournyRec. Battle Recover: $BattleRec.", $usernick);
                }
            }
            elsif ($arg[3] eq "newpass") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick)
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: NEWPASS <new password>", $usernick);
                }
                else {
                    $rps{$username}{pass} = crypt($arg[4],mksalt());
                    privmsg("Your password was changed.",$usernick);
                }
            }
            elsif ($arg[3] eq "backup") {
                if (!ha($username)) {
                    privmsg("You do not have access to BACKUP.", $usernick);
                }
                else {
                    backup();
                    privmsg("$opts{dbfile} was backed up.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "align") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick)
                }
                elsif (!defined($arg[4]) || (lc($arg[4]) ne "good" && lc($arg[4]) ne "neutral" && lc($arg[4]) ne "evil")) {
                    privmsg("Try: ALIGN <good|neutral|evil>", $usernick);
                }
                elsif (($arg[4] eq 'neutral') && ($rps{$username}{alignment} eq "n")) {
                    privmsg("You are already neutral.", $usernick);
                }
                elsif (($arg[4] eq 'evil') && ($rps{$username}{alignment} eq "e")) {
                    privmsg("You are already evil.", $usernick);
                }
                elsif (($arg[4] eq 'good') && ($rps{$username}{alignment} eq "g")) {
                    privmsg("You are already good", $usernick);
                }
                elsif ($rps{$username}{aligntime} > time()) {
                    my $aligntime = $rps{$username}{aligntime}-time();
                    privmsg("To change alignment again, please wait ".duration($aligntime).".", $usernick, 1);
                }
                else {
                    for my $ALWtourney (@alignwar) {
                      if ($ALWtourney eq $username) {
                         chanmsg("$username changed alignment during the 14Alignment Battle! Their TTL is doubled.");
                         my $ThisTTL = $rps{$username}{next} * 2;
                         $rps{$username}{next} = $ThisTTL;
                       }
                    }
                    $rps{$username}{alignment} = substr(lc($arg[4]),0,1);
                    $rps{$username}{aligntime} = 86400+time();
                    chanmsg("$username has changed alignment to: ".lc($arg[4]).".");
                }
            }
            elsif ($arg[3] eq "blackbuy") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                if (!defined($arg[4])) {
                    privmsg("blackbuy what?", $usernick);
                }
                else {
                    if ($arg[4] eq "scroll") {
                        blackbuy_scroll("$username", "$arg[4]");
                    }
                    else {
                        if (!defined($arg[5])) {
                            privmsg("blackbuy $arg[4] how many times?", $usernick);
                        }
                        elsif ($arg[5] < 1) {
                            privmsg("blackbuy $arg[4] how many times (greater than 0)?", $usernick);
                        }
                        else {
                            blackbuy_item("$username", "$arg[4]", "$arg[5]");
                        }
                    }
                }
            }
            elsif ($arg[3] eq "xpget") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick);
                }
                else {
                    if (!defined($arg[4])) {
                        privmsg("xpget what?", $usernick);
                    }
                    elsif ($arg[4] eq "scroll") {
                        xpget_scroll("$username", "scroll");
                    }
                    else {
                        if (!defined($arg[5])) {
                            privmsg("You must specify an amount (i.e. xpget $arg[4] 20).", $usernick);
                        }
                        else {
                            xpget_item("$username", "$arg[4]", "$arg[5]");
                        }
                    }
                }
            }
            elsif ($arg[3] eq "removeme") {
                if (!defined($username)) {
                    privmsg("You are not logged in.", $usernick)
                }
                else {
                    chanmsg("$arg[0] removed their account, $username, the $rps{$username}{class}.");
                    delete($rps{$username});
                }
            }
            elsif ($arg[3] eq "help") {
                if (!ha($username)) {
                    privmsg("For information on IRPG bot commands, see $opts{helpurl}", $usernick);
                }
                else {
                    privmsg("Help URL is $opts{helpurl}", $usernick, 1);
                }
            }
            elsif ($arg[3] eq "die") {
                if (!ha($username)) {
                    privmsg("You do not have access to DIE.", $usernick);
                }
                else {
                    $opts{reconnect} = 0;
                    writedb();
                    sts("QUIT :DIE from $arg[0]",1);
                }
            }
            elsif ($arg[3] eq "reloaddb") {
                if (!ha($username)) {
                    privmsg("You do not have access to RELOADDB.", $usernick);
                }
                elsif (!$pausemode) {
                    privmsg("ERROR: Can only use LOADDB while in PAUSE mode.",$usernick, 1);
                }
                else {
                    loaddb();
                    privmsg("Reread player database file; ".scalar(keys(%rps))." accounts loaded.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "pause") {
                if (!ha($username)) {
                    privmsg("You do not have access to PAUSE.", $usernick);
                }
                else {
                    $pausemode = $pausemode ? 0 : 1;
                    privmsg("PAUSE_MODE set to $pausemode.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "silent") {
                if (!ha($username)) {
                    privmsg("You do not have access to SILENT.", $usernick);
                }
                elsif (!defined($arg[4]) || $arg[4] < 0 || $arg[4] > 3) {
                    privmsg("Try: SILENT <mode>", $usernick,1);
                }
                else {
                    $silentmode = $arg[4];
                    privmsg("SILENT_MODE set to $silentmode.",$usernick,1);
                }
            }
            elsif ($arg[3] eq "jump") {
                if (!ha($username)) {
                    privmsg("You do not have access to JUMP.", $usernick);
                }
                elsif (!defined($arg[4])) {
                    privmsg("Try: JUMP <server[:port]>", $usernick, 1);
                }
                else {
                    writedb();
                    sts("QUIT :JUMP to $arg[4] from $arg[0]");
                    unshift(@{$opts{servers}},$arg[4]);
                    close($sock);
                    sleep(3);
                    goto CONNECT;
                }
            }
            elsif ($arg[3] eq "restart") {
                if (!ha($username)) {
                    privmsg("You do not have access to RESTART.", $usernick);
                }
                else {
                    writedb();
                    sts("QUIT :RESTART from $arg[0]",1);
                    close($sock);
                    exec("perl $0");
                }
            }
            elsif ($arg[3] eq "clearq") {
                if (!ha($username)) {
                    privmsg("You do not have access to CLEARQ.", $usernick);
                }
                else {
                    undef(@queue);
                    chanmsg("Outgoing message queue cleared by $arg[0].");
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
                    $statstown = scalar(grep { $rps{$_}{status} == TOWN && $rps{$_}{online} } keys %rps);
                    $statswork = scalar(grep { $rps{$_}{status} == WORK && $rps{$_}{online} } keys %rps);
                    $statsforest = scalar(grep { $rps{$_}{status} == FOREST && $rps{$_}{online} } keys %rps);
                    $Barbarian = scalar(grep { $rps{$_}{ability} eq BARBARIAN && $rps{$_}{online} } keys %rps);
                    $Wizard = scalar(grep { $rps{$_}{ability} eq WIZARD && $rps{$_}{online} } keys %rps);
                    $Paladin = scalar(grep { $rps{$_}{ability} eq PALADIN && $rps{$_}{online} } keys %rps);
                    $Rogue = scalar(grep { $rps{$_}{ability} eq ROGUE && $rps{$_}{online} } keys %rps);
                privmsg("Online players : there are $statstown players in town, $statswork at work and ".
                    "$statsforest in the forest. We have $Barbarian Barbarians, $Wizard Wizards, $Paladin Paladins ".
                    "and $Rogue Rogues.", $usernick);
            }
            elsif ($arg[3] eq "info") {
                my $info;
                if (!ha($username) && $opts{allowuserinfo}) {
                
                    $info = "IRPG bot v$version by raz, ".      ###raz### ;^)-~~
                    
                    "On via server: ".$opts{servers}->[0].". Admins online: ".
                    join(", ", map { $rps{$_}{nick} }
                        grep { $rps{$_}{admin} && $rps{$_}{online} } keys(%rps)).".";
                    privmsg($info, $usernick);
                }
                elsif (!ha($username) && !$opts{allowuserinfo}) {
                    privmsg("You do not have access to INFO.", $usernick);
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
                        duration(time()-$^T),
                        scalar(grep { $rps{$_}{online} } keys(%rps)),
                        scalar(keys(%rps)),
                        $registrations,
                        $pausemode,
                        $silentmode,
                        $queuedbytes,
                        scalar(@queue),
                        $opts{servers}->[0],
                        join(", ",map { $rps{$_}{nick} }
                          grep { $rps{$_}{admin} && $rps{$_}{online} }
                          keys(%rps)));
                    privmsg($info, $usernick, 1);
                }
            }
            elsif ($arg[3] eq "login") {
                if (!defined($username)) {
                    if ($#arg < 5 || $arg[5] eq "") {
                        notice("Try: LOGIN <username> <password>", $usernick);
                    }
                    elsif (!exists $rps{$arg[4]}) {
                        notice("Sorry, no such account name. Account names are case sensitive.",$usernick);
                    }
                    elsif (!exists $onchan{$usernick}) {
                        notice("Sorry, you're not in $opts{botchan}.",$usernick);
                    }
                    elsif ($rps{$arg[4]}{pass} ne crypt($arg[5],$rps{$arg[4]}{pass})) {
                        notice("Wrong password.", $usernick);
                    }
                    else {
                        if ($opts{voiceonlogin}) {
                            if ($rps{$arg[4]}{level} >= 0) {
                                sts("MODE $opts{botchan} +v :$usernick");
                            }
                        }
                        $rps{$arg[4]}{online} = 1;
                        $rps{$arg[4]}{nick} = $usernick;
                        $rps{$arg[4]}{userhost} = $arg[0];
                        $rps{$arg[4]}{last_login} = time();
                        chanmsg("$arg[4], the level $rps{$arg[4]}{level} $rps{$arg[4]}{class}, is now online from ".
                            "nickname $usernick. Next level in ".duration($rps{$arg[4]}{next}).".");
                    }
                }
            }
            #elsif (!penalize($username,"privmsg",length("@arg[3..$#arg]")) &&
            #   index(lc("@arg[3..$#arg]"),"http:") != -1 &&
            #   (time()-$onchan{$usernick}) < 90 && $opts{doban}) {
            #    my $isokurl = 0;
            #    for (@{$opts{okurl}}) {
            #        if (index(lc("@arg[3..$#arg]"),lc($_)) != -1) { $isokurl = 1; }
            #    }
            #    if (!$isokurl) {
            #        sts("MODE $opts{botchan} +b $arg[0]");
            #        sts("KICK $opts{botchan} $usernick :No advertising; ban will be lifted within the hour.");
            #        push(@bans,$arg[0]) if @bans < 12;
            #    }
            #}
        }
    }
}

sub sts {
    my($text,$skipq) = @_;
    if ($skipq) {
        if ($sock) {
            debug("sts(): $text\r\n");
            print $sock "$text\r\n";
            $outbytes += length($text) + 2;
        }
        else {
            debug("sts(): clear queue\r\n");
            undef(@queue);
            return;
        }
    }
    else {
        debug("sts(): queue: $text\r\n");
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
            debug("fq(): dequeue: $line\r\n");
            unshift(@queue,$line);
            last();
        }
        if ($sock) {
            --$freemessages if $freemessages > 0;
            debug("fq(): $line\r\n");
            print $sock "$line\r\n";
            $sentbytes += length($line) + 2;
        }
        else {
            debug("fq(): clear queue\r\n");
            undef(@queue);
            last();
        }
        $outbytes += length($line) + 2;
    }
}

sub ttl {
    my $lvl = shift;
    return ($opts{rpbase} * ($opts{rpstep}**$lvl)) if $lvl <= 60;
    return (($opts{rpbase} * ($opts{rpstep}**60)) + (86400*($lvl - 60)));
}

sub penttl {
    my $lvl = shift;
    return ($opts{rpbase} * ($opts{rppenstep}*$lvl));
}

sub duration {
    my $s = shift;
    return "NA ($s)" if $s !~ /^\d+$/;
    return sprintf("%d day%s, %02d:%02d:%02d",$s/86400,int($s/86400)==1?"":"s", ($s%86400)/3600,($s%3600)/60,($s%60));
}

sub ts { # timestamp
    my @ts = localtime(time());
    return sprintf("[%02d/%02d/%02d %02d:%02d:%02d] ", $ts[4]+1,$ts[3],$ts[5]%100,$ts[2],$ts[1],$ts[0]);
}

sub ab_pit { # pit argument players against each other
    my $u = shift;
    my $opp = shift;
    if ($rps{$u}{level} < 25) { return unless rand(4) < 1; }
    my $mysum = int((itemsum($u,1)+($rps{$u}{upgrade}*100))*($rps{$u}{life}/100));
    my $oppsum = int((itemsum($opp,1)+($rps{$opp}{upgrade}*100))*($rps{$opp}{life}/100));
    my $myroll = int(rand($mysum));
    my $opproll = int(rand($oppsum));
    if ($myroll >= $opproll) {
        my $gain = ($opp eq $primnick)?20:int($rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        chanmsg(clog("$u [$myroll/$mysum] has challenged $opp [$opproll/".
                     "$oppsum] in combat and won! ".duration($gain)." is ".
                     "removed from $u\'s clock."));
        $rps{$u}{next} -= $gain;
                $rps{$u}{bwon} += 1;
                $rps{$opp}{blost} += 1;
                $rps{$u}{bminus} += $gain;
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
        my $csfactor = $rps{$u}{alignment} eq "g" ? 50 :
                       $rps{$u}{alignment} eq "e" ? 20 :
                       35;
        if (rand($csfactor) < 1 && $opp ne $primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $rps{$opp}{next});
            chanmsg(clog("$u has dealt $opp a Critical Strike! ".
                         duration($gain)." is added to $opp\'s clock."));
            $rps{$opp}{next} += $gain;
                        $rps{$opp}{badd} += $gain;
            chanmsg("$opp reaches next level in ".duration($rps{$opp}{next}).
                    ".");
        }
        elsif (rand(25) < 1 && $opp ne $primnick && $rps{$u}{level} > 19) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if (int($rps{$opp}{item}{$type}) > int($rps{$u}{item}{$type})) {
                chanmsg(clog("In the fierce battle, $opp dropped his level ".int($rps{$opp}{item}{$type})." $type! $u picks ".
                    "it up, tossing his old level ".int($rps{$u}{item}{$type})." $type to $opp."));
                my $tempitem = $rps{$u}{item}{$type};
                $rps{$u}{item}{$type}=$rps{$opp}{item}{$type};
                $rps{$opp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($opp eq $primnick)?10:int($rps{$opp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        chanmsg(clog("$u [$myroll/$mysum] has challenged $opp [$opproll/".
            "$oppsum] in combat and lost! ".duration($gain)." is added to $u\'s clock."));
        $rps{$u}{next} += $gain;
        $rps{$u}{blost} += 1;
        $rps{$opp}{bwon} += 1;
        $rps{$u}{badd} += $gain;
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
    }
}

sub hog {
    my @players = grep { $rps{$_}{online} } keys(%rps);
    my $player = $players[rand(@players)];
    my $win = int(rand(5));
    my $time = int(((5 + int(rand(71)))/100) * $rps{$player}{next});
    if ($win) {
        chanmsg(clog("The Hand of God carried $player ".duration($time)." toward level ".($rps{$player}{level}+1)."."));
        $rps{$player}{next} -= $time;
    }
    else {
        chanmsg(clog("Lucifer consumed $player with fire, adding ".duration($time)." from level ".($rps{$player}{level}+1)."."));
        $rps{$player}{next} += $time;
    }
    chanmsg("$player reaches next level in ".duration($rps{$player}{next}).".");
}

sub rpcheck {
    checksplits() if $opts{detectsplits};
    fq();
    $lastreg = 0;
    my $online = scalar(grep { $rps{$_}{online} } keys(%rps));
    return unless $online;
    my $onlineevil = scalar(grep { $rps{$_}{online} && $rps{$_}{alignment} eq "e" } keys(%rps));
    my $onlinegood = scalar(grep { $rps{$_}{online} && $rps{$_}{alignment} eq "g" } keys(%rps));
    if (!$opts{noscale}) {
        if (rand((8*86400)/$opts{self_clock}) < $online) { hog();          }
        if (rand((4*86400)/$opts{self_clock}) < $online) { calamity();     }
        if (rand((4*86400)/$opts{self_clock}) < $online) { godsend();      }
        if (rand((1*86400)/$opts{self_clock}) < $online) { random_gold();  }
        if (rand((4*86400)/$opts{self_clock}) < $online) { monst_hunt();   }
        if (rand((4*86400)/$opts{self_clock}) < $online) { monst_attack(); }
    }
    else {
        hog()          if rand(4000) < 1;
        calamity()     if rand(4000) < 1;
        godsend()      if rand(2000) < 1;
        random_gold()  if rand(500)  < 1;
        monst_hunt()   if rand(4000) < 1;
        monst_attack() if rand(500)  < 1;
    }
    if (rand((86400)/$opts{self_clock}) < $onlineevil) {
        evilness();
        evilnessOffline();
    }
    if (rand((8*86400)/$opts{self_clock}) < $onlinegood) { goodness(); }
    moveplayers();
    if (($rpreport%120 < $oldrpreport%120) && $opts{writequestfile}) { writequestfile(); }
    if (time() > $quest{qtime}) {
        if (!@{$quest{questers}}) { quest(); }
        elsif ($quest{type} == 1) {
            chanmsg(clog(join(", ",(@{$quest{questers}})[0..$opts{questplayers}-2]).", and $quest{questers}->[$opts{questplayers}-1] have blessed the realm by ".
                "completing their quest! 25% of their burden is eliminated and they have a chance to find an ITEM each."));
            for (@{$quest{questers}}) {
                $rps{$_}{next} = int($rps{$_}{next} * .75);
                find_item($_);
                find_gold($_);
                monst_attack($_);
            }
            undef(@{$quest{questers}});
            $quest{qtime} = time() + 21600;
            writequestfile();
        }
    }
    #tournaments
    if ($opts{tournament} && time() > $tournamenttime) {
        if (!@tournament) { tournament(); }
        else { tournament_battle(); }
    }
    if ($opts{selfrestart} && time() > $selfrestarttime && !@tournament && !@deathmatch && !@megawar && !@powerwar && !@abilitywar && !@locationwar && !@alignwar) {
        writedb();
        sts("QUIT :SELF-RESTART",1);
        close($sock);
        exec("perl $0");
    }
    if ($opts{selfrestart} && time() > $selfrestarttime && @tournament) {
        $selfrestarttime = time() + 1800; #wait for these to end
    }
    if ($opts{selfrestart} && time() > $selfrestarttime && @deathmatch) {
        $selfrestarttime = time() + 1800; #wait for these to end
    }
    #end tournaments
    #deathmatch
    if ($opts{deathmatch} && time() > $deathmatchtime) {
        if (!@deathmatch) { deathmatch(); }
        else { deathmatch_battle(); }
    }
    #end deathmatch
    #megawar
    if ($opts{megawar} && time() > $megawartime) {
        if (!@megawar) { megawar(); }
        else { megawar_battle(); }
    }
    #end megawar
    #powerwar
    if ($opts{powerwar} && time() > $powerwartime) {
        if (!@powerwar) { powerwar(); }
        else { powerwar_battle(); }
    }
    #end powerwar
    #abilitywar
    if ($opts{abilitywar} && time() > $abilitywartime) {
        if (!@abilitywar) { abilitywar(); }
        else { abilitywar_battle(); }
    }
    #end abilitywar
    #locationwar
    if ($opts{locationwar} && time() > $locationwartime) {
        if (!@locationwar) { locationwar(); }
        else { locationwar_battle(); }
    }
    #end locationwar
    #alignwar
    if ($opts{alignwar} && time() > $alignwartime) {
        if (!@alignwar) { alignwar(); }
        else { alignwar_battle(); }
    }
    #end alignwar

    if ($rpreport && ($rpreport%14400 < $oldrpreport%14400)) { # 4 hours
        my @u = sort { ( ($rps{$b}{level} || 0) <=> ($rps{$a}{level} || 0) ) ||
            ( ($rps{$a}{next} || 0) <=> ($rps{$b}{next} || 0) ) } keys(%rps);

        my $n = $#u + 1;
           $n = 10 if(10 < $n);

        chanmsg("Idle RPG Top $n Players:") if @u;
        for my $i (0..9) {
            last if(!defined $u[$i] || !defined $rps{$u[$i]}{level});
            
            my $tempsum = itemsum($u[$i],0);

            chanmsg("#" . ($i + 1) . " - $u[$i]".
            " | Lvl $rps{$u[$i]}{level} | TTL " .(duration($rps{$u[$i]}{next})).
            " | Align $rps{$u[$i]}{alignment} | Ability $rps{$u[$i]}{ability}".
            " | Life $rps{$u[$i]}{life} | Sum $tempsum");
        }
    }
    if (($rpreport%3600 < $oldrpreport%3600) && $rpreport) { # 1 hour
        my @players = grep { $rps{$_}{online} && $rps{$_}{level} > 44 } keys(%rps);
        # 20% of all players must be level 45+
        if ((scalar(@players)/scalar(grep { $rps{$_}{online} } keys(%rps))) > .15) {
            challenge_opp($players[int(rand(@players))]);
        }
        while (@bans) {
            sts("MODE $opts{botchan} -bbbb :@bans[0..3]");
            splice(@bans,0,4);
        }
    }
    if ($rpreport%1800 < $oldrpreport%1800) { # 30 mins
        if ($opts{botnick} ne $primnick) {
            sts($opts{botghostcmd}) if $opts{botghostcmd};
            sts("NICK $primnick");
        }
    }
    if (($rpreport%1800 < $oldrpreport%1800)) { # every 30m
#        chansay1();
    }
    if (($rpreport%14400 < $oldrpreport%14400)) { # every 4 hours
        if ($IsEnding == 0) {
            AutoHeal();
        }
    }
    if (($rpreport%21600 < $oldrpreport%21600)) { # every 6 hours
        forestwalk();
    }
    if (($rpreport%28800 < $oldrpreport%28800)) { # every 8 hours
        lottery();
    }
    if (($rpreport%28800 < $oldrpreport%28800)) { # every 8 hours
        backup();
    }
    if (($rpreport%600 < $oldrpreport%600) && $pausemode) { # warn every 10m
        chanmsg("WARNING: Cannot write database in PAUSE mode!");
    }
    if ($lasttime != 1) {
        my $curtime=time();
        for my $k (keys(%rps)) {
            if ($rps{$k}{online} && exists $rps{$k}{nick} && $rps{$k}{nick} && exists $onchan{$rps{$k}{nick}}) {
                $rps{$k}{next} -= ($curtime - $lasttime);
                $rps{$k}{idled} += ($curtime - $lasttime);
                if ($rps{$k}{next} < 1) {
                    my $ttl = int(ttl($rps{$k}{level}));
                    $rps{$k}{level}++;
                    $rps{$k}{next} += $ttl;
                    chanmsg("$k, the $rps{$k}{class}, has attained level $rps{$k}{level}! Next level in ".duration($ttl).".");
                    find_item($k);
                    find_gold($k);
                    find_gems($k);
                    challenge_opp($k);
                    $rps{$k}{regentm} = time();
                    $rps{$k}{ffight} = 0;
                    $rps{$k}{scrolls} = 0;
                    #START ENDING CODE
                    if ($rps{$k}{level} == 100) {
                        slay_fest($k);
                    }
                    #END ENDING CODE
                }
            }
        }
        #START ENDING CODE
        slay_fest_check();
        end_tourney_check(); #ENDtournament
        #END ENDING CODE
        if (!$pausemode && ($rpreport%60 < $oldrpreport%60)) { writedb(); }
        $oldrpreport = $rpreport;
        $rpreport += $curtime - $lasttime;
        $lasttime = $curtime;
    }
}

sub slay_fest {
    my $user = shift;
    my @players = grep { $rps{$_}{level} > 99 } keys(%rps);
    if ($IsEnding == 1) {
        $IsEnding = 0;
    }
    if ($#players > 0) {
        chanmsg("$user has attained level ONE HUNDRED! Slay Fest will begin now and last for 8 hours!!!");
        $rps{$user}{pen_logout} = time() - 57600;
        for my $i (0...$#players) {
            $rps{$players[$i]}{pen_logout} = time() - 57600;
        }
        my @playersReset = grep { $rps{$_}{level} > 34} keys(%rps);
        for my $i (0...$#playersReset) {
            $rps{$playersReset[$i]}{dragontm} = 0;
        }
    }
    else {
        chanmsg("$user is the first to reach level ONE HUNDRED! Each item gets 500 points! ".
            "Slay Fest will begin now and last for 24 hours!");
        $rps{$user}{pen_logout} = time();
        $rps{$user}{item}{amulet} += 500;
        $rps{$user}{item}{boots} += 500;
        $rps{$user}{item}{charm} += 500;
        $rps{$user}{item}{gloves} += 500;
        $rps{$user}{item}{helm} += 500;
        $rps{$user}{item}{leggings} += 500;
        $rps{$user}{item}{ring} += 500;
        $rps{$user}{item}{shield} += 500;
        $rps{$user}{item}{tunic} += 500;
        $rps{$user}{item}{weapon} += 500;
        my @playersReset = grep { $rps{$_}{level} > 34} keys(%rps);
        for my $i (0...$#playersReset) {
            $rps{$playersReset[$i]}{dragontm} = 0;
        }
    }
}

sub slay_fest_check {
    my @players = grep { $rps{$_}{online} && $rps{$_}{level} > 99 && ( (time() - $rps{$_}{pen_logout}) < 86400 )} keys(%rps);
    my %Triggers = ();
    foreach my $item (@players) { $Triggers{$item} = 1 }
    @players = sort {$rps{$b}{pen_logout} <=> $rps{$a}{pen_logout}} keys(%Triggers);
    if ($#players >= 0) {
        $SlayTime = 3600;
        $IsEnding = 0;
        if ($rpreport%1800 < $oldrpreport%1800) {
            chanmsg("4Slay Fest ends in ".duration(86400 - (time() - $rps{$players[0]}{pen_logout})).".");
        }
    }
    else {
        $SlayTime = 43200;
    }
}

sub end_tourney_check {
    if ($IsWinner == 0) {
        my @players = grep {$rps{$_}{level} > 99} keys(%rps);
        if ($#players >= 0 && $SlayTime == 43200) {
            $IsEnding = 1;
            if ($opts{lasttournament} && time() > $ENDtournamenttime) {
                if (!@ENDtournament) {
                    ENDtournament();
                }
                else {
                    ENDtournament_battle();
                }
            }
        }
        else {
            $IsEnding = 0;
        }
    }
    else {
        $IsEnding = 0;
    }
}

sub war { # let the four quadrants battle
    my @players = grep { $rps{$_}{online} } keys(%rps);
    my @quadrantname = ("Northeast", "Southeast", "Southwest", "Northwest");
    my %quadrant = ();
    my @sum = (0,0,0,0,0);
    for my $k (@players) {
        # "quadrant" 4 is for players in the middle
        $quadrant{$k} = 4;
        if (2 * $rps{$k}{pos_y} + 1 < $opts{mapy}) {
            $quadrant{$k} = 3 if (2 * $rps{$k}{pos_x} + 1 < $opts{mapx});
            $quadrant{$k} = 0 if (2 * $rps{$k}{pos_x} + 1 > $opts{mapx});
        }
        elsif (2 * $rps{$k}{pos_y} + 1 > $opts{mapy})
        {
            $quadrant{$k} = 2 if (2 * $rps{$k}{pos_x} + 1 < $opts{mapx});
            $quadrant{$k} = 1 if (2 * $rps{$k}{pos_x} + 1 > $opts{mapx});
        }
        $sum[$quadrant{$k}] += itemsum($k);
    }
    my @roll = (0,0,0,0);
    $roll[$_] = int(rand($sum[$_])) foreach (0..3);
    # winner if value >= maximum value of both direct neighbors, "quadrant" 4 never wins
    my @iswinner = map($_ < 4 && $roll[$_] >= $roll[($_ + 1) % 4] && $roll[$_] >= $roll[($_ + 3) % 4],(0..4));
    my @winners = map("the $quadrantname[$_] [$roll[$_]/$sum[$_]]",grep($iswinner[$_],(0..3)));
    my $winnertext = "";
    $winnertext = pop(@winners) if (scalar(@winners) > 0);
    $winnertext = pop(@winners)." and $winnertext" if (scalar(@winners) > 0);
    $winnertext = pop(@winners).", $winnertext" while (scalar(@winners) > 0);
    $winnertext = "has shown the power of $winnertext" if ($winnertext ne "");
    # loser if value < minimum value of both direct neighbors, "quadrant" 4 never loses
    my @isloser = map($_ < 4 && $roll[$_] < $roll[($_ + 1) % 4] && $roll[$_] < $roll[($_ + 3) % 4],(0..4));
    my @losers = map("the $quadrantname[$_] [$roll[$_]/$sum[$_]]",grep($isloser[$_],(0..3)));
    my $losertext = "";
    $losertext = pop(@losers) if (scalar(@losers) > 0);
    $losertext = pop(@losers)." and $losertext" if (scalar(@losers) > 0);
    $losertext = pop(@losers).", $losertext" while (scalar(@losers) > 0);
    $losertext = "led $losertext to perdition" if ($losertext ne "");
    # build array of text for neutrals
    my @neutrals = map("the $quadrantname[$_] [$roll[$_]/$sum[$_]]",grep(!$iswinner[$_] && !$isloser[$_],(0..3)));
    # construct text from neutrals array
    my $neutraltext = "";
    $neutraltext = pop(@neutrals) if (scalar(@neutrals) > 0);
    $neutraltext = pop(@neutrals)." and $neutraltext" if (scalar(@neutrals) > 0);
    $neutraltext = pop(@neutrals).", $neutraltext" while (scalar(@neutrals) > 0);
    $neutraltext = " The diplomacy of $neutraltext was admirable." if ($neutraltext ne "");
    if ($winnertext ne "" && $losertext ne "") {
        chanmsg(clog("The war between the four parts of the realm $winnertext, whereas it $losertext. $neutraltext"));
    }
    elsif ($winnertext eq "" && $losertext eq "") {
        chanmsg(clog("The war between the four parts of the realm was well-balanced. $neutraltext"));
    }
    else {
        chanmsg(clog("The war between the four parts of the realm $winnertext$losertext. $neutraltext"));
    }
    for my $k (@players) {
        $rps{$k}{next} = int($rps{$k}{next} / 2) if ($iswinner[$quadrant{$k}]);
        $rps{$k}{next} *= 2 if ($isloser[$quadrant{$k}]);
    }
}

sub get_monst_name {
    my $monsum = shift;
    my $monname = "Monster";
    if (!open(Q,$opts{monstfile})) {
        chanmsg("ERROR: Failed to open $opts{monstfile}: $!");
        return $monname;
    }
    while (my $line = <Q>) {
        chomp($line);
        if ($line =~ /^(\d+) ([^\r]*)\r*/) {
            if ($1 >= $monsum) {
                $monname = $2;
                last();
            }
        }
    }
    close(Q);
    return $monname;
}

sub monst_attack {
    my @players = grep { $rps{$_}{online} } keys(%rps);
    return unless @players;
    return monst_attack_player($players[rand(@players)]);
}

sub monst_attack_player {
    my $u = shift;
    my $mysum = int((itemsum($u,1)+($rps{$u}{upgrade}*100))*($rps{$u}{life}/100));
    my $myroll = int(rand($mysum));
    my $monsum;
    my $monroll;
    my $gain;
    my $loss;
    if (rand(5) < 1) {
        # Easy challange, gain 7% lose 10%
        $monsum = int((30+rand(20))*$mysum/100);
        $gain = 7;
        $loss = 10;
    } elsif (rand(5) < 1) {
        # Hard challange, gain 22% lose 5%
        $monsum = int((150+rand(20))*$mysum/100);
        $gain = 22;
        $loss = 5;
    } else {
        # Normal challange, gain 12% lose 9%
        $monsum = int((85+rand(30))*$mysum/100);
        $gain = 12;
        $loss = 9;
    }
    if ($monsum < 1) { $monsum = 1 };
    my $monname = get_monst_name($monsum);
    $monroll = int(rand($monsum));
    if ($myroll >= $monroll) {
        $gain = int($gain*$rps{$u}{next}/100);
        $rps{$u}{next} -= $gain;
        chanmsg(clog("$u 8[$myroll/$mysum] has been set upon by some $monname ".
             "8[$monroll/$monsum] and won! ".duration($gain)." is removed from $u\'s clock."));
    }
    else {
        $loss = int($loss*$rps{$u}{next}/100);
        $rps{$u}{next} += $loss;
        chanmsg(clog("$u 8[$myroll/$mysum] has been set upon by some $monname ".
            "8[$monroll/$monsum] and lost! ".duration($loss)." is added to $u\'s clock."));        
    }
    chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
}

sub monst_hunt {
    my @opp = grep { $rps{$_}{online} } keys(%rps);
    return if @opp < 3;
    splice(@opp,int(rand(@opp)),1) while @opp > 3;
    fisher_yates_shuffle(\@opp);
    my $mysum = itemsum($opp[0],1) + itemsum($opp[1],1) + itemsum($opp[2],1);
    my $monsum = int((150+rand(20))*$mysum/100);
    my $gain = $rps{$opp[0]}{next};
    for my $p (1,2) {
        $gain = $rps{$opp[$p]}{next} if $gain > $rps{$opp[$p]}{next};
    }
    $gain = int($gain*.20);
    my $myroll = int(rand($mysum));
    my $monname = get_monst_name($monsum);
    my $monroll = int(rand($monsum));
    if ($myroll >= $monroll) {
        chanmsg(clog("$opp[0], $opp[1], and $opp[2] 8[$myroll/$mysum] have hunted down a bunch of $monname 8[$monroll/$monsum] and ".
             "defeated them! ".duration($gain)." is removed from their clocks. They all get 5 XP."));
        $rps{$opp[0]}{next} -= $gain;
        $rps{$opp[1]}{next} -= $gain;
        $rps{$opp[2]}{next} -= $gain;
        $rps{$opp[0]}{experience} += 5;
        $rps{$opp[1]}{experience} += 5;
        $rps{$opp[2]}{experience} += 5;
    }
    else {
        chanmsg(clog("$opp[0], $opp[1], and $opp[2] 8[$myroll/$mysum] have hunted down a bunch of $monname 8[$monroll/$monsum] but they ".
            "beat them badly! ".duration($gain)." is added to their clocks. They all get 2 XP."));
        $rps{$opp[0]}{next} += $gain;
        $rps{$opp[1]}{next} += $gain;
        $rps{$opp[2]}{next} += $gain;
        $rps{$opp[0]}{experience} += 2;
        $rps{$opp[1]}{experience} += 2;
        $rps{$opp[2]}{experience} += 2;
    }
}

sub lottery {
    my $nr1 = 0;
    my $nr2 = 0;
    my $nr3 = 0;
    my $numbers = 0;
    my $sorted = 0;
    my $nrsum = 0;
    my @numbers = (int(rand(20)+1), int(rand(20)+1), int(rand(20)+1));
    while ($numbers[0] == $numbers[1]) { $numbers[1] = int(rand(20)+1) }
    while ($numbers[0] == $numbers[2] || $numbers[1] == $numbers[2]) { $numbers[2] = int(rand(20)+1) }
    my @sorted = sort {$a <=> $b} (@numbers);
    $nr1 = $sorted[0];
    $nr2 = $sorted[1];
    $nr3 = $sorted[2];
    $nrsum = $nr1 + $nr2 + $nr3;            
    chanmsg("The 10Lottery numbers for today are: 10$nr1, $nr2 and10 $nr3. Lotto Sum is: 10$nrsum.");
    my @winners =
        grep { $rps{$_}{online} && (
            ($rps{$_}{lotto11} == $nr1 && $rps{$_}{lotto12} == $nr2 && $rps{$_}{lotto13} == $nr3) || 
            ($rps{$_}{lotto21} == $nr1 && $rps{$_}{lotto22} == $nr2 && $rps{$_}{lotto23} == $nr3) ||
            ($rps{$_}{lotto31} == $nr1 && $rps{$_}{lotto32} == $nr2 && $rps{$_}{lotto33} == $nr3)
        ) } keys(%rps);
    if (@winners > 0) {
        chanmsg("The Lottery winner(s) are: @winners !!!");
    }
    else {
        chanmsg("The are no Lottery winners.");
    }
    while (@winners > 0) {
        my $ThisPos = int(rand(@winners));
        my $winner = $winners[$ThisPos];
        $rps{$winner}{gems} += 50;
        $rps{$winner}{gold} += 2000;
        $rps{$winner}{lottowins} += 1;
        splice(@winners,$ThisPos,1);           
    }        
    my @winners_sum =
        grep { $rps{$_}{online} && (
            ($rps{$_}{lotto11} + $rps{$_}{lotto12} + $rps{$_}{lotto13} == $nrsum) ||
            ($rps{$_}{lotto21} + $rps{$_}{lotto22} + $rps{$_}{lotto23} == $nrsum) ||
            ($rps{$_}{lotto31} + $rps{$_}{lotto32} + $rps{$_}{lotto33} == $nrsum)
        ) } keys(%rps);
    if (@winners_sum > 0) {
        chanmsg("The Lotto Sum winner(s) are: @winners_sum !!!");
    }
    else {
        chanmsg("The are no Lotto Sum winners.");
    }
    while (@winners_sum > 0) {
        my $ThisPos = int(rand(@winners_sum));
        my $winner_sum = $winners_sum[$ThisPos];
        $rps{$winner_sum}{gems} += 1;
        $rps{$winner_sum}{gold} += 150;
        $rps{$winner_sum}{lottosumwins} += 1;
        splice(@winners_sum,$ThisPos,1);           
    }        
}

sub challenge_opp {
    my $u = shift;
    if ($rps{$u}{level} < 25) { return unless rand(4) < 1; }
    my @opps = grep { $rps{$_}{online} && $u ne $_ } keys(%rps);
    unless (@opps && rand(5) > 0) {
    monst_attack_player($u);
    return;
    }
    my $opp = $opps[int(rand(@opps))];
    my $mysum = 0;
    if ($rps{$u}{upgrade} > 0) {
        $mysum = int((itemsum($u,1)+($rps{$u}{upgrade}*100))*($rps{$u}{life}/100));
    }
    else {
        $mysum = int((itemsum($u,1))*($rps{$u}{life}/100));
    }
    my $oppsum = 0;
    if ($rps{$opp}{upgrade} > 0) {
        $oppsum = int((itemsum($opp,1)+($rps{$opp}{upgrade}*100))*($rps{$opp}{life}/100));
    }
    else {
        $oppsum = int((itemsum($opp,1))*($rps{$opp}{life}/100));
    }
    my $myroll = int(rand($mysum));
    my $opproll = int(rand($oppsum));
    my $xp = int(rand(4)+1);
    my $oxp = int(rand(2)+1);
    my $adamage = 0;
    my $ddamage = 0;
    if($rps{$opp}{life} > 10) {
        $adamage = int(rand(4)+1);
    }
    if($rps{$u}{life} > 10) {
        $ddamage = int(rand(4)+1);
    }
    if ($myroll >= $opproll) {
        my $gain = ($opp eq $primnick)?20:int($rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        $rps{$opp}{life} -= $adamage;
        chanmsg(clog("$u 9[$myroll/$mysum] has challenged $opp 9[$opproll/$oppsum] in combat and won! ".duration($gain)." is ".
            "removed from $u\'s clock. $u gets $xp XP and $opp gets $oxp XP. $opp has $rps{$opp}{life} life left."));
        $rps{$u}{next} -= $gain;
        $rps{$u}{bwon} += 1;
        $rps{$opp}{blost} += 1;
        $rps{$u}{bminus} += $gain;
        $rps{$u}{experience} += $xp;
        $rps{$opp}{experience} += $oxp;
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
        my $csfactor = $rps{$u}{alignment} eq "g" ? 50 :
           $rps{$u}{alignment} eq "e" ? 20 : 35;
        if (rand($csfactor) < 1 && $opp ne $primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $rps{$opp}{next});
            chanmsg(clog("$u has dealt $opp a Critical Strike! ".duration($gain)." is added to $opp\'s clock."));
            $rps{$opp}{next} += $gain;
            $rps{$opp}{badd} += $gain;
            chanmsg("$opp reaches next level in ".duration($rps{$opp}{next}).".");
        }
        elsif (rand(25) < 1 && $opp ne $primnick && $rps{$u}{level} > 19) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if ($rps{$opp}{item}{$type} > $rps{$u}{item}{$type}) {
                chanmsg(clog("In the fierce battle, $opp dropped their level $rps{$opp}{item}{$type} $type! $u picks ".
                     "it up, tossing their old level $rps{$u}{item}{$type} $type to $opp."));
                my $tempitem = $rps{$u}{item}{$type};
                $rps{$u}{item}{$type}=$rps{$opp}{item}{$type};
                $rps{$opp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($opp eq $primnick)?10:int($rps{$opp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        $rps{$u}{life} -= $ddamage;
        $rps{$u}{next} += $gain;
        $rps{$u}{experience} += $oxp;
        $rps{$opp}{experience} += $xp;
        $rps{$u}{blost} += 1;
        $rps{$opp}{bwon} += 1;
        $rps{$u}{badd} += $gain;
        chanmsg(clog("$u 9[$myroll/$mysum] has challenged $opp 9[$opproll/$oppsum] in combat and lost! ".duration($gain)." is ".
            "added to $u\'s clock. $u gets $oxp XP and $opp gets $xp XP. $u has $rps{$u}{life} life left."));        
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
    }
}

sub exchange_item {
    my $u = shift;
    my $type = shift;
    my $level = shift;
    my $ulevel = $level;
    my $tag = $level;
    chanmsg("$u found a level $level $type! Current $type is level ".$rps{$u}{item}{$type}.", so it seems luck is with $u !!!");
    $rps{$u}{item}{$type} = $level;
}

sub find_item {
    my $u = shift;
    my $level = $rps{$u}{level};
    my $align = $rps{$u}{alignment};
    my $FindAdv = 0;
    my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
    my $type = $items[rand(@items)];
    my $HoldThis = 1;
    my $CountThis = 0;
    my $ItemVal = 0;
    my $ThisItemVal = 0;
    my $AvgSum = itemsum($u,0);
    if ($AvgSum > 9) {
        $AvgSum = int($AvgSum/10);
    }
    if ($align eq "g") {
        $FindAdv = 1;
    }
    if ($align eq "e") {
        $FindAdv = -1;
    }
    if ($level < 15 && int(rand(3-$FindAdv)) < 1) {
        $ItemVal = int(rand(51)+25);
    }
    elsif ($level > 14 && int(rand(4-$FindAdv)) < 1) {
        $ItemVal = int($AvgSum*1.10);
    }
    else {
        chanmsg("$u looked for item upgrade scrolls, but none were found.");
    }
    if ($ItemVal > 0) {
        while ($HoldThis) {
            $type = $items[rand(@items)];
            $CountThis = $CountThis + 1;
            if ($ItemVal > $rps{$u}{item}{$type}) {
                my $tupgrade = 0;
                if ($rps{$u}{upgrade} > 0) {
                    $tupgrade = $rps{$u}{upgrade} * 2;
                    $tupgrade = int(rand($tupgrade) + 1);
                }
                $ThisItemVal  = int(($level/2) + $tupgrade + ($rps{$u}{item}{$type}*1.05) + 1);
                exchange_item($u,$type,$ThisItemVal);
                $HoldThis = "";
            }
            elsif ($CountThis > 3) {
                $ItemVal = -1;
                $HoldThis = "";
            }
        }
    }
    if ($ItemVal < 0) {
        chanmsg("$u found an item upgrade scroll, but it was useless, so it seems luck is against $u !!!");
    }
}

sub find_expert_item {
    my $ThisPlayer = shift;
    if ($rps{$ThisPlayer}{level} > 24) {
        if ($rps{$ThisPlayer}{ExpertItem01} eq "0" || $rps{$ThisPlayer}{ExpertItem02} eq "0" || $rps{$ThisPlayer}{ExpertItem03} eq "0") {
            if (rand(99) < 50) {
                my @ThisItem = sort {$rps{$ThisPlayer}{item}{$b} <=> $rps{$ThisPlayer}{item}{$a}} keys(%{$rps{$ThisPlayer}{item}});
                if ($rps{$ThisPlayer}{ExpertItem01} ne "0") {
                    if ($rps{$ThisPlayer}{ExpertItem02} ne "0") {
                        if ($rps{$ThisPlayer}{ExpertItem03} eq "0") {
                            if (rand(99) < 5) {
                                my @ValidItems = grep (!(/$rps{$ThisPlayer}{ExpertItem01}/ || /$rps{$ThisPlayer}{ExpertItem02}/),@ThisItem);
                                $rps{$ThisPlayer}{ExpertItem03} = $ValidItems[0];
                                chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the third expert knowledge for their $ValidItems[0]!");
                            }
                            else {
                                chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                            }
                        }
                    }
                    else {
                        if (rand(99) < 10) {
                            my @ValidItems = grep (!/$rps{$ThisPlayer}{ExpertItem01}/,@ThisItem);
                            $rps{$ThisPlayer}{ExpertItem02} = $ValidItems[0];
                            chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the second expert knowledge for their $ValidItems[0]!");
                        }
                        else {
                            chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                        }
                    }
                }
                else {
                    if (rand(99) < 15) {
                    $rps{$ThisPlayer}{ExpertItem01} = $ThisItem[0];
                    chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the first expert knowledge for their $ThisItem[0]!");
                    }
                    else {
                        chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                    }
                }
            }
            else {
                chanmsg("The wise old man is taking a break and not watching $ThisPlayer.");
            }
        }
    }
    else {
        chanmsg("The wise old man told $ThisPlayer to reach level 25 before he will observe.");
    }
}

sub moveplayers {
    return unless $lasttime > 1;
    my $onlinecount = grep { $rps{$_}{online} } keys %rps;
    return unless $onlinecount;
    for (my $i=0;$i<$opts{self_clock};++$i) {
        my %positions = ();
        if ($quest{type} == 2 && @{$quest{questers}}) {
            my $allgo = 1;
            for (@{$quest{questers}}) {
                if ($quest{stage}==1) {
                    if ($rps{$_}{pos_x} != $quest{p1}->[0] ||
                        $rps{$_}{pos_y} != $quest{p1}->[1]) {
                        $allgo=0;
                        last();
                    }
                }
                else {
                    if ($rps{$_}{pos_x} != $quest{p2}->[0] ||
                        $rps{$_}{pos_y} != $quest{p2}->[1]) {
                        $allgo=0;
                        last();
                    }
                }
            }
            if ($quest{stage}==1 && $allgo) {
                $quest{stage}=2;
                $allgo=0;
            }
            elsif ($quest{stage} == 2 && $allgo) {
                chanmsg(clog(join(", ",(@{$quest{questers}})[0..$opts{questminplayers}-2]).", ".
                     "and $quest{questers}->[$opts{questminplayers}-1] have completed their ".
                     "journey! 25% of their burden is eliminated and they have a chance to find an item."));
                for (@{$quest{questers}}) {
                    $rps{$_}{next} = int($rps{$_}{next} * .75);
                    find_item($_);
                    find_gold($_);
                    monst_attack($_);
                }
                undef(@{$quest{questers}});
                $quest{qtime} = time() + 3600;
                $quest{type} = 1;
                writequestfile();
            }
            else {
                my(%temp,$player);
                ++@temp{grep { $rps{$_}{online} } keys(%rps)};
                delete(@temp{@{$quest{questers}}});
                while ($player = each(%temp)) {
                    $rps{$player}{pos_x} += int(rand(3))-1;
                    $rps{$player}{pos_y} += int(rand(3))-1;
                    # if player goes over edge, wrap them back around
                    if ($rps{$player}{pos_x} > $opts{mapx}) { $rps{$player}{pos_x}=0; }
                    if ($rps{$player}{pos_y} > $opts{mapy}) { $rps{$player}{pos_y}=0; }
                    if ($rps{$player}{pos_x} < 0) { $rps{$player}{pos_x}=$opts{mapx}; }
                    if ($rps{$player}{pos_y} < 0) { $rps{$player}{pos_y}=$opts{mapy}; }

                    if (exists($positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}) &&
                        !$positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{battled}) {
                        if ($rps{$positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{user}}{admin} &&
                            !$rps{$player}{admin} && rand(100) < 1) {
                            chanmsg("$player encounters ".
                               $positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{user}." and bows humbly.");
                        }
                        if (rand($onlinecount) < 1) {
                            $positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{battled}=1;
                            collision_fight($player,$positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{user});
                        }
                    }
                    else {
                        $positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{battled}=0;
                        $positions{$rps{$player}{pos_x}}{$rps{$player}{pos_y}}{user}=$player;
                    }
                }
                for (@{$quest{questers}}) {
                    if ($quest{stage} == 1) {
                        if (rand(100) < 1) {
                            if ($rps{$_}{pos_x} != $quest{p1}->[0]) {
                                $rps{$_}{pos_x} += ($rps{$_}{pos_x} < $quest{p1}->[0] ? 1 : -1);
                            }
                            if ($rps{$_}{pos_y} != $quest{p1}->[1]) {
                                $rps{$_}{pos_y} += ($rps{$_}{pos_y} < $quest{p1}->[1] ? 1 : -1);
                            }
                        }
                    }
                    elsif ($quest{stage}==2) {
                        if (rand(100) < 1) {
                            if ($rps{$_}{pos_x} != $quest{p2}->[0]) {
                                $rps{$_}{pos_x} += ($rps{$_}{pos_x} < $quest{p2}->[0] ? 1 : -1);
                            }
                            if ($rps{$_}{pos_y} != $quest{p2}->[1]) {
                                $rps{$_}{pos_y} += ($rps{$_}{pos_y} < $quest{p2}->[1] ? 1 : -1);
                            }
                        }
                    }
                }
            }
        }
        else {
            for my $xplayer (keys(%rps)) {
                next unless $rps{$xplayer}{online};
                $rps{$xplayer}{pos_x} += int(rand(3))-1;
                $rps{$xplayer}{pos_y} += int(rand(3))-1;
                if ($rps{$xplayer}{pos_x} > $opts{mapx}) { $rps{$xplayer}{pos_x} = 0; }
                if ($rps{$xplayer}{pos_y} > $opts{mapy}) { $rps{$xplayer}{pos_y} = 0; }
                if ($rps{$xplayer}{pos_x} < 0) { $rps{$xplayer}{pos_x} = $opts{mapx}; }
                if ($rps{$xplayer}{pos_y} < 0) { $rps{$xplayer}{pos_y} = $opts{mapy}; }
                if (exists($positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}) &&
                    !$positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{battled}) {
                    if ($rps{$positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{user}}{admin} &&
                        !$rps{$xplayer}{admin} && rand(100) < 1) {
                        chanmsg("$xplayer encounters ".
                           $positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{user}." and bows humbly.");
                    }
                    if (rand($onlinecount) < 1) {
                        $positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{battled}=1;
                        collision_fight($xplayer,$positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{user});
                    }
                }
                else {
                    $positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{battled}=0;
                    $positions{$rps{$xplayer}{pos_x}}{$rps{$xplayer}{pos_y}}{user}=$xplayer;
                }
            }
        }
    }
}

sub mksalt { # passwds
    join '',('a'..'z','A'..'Z','0'..'9','/','.')[rand(64), rand(64)];
}

sub chanmsg {
    my $msg = shift or return undef;
    if ($silentmode & 1) { return undef; }
    privmsg($msg, $opts{botchan}, shift);
}

sub privmsg {
    my $msg = shift or return undef;
    my $target = shift or return undef;
    my $force = shift;
    if (($silentmode == 3 || ($target !~ /^[\+\&\#]/ && $silentmode == 2))
        && !$force) {
        return undef;
    }
    while (length($msg)) {
        sts("PRIVMSG $target :".substr($msg,0,450),$force);
        substr($msg,0,450)="";
    }
}

sub notice {
    my $msg = shift or return undef;
    my $target = shift or return undef;
    my $force = shift;
    if (($silentmode == 3 || ($target !~ /^[\+\&\#]/ && $silentmode == 2))
        && !$force) {
        return undef;
    }
    while (length($msg)) {
        sts("NOTICE $target :".substr($msg,0,450),$force);
        substr($msg,0,450)="";
    }
}

sub itemsum {
    my $user = shift;
    my $battle = shift;
    $battle = 1;
    return -1 unless defined $user;
    my $sum = 0;
    my $ExpertItemBonus = 0;
    my $ExpertItemType;
    if ($user eq $primnick) {
        return $sum+1;
    }
    if ($rps{$user}{ExpertItem01} ne "0") {
        $ExpertItemType = $rps{$user}{ExpertItem01};
        $ExpertItemBonus = $ExpertItemBonus + int($rps{$user}{item}{$ExpertItemType} * .1);
    }
    if ($rps{$user}{ExpertItem02} ne "0") {
        $ExpertItemType = $rps{$user}{ExpertItem02};
        $ExpertItemBonus = $ExpertItemBonus + int($rps{$user}{item}{$ExpertItemType} * .1);
    }
    if ($rps{$user}{ExpertItem03} ne "0") {
        $ExpertItemType = $rps{$user}{ExpertItem03};
        $ExpertItemBonus = $ExpertItemBonus + int($rps{$user}{item}{$ExpertItemType} * .1);
    }
    if (!exists($rps{$user})) { return -1; }
    $sum += $rps{$user}{item}{$_} for keys(%{$rps{$user}{item}});
    $sum = $sum + $ExpertItemBonus;
    return $sum;
}

sub daemonize() {
    if ($^O eq "MSWin32") {
        print debug("Nevermind, this is Win32, no I'm not.")."\n";
        return;
    }
    use POSIX 'setsid';
    $SIG{CHLD} = sub { };
    fork() && exit(0);
    POSIX::setsid() || debug("POSIX::setsid() failed: $!",1);
    $SIG{CHLD} = sub { };
    fork() && exit(0);
    $SIG{CHLD} = sub { };
    open(STDIN,'/dev/null') || debug("Cannot read /dev/null: $!",1);
    open(STDOUT,'>/dev/null') || debug("Cannot write to /dev/null: $!",1);
    open(STDERR,'>/dev/null') || debug("Cannot write to /dev/null: $!",1);
    open(PIDFILE,">$opts{pidfile}") || do {
        debug("Error: failed opening pid file: $!");
        return;
    };
    print PIDFILE $$;
    close(PIDFILE);
}

sub calamity {
    my @players = grep { $rps{$_}{online} } keys(%rps);
    return unless @players;
    my $player = $players[rand(@players)];
    if (rand(4) < 1) {
        my @items = ("amulet","boots","charm","gloves","helm","leggings","ring","shield","tunic","weapon");
        my $type = $items[rand(@items)];
        if ($type eq "amulet") {
            chanmsg(clog("$player fell, chipping the stone in their amulet! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "boots") {
            chanmsg(clog("$player stepped in some dragon shit! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "charm") {
            chanmsg(clog("$player slipped and dropped their charm in a dirty bog! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "gloves") {
            chanmsg(clog("$player tried to pick up some green slime! $player\'s $type loses 10% effectiveness."));
        }        
        elsif ($type eq "helm") {
            chanmsg(clog("$player needs a haircut! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "leggings") {
            chanmsg(clog("$player burned a hole through their leggings while ironing! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "ring") {
            chanmsg(clog("$player scratched their ring! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "shield") {
            chanmsg(clog("$player\'s shield was damaged while polishing it $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "tunic") {
            chanmsg(clog("$player spilled a level 7 shrinking potion on their tunic! $player\'s $type loses 10% effectiveness."));
        }        
        else {
            chanmsg(clog("$player left their weapon out in the rain to rust! $player\'s $type loses 10% effectiveness."));
        }        
        my $suffix="";
        if ($rps{$player}{item}{$type} =~ /(\D)$/) { $suffix=$1; }
        $rps{$player}{item}{$type} = int($rps{$player}{item}{$type} * .9);
        $rps{$player}{item}{$type}.=$suffix;
    }
    else {
        my $time = int(int(5 + rand(8)) / 100 * $rps{$player}{next});
        if (!open(Q,$opts{eventsfile})) {
            return chanmsg("ERROR: Failed to open $opts{eventsfile}: $!");
        }
        my($i,$actioned);
        while (my $line = <Q>) {
            chomp($line);
            if ($line =~ /^C (.*)/ && rand(++$i) < 1) { $actioned = $1; }
        }
        close(Q) or do {
            return chanmsg("ERROR: Failed to close $opts{eventsfile}: $!");
        };
        chanmsg(clog("$player $actioned !!! This terrible calamity has slowed them ".duration($time)." from level ".($rps{$player}{level}+1)."."));
        $rps{$player}{next} += $time;
        chanmsg("$player reaches next level in ".duration($rps{$player}{next}).".");
    }
}

sub godsend {
    my @players = grep { $rps{$_}{online} } keys(%rps);
    return unless @players;
    my $player = $players[rand(@players)];
    if (rand(4) < 1) {
        my @items = ("amulet","boots","charm","gloves","helm","leggings","ring","shield","tunic","weapon");
        my $type = $items[rand(@items)];
        if ($type eq "amulet") {
            chanmsg(clog("$player\'s amulet was blessed by a passing cleric! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "boots") {
            chanmsg(clog("$player\'s boots were shined! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "charm") {
            chanmsg(clog("$player\'s charm ate a bolt of lightning! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "gloves") {
            chanmsg(clog("The local wizard imbued $player\'s gloves with dragon claw powder! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "helm") {
            chanmsg(clog("The blacksmith added an MP3 player to $player\'s helm! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "leggings") {
            chanmsg(clog("$player\'s $type were dry cleaned...finally! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "ring") {
            chanmsg(clog("$player had the gem in their ring reset! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "shield") {
            chanmsg(clog("$player reinforced their shield with dragon scales! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "tunic") {
            chanmsg(clog("A magician cast a spell of Rigidity on $player\'s tunic! $player\'s $type gains 10% effectiveness."));
        }        
        else {
            chanmsg(clog("$player sharpened the edge of their weapon! $player\'s $type gains 10% effectiveness."));
        }
        my $suffix="";
        if ($rps{$player}{item}{$type} =~ /(\D)$/) { $suffix=$1; }
        $rps{$player}{item}{$type} = int($rps{$player}{item}{$type} * 1.1);
        $rps{$player}{item}{$type}.=$suffix;
    }
    else {
        my $time = int(int(5 + rand(8)) / 100 * $rps{$player}{next});
        my $actioned;
        if (!open(Q,$opts{eventsfile})) {
            return chanmsg("ERROR: Failed to open $opts{eventsfile}: $!");
        }
        my $i;
        while (my $line = <Q>) {
            chomp($line);
            if ($line =~ /^G (.*)/ && rand(++$i) < 1) {
                $actioned = $1;
            }
        }
        close(Q) or do {
            return chanmsg("ERROR: Failed to close $opts{eventsfile}: $!");
        };
        chanmsg(clog("$player $actioned !!! This moves them ".duration($time)." closer towards level ".($rps{$player}{level}+1)."."));
        $rps{$player}{next} -= $time;
        chanmsg("$player reaches next level in ".duration($rps{$player}{next}).".");
    }
}

sub quest {
    @{$quest{questers}} = grep { $rps{$_}{online} && $rps{$_}{level} > $opts{questminlevel} && time()-$rps{$_}{last_login}>3600 } keys(%rps);
    if (@{$quest{questers}} < $opts{questplayers}) { return undef(@{$quest{questers}}); }
    while (@{$quest{questers}} > $opts{questplayers}) {
        splice(@{$quest{questers}},int(rand(@{$quest{questers}})),1);
    }
    if (!open(Q,$opts{eventsfile})) {
        return chanmsg("ERROR: Failed to open $opts{eventsfile}: $!");
    }
    my $i;
    while (my $line = <Q>) {
        chomp($line);
        if ($line =~ /^Q/ && rand(++$i) < 1) {
            if ($line =~ /^Q1 (.*)/) {
                $quest{text} = $1;
                $quest{type} = 1;
                $quest{qtime} = time() + 21600 + int(rand(21601));
            }
            elsif ($line =~ /^Q2 (\d+) (\d+) (\d+) (\d+) (.*)/) {
                $quest{p1} = [$1,$2];
                $quest{p2} = [$3,$4];
                $quest{text} = $5;
                $quest{type} = 2;
                $quest{stage} = 1;
            }
        }
    }
    close(Q) or do {
        return chanmsg("ERROR: Failed to close $opts{eventsfile}: $!");
    };
    if ($quest{type} == 1) {
        chanmsg(join(", ",(@{$quest{questers}})[0..$opts{questplayers}-2]).", and $quest{questers}->[$opts{questplayers}-1] have been chosen to ".
                "$quest{text}. Quest to end in ".duration($quest{qtime}-time()).".");
    }
    elsif ($quest{type} == 2) {
        chanmsg(join(", ",(@{$quest{questers}})[0..$opts{questplayers}-2]).", and $quest{questers}->[$opts{questplayers}-1] have been chosen to ".
                "$quest{text}. Participants must first reach [$quest{p1}->[0],$quest{p1}->[1]], then [$quest{p2}->[0],$quest{p2}->[1]].".
                ($opts{mapurl}?" See $opts{mapurl} to monitor their journey's progress.":""));
    }
    writequestfile();
}

sub questpencheck {
    my $k = shift;
    my ($quester,$player);
    for $quester (@{$quest{questers}}) {
        if ($quester eq $k) {
            chanmsg(clog("$k has ruined the quest. One day will be added to $k\'s TTL!"));
            $rps{$k}{next} += 86400;
            undef(@{$quest{questers}});
            $quest{qtime} = time() + 7200;
            writequestfile();
            last;
        }
    }
    #If someone gets a penalty during a tourny, then the tourny is restarted.
    for my $tourney (@tournament) {
       if ($tourney eq $k) {
          chanmsg("$k has left so the 5Top Players Battle will be restarted in 1 minute.");
          undef @tournament;
          $tournamenttime = time() + 60;
          penalize($k,"tourney");
       }
    }
    for my $DMtourney (@deathmatch) {
       if ($DMtourney eq $k) {
          chanmsg("$k has left so the 6Death Match will be restarted in 1 minute.");
          undef @deathmatch;
          $deathmatchtime = time() + 60;
          penalize($k,"DMtourney");
       }
    }
    for my $MWtourney (@megawar) {
       if ($MWtourney eq $k) {
          chanmsg("$k has left so the 7Champions League will be restarted in 1 minute.");
          undef @megawar;
          $megawartime = time() + 60;
          penalize($k,"MWtourney");
       }
    }
    for my $PWtourney (@powerwar) {
       if ($PWtourney eq $k) {
          chanmsg("$k has left so the 12Power War will be restarted in 1 minute.");
          undef @powerwar;
          $powerwartime = time() + 60;
          penalize($k,"PWtourney");
        }
     }
     for my $AWtourney (@abilitywar) {
       if ($AWtourney eq $k) {
          chanmsg("$k has left so the 3Ability Battle will be restarted in 1 minute.");
          undef @abilitywar;
          $abilitywartime = time() + 60;
          penalize($k,"AWtourney");
        }
     }
     for my $LWtourney (@locationwar) {
       if ($LWtourney eq $k) {
          chanmsg("$k has left so the 13Location Battle will be restarted in 1 minute.");
          undef @locationwar;
          $locationwartime = time() + 60;
          penalize($k,"LWtourney");
        }
     }
     for my $ALWtourney (@alignwar) {
       if ($ALWtourney eq $k) {
          chanmsg("$k has left so the 14Alignment Battle will be restarted in 1 minute.");
          undef @alignwar;
          $alignwartime = time() + 60;
          penalize($k,"ALWtourney");
        }
     }
}

sub clog {
    my $mesg = shift;
    open(B,">>$opts{modsfile}") or do {
        chanmsg("Error: Cannot open $opts{modsfile}: $!");
        return $mesg;
    };
    print B ts()."$mesg\n";
    close(B);
    return $mesg;
}

sub penalize {
    my $username = shift;
    return 0 if !defined($username);
    return 0 if !exists($rps{$username});
    my $type = shift;
    my $pen = 0;
    questpencheck($username);
    if ($type eq "tourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving the 5Top Players Battle.");
    }
    if ($type eq "DMtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 6Death Match.");
    }
    if ($type eq "MWtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 7Champions League.");
    }
    if ($type eq "PWtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 12Power War".
             "$username just lost 5 points at each item." );
              $rps{$username}{item}{amulet} -= 5;
              $rps{$username}{item}{boots} -= 5;
              $rps{$username}{item}{charm} -= 5;
              $rps{$username}{item}{gloves} -= 5;
              $rps{$username}{item}{helm} -= 5;
              $rps{$username}{item}{leggings} -= 5;
              $rps{$username}{item}{ring} -= 5;
              $rps{$username}{item}{shield} -= 5;
              $rps{$username}{item}{tunic} -= 5;
              $rps{$username}{item}{weapon} -= 5;
    }
    if ($type eq "AWtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 3Ability Battle.");
    }
    if ($type eq "LWtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 13Location Battle.");
    }
    if ($type eq "ALWtourney") {
        $pen = int(300 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for leaving The 14Alignment Battle.");
    }

    if ($type eq "quit") {
        $pen = int(20 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{pen_quit}+=$pen;
        $rps{$username}{next}+=$pen;
        $rps{$username}{online}=0;
          chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for quitting.");
    }
    elsif ($type eq "nick") {
        my $newnick = shift;
        $pen = int(30 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{pen_nick}+=$pen;
        $rps{$username}{next}+=$pen;
        $rps{$username}{nick} = substr($newnick,1);
        $rps{$username}{userhost} =~ s/^[^!]+/$rps{$username}{nick}/e;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for nick change.");
    }
    elsif ($type eq "privmsg" || $type eq "notice") {
        $pen = int(shift(@_) * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{pen_mesg}+=$pen;
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for $type.");
    }
    elsif ($type eq "part") {
        $pen = int(200 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{pen_part}+=$pen;
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for parting.");
        $rps{$username}{online}=0;
    }
    elsif ($type eq "kick") {
        $pen = int(250 * penttl($rps{$username}{level}) / $opts{rpbase});
        if ($opts{limitpen} && $pen > $opts{limitpen}) {
            $pen = $opts{limitpen};
        }
        $rps{$username}{pen_kick}+=$pen;
        $rps{$username}{next}+=$pen;
        chanmsg("4Penalty of ".duration($pen)." added to ".$username."'s TTL for being kicked.");
        $rps{$username}{online}=0;
    }
    elsif ($type eq "logout") {
        chanmsg("$username has logged out.");
        $rps{$username}{online}=0;
        if ($opts{voiceonlogin}) {
            sts("MODE $opts{botchan} -v :$rps{$username}{nick}");
        }
    }
    return 1;
}

sub debug {
    (my $text = shift) =~ s/[\r\n]//g;
    my $die = shift;
    if ($opts{debug} || $opts{verbose}) {
        open(DBG,">>$opts{debugfile}") or do {
            chanmsg("Error: Cannot open debug file: $!");
            return;
        };
        print DBG ts()."$text\n";
        close(DBG);
    }
    if ($die) { die("$text\n"); }
    return $text;
}

sub finduser {
    my $nick = shift;
    return undef if !defined($nick);
    for my $user (keys(%rps)) {
        next unless $rps{$user}{online};
        if ($rps{$user}{nick} eq $nick) { return $user; }
    }
    return undef;
}

sub ha {
    my $user = shift;
    if (!defined($user)) {
        return 0;
    }
    if (!exists($rps{$user})) {
        return 0;
    }
    return $rps{$user}{admin};
}

sub checksplits {
    my $host;
    while ($host = each(%split)) {
        if (time()-$split{$host}{time} > $opts{splitwait}) {
            $rps{$split{$host}{account}}{online} = 0;
            delete($split{$host});
        }
    }
}

sub collision_fight {
    my($u,$opp) = @_;
    my $mysum = int((itemsum($u,1)+($rps{$u}{upgrade}*100))*($rps{$u}{life}/100));
    my $oppsum = int((itemsum($opp,1)+($rps{$opp}{upgrade}*100))*($rps{$opp}{life}/100));
    my $myroll = int(rand($mysum));
    my $opproll = int(rand($oppsum));
    my $xp = int(rand(4)+1);
    my $oxp = int(rand(2)+1);
    my $adamage = 0;
    my $ddamage = 0;
    if($rps{$opp}{life} > 10) {
        $adamage = int(rand(4)+1);
    }
    if($rps{$u}{life} > 10) {
        $ddamage = int(rand(4)+1);
    }
    if ($myroll >= $opproll) {
        my $gain = int($rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        $rps{$opp}{life} -= $adamage;
        chanmsg(clog("$u 9[$myroll/$mysum] has come upon $opp 9[$opproll/$oppsum] and taken them in combat! ".duration($gain)." is ".
            "removed from $u\'s clock. $u gets $xp XP and $opp gets $oxp XP. $opp has $rps{$opp}{life} life left."));
        $rps{$u}{next} -= $gain;
        $rps{$u}{experience} += $xp;
        $rps{$opp}{experience} += $oxp;
        $rps{$u}{bwon} += 1;
        $rps{$opp}{blost} += 1;
        $rps{$u}{bminus} += $gain;
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
        if (rand(35) < 1 && $opp ne $primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $rps{$opp}{next});
            chanmsg(clog("$u has dealt $opp a Critical Strike! ".duration($gain)." is added to $opp\'s clock."));
            $rps{$opp}{next} += $gain;
            $rps{$opp}{badd} += $gain;
            chanmsg("$opp reaches next level in ".duration($rps{$opp}{next}).".");
        }
        elsif (rand(25) < 1 && $opp ne $primnick && $rps{$u}{level} > 19) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");

            my $type = $items[rand(@items)];
            if ($rps{$opp}{item}{$type} > $rps{$u}{item}{$type}) {
                chanmsg("In the fierce battle, $opp dropped their level ".$rps{$opp}{item}{$type}." $type! $u picks it up, ".
                    "tossing their old level ".$rps{$u}{item}{$type}." $type to $opp.");
                my $tempitem = $rps{$u}{item}{$type};
                $rps{$u}{item}{$type}=$rps{$opp}{item}{$type};
                $rps{$opp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($opp eq $primnick)?10:int($rps{$opp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$u}{next});
        $rps{$u}{life} -= $ddamage;
        chanmsg(clog("$u 9[$myroll/$mysum] has come upon $opp 9[$opproll/$oppsum] and been defeated in combat! ".duration($gain)." is ".
            "added to $u\'s clock. $u gets $oxp XP and $opp gets $xp XP. $u has $rps{$u}{life} life left."));
        $rps{$u}{next} += $gain;
        $rps{$u}{experience} += $oxp;
        $rps{$opp}{experience} += $xp;
        $rps{$u}{blost} += 1;
        $rps{$opp}{bwon} += 1;
        $rps{$u}{badd} += $gain;
        chanmsg("$u reaches next level in ".duration($rps{$u}{next}).".");
    }
}

sub writequestfile {
    return unless $opts{writequestfile};
    open(QF,">$opts{questfilename}") or do {
        chanmsg("Error: Cannot open $opts{questfilename}: $!");
        return;
    };
    if (@{$quest{questers}}) {
        if ($quest{type}==1) {
            print QF "T $quest{text}\n".
                     "Y 1\n".
                     "S $quest{qtime}\n";

            for (my $i=0; $i<$opts{questplayers}; $i++) {
                last if($i > $#{$quest{questers}} || !$quest{questers}->[$i]);

                my $n = $i+1;

                print QF "P$n $quest{questers}->[$i]\n";
            }
        }
        elsif ($quest{type} == 2) {
            print QF "T $quest{text}\n".
                     "Y 2\n".
                     "S $quest{stage}\n".
                     "P $quest{p1}->[0] $quest{p1}->[1] $quest{p2}->[0] $quest{p2}->[1]\n";

            for (my $i=0; $i<$opts{questplayers}; $i++) {
                last if($i > $#{$quest{questers}} || !$quest{questers}->[$i]);

                my $n = $i+1;

                print QF "P$n $quest{questers}->[$i] $rps{$quest{questers}->[$i]}{pos_x} $rps{$quest{questers}->[$i]}{pos_y}\n";
            }
        }
    }
    close(QF) or do {
        chanmsg("Error: Cannot close $opts{questfilename}: $!");
    };
}

sub loadquestfile {
    return unless ($opts{writequestfile} && -e $opts{questfilename});
    open(QF,$opts{questfilename}) or do {
        chanmsg("Error: Cannot open $opts{questfilename}: $!");
        return;
    };
    my %questdata = ();
    while (my $line = <QF>) {
        chomp $line;
        my ($tag,$data) = split(/ /,$line,2);
        $questdata{$tag} = $data;
        debug("loadquestfile(): questdata: $tag = $data\r\n");
    }
    return unless defined($questdata{Y});
    $quest{text} = $questdata{T};
    $quest{type} = $questdata{Y};
    if ($quest{type} == 1) {
        $quest{qtime} = $questdata{S};
    }
    else {
        $quest{stage} = $questdata{S};
        my ($p1x,$p1y,$p2x,$p2y) = split(/ /,$questdata{P});
        $quest{p1}->[0] = $p1x;
        $quest{p1}->[1] = $p1y;
        $quest{p2}->[0] = $p2x;
        $quest{p2}->[1] = $p2y;
    }
    for my $i (0..$opts{questplayers}-1) {
        last if($i > $#{$quest{questers}} || !$quest{questers}->[$i]);

        ($quest{questers}->[$i],) = split(/ /,$questdata{'P'.($i+1)},2);
        debug("loadquestfile(): quester $i = $rps{$quest{questers}->[$i]}{online}\r\n");
        if (!$rps{$quest{questers}->[$i]}{online}) {
            undef(@{$quest{questers}});
            last;
        }
    }
    close(QF) or do {
        chanmsg("Error: Cannot close $opts{questfilename}: $!");
    };
    writequestfile();
}

sub goodness {
    my @players = grep { ($rps{$_}{alignment} eq "g" || 0) && $rps{$_}{online} } keys(%rps);
    return unless @players > 1;
    splice(@players,int(rand(@players)),1) while @players > 2;
    my $gain = 5 + int(rand(8));
    chanmsg(clog("$players[0] and $players[1] have prayed so $gain\% of their time is removed from their clocks."));
    $rps{$players[0]}{next} = int($rps{$players[0]}{next}*(1 - ($gain/100)));
    $rps{$players[1]}{next} = int($rps{$players[1]}{next}*(1 - ($gain/100)));
    chanmsg("$players[0] reaches next level in ".duration($rps{$players[0]}{next}).".");
    chanmsg("$players[1] reaches next level in ".duration($rps{$players[1]}{next}).".");
}

sub evilness {
    my $ThisEvil = shift;
    my $me;
    if ($ThisEvil) {
        $me = $ThisEvil;
    }
    else {
        my @evil = grep { $rps{$_}{online} && $rps{$_}{alignment} eq "e" } keys(%rps);
        return unless @evil;
        $me = $evil[rand(@evil)];
    }    
    if (int(rand(3)) < 1) {
        # evil only steals items from good or evil (but not themselves)
        my @players = grep { $rps{$_}{online} && ($rps{$_}{alignment} eq "g" || $rps{$_}{alignment} eq "e") && $_ ne $me } keys(%rps);
        if (@players > 0) {
            my $target = $players[rand(@players)];
            my $type;
            if ($rps{$target}{gold} > 150) {
                my $ThisValue = int($rps{$target}{gold} * .05);
                $rps{$me}{gold} += $ThisValue;
                $rps{$target}{gold} -= $ThisValue;
                chanmsg(clog("$me stole $ThisValue gold from $target!"));
            }
            elsif ($rps{$target}{gems} > 15) {
                my $ThisValue = int($rps{$target}{gems} * .05);
                if ($ThisValue < 1) {$ThisValue = 1;}
                $rps{$me}{gems} += $ThisValue;
                $rps{$target}{gems} -= $ThisValue;
                chanmsg(clog("$me stole $ThisValue gems from $target!"));
            }
        }
    }    
    elsif (int(rand(4)) < 1) {
        # evil only steals items from good or evil (but not themselves)
        my @players = grep { $rps{$_}{online} && ($rps{$_}{alignment} eq "g" || $rps{$_}{alignment} eq "e") && $_ ne $me } keys(%rps);
        if (@players > 0) {
            my $target = $players[rand(@players)];
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if ($rps{$target}{item}{$type} > $rps{$me}{item}{$type}) {
                my $tempitemamount = int($rps{$target}{item}{$type} * ((rand(40) + 10) / 100));
                $rps{$me}{item}{$type} += $tempitemamount;
                $rps{$target}{item}{$type} -= $tempitemamount;
                chanmsg(clog("$me stole an upgrade scroll from $target worth $tempitemamount points from their $type."));
            }
            else {
                chanmsg("$me stole $target\'s $type, but it was lower level than $me\'s own. $me returns the $type.");
            }
        }
    }
    else {
        my $gain = 1 + int(rand(5));
        chanmsg(clog("$me was caught stealing, however, they still get 5 XP for trying."));
        $rps{$me}{experience} += 5;
    }
}

sub evilnessOffline {
    my $ThisEvil = shift;
    my $me;
    if ($ThisEvil) {
        $me = $ThisEvil;
    }
    else {
        my @evil = grep {$rps{$_}{online} && $rps{$_}{alignment} eq "e"} keys(%rps);
        return unless @evil;
        $me = $evil[rand(@evil)];
    }
    if (int(rand(2)) < 1) {
        my @Offline = grep {!$rps{$_}{online} && ($rps{$_}{last_login} < time() - 86400)} keys(%rps);
        my $target = $Offline[rand(@Offline)];
        my @items = ("gold","gems");
        my $type = $items[rand(@items)];
        if ($rps{$target}{$type} > 0) {
            my $ThisValue = int($rps{$target}{$type} * .25);
            if ($ThisValue > 0) {
                $rps{$me}{$type} += $ThisValue;
                $rps{$target}{$type} -= $ThisValue;
            }
            else {
                $ThisValue = $rps{$target}{$type};
                $rps{$me}{$type} += $ThisValue;                
                $rps{$target}{$type} = 0;
            }
            chanmsg(clog("$me stole $ThisValue $type from $target while they were offline"));
        }
    }
}

sub chansay1 {
#    sts("notice $opts{botchan} : New game on Deja (irc.dejatoons.net) starting the morning of July 26 or 27.");
}

sub AutoHeal {    
    my @NeedLife;
    my $Healed = "";
    my $factor = 0;
    my $pay = 0;
    if ($IsWinner == 0) {
        @NeedLife = grep { $rps{$_}{online} && $rps{$_}{level} > 15 && $rps{$_}{life} < 15 && $rps{$_}{life} > 0 } keys %rps;
        if (@NeedLife > 0) {
            for my $i (0..$#NeedLife) {
                $factor = int($rps{$NeedLife[$i]}{level}/5);
                $pay = int((100-$rps{$NeedLife[$i]}{life})*$factor*1.1);
                if ($rps{$NeedLife[$i]}{gold} > ($pay*2)) {
                    $rps{$NeedLife[$i]}{gold} -= $pay;
                    $rps{$NeedLife[$i]}{life} = 100;
                    $Healed = $Healed . $NeedLife[$i] . ", ";
                }
            }
            if (!$Healed eq "") {
                $Healed = substr($Healed, 0,length($Healed)-2);
                chanmsg("The wandering healer has healed: $Healed for some profit. They could save gold by healing themself.");
            }
        }
        @NeedLife = grep { $rps{$_}{online} && $rps{$_}{level} > 15 && $rps{$_}{life} < 15 && $rps{$_}{life} < 0 } keys %rps;
        if (@NeedLife > 0) {
            for my $i (0..$#NeedLife) {
                $pay = 20;
                if ($rps{$NeedLife[$i]}{gold} > ($pay)) {
                    $rps{$NeedLife[$i]}{gold} -= $pay;
                    $rps{$NeedLife[$i]}{life} = 1;
                    $Healed = $Healed . $NeedLife[$i] . ", ";
                }
            }
            if (!$Healed eq "") {
                $Healed = substr($Healed, 0,length($Healed)-2);
                chanmsg("The wandering healer resurrected: $Healed for some profit. They could save gold by healing themself.");
            }
        }
    }
}

sub tournament {
  return if !$opts{tournament};
  my $TournyAmt = 0;
  my %u = grep { $rps{$_}{online} &&  $rps{$_}{level} > 15 &&  $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
           $rps{$_}{bt} < time() && time() -  $rps{$_}{last_login} > 3600 } keys(%rps);
  if(%u > 1) {
    @tournament = sort { $rps{$b}{level} <=> $rps{$a}{level} || $rps{$a}{next} <=> $rps{$b}{next} } keys %u;
    if ($TournyLvl == 32) {
      if (@tournament < 32) {
          if (@tournament < 16) {
                  if (@tournament < 8) {
                      if (@tournament < 4) {
                          $TournyAmt = 2;
                      }
                      else {
                          $TournyAmt = 4;
                      }
                  }
                  else {
                      $TournyAmt = 8;
                  }
              }
              else {
                  $TournyAmt = 16;
              }
          }
          else {
              $TournyAmt = 32;
          }
    }
    else {
          if (@tournament < 16) {
              if (@tournament < 8) {
                  if (@tournament < 4) {
                      $TournyAmt = 2;
                  }
                  else {
                      $TournyAmt = 4;
                  }
              }
              else {
                  $TournyAmt = 8;
              }
          }
          else {
              $TournyAmt = 16;
          }
    }
    splice(@tournament,int rand @tournament,1) while @tournament > $TournyAmt;
          
    chanmsg(join(", ",@tournament)." have been chosen to participate in the 5Top Players Battle.");       
    $round = 1;
    $battle = 1;
    fisher_yates_shuffle( \@tournament );
    $tournamenttime = time() + 40;
  }
}

sub deathmatch {
  return if !$opts{deathmatch};
  @deathmatch = grep { $rps{$_}{online} && $rps{$_}{level} > 25 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{tt} < time() && time()-$rps{$_}{last_login} > 3600 } keys %rps;
  if (@deathmatch < $TournyLvl) {
     $deathmatchtime = time() + 14400;
     return undef @deathmatch;
   }
  splice(@deathmatch,int rand @deathmatch,1) while @deathmatch > $TournyLvl;
  chanmsg(join(", ",@deathmatch)." have been chosen to participate in the 6Death Match.");
  $sess = 1;
  $scuff = 1;
  fisher_yates_shuffle( \@deathmatch );
  $deathmatchtime = time() + 40;
}

sub megawar {
  return if !$opts{megawar};
  @megawar = grep { $rps{$_}{online} && $rps{$_}{level} > 25 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{tt} < time() && time()-$rps{$_}{last_login} > 3600 } keys %rps;
  if (@megawar < $TournyLvl) {
     $megawartime = time() + 10800;
     return undef @megawar;
   }
  splice(@megawar,int rand @megawar,1) while @megawar > $TournyLvl;
  chanmsg(join(", ",@megawar)." have been chosen to participate in the 7Champions League.");
  $runda = 1;
  $lupta = 1;
  fisher_yates_shuffle( \@megawar );
  $megawartime = time() + 40;
}

sub powerwar {
  return if !$opts{powerwar};
  @powerwar = grep { $rps{$_}{online} && $rps{$_}{level} > 25 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{tt} < time() && time()-$rps{$_}{last_login} > 3600 } keys %rps;
  if (@powerwar < $TournyLvl) {
     $powerwartime = time() + 36000;
     return undef @powerwar;
   }
  splice(@powerwar,int rand @powerwar,1) while @powerwar > $TournyLvl;
  chanmsg(join(", ",@powerwar)." have been chosen to participate in the 12Power War.");
  $play = 1;
  $game = 1;
  fisher_yates_shuffle( \@powerwar );
  $powerwartime = time() + 40;
}

sub abilitywar {
  return if !$opts{abilitywar};
  my @Abilities = ("b","p","w","r");
  my $ThisAbility = $Abilities[rand(@Abilities)];
  @abilitywar = grep { $rps{$_}{online} && $rps{$_}{level} > 15 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{bt} < time() && time()-$rps{$_}{last_login} > 3600 && $rps{$_}{ability} eq $ThisAbility} keys %rps;
    
  my $TournyAmt = $TournyLvl;
  if (@abilitywar < 32) {
        if (@abilitywar < 16) {
            if (@abilitywar < 8) {
                if (@abilitywar < 4) {
                    if (@abilitywar < 2) {
                        $abilitywartime = time() + 5400 + int(rand(3600));
                        return undef @abilitywar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }
   
  splice(@abilitywar,int rand @abilitywar,1) while @abilitywar > $TournyAmt;
   if ($ThisAbility eq BARBARIAN) {
    $ThisAbility = "Barbarian";
   }
   elsif ($ThisAbility eq PALADIN) {
    $ThisAbility = "Paladin";
   }
   elsif ($ThisAbility eq WIZARD) {
    $ThisAbility = "Wizard";
   }
   elsif ($ThisAbility eq ROGUE) {
    $ThisAbility = "Rogue";
   }
  chanmsg(join(", ",@abilitywar)." have been chosen to participate in the 3Ability Battle - $ThisAbility.");
  $playAW = 1;
  $gameAW = 1;
  fisher_yates_shuffle( \@abilitywar );
  $abilitywartime = time() + 40;
}

sub locationwar {
  return if !$opts{locationwar};
  my @Locations = (TOWN, WORK, FOREST);
  my $ThisLocation = $Locations[rand(@Locations)];
  @locationwar = grep { $rps{$_}{online} && $rps{$_}{level} > 15 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{bt} < time() && time()-$rps{$_}{last_login} > 3600 && $rps{$_}{status} == $ThisLocation } keys %rps;
    
  my $TournyAmt = $TournyLvl;
  if (@locationwar < 32) {
        if (@locationwar < 16) {
            if (@locationwar < 8) {
                if (@locationwar < 4) {
                    if (@locationwar < 2) {
                        $locationwartime = time() + 5400 + int(rand(3600));
                        return undef @locationwar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }
   
  splice(@locationwar,int rand @locationwar,1) while @locationwar > $TournyAmt;
   if ($ThisLocation == TOWN) {
    $ThisLocation = "Town";
   }
   elsif ($ThisLocation == WORK) {
    $ThisLocation = "Work";
   }
   elsif ($ThisLocation == FOREST) {
    $ThisLocation = "Forest";
   }
  chanmsg(join(", ",@locationwar)." have been chosen to participate in the 13Location Battle - $ThisLocation.");
  $playLW = 1;
  $gameLW = 1;
  fisher_yates_shuffle( \@locationwar );
  $locationwartime = time() + 40;
}

sub alignwar {
  return if !$opts{alignwar};
  my @Align = ("g","n","e");
  my $ThisAlign = $Align[rand(@Align)];
  @alignwar = grep { $rps{$_}{online} && $rps{$_}{level} > 15 && $rps{$_}{gold} > 100 && $rps{$_}{life} > 20 &&
    $rps{$_}{bt} < time() && time()-$rps{$_}{last_login} > 3600 && $rps{$_}{alignment} eq $ThisAlign} keys %rps;
    
  my $TournyAmt = $TournyLvl;
  if (@alignwar < 32) {
        if (@alignwar < 16) {
            if (@alignwar < 8) {
                if (@alignwar < 4) {
                    if (@alignwar < 2) {
                        $alignwartime = time() + 5400 + int(rand(3600));
                        return undef @alignwar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }
   
  splice(@alignwar,int rand @alignwar,1) while @alignwar > $TournyAmt;
   if ($ThisAlign eq "g") {
    $ThisAlign = "Good";
   }
   elsif ($ThisAlign eq "n") {
    $ThisAlign = "Neutral";
   }
   elsif ($ThisAlign eq "e") {
    $ThisAlign = "Evil";
   }
  chanmsg(join(", ",@alignwar)." have been chosen to participate in the 14Alignment Battle - $ThisAlign.");
  $playALW = 1;
  $gameALW = 1;
  fisher_yates_shuffle( \@alignwar );
  $alignwartime = time() + 40;
}

sub tournament_battle {
   my $winner;
   my $loser;
   my $p1 = $battle*2-2;
   my $p2 = $p1 + 1;
   my $p1sum = int((itemsum($tournament[$p1],1)+($rps{$tournament[$p1]}{upgrade}*100))*($rps{$tournament[$p1]}{life}/100));
   my $p2sum = int((itemsum($tournament[$p2],1)+($rps{$tournament[$p2]}{upgrade}*100))*($rps{$tournament[$p2]}{life}/100));
   my $p1roll = int(rand($p1sum));
   my $p2roll = int(rand($p2sum));
   if ($p1roll >= $p2roll) {
      $winner = $p1;
      $loser = $p2;
   } else {
      $winner = $p2;
      $loser = $p1;
   }
   chanmsg("5Top Players Battle $round, Fight $battle: $tournament[$p1] ".
      "5[$p1roll/$p1sum] vs $tournament[$p2] 5[$p2roll/$p2sum] ... ".
      "$tournament[$winner] advances and gets 25 gold from $tournament[$loser]! $tournament[$winner] gets 2 XP, ".
      "$tournament[$loser] gets 1 XP and loses 2 life points.");
        $rps{$tournament[$winner]}{gold} += 25;
        $rps{$tournament[$winner]}{experience} += 2;
        $rps{$tournament[$loser]}{experience} += 1;
        $rps{$tournament[$loser]}{life} -= 2;
        $rps{$tournament[$loser]}{gold} -= 25;
   $tournament[$loser] = "xx";
   ++$battle;
   if ($battle > (@tournament / 2)) {
      ++$round;
      $battle = 1;
      my $ucnt = (@tournament - 1);
      while ($ucnt > -1) {
         if ($tournament[$ucnt] eq "xx") {
            splice(@tournament,$ucnt ,1);
         }
         --$ucnt;
      }
      if (@tournament > 1) {
         chanmsg(join(", ",@tournament)." advance to round $round of the 5Top Players Battle.");
      }
      fisher_yates_shuffle( \@tournament );
   }
   if (@tournament == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $rps{$tournament[0]}{next});
      chanmsg(clog("$tournament[0] has won the 5Top Players Battle! As a ".
        "reward, $tournament[0] gets 500 gold, 10 XP and 5 points added to each item!"));
      $rps{$tournament[0]}{item}{amulet} += 5;
      $rps{$tournament[0]}{item}{boots} += 5;
      $rps{$tournament[0]}{item}{charm} += 5;
      $rps{$tournament[0]}{item}{gloves} += 5;
      $rps{$tournament[0]}{item}{helm} += 5;
      $rps{$tournament[0]}{item}{leggings} += 5;
      $rps{$tournament[0]}{item}{ring} += 5;
      $rps{$tournament[0]}{item}{shield} += 5;
      $rps{$tournament[0]}{item}{tunic} += 5;
      $rps{$tournament[0]}{item}{weapon} += 5;
      $rps{$tournament[0]}{rt} += 1;
      $rps{$tournament[0]}{gold} += 500;
      $rps{$tournament[0]}{experience} += 10;
      $rps{$tournament[0]}{bt} = time() + 86400;
      $tournamenttime = time() + 10800 + int(rand(3600));
      undef @tournament;
   }
    else {
      $tournamenttime = time() + 40;
   }
}

sub deathmatch_battle {
   my $winnar;
   my $loser;
   my $SecondPlace;
   my $DMp1 = $scuff*2-2;
   my $DMp2 = $DMp1 + 1;
   my $DMp1sum = int((itemsum($deathmatch[$DMp1],1)+($rps{$deathmatch[$DMp1]}{upgrade}*100))*($rps{$deathmatch[$DMp1]}{life}/100));
   my $DMp2sum = int((itemsum($deathmatch[$DMp2],1)+($rps{$deathmatch[$DMp2]}{upgrade}*100))*($rps{$deathmatch[$DMp2]}{life}/100));
   my $DMp1roll = int(rand($DMp1sum));
   my $DMp2roll = int(rand($DMp2sum));
   if ($DMp1roll >= $DMp2roll) {
      $winnar = $DMp1;
      $loser = $DMp2;
   } else {
      $winnar = $DMp2;
      $loser = $DMp1;
   }
   chanmsg("6Death Match Round $sess, Fight $scuff: $deathmatch[$DMp1] ".
      "6[$DMp1roll/$DMp1sum] vs $deathmatch[$DMp2] 6[$DMp2roll/$DMp2sum] ... ".
      "$deathmatch[$winnar] is victorious and gets 50 gold from $deathmatch[$loser]! ".
      "$deathmatch[$winnar] gets 2 XP, $deathmatch[$loser] gets 1 XP and loses 5 life points.");
        $rps{$deathmatch[$winnar]}{gold} += 50;
        $rps{$deathmatch[$winnar]}{experience} += 2;
        $rps{$deathmatch[$loser]}{experience} += 1;
        $rps{$deathmatch[$loser]}{life} -= 5;
        $rps{$deathmatch[$loser]}{gold} -= 50;
        if (@deathmatch == 2) {
            $SecondPlace = $deathmatch[$loser];
        }
   $deathmatch[$loser] = "xx";
   ++$scuff;
   if ($scuff > (@deathmatch / 2)) {
      ++$sess;
      $scuff = 1;
      my $supunct = (@deathmatch - 1);
      while ($supunct > -1) {
         if ($deathmatch[$supunct] eq "xx") {
            splice(@deathmatch,$supunct ,1);
         }
         --$supunct;
      }
      if (@deathmatch > 1) {
         chanmsg(join(", ",@deathmatch)." progess to round $sess of the 6Death Match.");
      }
      fisher_yates_shuffle( \@deathmatch );
   }
   if (@deathmatch == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $rps{$deathmatch[0]}{next});
      chanmsg(clog("$deathmatch[0] has won the 6Death Match! As a reward, ".
        duration($time)." is removed from TTL $deathmatch[0] gets 30 gems, 30 XP and 3000 gold".
        " and $SecondPlace gets 10 gems, 10 XP and 1000 gold.."));
      $rps{$deathmatch[0]}{next} -= $time;
      $rps{$deathmatch[0]}{gems} += 30;
      $rps{$deathmatch[0]}{gold} += 3000;
      $rps{$deathmatch[0]}{experience} += 30;
      $rps{$SecondPlace}{gems} += 10;
      $rps{$SecondPlace}{gold} += 1000;
      $rps{$SecondPlace}{experience} += 10;
      $rps{$deathmatch[0]}{dm} += 1;
      $rps{$deathmatch[0]}{tt} = time() + 172800;
      $deathmatchtime = time() + 14400;
      undef @deathmatch;
   } else {
      $deathmatchtime = time() + 40;
   }
}

sub megawar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $MWp1 = $lupta*2-2;
   my $MWp2 = $MWp1 + 1;
   my $MWp1sum = int((itemsum($megawar[$MWp1],1)+($rps{$megawar[$MWp1]}{upgrade}*100))*($rps{$megawar[$MWp1]}{life}/100));
   my $MWp2sum = int((itemsum($megawar[$MWp2],1)+($rps{$megawar[$MWp2]}{upgrade}*100))*($rps{$megawar[$MWp2]}{life}/100));
   my $MWp1roll = int(rand($MWp1sum));
   my $MWp2roll = int(rand($MWp2sum));
   if ($MWp1roll >= $MWp2roll) {
      $winner = $MWp1;
      $loser = $MWp2;
   } else {
      $winner = $MWp2;
      $loser = $MWp1;
   }
   chanmsg("7Champions League Round $runda, Fight $lupta: $megawar[$MWp1] ".
      "7[$MWp1roll/$MWp1sum] vs $megawar[$MWp2] 7[$MWp2roll/$MWp2sum] ... ".
      "$megawar[$winner] advances and gets 50 gold from $megawar[$loser]! $megawar[$winner] gets 2 XP, ".
      "$megawar[$loser] gets 1 XP and loses 5 life points.");
        $rps{$megawar[$winner]}{gold} += 50;
        $rps{$megawar[$winner]}{experience} += 2;
        $rps{$megawar[$loser]}{experience} += 1;
        $rps{$megawar[$loser]}{life} -= 5;
        $rps{$megawar[$loser]}{gold} -= 50;
        if (@megawar == 2) {
            $SecondPlace = $megawar[$loser];
        }
   $megawar[$loser] = "xx";
   ++$lupta;
   if ($lupta > (@megawar / 2)) {
      ++$runda;
      $lupta = 1;
      my $ovi = (@megawar - 1);
      while ($ovi > -1) {
         if ($megawar[$ovi] eq "xx") {
            splice(@megawar,$ovi ,1);
         }
         --$ovi;
      }
      if (@megawar > 1) {
         chanmsg(join(", ",@megawar)." advance to round $runda of the 7Champions League.");
      }
      fisher_yates_shuffle( \@megawar );
   }
   if (@megawar == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $rps{$megawar[0]}{next});

      #if ($time > 86400) { $time=86400; }
      chanmsg(clog("$megawar[0] has won the 7Champions League! As a reward, ".duration($time).
        " is removed from TTL. $megawar[0] gets 15 gems, 40 XP and 2000 gold and $SecondPlace gets 5 gems, 5 XP and 500 gold"));
      $rps{$megawar[0]}{next} -= $time;
      $rps{$megawar[0]}{gems} += 15;
      $rps{$megawar[0]}{gold} += 2000;
      $rps{$megawar[0]}{experience} += 40;
      $rps{$SecondPlace}{gems} += 5;
      $rps{$SecondPlace}{gold} += 500;
      $rps{$SecondPlace}{experience} += 5;
      $rps{$megawar[0]}{cl} += 1;
      $rps{$megawar[0]}{tt} = time() + 172800;
      $megawartime = time() + 10800 + int(rand(10800));
      undef @megawar;
   }
    else {
      $megawartime = time() + 40;
   }
}

sub powerwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $PWp1 = $game*2-2;
   my $PWp2 = $PWp1 + 1;
   my $PWp1sum = int((itemsum($powerwar[$PWp1],1)+($rps{$powerwar[$PWp1]}{upgrade}*100))*($rps{$powerwar[$PWp1]}{life}/100));
   my $PWp2sum = int((itemsum($powerwar[$PWp2],1)+($rps{$powerwar[$PWp2]}{upgrade}*100))*($rps{$powerwar[$PWp2]}{life}/100));
   my $PWp1roll = int(rand($PWp1sum));
   my $PWp2roll = int(rand($PWp2sum));
   if ($PWp1roll >= $PWp2roll) {
      $winner = $PWp1;
      $loser = $PWp2;
   } else {
      $winner = $PWp2;
      $loser = $PWp1;
   }
   chanmsg("12Power War Round $play, Fight $game: $powerwar[$PWp1] ".
      "12[$PWp1roll/$PWp1sum] vs $powerwar[$PWp2] 12[$PWp2roll/$PWp2sum] ... ".
      "$powerwar[$winner] advances and gets 50 gold from $powerwar[$loser]! $powerwar[$winner] gets 2 XP, ".
      "$powerwar[$loser] gets 1 XP and loses 5 life.");
        $rps{$powerwar[$winner]}{gold} += 50;
        $rps{$powerwar[$winner]}{experience} += 2;
        $rps{$powerwar[$loser]}{experience} += 1;
        $rps{$powerwar[$loser]}{life} -= 5;
        $rps{$powerwar[$loser]}{gold} -= 50;
        if (@powerwar == 2) {
            $SecondPlace = $powerwar[$loser];
        }
   $powerwar[$loser] = "xx";
   ++$game;
   if ($game > (@powerwar / 2)) {
      ++$play;
      $game = 1;
      my $muie = (@powerwar - 1);
      while ($muie > -1) {
         if ($powerwar[$muie] eq "xx") {
            splice(@powerwar,$muie ,1);
         }
         --$muie;
      }
      if (@powerwar > 1) {
         chanmsg(join(", ",@powerwar)." advance to round $play of the 12Power War.");
      }
      fisher_yates_shuffle( \@powerwar );
   }
   if (@powerwar == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $rps{$powerwar[0]}{next});
      chanmsg(clog("$powerwar[0] has won the 12Power War! As a reward, ".duration($time).
        " is removed from TTL, gets 10 gems, 20 XP, their items gets 10 points stronger".
        " and $SecondPlace gets 5 gems and 10 XP."));
      $rps{$powerwar[0]}{next} -= $time;
      $rps{$powerwar[0]}{gems} += 10;
      $rps{$powerwar[0]}{experience} += 20;
      $rps{$SecondPlace}{gems} += 5;
      $rps{$SecondPlace}{experience} += 10;
      $rps{$powerwar[0]}{item}{amulet} += 10;
      $rps{$powerwar[0]}{item}{boots} += 10;
      $rps{$powerwar[0]}{item}{charm} += 10;
      $rps{$powerwar[0]}{item}{gloves} += 10;
      $rps{$powerwar[0]}{item}{helm} += 10;
      $rps{$powerwar[0]}{item}{leggings} += 10;
      $rps{$powerwar[0]}{item}{ring} += 10;
      $rps{$powerwar[0]}{item}{shield} += 10;
      $rps{$powerwar[0]}{item}{tunic} += 10;
      $rps{$powerwar[0]}{item}{weapon} += 10;
      $rps{$powerwar[0]}{pw} += 1;
      $rps{$powerwar[0]}{tt} = time() + 172800;
      $powerwartime = time() + 36000 + int(rand(36000));
      undef @powerwar;
   }
    else {
      $powerwartime = time() + 40;
   }
}

sub abilitywar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $AWp1 = $gameAW*2-2;
   my $AWp2 = $AWp1 + 1;
   my $ThisAbility = $rps{$abilitywar[$AWp1]}{ability};
   if ($ThisAbility eq BARBARIAN) {
    $ThisAbility = "Barbarian";
   }
   elsif ($ThisAbility eq PALADIN) {
    $ThisAbility = "Paladin";
   }
   elsif ($ThisAbility eq WIZARD) {
    $ThisAbility = "Wizard";
   }
   elsif ($ThisAbility eq ROGUE) {
    $ThisAbility = "Rogue";
   }
   my $AWp1sum = int((itemsum($abilitywar[$AWp1],1)+($rps{$abilitywar[$AWp1]}{upgrade}*100))*($rps{$abilitywar[$AWp1]}{life}/100));
   my $AWp2sum = int((itemsum($abilitywar[$AWp2],1)+($rps{$abilitywar[$AWp2]}{upgrade}*100))*($rps{$abilitywar[$AWp2]}{life}/100));
   my $AWp1roll = int(rand($AWp1sum));
   my $AWp2roll = int(rand($AWp2sum));
   if ($AWp1roll >= $AWp2roll) {
      $winner = $AWp1;
      $loser = $AWp2;
   } else {
      $winner = $AWp2;
      $loser = $AWp1;
   }
   chanmsg("3$ThisAbility Battle Round $playAW, Fight $gameAW: $abilitywar[$AWp1] ".
      "3[$AWp1roll/$AWp1sum] vs $abilitywar[$AWp2] 3[$AWp2roll/$AWp2sum] ... ".
      "$abilitywar[$winner] advances and gets 25 gold from $abilitywar[$loser]! $abilitywar[$winner] gets 2 XP, ".
      "$abilitywar[$loser] gets 1 XP and loses 2 life.");
        $rps{$abilitywar[$winner]}{gold} += 25;
        $rps{$abilitywar[$winner]}{experience} += 2;
        $rps{$abilitywar[$loser]}{experience} += 1;
        $rps{$abilitywar[$loser]}{life} -= 2;
        $rps{$abilitywar[$loser]}{gold} -= 25;
        if (@abilitywar == 2) {
            $SecondPlace = $abilitywar[$loser];
        }
   $abilitywar[$loser] = "xx";
   ++$gameAW;
   if ($gameAW > (@abilitywar / 2)) {
      ++$playAW;
      $gameAW = 1;
      my $muie = (@abilitywar - 1);
      while ($muie > -1) {
         if ($abilitywar[$muie] eq "xx") {
            splice(@abilitywar,$muie ,1);
         }
         --$muie;
      }
      if (@abilitywar > 1) {
         chanmsg(join(", ",@abilitywar)." advance to round $playAW of the 3$ThisAbility Battle.");
      }
      fisher_yates_shuffle( \@abilitywar );
   }
   if (@abilitywar == 1) {
      chanmsg(clog("$abilitywar[0] has won the 3$ThisAbility Battle! As a reward, manual fights are reset to 0 for their ". 
        "current level and the time for attack and slay are also reset. Good luck $abilitywar[0]!"));
      $rps{$abilitywar[0]}{ffight} = 0;
      $rps{$abilitywar[0]}{regentm} = 0;
      $rps{$abilitywar[0]}{dragontm} = 0;
      $rps{$abilitywar[0]}{aw} += 1;
      $rps{$abilitywar[0]}{bt} = time() + 86400;
      $abilitywartime = time() + 5400 + int(rand(3600));
      undef @abilitywar;
   }
    else {
      $abilitywartime = time() + 40;
   }
}

sub locationwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $LWp1 = $gameLW*2-2;
   my $LWp2 = $LWp1 + 1;
   my $ThisLocation = $rps{$locationwar[$LWp1]}{status};
   if ($ThisLocation == TOWN) {
    $ThisLocation = "Town";
   }
   elsif ($ThisLocation == WORK) {
    $ThisLocation = "Work";
   }
   elsif ($ThisLocation == FOREST) {
    $ThisLocation = "Forest";
   }
   my $LWp1sum = int((itemsum($locationwar[$LWp1],1)+($rps{$locationwar[$LWp1]}{upgrade}*100))*($rps{$locationwar[$LWp1]}{life}/100));
   my $LWp2sum = int((itemsum($locationwar[$LWp2],1)+($rps{$locationwar[$LWp2]}{upgrade}*100))*($rps{$locationwar[$LWp2]}{life}/100));
   my $LWp1roll = int(rand($LWp1sum));
   my $LWp2roll = int(rand($LWp2sum));
   if ($LWp1roll >= $LWp2roll) {
      $winner = $LWp1;
      $loser = $LWp2;
   } else {
      $winner = $LWp2;
      $loser = $LWp1;
   }
   chanmsg("13$ThisLocation Battle Round $playLW, Fight $gameLW: $locationwar[$LWp1] ".
      "13[$LWp1roll/$LWp1sum] vs $locationwar[$LWp2] 13[$LWp2roll/$LWp2sum] ... ".
      "$locationwar[$winner] advances and gets 25 gold from $locationwar[$loser]! $locationwar[$winner] gets 2 XP, ".
      "$locationwar[$loser] gets 1 XP and loses 2 life.");
        $rps{$locationwar[$winner]}{gold} += 25;
        $rps{$locationwar[$winner]}{experience} += 2;
        $rps{$locationwar[$loser]}{experience} += 1;
        $rps{$locationwar[$loser]}{life} -= 2;
        $rps{$locationwar[$loser]}{gold} -= 25;
        if (@locationwar == 2) {
            $SecondPlace = $locationwar[$loser];
        }
   $locationwar[$loser] = "xx";
   ++$gameLW;
   if ($gameLW > (@locationwar / 2)) {
      ++$playLW;
      $gameLW = 1;
      my $muie = (@locationwar - 1);
      while ($muie > -1) {
         if ($locationwar[$muie] eq "xx") {
            splice(@locationwar,$muie ,1);
         }
         --$muie;
      }
      if (@locationwar > 1) {
         chanmsg(join(", ",@locationwar)." advance to round $playLW of the 13$ThisLocation Battle.");
      }
      fisher_yates_shuffle( \@locationwar );
   }
   if (@locationwar == 1) {
      chanmsg(clog("$locationwar[0] has won the 13$ThisLocation Battle!"));
      if ($rps{$locationwar[0]}{Worktime} > 0) {
        my $time = int(((10 + int(rand(40)))/100) * $rps{$locationwar[0]}{next});
        $rps{$locationwar[0]}{next} -= $time;
        chanmsg(clog("$locationwar[0] received 2 days of wages (1440 gold) and ".duration($time)." is removed from TTL!"));
        $rps{$locationwar[0]}{gold} += 1440;
      }
      if ($rps{$locationwar[0]}{Towntime} > 0) {
        chanmsg(clog("$locationwar[0] received 2 days of experience (96 XP)!"));
        $rps{$locationwar[0]}{experience} += 96;
      }
      if ($rps{$locationwar[0]}{Foresttime} > 0) {
        chanmsg(clog("$locationwar[0] found 10 gems near a cave! $locationwar[0] will now explore the cave..."));
        $rps{$locationwar[0]}{gems} += 10;
        forestwalk($locationwar[0]);
      }
      $rps{$locationwar[0]}{lw} += 1;
      $rps{$locationwar[0]}{bt} = time() + 86400;
      $locationwartime = time() + 5400 + int(rand(3600));
      undef @locationwar;
   }
    else {
      $locationwartime = time() + 40;
   }
}

sub alignwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $ALWp1 = $gameALW*2-2;
   my $ALWp2 = $ALWp1 + 1;
   my $ThisAlign = $rps{$alignwar[$ALWp1]}{alignment};
   if ($ThisAlign eq "g") {
    $ThisAlign = "Good";
   }
   elsif ($ThisAlign eq "n") {
    $ThisAlign = "Neutral";
   }
   elsif ($ThisAlign eq "e") {
    $ThisAlign = "Evil";
   }
   my $ALWp1sum = int((itemsum($alignwar[$ALWp1],1)+($rps{$alignwar[$ALWp1]}{upgrade}*100))*($rps{$alignwar[$ALWp1]}{life}/100));
   my $ALWp2sum = int((itemsum($alignwar[$ALWp2],1)+($rps{$alignwar[$ALWp2]}{upgrade}*100))*($rps{$alignwar[$ALWp2]}{life}/100));
   my $ALWp1roll = int(rand($ALWp1sum));
   my $ALWp2roll = int(rand($ALWp2sum));
   if ($ALWp1roll >= $ALWp2roll) {
      $winner = $ALWp1;
      $loser = $ALWp2;
   } else {
      $winner = $ALWp2;
      $loser = $ALWp1;
   }
   chanmsg("14$ThisAlign Battle Round $playALW, Fight $gameALW: $alignwar[$ALWp1] ".
      "14[$ALWp1roll/$ALWp1sum] vs $alignwar[$ALWp2] 14[$ALWp2roll/$ALWp2sum] ... ".
      "$alignwar[$winner] advances and gets 25 gold from $alignwar[$loser]! $alignwar[$winner] gets 2 XP, ".
      "$alignwar[$loser] gets 1 XP and loses 2 life.");
        $rps{$alignwar[$winner]}{gold} += 25;
        $rps{$alignwar[$winner]}{experience} += 2;
        $rps{$alignwar[$loser]}{experience} += 1;
        $rps{$alignwar[$loser]}{life} -= 2;
        $rps{$alignwar[$loser]}{gold} -= 25;
        if (@alignwar == 2) {
            $SecondPlace = $alignwar[$loser];
        }
   $alignwar[$loser] = "xx";
   ++$gameALW;
   if ($gameALW > (@alignwar / 2)) {
      ++$playALW;
      $gameALW = 1;
      my $muie = (@alignwar - 1);
      while ($muie > -1) {
         if ($alignwar[$muie] eq "xx") {
            splice(@alignwar,$muie ,1);
         }
         --$muie;
      }
      if (@alignwar > 1) {
         chanmsg(join(", ",@alignwar)." advance to round $playALW of the 14$ThisAlign Battle.");
      }
      fisher_yates_shuffle( \@alignwar );
   }
   if (@alignwar == 1) {
      if ($rps{$alignwar[0]}{alignment} eq "g") {
        chanmsg(clog("$alignwar[0] has won the 14$ThisAlign Battle! $alignwar[0] received 500 gold, 10 gems and 20 XP ".
            "and a chance to find an item!"));
        $rps{$alignwar[0]}{gold} += 500;
        $rps{$alignwar[0]}{gems} += 10;
        $rps{$alignwar[0]}{experience} += 20;
        find_item($alignwar[0]);
      }
      if ($rps{$alignwar[0]}{alignment} eq "n") {
        chanmsg(clog("$alignwar[0] has won the 14$ThisAlign Battle! $alignwar[0] received 250 gold, 5 gems and 10 XP."));
        $rps{$alignwar[0]}{gems} += 5;
        $rps{$alignwar[0]}{gold} += 250;
        $rps{$alignwar[0]}{experience} += 10;
      }
      if ($rps{$alignwar[0]}{alignment} eq "e") {
        chanmsg(clog("$alignwar[0] has won the 14$ThisAlign Battle! $alignwar[0] gets a chance to steal!"));
        evilness($alignwar[0]);
        evilnessOffline($alignwar[0]);
      }
      $rps{$alignwar[0]}{alw} += 1;
      $rps{$alignwar[0]}{bt} = time() + 86400;
      $alignwartime = time() + 5400 + int(rand(3600));
      undef @alignwar;
   }
    else {
      $alignwartime = time() + 40;
   }
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub find_gold {
    my $u = shift;
    my $goldamount = int((rand($rps{$u}{level})*3)+10);
    $rps{$u}{gold} += $goldamount;
    chanmsg("$u found $goldamount goldpieces lying on the ground and picked them up to sum $rps{$u}{gold} total gold. ");
}

sub find_gems {
    my $u = shift;
    my $gemsamount = int(rand(4)+1);
    $rps{$u}{gems} += $gemsamount;
    chanmsg("$u found $gemsamount gems and has $rps{$u}{gems} total gems. ");
}

sub random_gold {
    my @players = grep { $rps{$_}{online} && $rps{$_}{status} == FOREST } keys(%rps);
    return unless @players;
    my $player = $players[rand(@players)];
    my $goldamount = int((rand($rps{$player}{level})*3)+10);
    $rps{$player}{gold} += $goldamount;
    chanmsg("$player just walked by $goldamount goldpieces and picked them up to sum $rps{$player}{gold} total gold. ");
}

sub buy_item {
    my $u = shift;
    my $type = shift;
    my $level = shift;
    my $comparelevel = $rps{$u}{level} * 2;
    my @items = ('ring','amulet','charm','weapon','helm','tunic','gloves','leggings','shield','boots');
    my $validitem = 0;
    my $item;
    foreach $item (@items) {
        if($item eq $type) { $validitem = 1; }
    }
    if($level > $comparelevel) {
        privmsg("You can not buy an item with an level larger than two times your ".
        "level. ", $rps{$u}{nick});
    }
    else {
        if($validitem) {
                if(int($rps{$u}{item}{$type}) >= $level) {
                    privmsg("That would be dumb. ", $rps{$u}{nick});
                }
                else {
                    if($rps{$u}{gold} >= ($level*3)) {
                        $rps{$u}{item}{$type} = $level;
                        $rps{$u}{gold} -= $level*3;
                        chanmsg("$u now has a level $level $type from the shop. $u has $rps{$u}{gold} gold left.");
                    }
                    else {
                        my $levelx3 = $level * 3;
                        privmsg("You don't have enough gold. You need: $levelx3 ", $rps{$u}{nick});
                    }
                }
        }
        else {
            privmsg("You did not type a valid item name. Try one of these: ".
                "ring, amulet, charm, weapon, helm, tunic, gloves, leggings, shield, boots.", $rps{$u}{nick});
        }
    }
}

sub buy_pots {
    my $u = shift;
    if($rps{$u}{gold} >= 100) {
        $rps{$u}{gold} -= 100;
        $rps{$u}{powerpotion} += 1;
        privmsg("You just bought yourself a powerpotion. In the next fight your powers will be increased.", $rps{$u}{nick});
    }
    else {
        privmsg("You don't have enough gold. You need: 100 ", $rps{$u}{nick});
    }
}

sub buy_experience {
    my $u = shift;
    my $gain = $rps{$u}{next};
    $gain = int($gain*.10);
    if($rps{$u}{gold} >= 500) {
        $rps{$u}{gold} -= 500;
        $rps{$u}{next} -= $gain;
        chanmsg("$u bought some experience. 10% of their TTL is removed for 500 gold.".
            " $u reaches next level in ".duration($rps{$u}{next}).". $u has $rps{$u}{gold} gold left.");
    }
    else {
        privmsg("You don't have enough gold. You need: 500 ", $rps{$u}{nick});
    }
}

sub buy_upgrade {
    my $u = shift;
    if($rps{$u}{gold} >= 500 && $rps{$u}{level} >= 35 && $rps{$u}{upgrade} == 0) {
        $rps{$u}{gold} -= 500;
        $rps{$u}{upgrade} = 1;
        chanmsg("$u made a level 1 upgrade. Their power will grow with 100 now. $u has $rps{$u}{gold} gold left.");            
    }
    elsif($rps{$u}{gold} >= 1000 && $rps{$u}{level} >= 40 && $rps{$u}{upgrade} == 1) {
        $rps{$u}{gold} -= 1000;
        $rps{$u}{upgrade} = 2;
        chanmsg("$u made a level 2 upgrade. Their power will grow with 200 now. $u has $rps{$u}{gold} gold left.");            
    }
    elsif($rps{$u}{gold} >= 2000 && $rps{$u}{level} >= 45 && $rps{$u}{upgrade} == 2) {
        $rps{$u}{gold} -= 2000;
        $rps{$u}{upgrade} = 3;
        chanmsg("$u made a level 3 upgrade. Their power will grow with 300 now. $u has $rps{$u}{gold} gold left.");            
    }
    elsif($rps{$u}{gold} >= 4000 && $rps{$u}{level} >= 50 && $rps{$u}{upgrade} == 3) {
        $rps{$u}{gold} -= 4000;
        $rps{$u}{upgrade} = 4;
        chanmsg("$u made a level 4 upgrade. Their power will grow with 400 now. $u has $rps{$u}{gold} gold left.");            
    }
    elsif($rps{$u}{gold} >= 8000 && $rps{$u}{level} >= 60 && $rps{$u}{upgrade} == 4) {
        $rps{$u}{gold} -= 8000;
        $rps{$u}{upgrade} = 5;
        chanmsg("$u made a level 5 upgrade. Their power will grow with 500 now. $u has $rps{$u}{gold} gold left.");            
    }
    else {
        privmsg("You don't have enough gold, the level for that upgrade or you had all the possible upgrades made ", $rps{$u}{nick});
    }
}

sub buy_mana {
    my $u = shift;
    if($rps{$u}{gold} >= 1000 && $rps{$u}{mana} == 0) {
        $rps{$u}{gold} -= 1000;
        $rps{$u}{mana} = 1;
        chanmsg("$u bought a mana potion. Their sum will double for the next fight. $u has $rps{$u}{gold} gold left.");
    }
    else {
        privmsg("You don't have enough gold or you already have full mana.", $rps{$u}{nick});
    }
}

sub buy_life {
    my $u = shift;

    if ($rps{$u}{life} < 0) {
        privmsg("You are a Zombie!", $rps{$u}{nick});
    }
    elsif ($IsEnding == 0) {
        if ($rps{$u}{level} > 0) {
            my $factor = int($rps{$u}{level}/5);
            if ($IsEnding == 1) {
                $factor = 25;
            }
            my $pay = (100-$rps{$u}{life})*$factor;
            my $recover = int($rps{$u}{gold}/$factor);
            if ($rps{$u}{gold} >= $pay && $rps{$u}{life} < 100) {
                $rps{$u}{gold} -= $pay;
                $rps{$u}{life} = 100;
                chanmsg("$u is now fully recovered and has $rps{$u}{gold} gold left.");
            }
            elsif ($rps{$u}{life} < 100) {
                if ($rps{$u}{gold} > 0) {
                    $rps{$u}{gold} = 0;
                    $rps{$u}{life} += $recover;
                    chanmsg("$u got $recover life points restored.");
                }
                else {
                    privmsg("You do not have any gold, you peasant...goto work!", $rps{$u}{nick});
                }
                
            }
            else {
                privmsg("You are already fully recovered.", $rps{$u}{nick});
            }
        }
        else {
            privmsg("You are at level 0 and can't buy life.", $rps{$u}{nick});
        }
    }
    else {
        if ($rps{$u}{life} > 0) {
            if ($rps{$u}{level} > 0) {
                my $factor = int($rps{$u}{level}/5);
                if ($IsEnding == 1) {
                    $factor = 25;
                }
                my $pay = (100-$rps{$u}{life})*$factor;
                my $recover = int($rps{$u}{gold}/$factor);
                if ($rps{$u}{gold} >= $pay && $rps{$u}{life} < 100) {
                    $rps{$u}{gold} -= $pay;
                    $rps{$u}{life} = 100;
                    chanmsg("$u is now fully recovered and has $rps{$u}{gold} gold left.");
                }
                elsif ($rps{$u}{life} < 100) {
                    if ($rps{$u}{gold} > 0) {
                        $rps{$u}{gold} = 0;
                        $rps{$u}{life} += $recover;
                        chanmsg("$u got $recover life points restored.");
                    }
                    else {
                        privmsg("You do not have any gold, you peasant...goto work!", $rps{$u}{nick});
                    }
                    
                }
                else {
                    privmsg("You are already fully recovered.", $rps{$u}{nick});
                }
            }
            else {
                privmsg("You are at level 0 and can't buy life.", $rps{$u}{nick});
            }
        }
        else {
            privmsg("You are dead and can't buy life.", $rps{$u}{nick});
        }
    }
}

sub buy_gems {
    my $u = shift;
    my $type = shift;
    my $type2 = int(abs($type));
    my $pay = 150*$type2;
    if($rps{$u}{gold} >= $pay) {
        $rps{$u}{gems} += $type2;
        $rps{$u}{gold} -= $pay;
        chanmsg("$u bought $type2 gems. $u has $rps{$u}{gold} gold left and $rps{$u}{gems} gems.");
    }
    else {
        privmsg("You don't have enough gold. You need: $pay gold.", $rps{$u}{nick});
    }
}

sub blackbuy_item {
    my $u = shift;
    my $type = shift;
    my $MassTimes = int(shift);
    my $GemAmt = 15;
    my @items = ('ring','amulet','charm','weapon','helm','tunic','gloves','leggings','shield','boots');
    my $validitem = 0;
    my $item;
    foreach $item (@items) {
        if($item eq $type) {
            $validitem = 1;
        }
    }
    if($validitem) {
        if($rps{$u}{gems} >= ($GemAmt*$MassTimes)) {
            my $tupgrade = 0;
            my $ThisUpgrade = 0;
            my $power = 0;
            my $MassTimesBonus = 0;
            if ($MassTimes > 1) {
                $MassTimesBonus = int($MassTimes * ($MassTimes * .5));
            }
            if ($MassTimesBonus > 100) {
                $MassTimesBonus = 100;
            }
            for (1..$MassTimes) {
                if ($rps{$u}{upgrade} > 0) {
                    $tupgrade = $rps{$u}{upgrade} * 2;
                    $tupgrade = int(rand($tupgrade) + 1);
                    $ThisUpgrade = $ThisUpgrade + $tupgrade;
                }
                $power = $power + int(rand(50)+15);
            }
            $power = $power + $MassTimesBonus;
            $rps{$u}{item}{$type} += ($power + $ThisUpgrade);
            $rps{$u}{gems} -= ($GemAmt * $MassTimes);
            chanmsg("$u used the black market $MassTimes times to upgrade their $type for $power points stronger ".
                "and has $rps{$u}{gems} gems left.");
            if ($ThisUpgrade > 0) {
                chanmsg("$u got $ThisUpgrade upgrade points.");
            }
        }
        else {
            privmsg("You don't have enough gems. You need: " .$GemAmt*$MassTimes. "!", $rps{$u}{nick});
        }
    }
    else {
        privmsg("$type is not a valid item!", $rps{$u}{nick});
    }
}

sub blackbuy_scroll {
    my $u = shift;
    my $type = shift;
    my $gain = $rps{$u}{next};
    $gain = int($gain*(rand(50)/100));
    if($type eq 'scroll') {
        if($rps{$u}{scrolls} && $rps{$u}{scrolls} == 5) {
            privmsg("You already have 5 scrolls.", $rps{$u}{nick});
            return;
        }
        if($rps{$u}{gems} >= 15) {
            $rps{$u}{gems} -= 15;
            $rps{$u}{next} -= $gain;
            $rps{$u}{scrolls} += 1;
            chanmsg("$u bought one experience scroll from the Black Market and gets " . duration($gain) .
                " removed from TTL. $u has $rps{$u}{gems} gems left. $u reaches next level in ".duration($rps{$u}{next}).".");
        }
        else {
            privmsg("You don't have enough gems. You need: 15 ", $rps{$u}{nick});
        }
    }
}

sub xpget_item {
    my $u = shift;
    my $type = shift;
    my $amount = int(shift);
    my @items = ('ring','amulet','charm','weapon','helm','tunic','gloves','leggings','shield','boots');
    my $validitem;
    my $item;
    my $power = 0;
    my $MinRoll = 0;
    if ($amount > 19) {
        foreach $item (@items) {
            if($item eq $type) { 
                $validitem = 1;
            }
        }
        if($validitem) {
            if($rps{$u}{experience} > 19) {
                if($rps{$u}{experience} >= $amount) {
                    $MinRoll = int($amount*.05);
                    $power = $amount;
                    if ($amount > 20) {
                        $power = $power - $MinRoll;
                    }
                    $power = int(rand($power) + $MinRoll);
                    $rps{$u}{item}{$type} += $power;
                    $rps{$u}{experience} -= $amount;
                    chanmsg("$u used $amount XP to upgrade their $type and gets $power points stronger. ".
                        "$u has $rps{$u}{experience} XP left.");
                }
                else {
                    privmsg("You don't have enough XP. You need $amount.", $rps{$u}{nick});
                }
            }
            else {
                privmsg("You don't have enough XP. You need 20.", $rps{$u}{nick});
            }
        }
        else {
            privmsg("$type is not a valid item.", $rps{$u}{nick});
        }
    }
    else {
        privmsg("You need to use at least 20 XP to use this command.", $rps{$u}{nick});
    }
}

sub xpget_scroll {
    my $u = shift;
    my $gain = $rps{$u}{next};
    if($rps{$u}{scrolls} && $rps{$u}{scrolls} == 5) {
        privmsg("You already have 5 scrolls.", $rps{$u}{nick});
        return;
    }
    if($rps{$u}{experience} >= 20) {
        $gain = int($gain*((rand(49)+1)/100));
        $rps{$u}{experience} -= 20;
        $rps{$u}{next} -= $gain;
        $rps{$u}{scrolls} += 1;
        chanmsg("$u used 20 XP for a scroll and gets " .duration($gain)." removed from TTL. ".
            "$u reaches next level in ".duration($rps{$u}{next})." $u has $rps{$u}{experience} XP left.");
    }
    else {
        privmsg("You don't have enough XP. You need 20.", $rps{$u}{nick});
    }
}

sub forestwalk {
    my $ThisForester = shift;
    my $CaveExplorer = shift;
    my @foresters;
    my $ForestEntry = 0;
    my $CaveEntry = 0;
    if ($ThisForester && !$CaveExplorer) {
        @foresters = $ThisForester;
        $ForestEntry = 1;
    }
    elsif ($ThisForester && $CaveExplorer) {
        @foresters = $ThisForester;
        $CaveEntry = 1;
    }
    else {
        @foresters = grep { $rps{$_}{online} && $rps{$_}{status} == FOREST } keys(%rps);
    }
    for my $i (0..$#foresters) {
        if ($ForestEntry == 1) {
        #on 1 player entering
            if (rand(4) < 1) { creep_fight($foresters[$i]); }
            if (rand(4) < 1) { find_gems($foresters[$i]); }
        }
        elsif ($CaveEntry == 1) {
        #on 1 player exploring a cave
            if (rand(4) < 1) { creep_fight($foresters[$i]); }
            if (rand(3) < 1) { find_gems($foresters[$i]); }
        }
        elsif (time() - $rps{$foresters[$i]}{Foresttime} > 14400) {
        #on greater than 4 hours
            if (rand(3) < 1) { creep_fight($foresters[$i]); }
            if (rand(3) < 1) { find_gems($foresters[$i]); }
        }
    }
}

sub creep_fight {
    my $user = shift;
    my @randcreep;
    my $ThisCreep;
    if ($rps{$user}{regentm} < time()) {
        if ($rps{$user}{level} <= 75) {
            @randcreep = grep { $monster{$_}{level} <= $rps{$user}{level} &&  $monster{$_}{level} >= ($rps{$user}{level} - 10)} keys(%monster);
            $ThisCreep = $randcreep[int(rand($#randcreep))]
        }
        elsif ($rps{$user}{level} > 75 && $rps{$user}{level} < 100) {
            $ThisCreep = "Phoenix"
        }
        else {
            $ThisCreep = "Werewolf"
        }
    }
    return unless $ThisCreep;
    monster_fight($user, $ThisCreep);
}

sub change_location {
    my $nick = shift;
    my $user = shift;
    my $location = shift;
    for my $LWtourney (@locationwar) {
       if ($LWtourney eq $user) {
          chanmsg("$user changed location during the 13Location Battle! Their TTL is doubled.");
          my $ThisTTL = $rps{$user}{next} * 2;
          $rps{$user}{next} = $ThisTTL;
        }
     }
    if ($location eq 'town') {
        if ($rps{$user}{level} > 0) {
            if ($rps{$user}{status} == WORK) {
                my $worktime = time() - $rps{$user}{Worktime};
                my $perc = ($worktime/60)/$rps{$user}{level};
                my $gainttl = int(($perc*0.01*$rps{$user}{next})/4);
                if ($rps{$user}{next} - $gainttl < 0) {
                    $rps{$user}{next} = 5;
                }
                else {
                    $rps{$user}{next} -= $gainttl;
                }
                my $gaingold = int($worktime/86.4);
                if ($gainttl != 0 && $gaingold != 0) {
                    chanmsg("$user worked for " .duration($worktime). " and is now " .duration($gainttl). 
                        " closer to the next level. $user gained " .$gaingold. " gold. $user is in Town.");
                }
                else {
                    chanmsg("$user is now in Town but didn't work long enough to earn any thing.");
                }
                $rps{$user}{gold} += $gaingold;
                $rps{$user}{status} = TOWN;
                $rps{$user}{Worktime} = 0;
                $rps{$user}{Towntime} = time();
            }
            elsif ($rps{$user}{status} == FOREST) {
                if (($rps{$user}{Foresttime} + 21600) < time()) {
                    if (rand(99) < 50) {
                        chanmsg("$user found a cave near the edge of the forest! $user will explore it...");
                        forestwalk($user, 'cave');
                    }
                    $rps{$user}{status} = TOWN;
                    $rps{$user}{Towntime} = time();
                    $rps{$user}{Foresttime} = 0;
                    chanmsg("$user is now in Town.");
                }
                else {
                    privmsg("You must explore the forest for at least 6 hours!", $nick);
                }
            }
        }
        else {
            privmsg("You need to get to level 1 before changing location!", $nick);
        }
    }
    elsif ($location eq 'work') {
        if ($rps{$user}{status} == FOREST) {
            privmsg("You first need to go to Town!", $nick);
        }
        elsif ($rps{$user}{status} == TOWN) {
            if ($rps{$user}{Towntime} > 0) {
                my $Towntime = time() - $rps{$user}{Towntime};
                my $gainXP = int($Towntime/1800);
                $rps{$user}{status} = WORK;
                $rps{$user}{Worktime} = time();
                $rps{$user}{Towntime} = 0;
                if ($gainXP > 0) {
                    chanmsg("$user has been in town for " .duration($Towntime). " and gained " .$gainXP. " XP. $user is at Work.");
                    $rps{$user}{experience} += $gainXP;
                }
                else {
                    chanmsg("$user is now at Work.");
                    privmsg("You were not in Town long enough to gain XP.", $nick);
                }
            }
            else {
                $rps{$user}{status} = WORK;
                $rps{$user}{Worktime} = time();
                chanmsg("$user is now at Work.");
            }
        }
        else {
            $rps{$user}{status} = WORK;
            $rps{$user}{Worktime} = time();
            chanmsg("$user is now at Work.");
        }
    }
    elsif ($location eq 'forest') {
        if ($rps{$user}{status} == WORK) {
            privmsg("You first need to go to Town to recieve payment!", $nick);
        }
        elsif ($rps{$user}{status} == TOWN) {
            if ($rps{$user}{Towntime} > 0) {
                my $Towntime = time() - $rps{$user}{Towntime};
                my $gainXP = int($Towntime/1800);
                $rps{$user}{status} = FOREST;
                $rps{$user}{Towntime} = 0;
                if ($gainXP > 0) {
                    chanmsg("$user has been in town for " .duration($Towntime). " and gained " .$gainXP. " XP. $user is in the Forest.");
                    $rps{$user}{experience} += $gainXP;
                }
                else {
                    chanmsg("$user is now in the Forest.");
                    privmsg("You were not in Town long enough to gain XP.", $nick);
                }
                $rps{$user}{Foresttime} = time();
                forestwalk($user);
            }
            else {
                $rps{$user}{status} = FOREST;
                chanmsg("$user is now in the Forest.");
                $rps{$user}{Foresttime} = time();
                forestwalk($user);
            }
        }
    }
}

sub BattlePlayers {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $rps{$ThisMe}{ability};
    my $ThisMySum = itemsum($ThisMe,0);
    my $ThisOppClass = $rps{$ThisOpp}{ability};
    my $ThisOppSum = itemsum($ThisOpp,0);
    my $ThisMyRoll = $ThisMySum;
    my $ThisOppRoll = $ThisOppSum;
    my $ThisRollPerc = 0;
        
    ### Barbarian
    if ($ThisMyClass eq BARBARIAN) {
    
        $ThisMyRoll = int($ThisMySum*1.3); #class bonus
        
        if ($ThisOppClass eq PALADIN) { #strength
            $ThisMyRoll = int($ThisMySum*.3);
            $ThisMySum = int($ThisMySum*1.3);
            $ThisMyRoll = $ThisMyRoll + $ThisMySum;
            $ThisRollPerc = int(rand(99)+1);
            if ($ThisRollPerc < 80) {
                $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.4));
            }
        }
        elsif ($ThisOppClass eq WIZARD) { #weakness
            $ThisOppSum = int($ThisOppSum*1.3);
            $ThisOppRoll = $ThisOppSum;
            $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.25));
        }
        elsif ($ThisOppClass eq BARBARIAN) {
            $ThisOppRoll = int($ThisOppRoll*1.30);
        }
    }
    ### Wizard
    if ($ThisMyClass eq WIZARD) {
    
        $ThisOppRoll = int($ThisOppSum - ($ThisOppSum*.25)); #class bonus
        
        if ($ThisOppClass eq BARBARIAN) { #strength
            $ThisOppRoll = int($ThisOppSum*1.30);
            $ThisOppRoll = int($ThisOppRoll - $ThisOppRoll*.25);            
            $ThisMySum = int($ThisMySum*1.3);
            $ThisMyRoll = $ThisMySum;            
        }
        elsif ($ThisOppClass eq ROGUE) { #weakness
            $ThisOppSum = int($ThisOppSum*1.3);
            $ThisOppRoll = int($ThisOppSum - ($ThisOppSum*.25));
        }
        elsif ($ThisOppClass eq PALADIN) {
            $ThisRollPerc = int(rand(99)+1);
            if ($ThisRollPerc < 80) {
                $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.4));
            }
        }
        elsif ($ThisOppClass eq WIZARD) {
            $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.25));
        }
    }
    ### Paladin
    if ($ThisMyClass eq PALADIN) {
        $ThisRollPerc = int(rand(99)+1);
        if ($ThisRollPerc < 80) { #class bonus
            $ThisOppRoll = int($ThisOppRoll - ($ThisOppRoll*.4));
        }
        if ($ThisOppClass eq ROGUE) { #strength
            $ThisMySum = int($ThisMySum*1.3);
            $ThisMyRoll = $ThisMySum;
        }
        elsif ($ThisOppClass eq BARBARIAN) { #weakness
            $ThisOppSum = int($ThisOppSum*1.3);
            $ThisOppRoll = int($ThisOppSum + $ThisOppSum*.3);
            if ($ThisRollPerc < 80) {
                $ThisOppRoll = int($ThisOppRoll - ($ThisOppSum*.4));
            }
        }
        elsif ($ThisOppClass eq WIZARD) {
            $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.25));
        }
        elsif ($ThisOppClass eq PALADIN) {
            $ThisRollPerc = int(rand(99)+1);
            if ($ThisRollPerc < 80) {
                $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.4));
            }
        }
    }
    ### Rogue
    if ($ThisMyClass eq ROGUE) {
        if ($ThisOppClass eq WIZARD) { #strength
            $ThisMySum = int($ThisMySum*1.3);
            $ThisMyRoll = int($ThisMySum - ($ThisMySum*.25));
        }
        elsif ($ThisOppClass eq PALADIN) { #weakness
            $ThisOppSum = int($ThisOppSum*1.3);
            $ThisOppRoll = $ThisOppSum;
            $ThisRollPerc = int(rand(99)+1);
            if ($ThisRollPerc < 80) {
                $ThisMyRoll = int($ThisMyRoll - ($ThisMyRoll*.4));
            }
        }
        elsif ($ThisOppClass eq BARBARIAN) {
            $ThisOppRoll = int($ThisOppSum*1.3);
        }
    }
    # Results
    my $ThisMyXP = int(rand(3)+3);
    my $ThisOppXP = int(rand(2)+1);
    my $ThisDamage = 0;
    my $ThisOppLife = $rps{$ThisOpp}{life};
    if ($ThisOppLife < 0) {
        $ThisOppLife = $ThisOppLife * -1;
    }
    $ThisMySum = int( ($ThisMySum + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    $ThisOppSum = int( ($ThisOppSum + ($rps{$ThisOpp}{upgrade}*100))*($ThisOppLife /100) );
    $ThisOppRoll = int( ($ThisOppRoll + ($rps{$ThisOpp}{upgrade}*100))*($ThisOppLife /100) );

    if ($ThisMyClass eq ROGUE) { #Rogue class bonus
        $ThisMyRoll = int(rand($ThisMyRoll - ($ThisMyRoll*.25)) + ($ThisMyRoll*.25));
    }
    else {
        $ThisMyRoll = int(rand($ThisMyRoll));
    }
    if ($ThisOppClass eq ROGUE) { #Rogue class bonus
        $ThisOppRoll = int(rand($ThisOppRoll - ($ThisOppRoll*.25)) + ($ThisOppRoll*.25));
    }
    else {
        $ThisOppRoll = int(rand($ThisOppRoll));
    }
    if ($ThisMyRoll > $ThisOppRoll) {
        my $gain = ($ThisOpp eq $primnick)?20:int($rps{$ThisOpp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$ThisMe}{next});
        if($rps{$ThisOpp}{life} > 10 || $rps{$ThisOpp}{life} < -10) {
            $ThisDamage = int(rand(4)+1);
        }
        if ($rps{$ThisOpp}{life} < 0) {
            $rps{$ThisOpp}{life} += $ThisDamage;
        }
        else {
            $rps{$ThisOpp}{life} -= $ThisDamage;
        }
        $rps{$ThisMe}{experience} += $ThisMyXP;
        $rps{$ThisOpp}{experience} += $ThisOppXP;
        $rps{$ThisMe}{next} -= $gain;
        $rps{$ThisMe}{bwon} += 1;
        $rps{$ThisOpp}{blost} += 1;
        $rps{$ThisMe}{bminus} += $gain;
        $rps{$ThisMe}{ffight} += 1;
        chanmsg(clog("$ThisMe 9[$ThisMyRoll/$ThisMySum] has challenged $ThisOpp 9[$ThisOppRoll/$ThisOppSum] ".
            "and won! ".duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $ThisMyXP XP, ".
            "$ThisOpp gets $ThisOppXP XP. $ThisOpp has $rps{$ThisOpp}{life} life left."));
        chanmsg("$ThisMe reaches next level in ".duration($rps{$ThisMe}{next}).".");
        item_special_proc($ThisMe,$ThisMyXP,"XP");
        item_special_proc($ThisMe,$gain,"TTL");
        item_special_proc($ThisOpp,$ThisOppXP,"XP");
        item_special_proc($ThisOpp,$ThisDamage,"Life");
        my $csfactor = $rps{$ThisMe}{alignment} eq "g" ? 50 :
                       $rps{$ThisMe}{alignment} eq "e" ? 20 :
                       35;
        if (rand($csfactor) < 1 && $ThisOpp ne $primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $rps{$ThisOpp}{next});
            chanmsg(clog("$ThisMe has dealt $ThisOpp a Critical Blow! ".
                duration($gain)." is added to $ThisOpp\'s clock."));
            $rps{$ThisOpp}{next} += $gain;
            chanmsg("$ThisOpp reaches next level in ".duration($rps{$ThisOpp}{next}).".");
        }
        elsif (rand(25) < 1 && $ThisOpp ne $primnick && $rps{$ThisMe}{level} > 35) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if (int($rps{$ThisOpp}{item}{$type}) > int($rps{$ThisMe}{item}{$type})) {
                chanmsg(clog("In the fierce battle, $ThisOpp dropped their level ".int($rps{$ThisOpp}{item}{$type}).
                    " $type! $ThisMe picks it up, tossing their old level ".int($rps{$ThisMe}{item}{$type}).
                    " $type to $ThisOpp."));
                my $tempitem = $rps{$ThisMe}{item}{$type};
                $rps{$ThisMe}{item}{$type}=$rps{$ThisOpp}{item}{$type};
                $rps{$ThisOpp}{item}{$type} = $tempitem;
            }
        }        
    }
    else {
        my $gain = ($ThisOpp eq $primnick)?10:int($rps{$ThisOpp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$rps{$ThisMe}{next});
        if($rps{$ThisMe}{life} > 10) {
            $ThisDamage = int(rand(4)+1);
        }
        $rps{$ThisMe}{life} -= $ThisDamage;
        $rps{$ThisMe}{experience} += $ThisOppXP;
        $rps{$ThisOpp}{experience} += $ThisMyXP;
        $rps{$ThisMe}{next} += $gain;
        $rps{$ThisMe}{blost} += 1;
        $rps{$ThisOpp}{bwon} += 1;
        $rps{$ThisMe}{badd} += $gain;
        $rps{$ThisMe}{ffight} += 1;
        chanmsg(clog("$ThisMe 9[$ThisMyRoll/$ThisMySum] has challenged $ThisOpp 9[$ThisOppRoll/$ThisOppSum] ".
            "and lost! ".duration($gain)." is added to $ThisMe\'s clock. $ThisMe gets $ThisOppXP XP, ".
            "$ThisOpp gets $ThisMyXP XP. $ThisMe has $rps{$ThisMe}{life} life left."));
        chanmsg("$ThisMe reaches next level in ".duration($rps{$ThisMe}{next}).".");
        item_special_proc($ThisMe,$ThisOppXP,"XP");
        item_special_proc($ThisMe,$ThisDamage,"Life");
        item_special_proc($ThisOpp,$ThisMyXP,"XP");
        if (rand(49) < 1) {
           my $TempTTL = $rps{$ThisMe}{next};
           $rps{$ThisMe}{next} += $TempTTL;
           chanmsg(clog("$ThisOpp hit back hard so $ThisMe\'s TTL is doubled. $ThisMe reaches next level in ".
           duration($rps{$ThisMe}{next})."."));
        }                
    }
    if (rand(19) < 1) {
        item_wear($ThisMe);
    }
    if (rand(19) < 1) {
        item_wear($ThisOpp);
    }
}

sub monster_fight {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $rps{$ThisMe}{ability};    
    my $ThisOppSum = $monster{$ThisOpp}{sum};
    my $ThisOppRoll = $ThisOppSum;
    my $ThisMySum = itemsum($ThisMe,0);
    my $ThisMyRoll = $ThisMySum;
    my $ThisRollPerc = 0;
    
    ### Barbarian
    if ($ThisMyClass eq BARBARIAN) {
        $ThisMyRoll = int($ThisMySum*1.3); #class bonus
    }
    ### Wizard
    if ($ThisMyClass eq WIZARD) {
        $ThisOppRoll = int($ThisOppRoll - ($ThisOppRoll*.25)); #class bonus
    }
    ### Paladin
    if ($ThisMyClass eq PALADIN) {
        $ThisRollPerc = int(rand(99)+1);
        if ($ThisRollPerc < 80) { #class bonus
            $ThisOppRoll = int($ThisOppRoll - ($ThisOppRoll*.4));
        }
    }     
    #Results
    my $gain;
    my $ThisMyXP = int(rand(3)+3);
    my $ThisOppXP = int(rand(2)+1);
    $ThisMySum = int( ($ThisMySum + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    if ($ThisMyClass eq ROGUE) { #Rogue class bonus
        $ThisMyRoll = int(rand($ThisMyRoll - ($ThisMyRoll*.25)) + ($ThisMyRoll*.25));
    }
    else {
        $ThisMyRoll = int(rand($ThisMyRoll));
    }
    $ThisOppRoll = int(rand($ThisOppRoll));
    $rps{$ThisMe}{regentm} = ($rps{$ThisMe}{level}*120)+21600+time();
    my $regentm = $rps{$ThisMe}{regentm}-time();
    if ($ThisMyRoll >= $ThisOppRoll) {
        $rps{$ThisMe}{gold} += $monster{$ThisOpp}{gold};
        $rps{$ThisMe}{gems} += $monster{$ThisOpp}{gem};
        $gain = int($rps{$ThisMe}{next} * .05);
        $rps{$ThisMe}{experience} += $ThisMyXP;
        $rps{$ThisMe}{next} -= $gain;
        $rps{$ThisMe}{bwon} += 1;
        $rps{$ThisMe}{bminus} += $gain;
        chanmsg(clog("$ThisMe 8[$ThisMyRoll/$ThisMySum] has attacked a $ThisOpp 8[$ThisOppRoll/$ThisOppSum] and killed it! ".
            duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $ThisMyXP XP."));
        find_expert_item($ThisMe);
        chanmsg("$ThisMe reaches next level in ".duration($rps{$ThisMe}{next}).", and must wait ".
            duration($regentm)." to attack again.");
        if ($monster{$ThisOpp}{gold} > 0) {
            chanmsg("$ThisMe found $monster{$ThisOpp}{gold} goldpieces and has $rps{$ThisMe}{gold} total gold.");
            item_special_proc($ThisMe,$monster{$ThisOpp}{gold},"Gold");
        }
        if ($monster{$ThisOpp}{gem} > 0) {
            chanmsg("$ThisMe found $monster{$ThisOpp}{gem} gems and has $rps{$ThisMe}{gems} total gems.");
            item_special_proc($ThisMe,$monster{$ThisOpp}{gem},"Gem");
        }
        find_item($ThisMe);
        item_special_proc($ThisMe,$ThisMyXP,"XP");
        item_special_proc($ThisMe,$gain,"TTL");
    }
    else {
        my $ThisDamage = 5;
        if($rps{$ThisMe}{life} > 20) {
            $ThisDamage = int(rand(9)+1);
        }
        $gain = int($rps{$ThisMe}{next} * .05);
        $rps{$ThisMe}{life} -= $ThisDamage;
        $rps{$ThisMe}{experience} += $ThisOppXP;
        $rps{$ThisMe}{next} += $gain;
        $rps{$ThisMe}{blost} += 1;
        $rps{$ThisMe}{badd} += $gain;        
        $rps{$ThisMe}{regentm} = ($rps{$ThisMe}{level}*120)+21600+time();        
        chanmsg(clog("$ThisMe 8[$ThisMyRoll/$ThisMySum] has attacked a $ThisOpp 8[$ThisOppRoll/$ThisOppSum] and lost! ".
            duration($gain)." is added to $ThisMe\'s clock. $ThisMe gets $ThisOppXP XP. $ThisMe has ".
            "$rps{$ThisMe}{life} life left"));    
        chanmsg("$ThisMe reaches next level in ".duration($rps{$ThisMe}{next}).", and must wait ".
            duration($regentm)." to attack again.");
        item_special_proc($ThisMe,$ThisOppXP,"XP");
        item_special_proc($ThisMe,$ThisDamage,"Life");
    }
    if (rand(19) < 1) {
        item_wear($ThisMe);
    }
}

sub dragon_fight {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $rps{$ThisMe}{ability};    
    my $ThisOppSum = $dragon{$ThisOpp}{sum};
    my $ThisOppRoll = $ThisOppSum;
    my $ThisMySum = itemsum($ThisMe,0);
    my $ThisMyRoll = $ThisMySum;
    my $ThisRollPerc = 0;
    my $MinSum = 0;
    my $AddDamage = 1;
    if ($ThisOpp eq "Bronze_Dragon") {
        $MinSum = 10000;
        $AddDamage = 1.5;
    }
    if ($ThisOpp eq "Silver_Dragon") {
        $MinSum = 20000;
        $AddDamage = 2;
    }
    if ($ThisOpp eq "Gold_Dragon") {
        $MinSum = 40000;
        $AddDamage = 2.5;
    }
    if ($ThisOpp eq "Platinum_Dragon") {
        $MinSum = 60000;
        $AddDamage = 3;
    }
    $ThisOppSum =  $ThisOppSum + $MinSum;
    
    ### Barbarian
    if ($ThisMyClass eq BARBARIAN) {
        $ThisMyRoll = int($ThisMySum*1.3); #class bonus
    }
    ### Wizard
    if ($ThisMyClass eq WIZARD) {
        $ThisOppRoll = int($ThisOppRoll - ($ThisOppRoll*.25)); #class bonus
    }
    ### Paladin
    if ($ThisMyClass eq PALADIN) {
        $ThisRollPerc = int(rand(99)+1);
        if ($ThisRollPerc < 80) { #class bonus
            $ThisOppRoll = int($ThisOppRoll - ($ThisOppRoll*.4));
        }
    }     
    #Results
    my $gain;    
    my $UsedMana = $rps{$ThisMe}{mana};
    $ThisMySum = int( ($ThisMySum + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    if ($UsedMana == 1) {
        $ThisMySum = int( (($ThisMySum*2) + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
        $ThisMyRoll = int( (($ThisMyRoll*2) + ($rps{$ThisMe}{upgrade}*100))*($rps{$ThisMe}{life}/100) );
    }
    if ($ThisMyClass eq ROGUE) { #Rogue class bonus
        $ThisMyRoll = int(rand($ThisMyRoll - ($ThisMyRoll*.25)) + ($ThisMyRoll*.25));
    }
    else {
        $ThisMyRoll = int(rand($ThisMyRoll));
    }
    $ThisOppRoll = int(rand($ThisOppRoll) + $MinSum);
    my $MyXP = int(rand(9)+1);
    my $OppXP = int(rand(4)+1);
    my $ThisDamage = 1;
    if($rps{$ThisMe}{life} > 30) {
        $ThisDamage = int(rand(9)+1);
    }
    $rps{$ThisMe}{dragontm} = $SlayTime + time();
    my $dragontm = $rps{$ThisMe}{dragontm} - time();
    my $goldamount = $dragon{$ThisOpp}{gold};
    my $itemamount = $dragon{$ThisOpp}{item};
    if ($ThisMyRoll >= $ThisOppRoll) {
        $gain = int(($rps{$ThisMe}{next} * .1)/4);
        $rps{$ThisMe}{mana} = 0;
        $rps{$ThisMe}{experience} += $MyXP;
        $rps{$ThisMe}{next} -= $gain;
        $rps{$ThisMe}{bwon} += 1;
        $rps{$ThisMe}{bminus} += $gain;        
        $rps{$ThisMe}{gold} += $goldamount;
        $rps{$ThisMe}{gems} += $dragon{$ThisOpp}{gem};
        $rps{$ThisMe}{item}{amulet} += $itemamount;
        $rps{$ThisMe}{item}{boots} += $itemamount;
        $rps{$ThisMe}{item}{charm} += $itemamount;
        $rps{$ThisMe}{item}{gloves} += $itemamount;
        $rps{$ThisMe}{item}{helm} += $itemamount;
        $rps{$ThisMe}{item}{leggings} += $itemamount;
        $rps{$ThisMe}{item}{ring} += $itemamount;
        $rps{$ThisMe}{item}{shield} += $itemamount;
        $rps{$ThisMe}{item}{tunic} += $itemamount;
        $rps{$ThisMe}{item}{weapon} += $itemamount;
        chanmsg(clog("$ThisMe 11[$ThisMyRoll/$ThisMySum] tried to slay a $ThisOpp 11[$ThisOppRoll/$ThisOppSum] and won! ".
            duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $MyXP XP. Each item gains $itemamount points."));            
        chanmsg("$ThisMe reaches next level in ".duration($rps{$ThisMe}{next}).", and must wait ".
                duration($dragontm)." to slay again. $ThisMe found $goldamount goldpieces and has ".
                "$rps{$ThisMe}{gold} total gold. They also get $dragon{$ThisOpp}{gem} gems ".
                "and has $rps{$ThisMe}{gems} total gems.");
        find_item($ThisMe);
        item_special_find($ThisMe);
        item_special_proc($ThisMe,$MyXP,"XP");
        item_special_proc($ThisMe,$goldamount,"Gold");
        item_special_proc($ThisMe,$dragon{$ThisOpp}{gem},"Gem");
        item_special_proc($ThisMe,$gain,"TTL");
    }
    else {
        $gain = int((($rps{$ThisMe}{next} * .05)/4)*$AddDamage);
        $rps{$ThisMe}{life} -= int(($ThisDamage*$AddDamage)+5);
        $rps{$ThisMe}{next} += $gain;
        $rps{$ThisMe}{blost} += 1;
        $rps{$ThisMe}{badd} += $gain;
        $rps{$ThisMe}{dragontm} = $SlayTime + time();
        $rps{$ThisMe}{mana} = 0;
        $rps{$ThisMe}{experience} += $OppXP;
        $rps{$ThisMe}{item}{amulet} -= $itemamount;
        $rps{$ThisMe}{item}{boots} -= $itemamount;
        $rps{$ThisMe}{item}{charm} -= $itemamount;
        $rps{$ThisMe}{item}{gloves} -= $itemamount;
        $rps{$ThisMe}{item}{helm} -= $itemamount;
        $rps{$ThisMe}{item}{leggings} -= $itemamount;
        $rps{$ThisMe}{item}{ring} -= $itemamount;
        $rps{$ThisMe}{item}{shield} -= $itemamount;
        $rps{$ThisMe}{item}{tunic} -= $itemamount;
        $rps{$ThisMe}{item}{weapon} -= $itemamount;
        chanmsg(clog("$ThisMe 11[$ThisMyRoll/$ThisMySum] tried to slay a $ThisOpp 11[$ThisOppRoll/$ThisOppSum] and lost! ".
            duration($gain) ." is added to $ThisMe\'s clock. $ThisMe reaches next level in ".
            duration($rps{$ThisMe}{next}) .", and must wait ". duration($dragontm) ." to slay again. ".
            "$ThisMe gets $OppXP XP. Each item loses $itemamount points. $ThisMe has $rps{$ThisMe}{life} life left."));
        item_special_proc($ThisMe,$OppXP,"XP");
        my $ThisLife = int(($ThisDamage*$AddDamage)+5);
        item_special_proc($ThisMe,$ThisLife,"Life");
    }
    if (rand(19) < 1) {
        item_wear($ThisMe);
    }
}

sub item_wear {
    my $ThisPlayer = shift;
    my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
    my $type = $items[rand(@items)];
    my $ThisVal = $rps{$ThisPlayer}{item}{$type};
    my $ThisLvl = int( ($rps{$ThisPlayer}{level}/10) - 1 );
    if ($ThisLvl < 1) {
        $ThisLvl = 1;
    }
    my $ThisDamage = int(rand($ThisLvl) + 1);
    chanmsg("$ThisPlayer $type was damaged and loses $ThisDamage % effectiveness!");
    $ThisDamage = (100-$ThisDamage)/100;
    $rps{$ThisPlayer}{item}{$type} = int($ThisVal*$ThisDamage);    
}

sub item_special_find {
    if (int(rand(19)) < 1) {
        my $ThisPlayer = shift;
        my @items = ("Gold","Gem","Life","XP","TTL","rand");
        my $type = $items[rand(@items)];
        if ($rps{$ThisPlayer}{Special01} eq "0") {
            $rps{$ThisPlayer}{Special01} = $type;
            chanmsg("$ThisPlayer received a $type Stone!");
        }
        elsif ($rps{$ThisPlayer}{Special02} eq "0") {
            $rps{$ThisPlayer}{Special02} = $type;
            chanmsg("$ThisPlayer received a $type Stone!");
        }
        elsif ($rps{$ThisPlayer}{Special03} eq "0") {
            $rps{$ThisPlayer}{Special03} = $type;
            chanmsg("$ThisPlayer received a $type Stone!");
        }
    }
    else {
        return;
    }
}

sub item_special_proc {
    my $ThisPlayer = shift;
    my $ThisAmount = shift;
    my $ThisType = shift;
    if ($ThisAmount > 0) {
        if ($rps{$ThisPlayer}{Special01} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($rps{$ThisPlayer}{Special01} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
        if ($rps{$ThisPlayer}{Special02} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($rps{$ThisPlayer}{Special02} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
        if ($rps{$ThisPlayer}{Special03} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($rps{$ThisPlayer}{Special03} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
    }
    else {
        return;
    }
}

sub item_special_use {
    my $ThisPlayer = shift;
    my $ThisAmount = shift;
    my $ThisType = shift;
    my $Thisrand = shift;
    my $ItemUse = 0;
    my $Amt = 0;
    if ($Thisrand) {
        my @items = ("Gold","Gem","Life","XP","TTL");
        my $type = $items[rand(@items)];
        if ($ThisType eq $type) {
            $ItemUse = $ThisType;
        }
    }
    else {
        $ItemUse = $ThisType;
    }    
    if ($ItemUse eq "Gold") {
        $Amt = int($ThisAmount*.10);
        $rps{$ThisPlayer}{gold} += $Amt;
        chanmsg("$ThisPlayer has a Gold Stone and gets $Amt more gold!");
    }
    elsif ($ItemUse eq "Gem") {
        $Amt = int($ThisAmount*.20);
        if ($Amt > 0) {
            $rps{$ThisPlayer}{gems} += $Amt;
            chanmsg("$ThisPlayer has a Gem Stone and gets $Amt more gem(s)!");
        }        
    }
    elsif ($ItemUse eq "Life") {
        $Amt = int($rps{$ThisPlayer}{life}*.1);
        if ($rps{$ThisPlayer}{life} < 100) {
            if ( $rps{$ThisPlayer}{life} > 0 && ($rps{$ThisPlayer}{life} + $Amt) < 100 ) {
                $rps{$ThisPlayer}{life} += $Amt;
                chanmsg("$ThisPlayer has a Life Stone and gets $Amt life restored!");
            }
            elsif ($rps{$ThisPlayer}{life} > 0) {
                $rps{$ThisPlayer}{life} = 100;
                chanmsg("$ThisPlayer has a Life Stone and gets ALL life restored!");
            }                
        }
    }
    elsif ($ItemUse eq "XP") {
        $Amt = int($ThisAmount*.5);
        if ($Amt > 0) {
            $rps{$ThisPlayer}{experience} += $Amt;
            chanmsg("$ThisPlayer has an XP Stone and gets $Amt more XP!");
        }
    }
    elsif ($ItemUse eq "TTL") {
        $Amt = int($ThisAmount*.20);
        $rps{$ThisPlayer}{next} -= $Amt;
        chanmsg("$ThisPlayer has a TTL Stone and gets ".duration($Amt)." TTL removed!");
    }
    else {
        return;
    }
}

sub item_special_toss {
    my $ThisPlayer = shift;
    my $ThisItem = shift;
    if ($ThisItem eq $rps{$ThisPlayer}{Special01}) {
        $rps{$ThisPlayer}{Special01} = 0;
    }
    elsif ($ThisItem eq $rps{$ThisPlayer}{Special02}) {
        $rps{$ThisPlayer}{Special02} = 0;
    }
    elsif ($ThisItem eq $rps{$ThisPlayer}{Special03}) {
        $rps{$ThisPlayer}{Special03} = 0;
    }
    if ($rps{$ThisPlayer}{Special01} eq "0" && $rps{$ThisPlayer}{Special02} ne "0") {
        $rps{$ThisPlayer}{Special01} = $rps{$ThisPlayer}{Special02};
        if ($rps{$ThisPlayer}{Special03} ne "0") {
            $rps{$ThisPlayer}{Special02} = $rps{$ThisPlayer}{Special03};
            $rps{$ThisPlayer}{Special03} = 0;
        }
        else {
            $rps{$ThisPlayer}{Special02} = 0;
        }
    }
    if ($rps{$ThisPlayer}{Special02} eq "0" && $rps{$ThisPlayer}{Special03} ne "0" ) {
        $rps{$ThisPlayer}{Special02} = $rps{$ThisPlayer}{Special03};
        $rps{$ThisPlayer}{Special03} = 0;
    }
    chanmsg("$ThisPlayer tossed their $ThisItem Stone!");
}

sub ENDtournament {
  return if !$opts{lasttournament};
  my $TournyAmt = 0;
  my $DefaultTournyAmt = $TournyLvl;
  my @Endplayers = grep {$rps{$_}{EndPlayer} > 0} keys(%rps);
  if ($#Endplayers >= 0) {
      $EndTourny = $EndTourny + 1;
  }
  $EndTourny = $EndTourny + 1;
  
  if ($EndTourny == 1) {
    my @u = sort { $rps{$b}{level} <=> $rps{$a}{level} || $rps{$a}{next} <=> $rps{$b}{next} } keys(%rps);
    for my $i (0..$DefaultTournyAmt-1) {
        $rps{$u[$i]}{EndPlayer} = 500;
    }
    writedb();
  }
  
  @ENDtournament = grep { $rps{$_}{life} > 0 && $rps{$_}{EndPlayer} > 0 } keys %rps;
    if (@ENDtournament < 32) {
        if (@ENDtournament < 16) {
            if (@ENDtournament < 8) {
                if (@ENDtournament < 4) {
                    if (@ENDtournament < 2) {
                        chanmsg("4END TOURNY Winner is $ENDtournament[0]");
                    }
                    else {
                        chanmsg("4END TOURNY FINALS");
                        $TournyAmt = 2;
                        $EndPlayerAmt = 1;
                    }
                }
                else {
                    $TournyAmt = 4;
                    $EndPlayerAmt = 2;
                }
            }
            else {
                $TournyAmt = 8;
                $EndPlayerAmt = 3;
            }
        }
        else {
            $TournyAmt = 16;
            $EndPlayerAmt = 4;
        }
    }
    else {
        $TournyAmt = 32;
        $EndPlayerAmt = 5;
    }
  if (@ENDtournament > 1) {
      splice(@ENDtournament,int rand @ENDtournament,1) while @ENDtournament > $TournyAmt;
      chanmsg(join(", ",@ENDtournament)." have been chosen for the 4END TOURNY. Players: $TournyAmt");
      $ENDround = 1;
      $ENDbattle = 1;
      fisher_yates_shuffle( \@ENDtournament );
      $ENDtournamenttime = time() + 20;
  }
  elsif (@ENDtournament == 1) {
      chanmsg(join("",@ENDtournament)." is declared winner and is now a Zombie with 200 chances to eat! ");
      $IsWinner = 1;
      if ($rps{$ENDtournament[0]}{life} > 0) {
          $rps{$ENDtournament[0]}{life} = -100;
          $rps{$ENDtournament[0]}{ffight} = -195;
      }
  }
  if ($IsWinner == 1) {
      my @u = sort { $rps{$b}{level} <=> $rps{$a}{level} || $rps{$a}{next} <=> $rps{$b}{next} } keys(%rps);
      for my $i (0..$DefaultTournyAmt-1) {
          $rps{$u[$i]}{EndPlayer} = 0;
      }
      writedb();
  }
}

sub ENDtournament_battle {
   my $winner;
   my $loser;
   my $p1 = $ENDbattle*2-2;
   my $p2 = $p1 + 1;
   my $p1sum = int(($rps{$ENDtournament[$p1]}{level}*1.5)+(itemsum($ENDtournament[$p1],1)+($rps{$ENDtournament[$p1]}{upgrade}*100))*($rps{$ENDtournament[$p1]}{life}/100));
   my $p2sum = int(($rps{$ENDtournament[$p2]}{level}*1.5)+(itemsum($ENDtournament[$p2],1)+($rps{$ENDtournament[$p2]}{upgrade}*100))*($rps{$ENDtournament[$p2]}{life}/100));
   
   my $HoldSum = 0;
   my $HoldP;
   if ($p1sum < $p2sum) {
    $HoldSum = $p2sum;
    $p2sum = $p1sum;
    $p1sum = $HoldSum;
    $HoldP = $p2;
    $p2 = $p1;
    $p1 = $HoldP;
   }
   my $p1roll = int(rand($p1sum));
   my $p2roll = int(rand($p2sum));
   if ($p1roll >= $p2roll) {
      $winner = $p1;
      $loser = $p2;
   } else {
      $winner = $p2;
      $loser = $p1;
   }
   chanmsg("4END TOURNY ROUND $ENDround, Fight $ENDbattle: $ENDtournament[$p1] ".
      "4[$p1roll/$p1sum] vs $ENDtournament[$p2] 4[$p2roll/$p2sum] ... ".
      "$ENDtournament[$winner] advances. $ENDtournament[$loser] loses.");
        if ($rps{$ENDtournament[$loser]}{EndPlayer} > $EndPlayerAmt) {
            $rps{$ENDtournament[$loser]}{EndPlayer} -= $EndPlayerAmt;
            chanmsg("$ENDtournament[$loser] has $rps{$ENDtournament[$loser]}{EndPlayer} more chances.");
        }
        else {
            $rps{$ENDtournament[$loser]}{EndPlayer} = 0;
            $rps{$ENDtournament[$loser]}{life} = -100;
            $rps{$ENDtournament[$loser]}{ffight} = -95;
            chanmsg("$ENDtournament[$loser] is a Zombie!");
        }
        
   $ENDtournament[$loser] = "xx";
   ++$ENDbattle;
   
   if ($ENDbattle > (@ENDtournament / 2)) {
      ++$ENDround;
      $ENDbattle = 1;
      my $ucnt = (@ENDtournament - 1);
      while ($ucnt > -1) {
         if ($ENDtournament[$ucnt] eq "xx") {
            splice(@ENDtournament,$ucnt ,1);
         }
         --$ucnt;
      }
      if (@ENDtournament > 1) {
         chanmsg(join(", ",@ENDtournament)." advance to round $ENDround of the 4END TOURNY.");
      }
      fisher_yates_shuffle( \@ENDtournament );
   }
   if (@ENDtournament == 1) {
      my $time = 30;
      chanmsg(clog("$ENDtournament[0] has won the 4END TOURNY!"));
      $ENDtournamenttime = time() + 40;
      undef @ENDtournament;
      writedb();
   }
    else {
      $ENDtournamenttime = time() + 20;
   }
}

sub EatPlayers {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $BrainAmt = int(rand(9) + 1);
    if ($rps{$ThisOpp}{life} > $BrainAmt) {
        $rps{$ThisOpp}{life} -= $BrainAmt;
        $rps{$ThisMe}{life} -= int($BrainAmt * 2);
        $rps{$ThisMe}{ffight} += 1;
        $rps{$ThisMe}{EmptyField} = time() + 600;
            chanmsg(clog("$ThisMe has eaten the brains of $ThisOpp and took $BrainAmt life points! ".
            "$ThisMe turns $BrainAmt more Zombie."));
        }
        else {
            $rps{$ThisOpp}{life} -= $BrainAmt;
            if ($rps{$ThisOpp}{life} == 0) { $rps{$ThisOpp}{life} = -10; }
            $rps{$ThisMe}{ffight} -= 2;
        $rps{$ThisMe}{EmptyField} = time() + 600;
            $rps{$ThisMe}{life} -= $BrainAmt;
            chanmsg(clog("$ThisMe has eaten all the brains of $ThisOpp they are now a Zombie! ".
            "$ThisMe turns $BrainAmt more Zombie and gets 2 more fights."));
    } 
}

sub readconfig {
    if (-r $opts{conffile}) {
        open(CONF, '<', $opts{conffile}) or return;

        my($line,$key,$val);

        while ($line=<CONF>) {
            next() if $line =~ /^#/; # skip comments

            $line =~ s/[\r\n]//g;
            $line =~ s/^\s+//g;

            next() if !length($line); # skip blank lines

            ($key,$val) = split(/\s+/,$line,2);

            $key = lc($key);
            $val = "" if(!defined($val));

            if    (lc($val) eq "on"  || lc($val) eq "yes") { $val = 1; }
            elsif (lc($val) eq "off" || lc($val) eq "no")  { $val = 0; }

            if ($key eq "die") {
                die("Please edit the file $opts{conffile} to setup your bot's options. Also, read the README file if you haven't yet.\n");
            }
            elsif ($key eq "server") {
                push(@{$opts{servers}},$val);
            }
            elsif ($key eq "okurl")  {
                push(@{$opts{okurl}},$val);
            }
            else {
                $opts{$key} = $val;
            }
        }
    }
}

sub backup() {
    if (! -d ".dbbackup") { mkdir(".dbbackup",0700); }
    if ($^O ne "MSWin32") {
        system("cp $opts{dbfile} .dbbackup/$opts{dbfile}".time());
    }
    else {
        system("copy $opts{dbfile} .dbbackup\\$opts{dbfile}".time());
    }
}

sub loadjsondb {
    %rps = ();

    if(-r $opts{dbfile}) {
        my $json = read_file($opts{dbfile}, err_mode => 'carp');
        
        if($json) {
            my $data = from_json(encode('utf8', $json), { utf8 => 1 });

            %rps = %{$data};

            return $data;
        }
    }

    return;
}

sub writejsondb() {
    delete $rps{''} if(exists $rps{''});
    foreach my $username (keys %rps) {
        delete $rps{$username} if(!defined $rps{$username}{level});
    }

    my $json = to_json(\%rps, { utf8 => 1, pretty => 1 });

    if(!write_file($opts{dbfile}, { err_mode => 'carp' }, $json)) {
        chanmsg("ERROR: Cannot write $opts{dbfile}: $!");
        return;
    }

    return $json;
}

sub loaddb {
    backup();
    
    %rps = ();

    if (!-r $opts{dbfile}) {
        sts("QUIT :loaddb() cannot read database");
        return;
    }
    if (!open(RPS,$opts{dbfile})) {
        sts("QUIT :loaddb() failed: $!");
        return;
    }

    my $l = '';
    my $n = 1;
    my $r = undef;

    while ($l=<RPS>) {
        chomp($l);

        # new JSON database format
        if($n == 1 && $l =~ /^\{/o) {
            $r = loadjsondb();
            last;
        }

        next if $l =~ /^#/;

        my @i = split("\t",$l);

        print Dumper(@i) if @i != 80;
        if (@i != 80) {
            sts("QUIT: Anomaly in loaddb(); line $. of $opts{dbfile} has wrong fields (".scalar(@i).")");
            debug("Anomaly in loaddb(); line $. of $opts{dbfile} has wrong fields (".scalar(@i).")",1);
            last;
        }

        if (!$sock) {
            if ($i[8]) { $prev_online{$i[7]}=$i[0]; }
        }

        ($rps{$i[0]}{pass},
        $rps{$i[0]}{admin},
        $rps{$i[0]}{level},
        $rps{$i[0]}{class},
        $rps{$i[0]}{next},
        $rps{$i[0]}{nick},
        $rps{$i[0]}{userhost},
        $rps{$i[0]}{online},
        $rps{$i[0]}{idled},
        $rps{$i[0]}{pos_x},
        $rps{$i[0]}{pos_y},
        $rps{$i[0]}{pen_mesg},
        $rps{$i[0]}{pen_nick},
        $rps{$i[0]}{pen_part},
        $rps{$i[0]}{pen_kick},
        $rps{$i[0]}{pen_quit},
        $rps{$i[0]}{pen_quest},
        $rps{$i[0]}{pen_logout},
        $rps{$i[0]}{created},
        $rps{$i[0]}{last_login},
        $rps{$i[0]}{item}{amulet},
        $rps{$i[0]}{item}{charm},
        $rps{$i[0]}{item}{helm},
        $rps{$i[0]}{item}{boots},
        $rps{$i[0]}{item}{gloves},
        $rps{$i[0]}{item}{ring},
        $rps{$i[0]}{item}{leggings},
        $rps{$i[0]}{item}{shield},
        $rps{$i[0]}{item}{tunic},
        $rps{$i[0]}{item}{weapon},
        $rps{$i[0]}{alignment},
        $rps{$i[0]}{ffight},
        $rps{$i[0]}{bwon},
        $rps{$i[0]}{blost},
        $rps{$i[0]}{badd},
        $rps{$i[0]}{bminus},
        $rps{$i[0]}{gold},
        $rps{$i[0]}{powerpotion},
        $rps{$i[0]}{status},
        $rps{$i[0]}{ability},
        $rps{$i[0]}{gems},
        $rps{$i[0]}{upgrade},
        $rps{$i[0]}{rt},
        $rps{$i[0]}{dm},
        $rps{$i[0]}{cl},
        $rps{$i[0]}{pw},
        $rps{$i[0]}{aw},
        $rps{$i[0]}{lw},
        $rps{$i[0]}{alw},
        $rps{$i[0]}{tt},
        $rps{$i[0]}{bt},
        $rps{$i[0]}{regentm},
        $rps{$i[0]}{dragontm},
        $rps{$i[0]}{mana},
        $rps{$i[0]}{lotto11},
        $rps{$i[0]}{lotto12},
        $rps{$i[0]}{lotto13},
        $rps{$i[0]}{lotto21},
        $rps{$i[0]}{lotto22},
        $rps{$i[0]}{lotto23},
        $rps{$i[0]}{lotto31},
        $rps{$i[0]}{lotto32},
        $rps{$i[0]}{lotto33},
        $rps{$i[0]}{experience},
        $rps{$i[0]}{life},
        $rps{$i[0]}{lottowins},
        $rps{$i[0]}{lottosumwins},
        $rps{$i[0]}{aligntime},
        $rps{$i[0]}{Worktime},
        $rps{$i[0]}{Towntime},
        $rps{$i[0]}{Foresttime},
        $rps{$i[0]}{Special01},
        $rps{$i[0]}{Special02},
        $rps{$i[0]}{Special03},
        $rps{$i[0]}{ExpertItem01},
        $rps{$i[0]}{ExpertItem02},
        $rps{$i[0]}{ExpertItem03},
        $rps{$i[0]}{EndPlayer},
        $rps{$i[0]}{EmptyField}) = (@i[1..7],($sock?$i[8]:0),@i[9..$#i]);

        $n++;
        $r = \%rps;
    }
    close(RPS);

    return $r;
}

sub writedb {
    # New databases should only use the JSON format
    return writejsondb();

    open(RPS,">$opts{dbfile}") or do {
        chanmsg("ERROR: Cannot write $opts{dbfile}: $!");
        return 0;
    };
    print RPS join("\t","# username",
        "pass",
        "admin",
        "level",
        "class",
        "next",
        "nick",
        "userhost",
        "online",
        "idled",
        "pos_x",
        "pos_y",
        "pen_mesg",
        "pen_nick",
        "pen_part",
        "pen_kick",
        "pen_quit",
        "pen_quest",
        "pen_logout",
        "created",
        "last_login",
        "amulet",
        "charm",
        "helm",
        "boots",
        "gloves",
        "ring",
        "leggings",
        "shield",
        "tunic",
        "weapon",
        "alignment",
        "ffight",
        "bwon",
        "blost",
        "badd",
        "bminus",
        "gold",
        "powerpotion",
        "status",
        "ability",
        "gems",
        "upgrade",
        "rt",
        "dm",
        "cl",
        "pw",
        "aw",
        "lw",
        "alw",
        "tt",
        "bt",
        "regentm",
        "dragontm",
        "mana",
        "lotto11",
        "lotto12",
        "lotto13",
        "lotto21",
        "lotto22",
        "lotto23",
        "lotto31",
        "lotto32",
        "lotto33",
        "experience",
        "life",
        "lottowins",
        "lottosumwins",
        "aligntime",
        "Worktime",
        "Towntime",
        "Foresttime",
        "Special01",
        "Special02",
        "Special03",
        "ExpertItem01",
        "ExpertItem02",
        "ExpertItem03",
        "EndPlayer",
        "EmptyField")."\n";
    my $k;
    keys(%rps);
    while ($k=each(%rps)) {
        if (exists($rps{$k}{next}) && defined($rps{$k}{next})) {
            print RPS join("\t",$k,
                $rps{$k}{pass},
                $rps{$k}{admin},
                $rps{$k}{level},
                $rps{$k}{class},
                $rps{$k}{next},
                $rps{$k}{nick},
                $rps{$k}{userhost},
                $rps{$k}{online},
                $rps{$k}{idled},
                $rps{$k}{pos_x},
                $rps{$k}{pos_y},
                $rps{$k}{pen_mesg},
                $rps{$k}{pen_nick},
                $rps{$k}{pen_part},
                $rps{$k}{pen_kick},
                $rps{$k}{pen_quit},
                $rps{$k}{pen_quest},
                $rps{$k}{pen_logout},
                $rps{$k}{created},
                $rps{$k}{last_login},
                $rps{$k}{item}{amulet},
                $rps{$k}{item}{charm},
                $rps{$k}{item}{helm},
                $rps{$k}{item}{boots},
                $rps{$k}{item}{gloves},
                $rps{$k}{item}{ring},
                $rps{$k}{item}{leggings},
                $rps{$k}{item}{shield},
                $rps{$k}{item}{tunic},
                $rps{$k}{item}{weapon},
                $rps{$k}{alignment},
                $rps{$k}{ffight},
                $rps{$k}{bwon},
                $rps{$k}{blost},
                $rps{$k}{badd},
                $rps{$k}{bminus},
                $rps{$k}{gold},
                $rps{$k}{powerpotion},
                $rps{$k}{status},
                $rps{$k}{ability},
                $rps{$k}{gems},
                $rps{$k}{upgrade},
                $rps{$k}{rt},
                $rps{$k}{dm},
                $rps{$k}{cl},
                $rps{$k}{pw},
                $rps{$k}{aw},
                $rps{$k}{lw},
                $rps{$k}{alw},
                $rps{$k}{tt},
                $rps{$k}{bt},
                $rps{$k}{regentm},
                $rps{$k}{dragontm},
                $rps{$k}{mana},
                $rps{$k}{lotto11},
                $rps{$k}{lotto12},
                $rps{$k}{lotto13},
                $rps{$k}{lotto21},
                $rps{$k}{lotto22},
                $rps{$k}{lotto23},
                $rps{$k}{lotto31},
                $rps{$k}{lotto32},
                $rps{$k}{lotto33},
                $rps{$k}{experience},
                $rps{$k}{life},
                $rps{$k}{lottowins},
                $rps{$k}{lottosumwins},
                $rps{$k}{aligntime},
                $rps{$k}{Worktime},
                $rps{$k}{Towntime},
                $rps{$k}{Foresttime},
                $rps{$k}{Special01},
                $rps{$k}{Special02},
                $rps{$k}{Special03},
                $rps{$k}{ExpertItem01},
                $rps{$k}{ExpertItem02},
                $rps{$k}{ExpertItem03},
                $rps{$k}{EndPlayer},
                $rps{$k}{EmptyField})."\n";
        }
    }
    close(RPS);
}

