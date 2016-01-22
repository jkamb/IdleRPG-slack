package PVP;

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

sub BattlePlayers {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $Simulation::rps{$ThisMe}{ability};
    my $ThisMySum = Equipment::itemsum($ThisMe,0);
    my $ThisOppClass = $Simulation::rps{$ThisOpp}{ability};
    my $ThisOppSum = Equipment::itemsum($ThisOpp,0);
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
    my $ThisOppLife = $Simulation::rps{$ThisOpp}{life};
    if ($ThisOppLife < 0) {
        $ThisOppLife = $ThisOppLife * -1;
    }
    $ThisMySum = int( ($ThisMySum + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    $ThisOppSum = int( ($ThisOppSum + ($Simulation::rps{$ThisOpp}{upgrade}*100))*($ThisOppLife /100) );
    $ThisOppRoll = int( ($ThisOppRoll + ($Simulation::rps{$ThisOpp}{upgrade}*100))*($ThisOppLife /100) );

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
        my $gain = ($ThisOpp eq $IRC::primnick)?20:int($Simulation::rps{$ThisOpp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$ThisMe}{next});
        if($Simulation::rps{$ThisOpp}{life} > 10 || $Simulation::rps{$ThisOpp}{life} < -10) {
            $ThisDamage = int(rand(4)+1);
        }
        if ($Simulation::rps{$ThisOpp}{life} < 0) {
           $Simulation::rps{$ThisOpp}{life} += $ThisDamage;
        }
        else {
            $Simulation::rps{$ThisOpp}{life} -= $ThisDamage;
        }
        $Simulation::rps{$ThisMe}{experience} += $ThisMyXP;
        $Simulation::rps{$ThisOpp}{experience} += $ThisOppXP;
        $Simulation::rps{$ThisMe}{next} -= $gain;
        $Simulation::rps{$ThisMe}{bwon} += 1;
        $Simulation::rps{$ThisOpp}{blost} += 1;
        $Simulation::rps{$ThisMe}{bminus} += $gain;
        $Simulation::rps{$ThisMe}{ffight} += 1;
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] has challenged $ThisOpp [$ThisOppRoll/$ThisOppSum] ".
            "and won! ".Simulation::duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $ThisMyXP XP, ".
            "$ThisOpp gets $ThisOppXP XP. $ThisOpp has $Simulation::rps{$ThisOpp}{life}\% of their Life remaining."));
        IRC::chanmsg("$ThisMe reaches next level in ".Simulation::duration($Simulation::rps{$ThisMe}{next}).".");
        Equipment::item_special_proc($ThisMe,$ThisMyXP,"XP");
        Equipment::item_special_proc($ThisMe,$gain,"TTL");
        Equipment::item_special_proc($ThisOpp,$ThisOppXP,"XP");
        Equipment::item_special_proc($ThisOpp,$ThisDamage,"Life");
        my $csfactor = $Simulation::rps{$ThisMe}{alignment} eq "g" ? 50 :
                       $Simulation::rps{$ThisMe}{alignment} eq "e" ? 20 :
                       35;
        if (rand($csfactor) < 1 && $ThisOpp ne $IRC::primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $Simulation::rps{$ThisOpp}{next});
            IRC::chanmsg(Simulation::clog("$ThisMe has dealt $ThisOpp a Critical Blow! ".
                Simulation::duration($gain)." is added to $ThisOpp\'s clock."));
            $Simulation::rps{$ThisOpp}{next} += $gain;
            IRC::chanmsg("$ThisOpp reaches next level in ".Simulation::duration($Simulation::rps{$ThisOpp}{next}).".");
        }
        elsif (rand(25) < 1 && $ThisOpp ne $IRC::primnick && $Simulation::rps{$ThisMe}{level} > 35) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if (int($Simulation::rps{$ThisOpp}{item}{$type}) > int($Simulation::rps{$ThisMe}{item}{$type})) {
                IRC::chanmsg(Simulation::clog("In the fierce battle, $ThisOpp dropped their level ".int($Simulation::rps{$ThisOpp}{item}{$type}).
                    " $type! $ThisMe picks it up, tossing their old level ".int($Simulation::rps{$ThisMe}{item}{$type}).
                    " $type to $ThisOpp."));
                my $tempitem = $Simulation::rps{$ThisMe}{item}{$type};
                $Simulation::rps{$ThisMe}{item}{$type}=$Simulation::rps{$ThisOpp}{item}{$type};
                $Simulation::rps{$ThisOpp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($ThisOpp eq $IRC::primnick)?10:int($Simulation::rps{$ThisOpp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$ThisMe}{next});
        if($Simulation::rps{$ThisMe}{life} > 10) {
            $ThisDamage = int(rand(4)+1);
        }
        $Simulation::rps{$ThisMe}{life} -= $ThisDamage;
        $Simulation::rps{$ThisMe}{experience} += $ThisOppXP;
        $Simulation::rps{$ThisOpp}{experience} += $ThisMyXP;
        $Simulation::rps{$ThisMe}{next} += $gain;
        $Simulation::rps{$ThisMe}{blost} += 1;
        $Simulation::rps{$ThisOpp}{bwon} += 1;
        $Simulation::rps{$ThisMe}{badd} += $gain;
        $Simulation::rps{$ThisMe}{ffight} += 1;
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] has challenged $ThisOpp [$ThisOppRoll/$ThisOppSum] ".
            "and lost! ".Simulation::duration($gain)." is added to $ThisMe\'s clock. $ThisMe gets $ThisOppXP XP, ".
            "$ThisOpp gets $ThisMyXP XP. $ThisMe has $Simulation::rps{$ThisMe}{life}\% of their Life remaining."));
        IRC::chanmsg("$ThisMe reaches next level in ".Simulation::duration($Simulation::rps{$ThisMe}{next}).".");
        Equipment::item_special_proc($ThisMe,$ThisOppXP,"XP");
        Equipment::item_special_proc($ThisMe,$ThisDamage,"Life");
        Equipment::item_special_proc($ThisOpp,$ThisMyXP,"XP");
        if (rand(49) < 1) {
           my $TempTTL = $Simulation::rps{$ThisMe}{next};
           $Simulation::rps{$ThisMe}{next} += $TempTTL;
           IRC::chanmsg(Simulation::clog("$ThisOpp hit back hard so $ThisMe\'s TTL is doubled. $ThisMe reaches next level in ".
           Simulation::duration($Simulation::rps{$ThisMe}{next})."."));
        }
    }
    if (rand(19) < 1) {
        Equipment::item_wear($ThisMe);
    }
    if (rand(19) < 1) {
        Equipment::item_wear($ThisOpp);
    }
}

sub challenge_opp {
    my $u = shift;
    if ($Simulation::rps{$u}{level} < 25) { return unless rand(4) < 1; }
    my @opps = grep { $Simulation::rps{$_}{online} && $u ne $_ } keys(%Simulation::rps);
    unless (@opps && rand(5) > 0) {
    monst_attack_player($u);
    return;
    }
    my $opp = $opps[int(rand(@opps))];
    my $mysum = 0;
    if ($Simulation::rps{$u}{upgrade} > 0) {
        $mysum = int((Equipment::itemsum($u,1)+($Simulation::rps{$u}{upgrade}*100))*($Simulation::rps{$u}{life}/100));
    }
    else {
        $mysum = int((Equipment::itemsum($u,1))*($Simulation::rps{$u}{life}/100));
    }
    my $oppsum = 0;
    if ($Simulation::rps{$opp}{upgrade} > 0) {
        $oppsum = int((Equipment::itemsum($opp,1)+($Simulation::rps{$opp}{upgrade}*100))*($Simulation::rps{$opp}{life}/100));
    }
    else {
        $oppsum = int((Equipment::itemsum($opp,1))*($Simulation::rps{$opp}{life}/100));
    }
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
        my $gain = ($opp eq $IRC::primnick)?20:int($Simulation::rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$u}{next});
        $Simulation::rps{$opp}{life} -= $adamage;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has challenged $opp [$opproll/$oppsum] in combat and won! ".Simulation::duration($gain)." is ".
            "removed from $u\'s clock. $u gets $xp XP and $opp gets $oxp XP. $opp has $Simulation::rps{$opp}{life}\% of their Life remaining."));
        $Simulation::rps{$u}{next} -= $gain;
        $Simulation::rps{$u}{bwon} += 1;
        $Simulation::rps{$opp}{blost} += 1;
        $Simulation::rps{$u}{bminus} += $gain;
        $Simulation::rps{$u}{experience} += $xp;
        $Simulation::rps{$opp}{experience} += $oxp;
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
        my $csfactor = $Simulation::rps{$u}{alignment} eq "g" ? 50 :
           $Simulation::rps{$u}{alignment} eq "e" ? 20 : 35;
        if (rand($csfactor) < 1 && $opp ne $IRC::primnick) {
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
                IRC::chanmsg(Simulation::clog("In the fierce battle, $opp dropped their level $Simulation::rps{$opp}{item}{$type} $type! $u picks ".
                     "it up, tossing their old level $Simulation::rps{$u}{item}{$type} $type to $opp."));
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
        $Simulation::rps{$u}{next} += $gain;
        $Simulation::rps{$u}{experience} += $oxp;
        $Simulation::rps{$opp}{experience} += $xp;
        $Simulation::rps{$u}{blost} += 1;
        $Simulation::rps{$opp}{bwon} += 1;
        $Simulation::rps{$u}{badd} += $gain;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has challenged $opp [$opproll/$oppsum] in combat and lost! ".Simulation::duration($gain)." is ".
            "added to $u\'s clock. $u gets $oxp XP and $opp gets $xp XP. $u has $Simulation::rps{$u}{life}\% of their Life remaining."));
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
    }
}

sub war { # let the four quadrants battle
    my @players = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    my @quadrantname = ("Northeast", "Southeast", "Southwest", "Northwest");
    my %quadrant = ();
    my @sum = (0,0,0,0,0);
    for my $k (@players) {
        # "quadrant" 4 is for players in the middle
        $quadrant{$k} = 4;
        if (2 * $Simulation::rps{$k}{pos_y} + 1 < $Options::opts{mapy}) {
            $quadrant{$k} = 3 if (2 * $Simulation::rps{$k}{pos_x} + 1 < $Options::opts{mapx});
            $quadrant{$k} = 0 if (2 * $Simulation::rps{$k}{pos_x} + 1 > $Options::opts{mapx});
        }
        elsif (2 * $Simulation::rps{$k}{pos_y} + 1 > $Options::opts{mapy})
        {
            $quadrant{$k} = 2 if (2 * $Simulation::rps{$k}{pos_x} + 1 < $Options::opts{mapx});
            $quadrant{$k} = 1 if (2 * $Simulation::rps{$k}{pos_x} + 1 > $Options::opts{mapx});
        }
        $sum[$quadrant{$k}] += Equipment::itemsum($k);
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
        IRC::chanmsg(Simulation::clog("The war between the four parts of the realm $winnertext, whereas it $losertext. $neutraltext"));
    }
    elsif ($winnertext eq "" && $losertext eq "") {
        IRC::chanmsg(Simulation::clog("The war between the four parts of the realm was well-balanced. $neutraltext"));
    }
    else {
        IRC::chanmsg(Simulation::clog("The war between the four parts of the realm $winnertext$losertext. $neutraltext"));
    }
    for my $k (@players) {
        $Simulation::rps{$k}{next} = int($Simulation::rps{$k}{next} / 2) if ($iswinner[$quadrant{$k}]);
        $Simulation::rps{$k}{next} *= 2 if ($isloser[$quadrant{$k}]);
    }
}



1;
