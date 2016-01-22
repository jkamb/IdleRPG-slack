package Simulation;

#use IdleRPG::Database;
#use IdleRPG::Options;
#use IdleRPG::IRC;
#use IdleRPG::Gameplay::Events;
#use IdleRPG::Gameplay::Equipment;
#use IdleRPG::Gameplay::Quests;
#use IdleRPG::Gameplay::Tournaments;
#use IdleRPG::Gameplay::PVP;

our %rps = Database::loadjsondb();

my $rpreport = 0;
my $oldrpreport = 0;

our $pausemode = 0;
my $IsEnding = 0;

my $selfrestarttime = time() + 43000;

sub rpcheck {
    IRC::fq();
    $lastreg = 0;
    my $online = scalar(grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps));
    return unless $online;
    my $onlineevil = scalar(grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{alignment} eq "e" } keys(%Simulation::rps));
    my $onlinegood = scalar(grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{alignment} eq "g" } keys(%Simulation::rps));
    if (!$Options::opts{noscale}) {
        if (rand((8*86400)/$Options::opts{self_clock}) < $online) { Events::hog();          }
        if (rand((4*86400)/$Options::opts{self_clock}) < $online) { Events::calamity();     }
        if (rand((4*86400)/$Options::opts{self_clock}) < $online) { Events::godsend();      }
        if (rand((1*86400)/$Options::opts{self_clock}) < $online) { Events::random_gold();  }
        if (rand((4*86400)/$Options::opts{self_clock}) < $online) { PVE::monst_hunt();   }
        if (rand((4*86400)/$Options::opts{self_clock}) < $online) { PVE::monst_attack(); }
    }
    else {
        Events::hog()          if rand(4000) < 1;
        Events::calamity()     if rand(4000) < 1;
        Events::godsend()      if rand(2000) < 1;
        Events::random_gold()  if rand(500)  < 1;
        PVE::monst_hunt()   if rand(4000) < 1;
        PVE::monst_attack() if rand(500)  < 1;
    }
    if (rand((86400)/$Options::opts{self_clock}) < $onlineevil) {
        Events::evilness();
        Events::evilnessOffline();
    }
    if (rand((8*86400)/$Options::opts{self_clock}) < $onlinegood) { Events::goodness(); }
    Events::moveplayers();
    if (($rpreport%120 < $oldrpreport%120) && $Options::opts{writequestfile}) { Quests::writequestfile(); }
    if (time() > $Quests::quest{qtime}) {
        if (!@{$Quests::quest{questers}}) { Quests::quest(); }
        elsif ($Quests::quest{type} == 1) {
            IRC::chanmsg(Simulation::clog(join(", ",(@{$Quests::quest{questers}})[0..$Options::opts{questplayers}-2]).", and $Quests::quest{questers}->[$Options::opts{questplayers}-1] have blessed the realm by ".
                "completing their quest! 25% of their burden is eliminated and they have a chance to find an ITEM each."));
            for (@{$Quests::quest{questers}}) {
                $Simulation::rps{$_}{next} = int($Simulation::rps{$_}{next} * .75);
                Equipment::find_item($_);
                Events::find_gold($_);
                PVE::monst_attack($_);
            }
            undef(@{$Quests::quest{questers}});
            $Quests::quest{qtime} = time() + 21600;
            Quests::writequestfile();
        }
    }
    #tournaments
    if ($Options::opts{tournament} && time() > $Tournaments::tournamenttime) {
        if (!@Tournaments::tournament) { Tournaments::tournament(); }
        else { Tournaments::tournament_battle(); }
    }
    if ($Options::opts{selfrestart} && time() > $selfrestarttime && !@Tournaments::tournament && !@Tournaments::deathmatch && !@Tournaments::megawar && !@Tournaments::powerwar && !@Tournaments::abilitywar && !@Tournaments::locationwar && !@Tournaments::alignwar) {
        Database::writejsondb(\%Simulation::rps);
        IRC::sts("QUIT :SELF-RESTART",1);
        close($IRC::sock);
        exec("perl $0");
    }
    if ($Options::opts{selfrestart} && time() > $selfrestarttime && @Tournaments::tournament) {
        $selfrestarttime = time() + 1800; #wait for these to end
    }
    if ($Options::opts{selfrestart} && time() > $selfrestarttime && @Tournaments::deathmatch) {
        $selfrestarttime = time() + 1800; #wait for these to end
    }
    #end tournaments
    #deathmatch
    if ($Options::opts{deathmatch} && time() > $Tournaments::deathmatchtime) {
        if (!@Tournaments::deathmatch) { Tournaments::deathmatch(); }
        else { Tournaments::deathmatch_battle(); }
    }
    #end deathmatch
    #megawar
    if ($Options::opts{megawar} && time() > $Tournaments::megawartime) {
        if (!@Tournaments::megawar) { Tournaments::megawar(); }
        else { Tournaments::megawar_battle(); }
    }
    #end megawar
    #powerwar
    if ($Options::opts{powerwar} && time() > $Tournaments::powerwartime) {
        if (!@Tournaments::powerwar) { Tournaments::powerwar(); }
        else { Tournaments::powerwar_battle(); }
    }
    #end powerwar
    #abilitywar
    if ($Options::opts{abilitywar} && time() > $Tournaments::abilitywartime) {
        if (!@Tournaments::abilitywar) { Tournaments::abilitywar(); }
        else { Tournaments::abilitywar_battle(); }
    }
    #end abilitywar
    #locationwar
    if ($Options::opts{locationwar} && time() > $Tournaments::locationwartime) {
        if (!@Tournaments::locationwar) { Tournaments::locationwar(); }
        else { Tournaments::locationwar_battle(); }
    }
    #end locationwar
    #alignwar
    if ($Options::opts{alignwar} && time() > $Tournaments::alignwartime) {
        if (!@Tournaments::alignwar) { Tournaments::alignwar(); }
        else { Tournaments::alignwar_battle(); }
    }
    #end alignwar

    if ($rpreport && ($rpreport%14400 < $oldrpreport%14400)) { # 4 hours
        my @u = sort { ( ($Simulation::rps{$b}{level} || 0) <=> ($Simulation::rps{$a}{level} || 0) ) ||
            ( ($Simulation::rps{$a}{next} || 0) <=> ($Simulation::rps{$b}{next} || 0) ) } keys(%Simulation::rps);

        my $n = $#u + 1;
           $n = 10 if(10 < $n);

        IRC::chanmsg("Idle RPG Top $n Players:") if @u;
        for my $i (0..9) {
            last if(!defined $u[$i] || !defined $Simulation::rps{$u[$i]}{level});

            my $tempsum = Equipment::itemsum($u[$i],0);

            IRC::chanmsg("#" . ($i + 1) . " - $u[$i]".
            " | Lvl $Simulation::rps{$u[$i]}{level} | TTL " .(Simulation::duration($Simulation::rps{$u[$i]}{next})).
            " | Align $Simulation::rps{$u[$i]}{alignment} | Ability $Simulation::rps{$u[$i]}{ability}".
            " | Life $Simulation::rps{$u[$i]}{life} | Sum $tempsum");
        }
    }
    if (($rpreport%3600 < $oldrpreport%3600) && $rpreport) { # 1 hour
        my @players = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 44 } keys(%Simulation::rps);
        # 20% of all players must be level 45+
        if ((scalar(@players)/scalar(grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps))) > .15) {
            PVP::challenge_opp($players[int(rand(@players))]);
        }
    }
    if ($rpreport%1800 < $oldrpreport%1800) { # 30 mins
        if ($Options::opts{botnick} ne $IRC::primnick) {
            IRC::sts($Options::opts{botghostcmd}) if $Options::opts{botghostcmd};
            IRC::sts("NICK $IRC::primnick");
        }
    }
    if (($rpreport%14400 < $oldrpreport%14400)) { # every 4 hours
        if ($IsEnding == 0) {
            Events::AutoHeal();
        }
    }
    if (($rpreport%21600 < $oldrpreport%21600)) { # every 6 hours
        Events::forestwalk();
    }
    if (($rpreport%28800 < $oldrpreport%28800)) { # every 8 hours
        Events::lottery();
    }
    if (($rpreport%28800 < $oldrpreport%28800)) { # every 8 hours
        Database::backup();
    }
    if (($rpreport%600 < $oldrpreport%600) && $pausemode) { # warn every 10m
        IRC::chanmsg("WARNING: Cannot write database in PAUSE mode!");
    }
    if ($IRC::lasttime != 1) {
        my $curtime=time();
        for my $k (keys(%Simulation::rps)) {
            if ($Simulation::rps{$k}{online} && exists $Simulation::rps{$k}{nick} && $Simulation::rps{$k}{nick} && exists $IRC::onchan{$Simulation::rps{$k}{nick}}) {
                $Simulation::rps{$k}{next} -= ($curtime - $IRC::lasttime);
                $Simulation::rps{$k}{idled} += ($curtime - $IRC::lasttime);
                if ($Simulation::rps{$k}{next} < 1) {
                    my $ttl = int(Level::ttl($Simulation::rps{$k}{level}));
                    $Simulation::rps{$k}{level}++;
                    $Simulation::rps{$k}{next} += $ttl;
                    IRC::chanmsg("$k, the $Simulation::rps{$k}{class}, has attained level $Simulation::rps{$k}{level}! Next level in ".Simulation::duration($ttl).".");
                    Equipment::find_item($k);
                    Events::find_gold($k);
                    Events::find_gems($k);
                    PVP::challenge_opp($k);
                    $Simulation::rps{$k}{regentm} = time();
                    $Simulation::rps{$k}{ffight} = 0;
                    $Simulation::rps{$k}{scrolls} = 0;
                }
            }
        }
        if (!$pausemode && ($rpreport%60 < $oldrpreport%60)) { Database::writejsondb(\%Simulation::rps); }
        $oldrpreport = $rpreport;
        $rpreport += $curtime - $IRC::lasttime;
        $IRC::lasttime = $curtime;
    }
}


sub duration {
    my $s = shift;
    return "NA ($s)" if $s !~ /^\d+$/;
    return sprintf("%d day%s, %02d:%02d:%02d",$s/86400,int($s/86400)==1?"":"s", ($s%86400)/3600,($s%3600)/60,($s%60));
}

sub clog {
    my $mesg = shift;
    open(B,">>$Options::opts{modsfile}") or do {
        IRC::chanmsg("Error: Cannot open $Options::opts{modsfile}: $!");
        return $mesg;
    };
    print B ts()."$mesg\n";
    close(B);
    return $mesg;
}

sub ts { # timestamp
    my @ts = localtime(time());
    return sprintf("[%02d/%02d/%02d %02d:%02d:%02d] ", $ts[4]+1,$ts[3],$ts[5]%100,$ts[2],$ts[1],$ts[0]);
}


1;
