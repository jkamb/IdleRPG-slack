package Equipment;

#use IdleRPG::IRC;
#use IdleRPG::Simulation;

sub itemsum {
    my $user = shift;
    my $battle = shift;
    $battle = 1;
    return -1 unless defined $user;
    my $sum = 0;
    my $ExpertItemBonus = 0;
    my $ExpertItemType;
    if ($user eq $IRC::primnick) {
        return $sum+1;
    }
    if ($Simulation::rps{$user}{ExpertItem01} ne "0") {
        $ExpertItemType = $Simulation::rps{$user}{ExpertItem01};
        $ExpertItemBonus = $ExpertItemBonus + int($Simulation::rps{$user}{item}{$ExpertItemType} * .1);
    }
    if ($Simulation::rps{$user}{ExpertItem02} ne "0") {
        $ExpertItemType = $Simulation::rps{$user}{ExpertItem02};
        $ExpertItemBonus = $ExpertItemBonus + int($Simulation::rps{$user}{item}{$ExpertItemType} * .1);
    }
    if ($Simulation::rps{$user}{ExpertItem03} ne "0") {
        $ExpertItemType = $Simulation::rps{$user}{ExpertItem03};
        $ExpertItemBonus = $ExpertItemBonus + int($Simulation::rps{$user}{item}{$ExpertItemType} * .1);
    }
    if (!exists($Simulation::rps{$user})) { return -1; }
    $sum += $Simulation::rps{$user}{item}{$_} for keys(%{$Simulation::rps{$user}{item}});
    $sum = $sum + $ExpertItemBonus;
    return $sum;
}


sub item_special_toss {
    my $ThisPlayer = shift;
    my $ThisItem = shift;
    if ($ThisItem eq $Simulation::rps{$ThisPlayer}{Special01}) {
        $Simulation::rps{$ThisPlayer}{Special01} = 0;
    }
    elsif ($ThisItem eq $Simulation::rps{$ThisPlayer}{Special02}) {
        $Simulation::rps{$ThisPlayer}{Special02} = 0;
    }
    elsif ($ThisItem eq $Simulation::rps{$ThisPlayer}{Special03}) {
        $Simulation::rps{$ThisPlayer}{Special03} = 0;
    }
    if ($Simulation::rps{$ThisPlayer}{Special01} eq "0" && $Simulation::rps{$ThisPlayer}{Special02} ne "0") {
        $Simulation::rps{$ThisPlayer}{Special01} = $Simulation::rps{$ThisPlayer}{Special02};
        if ($Simulation::rps{$ThisPlayer}{Special03} ne "0") {
            $Simulation::rps{$ThisPlayer}{Special02} = $Simulation::rps{$ThisPlayer}{Special03};
            $Simulation::rps{$ThisPlayer}{Special03} = 0;
        }
        else {
            $Simulation::rps{$ThisPlayer}{Special02} = 0;
        }
    }
    if ($Simulation::rps{$ThisPlayer}{Special02} eq "0" && $Simulation::rps{$ThisPlayer}{Special03} ne "0" ) {
        $Simulation::rps{$ThisPlayer}{Special02} = $Simulation::rps{$ThisPlayer}{Special03};
        $Simulation::rps{$ThisPlayer}{Special03} = 0;
    }
    IRC::chanmsg("$ThisPlayer tossed their $ThisItem Stone!");
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
        $Simulation::rps{$ThisPlayer}{gold} += $Amt;
        IRC::chanmsg("$ThisPlayer has a Gold Stone and gets $Amt more gold!");
    }
    elsif ($ItemUse eq "Gem") {
        $Amt = int($ThisAmount*.20);
        if ($Amt > 0) {
            $Simulation::rps{$ThisPlayer}{gems} += $Amt;
            IRC::chanmsg("$ThisPlayer has a Gem Stone and gets $Amt more gem(s)!");
        }
    }
    elsif ($ItemUse eq "Life") {
        $Amt = int($Simulation::rps{$ThisPlayer}{life}*.1);
        if ($Simulation::rps{$ThisPlayer}{life} < 100) {
            if ( $Simulation::rps{$ThisPlayer}{life} > 0 && ($Simulation::rps{$ThisPlayer}{life} + $Amt) < 100 ) {
                $Simulation::rps{$ThisPlayer}{life} += $Amt;
                IRC::chanmsg("$ThisPlayer has a Life Stone and gets $Amt life restored!");
            }
            elsif ($Simulation::rps{$ThisPlayer}{life} > 0) {
                $Simulation::rps{$ThisPlayer}{life} = 100;
                IRC::chanmsg("$ThisPlayer has a Life Stone and gets ALL life restored!");
            }
        }
    }
    elsif ($ItemUse eq "XP") {
        $Amt = int($ThisAmount*.5);
        if ($Amt > 0) {
            $Simulation::rps{$ThisPlayer}{experience} += $Amt;
            IRC::chanmsg("$ThisPlayer has an XP Stone and gets $Amt more XP!");
        }
    }
    elsif ($ItemUse eq "TTL") {
        $Amt = int($ThisAmount*.20);
        $Simulation::rps{$ThisPlayer}{next} -= $Amt;
        IRC::chanmsg("$ThisPlayer has a TTL Stone and gets ".duration($Amt)." TTL removed!");
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
        if ($Simulation::rps{$ThisPlayer}{Special01} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($Simulation::rps{$ThisPlayer}{Special01} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
        if ($Simulation::rps{$ThisPlayer}{Special02} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($Simulation::rps{$ThisPlayer}{Special02} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
        if ($Simulation::rps{$ThisPlayer}{Special03} eq $ThisType) {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"0");
        }
        elsif ($Simulation::rps{$ThisPlayer}{Special03} eq "rand") {
            item_special_use($ThisPlayer,$ThisAmount,$ThisType,"1");
        }
    }
    else {
        return;
    }
}

sub item_special_find {
    if (int(rand(19)) < 1) {
        my $ThisPlayer = shift;
        my @items = ("Gold","Gem","Life","XP","TTL","rand");
        my $type = $items[rand(@items)];
        if ($Simulation::rps{$ThisPlayer}{Special01} eq "0") {
            $Simulation::rps{$ThisPlayer}{Special01} = $type;
            IRC::chanmsg("$ThisPlayer received a $type Stone!");
        }
        elsif ($Simulation::rps{$ThisPlayer}{Special02} eq "0") {
            $Simulation::rps{$ThisPlayer}{Special02} = $type;
            IRC::chanmsg("$ThisPlayer received a $type Stone!");
        }
        elsif ($Simulation::rps{$ThisPlayer}{Special03} eq "0") {
            $Simulation::rps{$ThisPlayer}{Special03} = $type;
            IRC::chanmsg("$ThisPlayer received a $type Stone!");
        }
    }
    else {
        return;
    }
}

sub item_wear {
    my $ThisPlayer = shift;
    my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
    my $type = $items[rand(@items)];
    my $ThisVal = $Simulation::rps{$ThisPlayer}{item}{$type};
    my $ThisLvl = int( ($Simulation::rps{$ThisPlayer}{level}/10) - 1 );
    if ($ThisLvl < 1) {
        $ThisLvl = 1;
    }
    my $ThisDamage = int(rand($ThisLvl) + 1);
    IRC::chanmsg("$ThisPlayer $type was damaged and loses $ThisDamage % effectiveness!");
    $ThisDamage = (100-$ThisDamage)/100;
    $Simulation::rps{$ThisPlayer}{item}{$type} = int($ThisVal*$ThisDamage);
}

sub find_item {
    my $u = shift;
    my $level = $Simulation::rps{$u}{level};
    my $align = $Simulation::rps{$u}{alignment};
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
        IRC::chanmsg("$u looked for item upgrade scrolls, but none were found.");
    }
    if ($ItemVal > 0) {
        while ($HoldThis) {
            $type = $items[rand(@items)];
            $CountThis = $CountThis + 1;
            if ($ItemVal > $Simulation::rps{$u}{item}{$type}) {
                my $tupgrade = 0;
                if ($Simulation::rps{$u}{upgrade} > 0) {
                    $tupgrade = $Simulation::rps{$u}{upgrade} * 2;
                    $tupgrade = int(rand($tupgrade) + 1);
                }
                $ThisItemVal  = int(($level/2) + $tupgrade + ($Simulation::rps{$u}{item}{$type}*1.05) + 1);
                exchange_item($u,$type,$ThisItemVal);
                $HoldThis = 0;
            }
            elsif ($CountThis > 3) {
                $ItemVal = -1;
                $HoldThis = 0;
            }
        }
    }
    if ($ItemVal < 0) {
        IRC::chanmsg("$u found an item upgrade scroll, but it was useless, so it seems luck is against $u !!!");
    }
}

sub exchange_item {
    my $u = shift;
    my $type = shift;
    my $level = shift;
    my $ulevel = $level;
    my $tag = $level;
    IRC::chanmsg("$u found a level $level $type! Current $type is level ".$Simulation::rps{$u}{item}{$type}.", so it seems luck is with $u !!!");
    $Simulation::rps{$u}{item}{$type} = $level;
}

sub find_expert_item {
    my $ThisPlayer = shift;
    if ($Simulation::rps{$ThisPlayer}{level} > 24) {
        if ($Simulation::rps{$ThisPlayer}{ExpertItem01} eq "0" || $Simulation::rps{$ThisPlayer}{ExpertItem02} eq "0" || $Simulation::rps{$ThisPlayer}{ExpertItem03} eq "0") {
            if (rand(99) < 50) {
                my @ThisItem = sort {$Simulation::rps{$ThisPlayer}{item}{$b} <=> $Simulation::rps{$ThisPlayer}{item}{$a}} keys(%{$Simulation::rps{$ThisPlayer}{item}});
                if ($Simulation::rps{$ThisPlayer}{ExpertItem01} ne "0") {
                    if ($Simulation::rps{$ThisPlayer}{ExpertItem02} ne "0") {
                        if ($Simulation::rps{$ThisPlayer}{ExpertItem03} eq "0") {
                            if (rand(99) < 5) {
                                my @ValidItems = grep (!(/$Simulation::rps{$ThisPlayer}{ExpertItem01}/ || /$Simulation::rps{$ThisPlayer}{ExpertItem02}/),@ThisItem);
                                $Simulation::rps{$ThisPlayer}{ExpertItem03} = $ValidItems[0];
                                IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the third expert knowledge for their $ValidItems[0]!");
                            }
                            else {
                                IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                            }
                        }
                    }
                    else {
                        if (rand(99) < 10) {
                            my @ValidItems = grep (!/$Simulation::rps{$ThisPlayer}{ExpertItem01}/,@ThisItem);
                            $Simulation::rps{$ThisPlayer}{ExpertItem02} = $ValidItems[0];
                            IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the second expert knowledge for their $ValidItems[0]!");
                        }
                        else {
                            IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                        }
                    }
                }
                else {
                    if (rand(99) < 15) {
                    $Simulation::rps{$ThisPlayer}{ExpertItem01} = $ThisItem[0];
                    IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack and gave the first expert knowledge for their $ThisItem[0]!");
                    }
                    else {
                        IRC::chanmsg("A wise old man observed $ThisPlayer\'s attack, but more practice is needed before he shares his expert knowledge.");
                    }
                }
            }
            else {
                IRC::chanmsg("The wise old man is taking a break and not watching $ThisPlayer.");
            }
        }
    }
    else {
        IRC::chanmsg("The wise old man told $ThisPlayer to reach level 25 before he will observe.");
    }
}


1;
