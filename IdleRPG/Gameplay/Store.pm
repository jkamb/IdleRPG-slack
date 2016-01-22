package Store;

#use IdleRPG::IRC;
#use IdleRPG::Simulation;

sub buy_gems {
    my $u = shift;
    my $type = shift;
    my $type2 = int(abs($type));
    my $pay = 150*$type2;
    if($Simulation::rps{$u}{gold} >= $pay) {
        $Simulation::rps{$u}{gems} += $type2;
        $Simulation::rps{$u}{gold} -= $pay;
        IRC::chanmsg("$u bought $type2 gems. $u has $Simulation::rps{$u}{gold} gold left and $Simulation::rps{$u}{gems} gems.");
    }
    else {
        IRC::privmsg("You don't have enough gold. You need: $pay gold.", $Simulation::rps{$u}{nick});
    }
}

sub xpget_scroll {
    my $u = shift;
    my $gain = $Simulation::rps{$u}{next};
    if($Simulation::rps{$u}{scrolls} && $Simulation::rps{$u}{scrolls} == 5) {
        IRC::privmsg("You already have 5 scrolls.", $Simulation::rps{$u}{nick});
        return;
    }
    if($Simulation::rps{$u}{experience} >= 20) {
        $gain = int($gain*((rand(49)+1)/100));
        $Simulation::rps{$u}{experience} -= 20;
        $Simulation::rps{$u}{next} -= $gain;
        $Simulation::rps{$u}{scrolls} += 1;
        IRC::chanmsg("$u used 20 XP for a scroll and gets " .Simulation::duration($gain)." removed from TTL. ".
            "$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next})." $u has $Simulation::rps{$u}{experience} XP left.");
    }
    else {
        IRC::privmsg("You don't have enough XP. You need 20.", $Simulation::rps{$u}{nick});
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
            if($Simulation::rps{$u}{experience} > 19) {
                if($Simulation::rps{$u}{experience} >= $amount) {
                    $MinRoll = int($amount*.05);
                    $power = $amount;
                    if ($amount > 20) {
                        $power = $power - $MinRoll;
                    }
                    $power = int(rand($power) + $MinRoll);
                    $Simulation::rps{$u}{item}{$type} += $power;
                    $Simulation::rps{$u}{experience} -= $amount;
                    IRC::chanmsg("$u used $amount XP to upgrade their $type and gets $power points stronger. ".
                        "$u has $Simulation::rps{$u}{experience} XP left.");
                }
                else {
                    IRC::privmsg("You don't have enough XP. You need $amount.", $Simulation::rps{$u}{nick});
                }
            }
            else {
                IRC::privmsg("You don't have enough XP. You need 20.", $Simulation::rps{$u}{nick});
            }
        }
        else {
            IRC::privmsg("$type is not a valid item.", $Simulation::rps{$u}{nick});
        }
    }
    else {
        IRC::privmsg("You need to use at least 20 XP to use this command.", $Simulation::rps{$u}{nick});
    }
}

sub blackbuy_scroll {
    my $u = shift;
    my $type = shift;
    my $gain = $Simulation::rps{$u}{next};
    $gain = int($gain*(rand(50)/100));
    if($type eq 'scroll') {
        if($Simulation::rps{$u}{scrolls} && $Simulation::rps{$u}{scrolls} == 5) {
            IRC::privmsg("You already have 5 scrolls.", $Simulation::rps{$u}{nick});
            return;
        }
        if($Simulation::rps{$u}{gems} >= 15) {
            $Simulation::rps{$u}{gems} -= 15;
            $Simulation::rps{$u}{next} -= $gain;
            $Simulation::rps{$u}{scrolls} += 1;
            IRC::chanmsg("$u bought one experience scroll from the Black Market and gets " . Simulation::duration($gain) .
                " removed from TTL. $u has $Simulation::rps{$u}{gems} gems left. $u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
        }
        else {
            IRC::privmsg("You don't have enough gems. You need: 15 ", $Simulation::rps{$u}{nick});
        }
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
        if($Simulation::rps{$u}{gems} >= ($GemAmt*$MassTimes)) {
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
                if ($Simulation::rps{$u}{upgrade} > 0) {
                    $tupgrade = $Simulation::rps{$u}{upgrade} * 2;
                    $tupgrade = int(rand($tupgrade) + 1);
                    $ThisUpgrade = $ThisUpgrade + $tupgrade;
                }
                $power = $power + int(rand(50)+15);
            }
            $power = $power + $MassTimesBonus;
            $Simulation::rps{$u}{item}{$type} += ($power + $ThisUpgrade);
            $Simulation::rps{$u}{gems} -= ($GemAmt * $MassTimes);
            IRC::chanmsg("$u used the black market $MassTimes times to upgrade their $type for $power points stronger ".
                "and has $Simulation::rps{$u}{gems} gems left.");
            if ($ThisUpgrade > 0) {
                IRC::chanmsg("$u got $ThisUpgrade upgrade points.");
            }
        }
        else {
            IRC::privmsg("You don't have enough gems. You need: " .$GemAmt*$MassTimes. "!", $Simulation::rps{$u}{nick});
        }
    }
    else {
        IRC::privmsg("$type is not a valid item!", $Simulation::rps{$u}{nick});
    }
}

sub rest {
    my $u = shift;
    my $IsEnding = 0;

    if ($Simulation::rps{$u}{life} < 0) {
        IRC::privmsg("You are a Zombie!", $Simulation::rps{$u}{nick});
    }
    elsif ($IsEnding == 0) {
        if ($Simulation::rps{$u}{level} > 0) {
            my $factor = int($Simulation::rps{$u}{level}/5);
            if ($IsEnding == 1) {
                $factor = 25;
            }
            my $pay = (100-$Simulation::rps{$u}{life})*$factor;
            my $recover = int($Simulation::rps{$u}{gold}/$factor);
            if ($Simulation::rps{$u}{gold} >= $pay && $Simulation::rps{$u}{life} < 100) {
                $Simulation::rps{$u}{gold} -= $pay;
                $Simulation::rps{$u}{life} = 100;
                IRC::chanmsg("$u rested to regain their life and has $Simulation::rps{$u}{gold} gold left.");
            }
            elsif ($Simulation::rps{$u}{life} < 100) {
                if ($Simulation::rps{$u}{gold} > 0) {
                    $Simulation::rps{$u}{gold} = 0;
                    $Simulation::rps{$u}{life} += $recover;
                    IRC::chanmsg("$u got $recover life restored.");
                }
                else {
                    IRC::privmsg("You do not have any gold, you peasant...goto work!", $Simulation::rps{$u}{nick});
                }

            }
            else {
                IRC::privmsg("You are already rested.", $Simulation::rps{$u}{nick});
            }
        }
        else {
            IRC::privmsg("You are at level 0 and do not need to rest yet.", $Simulation::rps{$u}{nick});
        }
    }
    else {
        if ($Simulation::rps{$u}{life} > 0) {
            if ($Simulation::rps{$u}{level} > 0) {
                my $factor = int($Simulation::rps{$u}{level}/5);
                if ($IsEnding == 1) {
                    $factor = 25;
                }
                my $pay = (100-$Simulation::rps{$u}{life})*$factor;
                my $recover = int($Simulation::rps{$u}{gold}/$factor);
                if ($Simulation::rps{$u}{gold} >= $pay && $Simulation::rps{$u}{life} < 100) {
                    $Simulation::rps{$u}{gold} -= $pay;
                    $Simulation::rps{$u}{life} = 100;
                    IRC::chanmsg("$u fully regained their life and has $Simulation::rps{$u}{gold} gold left.");
                }
                elsif ($Simulation::rps{$u}{life} < 100) {
                    if ($Simulation::rps{$u}{gold} > 0) {
                        $Simulation::rps{$u}{gold} = 0;
                        $Simulation::rps{$u}{life} += $recover;
                        IRC::chanmsg("$u rested and got $recover life restored.");
                    }
                    else {
                        IRC::privmsg("You do not have any gold, you peasant...goto work!", $Simulation::rps{$u}{nick});
                    }

                }
                else {
                    IRC::privmsg("You are already rested.", $Simulation::rps{$u}{nick});
                }
            }
            else {
                IRC::privmsg("You are at level 0 and do not need to rest yet.", $Simulation::rps{$u}{nick});
            }
        }
        else {
            IRC::privmsg("You are dead and forever restless.", $Simulation::rps{$u}{nick});
        }
    }
}

sub buy_mana {
    my $u = shift;
    if($Simulation::rps{$u}{gold} >= 1000 && $Simulation::rps{$u}{mana} == 0) {
        $Simulation::rps{$u}{gold} -= 1000;
        $Simulation::rps{$u}{mana} = 1;
        IRC::chanmsg("$u bought a mana potion. Their sum will double for the next fight. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    else {
        IRC::privmsg("You don't have enough gold or you already have full mana.", $Simulation::rps{$u}{nick});
    }
}

sub buy_item {
    my $u = shift;
    my $type = shift;
    my $level = shift;
    my $comparelevel = $Simulation::rps{$u}{level} * 2;
    my @items = ('ring','amulet','charm','weapon','helm','tunic','gloves','leggings','shield','boots');
    my $validitem = 0;
    my $item;
    foreach $item (@items) {
        if($item eq $type) { $validitem = 1; }
    }
    if($level > $comparelevel) {
        IRC::privmsg("You can not buy an item with an level larger than two times your ".
        "level. ", $Simulation::rps{$u}{nick});
    }
    else {
        if($validitem) {
                if(int($Simulation::rps{$u}{item}{$type}) >= $level) {
                    IRC::privmsg("That would be dumb. ", $Simulation::rps{$u}{nick});
                }
                else {
                    if($Simulation::rps{$u}{gold} >= ($level*3)) {
                        $Simulation::rps{$u}{item}{$type} = $level;
                        $Simulation::rps{$u}{gold} -= $level*3;
                        IRC::chanmsg("$u now has a level $level $type from the shop. $u has $Simulation::rps{$u}{gold} gold left.");
                    }
                    else {
                        my $levelx3 = $level * 3;
                        IRC::privmsg("You don't have enough gold. You need: $levelx3 ", $Simulation::rps{$u}{nick});
                    }
                }
        }
        else {
            IRC::privmsg("You did not type a valid item name. Try one of these: ".
                "ring, amulet, charm, weapon, helm, tunic, gloves, leggings, shield, boots.", $Simulation::rps{$u}{nick});
        }
    }
}

sub buy_pots {
    my $u = shift;
    if($Simulation::rps{$u}{gold} >= 100) {
        $Simulation::rps{$u}{gold} -= 100;
        $Simulation::rps{$u}{powerpotion} += 1;
        IRC::privmsg("You just bought yourself a powerpotion. In the next fight your powers will be increased.", $Simulation::rps{$u}{nick});
    }
    else {
        IRC::privmsg("You don't have enough gold. You need: 100 ", $Simulation::rps{$u}{nick});
    }
}

sub buy_experience {
    my $u = shift;
    my $gain = $Simulation::rps{$u}{next};
    $gain = int($gain*.10);
    if($Simulation::rps{$u}{gold} >= 500) {
        $Simulation::rps{$u}{gold} -= 500;
        $Simulation::rps{$u}{next} -= $gain;
        IRC::chanmsg("$u bought some experience. 10% of their TTL is removed for 500 gold.".
            " $u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).". $u has $Simulation::rps{$u}{gold} gold left.");
    }
    else {
        IRC::privmsg("You don't have enough gold. You need: 500 ", $Simulation::rps{$u}{nick});
    }
}

sub buy_upgrade {
    my $u = shift;
    if($Simulation::rps{$u}{gold} >= 500 && $Simulation::rps{$u}{level} >= 35 && $Simulation::rps{$u}{upgrade} == 0) {
        $Simulation::rps{$u}{gold} -= 500;
        $Simulation::rps{$u}{upgrade} = 1;
        IRC::chanmsg("$u made a level 1 upgrade. Their power will grow with 100 now. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    elsif($Simulation::rps{$u}{gold} >= 1000 && $Simulation::rps{$u}{level} >= 40 && $Simulation::rps{$u}{upgrade} == 1) {
        $Simulation::rps{$u}{gold} -= 1000;
        $Simulation::rps{$u}{upgrade} = 2;
        IRC::chanmsg("$u made a level 2 upgrade. Their power will grow with 200 now. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    elsif($Simulation::rps{$u}{gold} >= 2000 && $Simulation::rps{$u}{level} >= 45 && $Simulation::rps{$u}{upgrade} == 2) {
        $Simulation::rps{$u}{gold} -= 2000;
        $Simulation::rps{$u}{upgrade} = 3;
        IRC::chanmsg("$u made a level 3 upgrade. Their power will grow with 300 now. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    elsif($Simulation::rps{$u}{gold} >= 4000 && $Simulation::rps{$u}{level} >= 50 && $Simulation::rps{$u}{upgrade} == 3) {
        $Simulation::rps{$u}{gold} -= 4000;
        $Simulation::rps{$u}{upgrade} = 4;
        IRC::chanmsg("$u made a level 4 upgrade. Their power will grow with 400 now. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    elsif($Simulation::rps{$u}{gold} >= 8000 && $Simulation::rps{$u}{level} >= 60 && $Simulation::rps{$u}{upgrade} == 4) {
        $Simulation::rps{$u}{gold} -= 8000;
        $Simulation::rps{$u}{upgrade} = 5;
        IRC::chanmsg("$u made a level 5 upgrade. Their power will grow with 500 now. $u has $Simulation::rps{$u}{gold} gold left.");
    }
    else {
        IRC::privmsg("You don't have enough gold, the level for that upgrade or you had all the possible upgrades made ", $Simulation::rps{$u}{nick});
    }
}


1;
