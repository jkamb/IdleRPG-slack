package PVE;

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

our %monster = Monsters::getList();
our %dragon = Dragons::getList();

my $SlayTime = 43200;

sub dragon_fight {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $Simulation::rps{$ThisMe}{ability};
    my $ThisOppSum = $dragon{$ThisOpp}{sum};
    my $ThisOppRoll = $ThisOppSum;
    my $ThisMySum = Equipment::itemsum($ThisMe,0);
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
    my $UsedMana = $Simulation::rps{$ThisMe}{mana};
    $ThisMySum = int( ($ThisMySum + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    if ($UsedMana == 1) {
        $ThisMySum = int( (($ThisMySum*2) + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
        $ThisMyRoll = int( (($ThisMyRoll*2) + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
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
    if($Simulation::rps{$ThisMe}{life} > 30) {
        $ThisDamage = int(rand(9)+1);
    }
    $Simulation::rps{$ThisMe}{dragontm} = $SlayTime + time();
    my $dragontm = $Simulation::rps{$ThisMe}{dragontm} - time();
    my $goldamount = $dragon{$ThisOpp}{gold};
    my $itemamount = $dragon{$ThisOpp}{item};
    if ($ThisMyRoll >= $ThisOppRoll) {
        $gain = int(($Simulation::rps{$ThisMe}{next} * .1)/4);
        $Simulation::rps{$ThisMe}{mana} = 0;
        $Simulation::rps{$ThisMe}{experience} += $MyXP;
        $Simulation::rps{$ThisMe}{next} -= $gain;
        $Simulation::rps{$ThisMe}{bwon} += 1;
        $Simulation::rps{$ThisMe}{bminus} += $gain;
        $Simulation::rps{$ThisMe}{gold} += $goldamount;
        $Simulation::rps{$ThisMe}{gems} += $dragon{$ThisOpp}{gem};
        $Simulation::rps{$ThisMe}{item}{amulet} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{boots} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{charm} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{gloves} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{helm} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{leggings} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{ring} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{shield} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{tunic} += $itemamount;
        $Simulation::rps{$ThisMe}{item}{weapon} += $itemamount;
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] tried to slay a $ThisOpp [$ThisOppRoll/$ThisOppSum] and won! ".
            Simulation::duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $MyXP XP. Each item gains $itemamount points."));
        IRC::chanmsg("$ThisMe reaches next level in ".Simulation::duration($Simulation::rps{$ThisMe}{next}).", and must wait ".
                Simulation::duration($dragontm)." to slay again. $ThisMe found $goldamount goldpieces and has ".
                "$Simulation::rps{$ThisMe}{gold} total gold. They also get $dragon{$ThisOpp}{gem} gems ".
                "and has $Simulation::rps{$ThisMe}{gems} total gems.");
        Equipment::find_item($ThisMe);
        Equipment::item_special_find($ThisMe);
        Equipment::item_special_proc($ThisMe,$MyXP,"XP");
        Equipment::item_special_proc($ThisMe,$goldamount,"Gold");
        Equipment::item_special_proc($ThisMe,$dragon{$ThisOpp}{gem},"Gem");
        Equipment::item_special_proc($ThisMe,$gain,"TTL");
    }
    else {
        $gain = int((($Simulation::rps{$ThisMe}{next} * .05)/4)*$AddDamage);
        $Simulation::rps{$ThisMe}{life} -= int(($ThisDamage*$AddDamage)+5);
        $Simulation::rps{$ThisMe}{next} += $gain;
        $Simulation::rps{$ThisMe}{blost} += 1;
        $Simulation::rps{$ThisMe}{badd} += $gain;
        $Simulation::rps{$ThisMe}{dragontm} = $SlayTime + time();
        $Simulation::rps{$ThisMe}{mana} = 0;
        $Simulation::rps{$ThisMe}{experience} += $OppXP;
        $Simulation::rps{$ThisMe}{item}{amulet} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{boots} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{charm} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{gloves} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{helm} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{leggings} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{ring} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{shield} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{tunic} -= $itemamount;
        $Simulation::rps{$ThisMe}{item}{weapon} -= $itemamount;
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] tried to slay a $ThisOpp [$ThisOppRoll/$ThisOppSum] and lost! ".
            Simulation::duration($gain) ." is added to $ThisMe\'s clock. $ThisMe reaches next level in ".
            Simulation::duration($Simulation::rps{$ThisMe}{next}) .", and must wait ". Simulation::duration($dragontm) ." to slay again. ".
            "$ThisMe gets $OppXP XP. Each item loses $itemamount points. $ThisMe has $Simulation::rps{$ThisMe}{life}\% of their Life remaining.."));
        Equipment::item_special_proc($ThisMe,$OppXP,"XP");
        my $ThisLife = int(($ThisDamage*$AddDamage)+5);
        Equipment::item_special_proc($ThisMe,$ThisLife,"Life");
    }
    if (rand(19) < 1) {
        Equipment::item_wear($ThisMe);
    }
}

sub monster_fight {
    my $ThisMe = shift;
    my $ThisOpp = shift;
    my $ThisMyClass = $Simulation::rps{$ThisMe}{ability};
    my $ThisOppSum = $monster{$ThisOpp}{sum};
    my $ThisOppRoll = $ThisOppSum;
    my $ThisMySum = Equipment::itemsum($ThisMe,0);
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
    $ThisMySum = int( ($ThisMySum + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    $ThisMyRoll = int( ($ThisMyRoll + ($Simulation::rps{$ThisMe}{upgrade}*100))*($Simulation::rps{$ThisMe}{life}/100) );
    if ($ThisMyClass eq ROGUE) { #Rogue class bonus
        $ThisMyRoll = int(rand($ThisMyRoll - ($ThisMyRoll*.25)) + ($ThisMyRoll*.25));
    }
    else {
        $ThisMyRoll = int(rand($ThisMyRoll));
    }
    $ThisOppRoll = int(rand($ThisOppRoll));
    $Simulation::rps{$ThisMe}{regentm} = ($Simulation::rps{$ThisMe}{level}*120)+21600+time();
    my $regentm = $Simulation::rps{$ThisMe}{regentm}-time();
    if ($ThisMyRoll >= $ThisOppRoll) {
        $Simulation::rps{$ThisMe}{gold} += $monster{$ThisOpp}{gold};
        $Simulation::rps{$ThisMe}{gems} += $monster{$ThisOpp}{gem};
        $gain = int($Simulation::rps{$ThisMe}{next} * .05);
        $Simulation::rps{$ThisMe}{experience} += $ThisMyXP;
        $Simulation::rps{$ThisMe}{next} -= $gain;
        $Simulation::rps{$ThisMe}{bwon} += 1;
        $Simulation::rps{$ThisMe}{bminus} += $gain;
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] has attacked a $ThisOpp [$ThisOppRoll/$ThisOppSum] and killed it! ".
            Simulation::duration($gain)." is removed from $ThisMe\'s clock. $ThisMe gets $ThisMyXP XP."));
        Equipment::find_expert_item($ThisMe);
        IRC::chanmsg("$ThisMe reaches next level in ".Simulation::duration($Simulation::rps{$ThisMe}{next}).", and must wait ".
            Simulation::duration($regentm)." to attack again.");
        if ($monster{$ThisOpp}{gold} > 0) {
            IRC::chanmsg("$ThisMe found $monster{$ThisOpp}{gold} goldpieces and has $Simulation::rps{$ThisMe}{gold} total gold.");
            Equipment::item_special_proc($ThisMe,$monster{$ThisOpp}{gold},"Gold");
        }
        if ($monster{$ThisOpp}{gem} > 0) {
            IRC::chanmsg("$ThisMe found $monster{$ThisOpp}{gem} gems and has $Simulation::rps{$ThisMe}{gems} total gems.");
            Equipment::item_special_proc($ThisMe,$monster{$ThisOpp}{gem},"Gem");
        }
        Equipment::find_item($ThisMe);
        Equipment::item_special_proc($ThisMe,$ThisMyXP,"XP");
        Equipment::item_special_proc($ThisMe,$gain,"TTL");
    }
    else {
        my $ThisDamage = 5;
        if($Simulation::rps{$ThisMe}{life} > 20) {
            $ThisDamage = int(rand(9)+1);
        }
        $gain = int($Simulation::rps{$ThisMe}{next} * .05);
        $Simulation::rps{$ThisMe}{life} -= $ThisDamage;
        $Simulation::rps{$ThisMe}{experience} += $ThisOppXP;
        $Simulation::rps{$ThisMe}{next} += $gain;
        $Simulation::rps{$ThisMe}{blost} += 1;
        $Simulation::rps{$ThisMe}{badd} += $gain;
        $Simulation::rps{$ThisMe}{regentm} = ($Simulation::rps{$ThisMe}{level}*120)+21600+time();
        IRC::chanmsg(Simulation::clog("$ThisMe [$ThisMyRoll/$ThisMySum] has attacked a $ThisOpp [$ThisOppRoll/$ThisOppSum] and lost! ".
            Simulation::duration($gain)." is added to $ThisMe\'s clock. $ThisMe gets $ThisOppXP XP. $ThisMe has ".
            "$Simulation::rps{$ThisMe}{life}\% of their Life remaining."));
        IRC::chanmsg("$ThisMe reaches next level in ".Simulation::duration($Simulation::rps{$ThisMe}{next}).", and must wait ".
            Simulation::duration($regentm)." to attack again.");
        Equipment::item_special_proc($ThisMe,$ThisOppXP,"XP");
        Equipment::item_special_proc($ThisMe,$ThisDamage,"Life");
    }
    if (rand(19) < 1) {
        Equipment::item_wear($ThisMe);
    }
}

sub creep_fight {
    my $user = shift;
    my @randcreep;
    my $ThisCreep;
    if ($Simulation::rps{$user}{regentm} < time()) {
        if ($Simulation::rps{$user}{level} <= 75) {
            @randcreep = grep { $PVE::monster{$_}{level} <= $Simulation::rps{$user}{level} &&  $PVE::monster{$_}{level} >= ($Simulation::rps{$user}{level} - 10)} keys(%PVE::monster);
            $ThisCreep = $randcreep[int(rand($#randcreep))]
        }
        elsif ($Simulation::rps{$user}{level} > 75 && $Simulation::rps{$user}{level} < 100) {
            $ThisCreep = "Phoenix"
        }
        else {
            $ThisCreep = "Werewolf"
        }
    }
    return unless $ThisCreep;
    PVE::monster_fight($user, $ThisCreep);
}

sub monst_attack {
    my @players = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    return unless @players;
    return monst_attack_player($players[rand(@players)]);
}

sub monst_attack_player {
    my $u = shift;
    my $mysum = int((Equipment::itemsum($u,1)+($Simulation::rps{$u}{upgrade}*100))*($Simulation::rps{$u}{life}/100));
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
    my $monname = Monsters::get_monst_name($monsum);
    $monroll = int(rand($monsum));
    if ($myroll >= $monroll) {
        $gain = int($gain*$Simulation::rps{$u}{next}/100);
        $Simulation::rps{$u}{next} -= $gain;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has been set upon by some $monname ".
             "[$monroll/$monsum] and won! ".Simulation::duration($gain)." is removed from $u\'s clock."));
    }
    else {
        $loss = int($loss*$Simulation::rps{$u}{next}/100);
        $Simulation::rps{$u}{next} += $loss;
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has been set upon by some $monname ".
            "[$monroll/$monsum] and lost! ".Simulation::duration($loss)." is added to $u\'s clock."));
    }
    IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
}

sub monst_hunt {
    my @opp = grep { $Simulation::rps{$_}{online} } keys(%Simulation::rps);
    return if @opp < 3;
    splice(@opp,int(rand(@opp)),1) while @opp > 3;
    RNG::fisher_yates_shuffle(\@opp);
    my $mysum = Equipment::itemsum($opp[0],1) + Equipment::itemsum($opp[1],1) + Equipment::itemsum($opp[2],1);
    my $monsum = int((150+rand(20))*$mysum/100);
    my $gain = $Simulation::rps{$opp[0]}{next};
    for my $p (1,2) {
        $gain = $Simulation::rps{$opp[$p]}{next} if $gain > $Simulation::rps{$opp[$p]}{next};
    }
    $gain = int($gain*.20);
    my $myroll = int(rand($mysum));
    my $monname = Monsters::get_monst_name($monsum);
    my $monroll = int(rand($monsum));
    if ($myroll >= $monroll) {
        IRC::chanmsg(Simulation::clog("$opp[0], $opp[1], and $opp[2] [$myroll/$mysum] have hunted down a bunch of $monname [$monroll/$monsum] and ".
             "defeated them! ".Simulation::duration($gain)." is removed from their clocks. They all get 5 XP."));
        $Simulation::rps{$opp[0]}{next} -= $gain;
        $Simulation::rps{$opp[1]}{next} -= $gain;
        $Simulation::rps{$opp[2]}{next} -= $gain;
        $Simulation::rps{$opp[0]}{experience} += 5;
        $Simulation::rps{$opp[1]}{experience} += 5;
        $Simulation::rps{$opp[2]}{experience} += 5;
    }
    else {
        IRC::chanmsg(Simulation::clog("$opp[0], $opp[1], and $opp[2] [$myroll/$mysum] have hunted down a bunch of $monname [$monroll/$monsum] but they ".
            "beat them badly! ".Simulation::duration($gain)." is added to their clocks. They all get 2 XP."));
        $Simulation::rps{$opp[0]}{next} += $gain;
        $Simulation::rps{$opp[1]}{next} += $gain;
        $Simulation::rps{$opp[2]}{next} += $gain;
        $Simulation::rps{$opp[0]}{experience} += 2;
        $Simulation::rps{$opp[1]}{experience} += 2;
        $Simulation::rps{$opp[2]}{experience} += 2;
    }
}


1;
