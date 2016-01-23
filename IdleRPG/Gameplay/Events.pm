package Events;

#use IdleRPG::IRC;
#use IdleRPG::Simulation;

sub moveplayers {
    return unless $IRC::lasttime > 1;
    my $onlinecount = grep { $Simulation::rps{$_}{online} } keys %Simulation::rps;
    return unless $onlinecount;
    for (my $i=0;$i<$Options::opts{self_clock};++$i) {
        my %positions = ();
        if ($Quests::quest{type} == 2 && @{$Quests::quest{questers}}) {
            my $allgo = 1;
            for (@{$Quests::quest{questers}}) {
                if ($Quests::quest{stage}==1) {
                    if ($Simulation::rps{$_}{pos_x} != $Quests::quest{p1}->[0] ||
                        $Simulation::rps{$_}{pos_y} != $Quests::quest{p1}->[1]) {
                        $allgo=0;
                        last();
                    }
                }
                else {
                    if ($Simulation::rps{$_}{pos_x} != $Quests::quest{p2}->[0] ||
                        $Simulation::rps{$_}{pos_y} != $Quests::quest{p2}->[1]) {
                        $allgo=0;
                        last();
                    }
                }
            }
            if ($Quests::quest{stage}==1 && $allgo) {
                $Quests::quest{stage}=2;
                $allgo=0;
            }
            elsif ($Quests::quest{stage} == 2 && $allgo) {
                IRC::chanmsg(Simulation::clog(join(", ",(@{$Quests::quest{questers}})[0..$Options::opts{questminplayers}-2]).", ".
                     "and $Quests::quest{questers}->[$Options::opts{questminplayers}-1] have completed their ".
                     "journey! 25% of their burden is eliminated and they have a chance to find an item."));
                for (@{$Quests::quest{questers}}) {
                    $Simulation::rps{$_}{next} = int($Simulation::rps{$_}{next} * .75);
                    Equipment::find_item($_);
                    Events::find_gold($_);
                    PVE::monst_attack($_);
                }
                undef(@{$Quests::quest{questers}});
                $Quests::quest{qtime} = time() + 3600;
                $Quests::quest{type} = 1;
                Quests::writequestfile();
            }
            else {
                my(%temp,$player);
                ++@temp{grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps)};
                delete(@temp{@{$Quests::quest{questers}}});
                while ($player = each(%temp)) {
                    $Simulation::rps{$player}{pos_x} += int(rand(3))-1;
                    $Simulation::rps{$player}{pos_y} += int(rand(3))-1;
                    # if player goes over edge, wrap them back around
                    if ($Simulation::rps{$player}{pos_x} > $Options::opts{mapx}) { $Simulation::rps{$player}{pos_x}=0; }
                    if ($Simulation::rps{$player}{pos_y} > $Options::opts{mapy}) { $Simulation::rps{$player}{pos_y}=0; }
                    if ($Simulation::rps{$player}{pos_x} < 0) { $Simulation::rps{$player}{pos_x}=$Options::opts{mapx}; }
                    if ($Simulation::rps{$player}{pos_y} < 0) { $Simulation::rps{$player}{pos_y}=$Options::opts{mapy}; }

                    if (exists($positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}) &&
                        !$positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{battled}) {
                        if ($Simulation::rps{$positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{user}}{admin} &&
                            !$Simulation::rps{$player}{admin} && rand(100) < 1) {
                            IRC::chanmsg("$player encounters ".
                               $positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{user}." and bows humbly.");
                        }
                        if (rand($onlinecount) < 1) {
                            $positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{battled}=1;
                            Events::collision_fight($player,$positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{user});
                        }
                    }
                    else {
                        $positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{battled}=0;
                        $positions{$Simulation::rps{$player}{pos_x}}{$Simulation::rps{$player}{pos_y}}{user}=$player;
                    }
                }
                for (@{$Quests::quest{questers}}) {
                    if ($Quests::quest{stage} == 1) {
                        if (rand(100) < 1) {
                            if ($Simulation::rps{$_}{pos_x} != $Quests::quest{p1}->[0]) {
                                $Simulation::rps{$_}{pos_x} += ($Simulation::rps{$_}{pos_x} < $Quests::quest{p1}->[0] ? 1 : -1);
                            }
                            if ($Simulation::rps{$_}{pos_y} != $Quests::quest{p1}->[1]) {
                                $Simulation::rps{$_}{pos_y} += ($Simulation::rps{$_}{pos_y} < $Quests::quest{p1}->[1] ? 1 : -1);
                            }
                        }
                    }
                    elsif ($Quests::quest{stage}==2) {
                        if (rand(100) < 1) {
                            if ($Simulation::rps{$_}{pos_x} != $Quests::quest{p2}->[0]) {
                                $Simulation::rps{$_}{pos_x} += ($Simulation::rps{$_}{pos_x} < $Quests::quest{p2}->[0] ? 1 : -1);
                            }
                            if ($Simulation::rps{$_}{pos_y} != $Quests::quest{p2}->[1]) {
                                $Simulation::rps{$_}{pos_y} += ($Simulation::rps{$_}{pos_y} < $Quests::quest{p2}->[1] ? 1 : -1);
                            }
                        }
                    }
                }
            }
        }
        else {
            for my $xplayer (keys(%Simulation::rps)) {
                next unless $Simulation::rps{$xplayer}{online};
                $Simulation::rps{$xplayer}{pos_x} += int(rand(3))-1;
                $Simulation::rps{$xplayer}{pos_y} += int(rand(3))-1;
                if ($Simulation::rps{$xplayer}{pos_x} > $Options::opts{mapx}) { $Simulation::rps{$xplayer}{pos_x} = 0; }
                if ($Simulation::rps{$xplayer}{pos_y} > $Options::opts{mapy}) { $Simulation::rps{$xplayer}{pos_y} = 0; }
                if ($Simulation::rps{$xplayer}{pos_x} < 0) { $Simulation::rps{$xplayer}{pos_x} = $Options::opts{mapx}; }
                if ($Simulation::rps{$xplayer}{pos_y} < 0) { $Simulation::rps{$xplayer}{pos_y} = $Options::opts{mapy}; }
                if (exists($positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}) &&
                    !$positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{battled}) {
                    if ($Simulation::rps{$positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{user}}{admin} &&
                        !$Simulation::rps{$xplayer}{admin} && rand(100) < 1) {
                        IRC::chanmsg("$xplayer encounters ".
                           $positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{user}." and bows humbly.");
                    }
                    if (rand($onlinecount) < 1) {
                        $positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{battled}=1;
                        Events::collision_fight($xplayer,$positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{user});
                    }
                }
                else {
                    $positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{battled}=0;
                    $positions{$Simulation::rps{$xplayer}{pos_x}}{$Simulation::rps{$xplayer}{pos_y}}{user}=$xplayer;
                }
            }
        }
    }
}


sub find_gold {
    my $u = shift;
    my $goldamount = int((rand($Simulation::rps{$u}{level})*3)+10);
    $Simulation::rps{$u}{gold} += $goldamount;
    IRC::chanmsg("$u found $goldamount goldpieces lying on the ground and picked them up to sum $Simulation::rps{$u}{gold} total gold. ");
}

sub find_gems {
    my $u = shift;
    my $gemsamount = int(rand(4)+1);
    $Simulation::rps{$u}{gems} += $gemsamount;
    IRC::chanmsg("$u found $gemsamount gems and has $Simulation::rps{$u}{gems} total gems. ");
}

sub random_gold {
    my @players = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{status} == FOREST } keys(%Simulation::rps);
    return unless @players;
    my $player = $players[rand(@players)];
    my $goldamount = int((rand($Simulation::rps{$player}{level})*3)+10);
    $Simulation::rps{$player}{gold} += $goldamount;
    IRC::chanmsg("$player just walked by $goldamount goldpieces and picked them up to sum $Simulation::rps{$player}{gold} total gold. ");
}

sub calamity {
    my @players = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    return unless @players;
    my $player = $players[rand(@players)];
    if (rand(4) < 1) {
        my @items = ("amulet","boots","charm","gloves","helm","leggings","ring","shield","tunic","weapon");
        my $type = $items[rand(@items)];
        if ($type eq "amulet") {
            IRC::chanmsg(Simulation::clog("$player fell, chipping the stone in their amulet! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "boots") {
            IRC::chanmsg(Simulation::clog("$player stepped in some dragon shit! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "charm") {
            IRC::chanmsg(Simulation::clog("$player slipped and dropped their charm in a dirty bog! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "gloves") {
            IRC::chanmsg(Simulation::clog("$player tried to pick up some green slime! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "helm") {
            IRC::chanmsg(Simulation::clog("$player needs a haircut! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "leggings") {
            IRC::chanmsg(Simulation::clog("$player burned a hole through their leggings while ironing! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "ring") {
            IRC::chanmsg(Simulation::clog("$player scratched their ring! $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "shield") {
            IRC::chanmsg(Simulation::clog("$player\'s shield was damaged while polishing it $player\'s $type loses 10% effectiveness."));
        }
        elsif ($type eq "tunic") {
            IRC::chanmsg(Simulation::clog("$player spilled a level 7 shrinking potion on their tunic! $player\'s $type loses 10% effectiveness."));
        }
        else {
            IRC::chanmsg(Simulation::clog("$player left their weapon out in the rain to rust! $player\'s $type loses 10% effectiveness."));
        }
        my $suffix="";
        if ($Simulation::rps{$player}{item}{$type} =~ /(\D)$/) { $suffix=$1; }
        $Simulation::rps{$player}{item}{$type} = int($Simulation::rps{$player}{item}{$type} * .9);
        $Simulation::rps{$player}{item}{$type}.=$suffix;
    }
    else {
        my $time = int(int(5 + rand(8)) / 100 * $Simulation::rps{$player}{next});
        if (!open(Q,$Options::opts{eventsfile})) {
            return IRC::chanmsg("ERROR: Failed to open $Options::opts{eventsfile}: $!");
        }
        my($i,$actioned);
        while (my $line = <Q>) {
            chomp($line);
            if ($line =~ / (.*)/ && rand(++$i) < 1) { $actioned = $1; }
        }
        close(Q) or do {
            return IRC::chanmsg("ERROR: Failed to close $Options::opts{eventsfile}: $!");
        };
        IRC::chanmsg(Simulation::clog("$player $actioned. This terrible calamity has slowed them ".Simulation::duration($time)." from level ".($Simulation::rps{$player}{level}+1)."."));
        $Simulation::rps{$player}{next} += $time;
        IRC::chanmsg("$player reaches next level in ".Simulation::duration($Simulation::rps{$player}{next}).".");
    }
}

sub godsend {
    my @players = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    return unless @players;
    my $player = $players[rand(@players)];
    if (rand(4) < 1) {
        my @items = ("amulet","boots","charm","gloves","helm","leggings","ring","shield","tunic","weapon");
        my $type = $items[rand(@items)];
        if ($type eq "amulet") {
            IRC::chanmsg(Simulation::clog("$player\'s amulet was blessed by a passing cleric! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "boots") {
            IRC::chanmsg(Simulation::clog("$player\'s boots were shined! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "charm") {
            IRC::chanmsg(Simulation::clog("$player\'s charm ate a bolt of lightning! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "gloves") {
            IRC::chanmsg(Simulation::clog("The local wizard imbued $player\'s gloves with dragon claw powder! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "helm") {
            IRC::chanmsg(Simulation::clog("The blacksmith added an MP3 player to $player\'s helm! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "leggings") {
            IRC::chanmsg(Simulation::clog("$player\'s $type were dry cleaned...finally! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "ring") {
            IRC::chanmsg(Simulation::clog("$player had the gem in their ring reset! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "shield") {
            IRC::chanmsg(Simulation::clog("$player reinforced their shield with dragon scales! $player\'s $type gains 10% effectiveness."));
        }
        elsif ($type eq "tunic") {
            IRC::chanmsg(Simulation::clog("A magician cast a spell of Rigidity on $player\'s tunic! $player\'s $type gains 10% effectiveness."));
        }
        else {
            IRC::chanmsg(Simulation::clog("$player sharpened the edge of their weapon! $player\'s $type gains 10% effectiveness."));
        }
        my $suffix="";
        if ($Simulation::rps{$player}{item}{$type} =~ /(\D)$/) { $suffix=$1; }
        $Simulation::rps{$player}{item}{$type} = int($Simulation::rps{$player}{item}{$type} * 1.1);
        $Simulation::rps{$player}{item}{$type}.=$suffix;
    }
    else {
        my $time = int(int(5 + rand(8)) / 100 * $Simulation::rps{$player}{next});
        my $actioned;
        if (!open(Q,$Options::opts{eventsfile})) {
            return IRC::chanmsg("ERROR: Failed to open $Options::opts{eventsfile}: $!");
        }
        my $i;
        while (my $line = <Q>) {
            chomp($line);
            if ($line =~ /^G (.*)/ && rand(++$i) < 1) {
                $actioned = $1;
            }
        }
        close(Q) or do {
            return IRC::chanmsg("ERROR: Failed to close $Options::opts{eventsfile}: $!");
        };
        IRC::chanmsg(Simulation::clog("$player $actioned. This moves them ".Simulation::duration($time)." closer towards level ".($Simulation::rps{$player}{level}+1)."."));
        $Simulation::rps{$player}{next} -= $time;
        IRC::chanmsg("$player reaches next level in ".Simulation::duration($Simulation::rps{$player}{next}).".");
    }
}

sub hog {
    my @players = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    my $player = $players[rand(@players)];
    my $win = int(rand(5));
    my $time = int(((5 + int(rand(71)))/100) * $Simulation::rps{$player}{next});
    if ($win) {
        IRC::chanmsg(Simulation::clog("The Hand of God carried $player ".Simulation::duration($time)." toward level ".($Simulation::rps{$player}{level}+1)."."));
        $Simulation::rps{$player}{next} -= $time;
    }
    else {
        IRC::chanmsg(Simulation::clog("Lucifer consumed $player with fire, adding ".Simulation::duration($time)." from level ".($Simulation::rps{$player}{level}+1)."."));
        $Simulation::rps{$player}{next} += $time;
    }
    IRC::chanmsg("$player reaches next level in ".Simulation::duration($Simulation::rps{$player}{next}).".");
}

sub AutoHeal {
    my @NeedLife;
    my $Healed = "";
    my $factor = 0;
    my $pay = 0;
        @NeedLife = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 15 && $Simulation::rps{$_}{life} < 15 && $Simulation::rps{$_}{life} > 0 } keys %Simulation::rps;
        if (@NeedLife > 0) {
            for my $i (0..$#NeedLife) {
                $factor = int($Simulation::rps{$NeedLife[$i]}{level}/5);
                $pay = int((100-$Simulation::rps{$NeedLife[$i]}{life})*$factor*1.1);
                if ($Simulation::rps{$NeedLife[$i]}{gold} > ($pay*2)) {
                    $Simulation::rps{$NeedLife[$i]}{gold} -= $pay;
                    $Simulation::rps{$NeedLife[$i]}{life} = 100;
                    $Healed = $Healed . $NeedLife[$i] . ", ";
                }
            }
            if (!$Healed eq "") {
                $Healed = substr($Healed, 0,length($Healed)-2);
                IRC::chanmsg("The wandering healer has healed: $Healed for some profit. They could save gold by healing themself.");
            }
        }
        @NeedLife = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 15 && $Simulation::rps{$_}{life} < 15 && $Simulation::rps{$_}{life} < 0 } keys %Simulation::rps;
        if (@NeedLife > 0) {
            for my $i (0..$#NeedLife) {
                $pay = 20;
                if ($Simulation::rps{$NeedLife[$i]}{gold} > ($pay)) {
                    $Simulation::rps{$NeedLife[$i]}{gold} -= $pay;
                    $Simulation::rps{$NeedLife[$i]}{life} = 1;
                    $Healed = $Healed . $NeedLife[$i] . ", ";
                }
            }
            if (!$Healed eq "") {
                $Healed = substr($Healed, 0,length($Healed)-2);
                IRC::chanmsg("The wandering healer resurrected: $Healed for some profit. They could save gold by healing themself.");
            }
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
        @foresters = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{status} == FOREST } keys(%Simulation::rps);
    }
    for my $i (0..$#foresters) {
        if ($ForestEntry == 1) {
        #on 1 player entering
            if (rand(4) < 1) { PVE::creep_fight($foresters[$i]); }
            if (rand(4) < 1) { Events::find_gems($foresters[$i]); }
        }
        elsif ($CaveEntry == 1) {
        #on 1 player exploring a cave
            if (rand(4) < 1) { PVE::creep_fight($foresters[$i]); }
            if (rand(3) < 1) { Events::find_gems($foresters[$i]); }
        }
        elsif (time() - $Simulation::rps{$foresters[$i]}{Foresttime} > 14400) {
        #on greater than 4 hours
            if (rand(3) < 1) { PVE::creep_fight($foresters[$i]); }
            if (rand(3) < 1) { Events::find_gems($foresters[$i]); }
        }
    }
}

sub evilnessOffline {
    my $ThisEvil = shift;
    my $me;
    if ($ThisEvil) {
        $me = $ThisEvil;
    }
    else {
        my @evil = grep {$Simulation::rps{$_}{online} && $Simulation::rps{$_}{alignment} eq "e"} keys(%Simulation::rps);
        return unless @evil;
        $me = $evil[rand(@evil)];
    }
    if (int(rand(2)) < 1) {
        my @Offline = grep {!$Simulation::rps{$_}{online} && ($Simulation::rps{$_}{last_login} < time() - 86400)} keys(%Simulation::rps);
        my $target = $Offline[rand(@Offline)];
        my @items = ("gold","gems");
        my $type = $items[rand(@items)];
        if ($Simulation::rps{$target}{$type} > 0) {
            my $ThisValue = int($Simulation::rps{$target}{$type} * .25);
            if ($ThisValue > 0) {
                $Simulation::rps{$me}{$type} += $ThisValue;
                $Simulation::rps{$target}{$type} -= $ThisValue;
            }
            else {
                $ThisValue = $Simulation::rps{$target}{$type};
                $Simulation::rps{$me}{$type} += $ThisValue;
                $Simulation::rps{$target}{$type} = 0;
            }
            IRC::chanmsg(Simulation::clog("$me stole $ThisValue $type from $target while they were offline"));
        }
    }
}

sub evilness {
    my $ThisEvil = shift;
    my $me;
    if ($ThisEvil) {
        $me = $ThisEvil;
    }
    else {
        my @evil = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{alignment} eq "e" } keys(%Simulation::rps);
        return unless @evil;
        $me = $evil[rand(@evil)];
    }
    if (int(rand(3)) < 1) {
        # evil only steals items from good or evil (but not themselves)
        my @players = grep { $Simulation::rps{$_}{online} && ($Simulation::rps{$_}{alignment} eq "g" || $Simulation::rps{$_}{alignment} eq "e") && $_ ne $me } keys(%Simulation::rps);
        if (@players > 0) {
            my $target = $players[rand(@players)];
            my $type;
            if ($Simulation::rps{$target}{gold} > 150) {
                my $ThisValue = int($Simulation::rps{$target}{gold} * .05);
                $Simulation::rps{$me}{gold} += $ThisValue;
                $Simulation::rps{$target}{gold} -= $ThisValue;
                IRC::chanmsg(Simulation::clog("$me stole $ThisValue gold from $target!"));
            }
            elsif ($Simulation::rps{$target}{gems} > 15) {
                my $ThisValue = int($Simulation::rps{$target}{gems} * .05);
                if ($ThisValue < 1) {$ThisValue = 1;}
                $Simulation::rps{$me}{gems} += $ThisValue;
                $Simulation::rps{$target}{gems} -= $ThisValue;
                IRC::chanmsg(Simulation::clog("$me stole $ThisValue gems from $target!"));
            }
        }
    }
    elsif (int(rand(4)) < 1) {
        # evil only steals items from good or evil (but not themselves)
        my @players = grep { $Simulation::rps{$_}{online} && ($Simulation::rps{$_}{alignment} eq "g" || $Simulation::rps{$_}{alignment} eq "e") && $_ ne $me } keys(%Simulation::rps);
        if (@players > 0) {
            my $target = $players[rand(@players)];
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if ($Simulation::rps{$target}{item}{$type} > $Simulation::rps{$me}{item}{$type}) {
                my $tempitemamount = int($Simulation::rps{$target}{item}{$type} * ((rand(40) + 10) / 100));
                $Simulation::rps{$me}{item}{$type} += $tempitemamount;
                $Simulation::rps{$target}{item}{$type} -= $tempitemamount;
                IRC::chanmsg(Simulation::clog("$me stole an upgrade scroll from $target worth $tempitemamount points from their $type."));
            }
            else {
                IRC::chanmsg("$me stole $target\'s $type, but it was lower level than $me\'s own. $me returns the $type.");
            }
        }
    }
    else {
        my $gain = 1 + int(rand(5));
        IRC::chanmsg(Simulation::clog("$me was caught stealing, however, they still get 5 XP for trying."));
        $Simulation::rps{$me}{experience} += 5;
    }
}

sub goodness {
    my @players = grep { ($Simulation::rps{$_}{alignment} eq "g" || 0) && $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    return unless @players > 1;
    splice(@players,int(rand(@players)),1) while @players > 2;
    my $gain = 5 + int(rand(8));
    IRC::chanmsg(Simulation::clog("$players[0] and $players[1] have prayed so $gain\% of their time is removed from their clocks."));
    $Simulation::rps{$players[0]}{next} = int($Simulation::rps{$players[0]}{next}*(1 - ($gain/100)));
    $Simulation::rps{$players[1]}{next} = int($Simulation::rps{$players[1]}{next}*(1 - ($gain/100)));
    IRC::chanmsg("$players[0] reaches next level in ".Simulation::duration($Simulation::rps{$players[0]}{next}).".");
    IRC::chanmsg("$players[1] reaches next level in ".Simulation::duration($Simulation::rps{$players[1]}{next}).".");
}

sub collision_fight {
    my($u,$opp) = @_;
    my $mysum = int((Equipment::itemsum($u,1)+($Simulation::rps{$u}{upgrade}*100))*($Simulation::rps{$u}{life}/100));
    my $oppsum = int((Equipment::itemsum($opp,1)+($Simulation::rps{$opp}{upgrade}*100))*($Simulation::rps{$opp}{life}/100));
    my $myroll = int(rand($mysum));
    my $opproll = int(rand($oppsum));
    my $xp = int(rand(4)+1);
    my $oxp = int(rand(2)+1);
    my $adamage = 0;
    my $ddamage = 0;
    if($Simulation::rps{$opp}{life} > 10) {
        $adamage = int(rand(4)+1);
    }
    if($Simulation::rps{$u}{life} > 10) {
        $ddamage = int(rand(4)+1);
    }
    if ($myroll >= $opproll) {
        my $gain = int($Simulation::rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$u}{next});
        $Simulation::rps{$opp}{life} -= $adamage;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has come upon $opp [$opproll/$oppsum] and taken them in combat! ".Simulation::duration($gain)." is ".
            "removed from $u\'s clock. $u gets $xp XP and $opp gets $oxp XP. $opp has $Simulation::rps{$opp}{life}\% of their Life remaining."));
        $Simulation::rps{$u}{next} -= $gain;
        $Simulation::rps{$u}{experience} += $xp;
        $Simulation::rps{$opp}{experience} += $oxp;
        $Simulation::rps{$u}{bwon} += 1;
        $Simulation::rps{$opp}{blost} += 1;
        $Simulation::rps{$u}{bminus} += $gain;
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
        if (rand(35) < 1 && $opp ne $IRC::primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $Simulation::rps{$opp}{next});
            IRC::chanmsg(Simulation::clog("$u has dealt $opp a Critical Strike! ".Simulation::duration($gain)." is added to $opp\'s clock."));
            $Simulation::rps{$opp}{next} += $gain;
            $Simulation::rps{$opp}{badd} += $gain;
            IRC::chanmsg("$opp reaches next level in ".Simulation::duration($Simulation::rps{$opp}{next}).".");
        }
        elsif (rand(25) < 1 && $opp ne $IRC::primnick && $Simulation::rps{$u}{level} > 19) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");

            my $type = $items[rand(@items)];
            if ($Simulation::rps{$opp}{item}{$type} > $Simulation::rps{$u}{item}{$type}) {
                IRC::chanmsg("In the fierce battle, $opp dropped their level ".$Simulation::rps{$opp}{item}{$type}." $type! $u picks it up, ".
                    "tossing their old level ".$Simulation::rps{$u}{item}{$type}." $type to $opp.");
                my $tempitem = $Simulation::rps{$u}{item}{$type};
                $Simulation::rps{$u}{item}{$type}=$Simulation::rps{$opp}{item}{$type};
                $Simulation::rps{$opp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($opp eq $IRC::primnick)?10:int($Simulation::rps{$opp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$u}{next});
        $Simulation::rps{$u}{life} -= $ddamage;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has come upon $opp [$opproll/$oppsum] and been defeated in combat! ".Simulation::duration($gain)." is ".
            "added to $u\'s clock. $u gets $oxp XP and $opp gets $xp XP. $u has $Simulation::rps{$u}{life}\% of their Life remaining."));
        $Simulation::rps{$u}{next} += $gain;
        $Simulation::rps{$u}{experience} += $oxp;
        $Simulation::rps{$opp}{experience} += $xp;
        $Simulation::rps{$u}{blost} += 1;
        $Simulation::rps{$opp}{bwon} += 1;
        $Simulation::rps{$u}{badd} += $gain;
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
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
    IRC::chanmsg("The Lottery numbers for today are: $nr1, $nr2 and $nr3. Lotto Sum is: $nrsum.");
    my @winners =
        grep { $Simulation::rps{$_}{online} && (
            ($Simulation::rps{$_}{lotto11} == $nr1 && $Simulation::rps{$_}{lotto12} == $nr2 && $Simulation::rps{$_}{lotto13} == $nr3) ||
            ($Simulation::rps{$_}{lotto21} == $nr1 && $Simulation::rps{$_}{lotto22} == $nr2 && $Simulation::rps{$_}{lotto23} == $nr3) ||
            ($Simulation::rps{$_}{lotto31} == $nr1 && $Simulation::rps{$_}{lotto32} == $nr2 && $Simulation::rps{$_}{lotto33} == $nr3)
        ) } keys(%Simulation::rps);
    if (@winners > 0) {
        IRC::chanmsg("The Lottery winner(s) are: @winners!");
    }
    else {
        IRC::chanmsg("The are no Lottery winners.");
    }
    while (@winners > 0) {
        my $ThisPos = int(rand(@winners));
        my $winner = $winners[$ThisPos];
        $Simulation::rps{$winner}{gems} += 50;
        $Simulation::rps{$winner}{gold} += 2000;
        $Simulation::rps{$winner}{lottowins} += 1;
        splice(@winners,$ThisPos,1);
    }
    my @winners_sum =
        grep { $Simulation::rps{$_}{online} && (
            ($Simulation::rps{$_}{lotto11} + $Simulation::rps{$_}{lotto12} + $Simulation::rps{$_}{lotto13} == $nrsum) ||
            ($Simulation::rps{$_}{lotto21} + $Simulation::rps{$_}{lotto22} + $Simulation::rps{$_}{lotto23} == $nrsum) ||
            ($Simulation::rps{$_}{lotto31} + $Simulation::rps{$_}{lotto32} + $Simulation::rps{$_}{lotto33} == $nrsum)
        ) } keys(%Simulation::rps);
    if (@winners_sum > 0) {
        IRC::chanmsg("The Lotto Sum winner(s) are: @winners_sum!");
    }
    else {
        IRC::chanmsg("The are no Lotto Sum winners.");
    }
    while (@winners_sum > 0) {
        my $ThisPos = int(rand(@winners_sum));
        my $winner_sum = $winners_sum[$ThisPos];
        $Simulation::rps{$winner_sum}{gems} += 1;
        $Simulation::rps{$winner_sum}{gold} += 150;
        $Simulation::rps{$winner_sum}{lottosumwins} += 1;
        splice(@winners_sum,$ThisPos,1);
    }
}

1;
