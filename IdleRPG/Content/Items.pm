package Items;

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
        $rps{$ThisPlayer}{gold} += $Amt;
        IRC::chanmsg("$ThisPlayer has a Gold Stone and gets $Amt more gold!");
    }
    elsif ($ItemUse eq "Gem") {
        $Amt = int($ThisAmount*.20);
        if ($Amt > 0) {
            $rps{$ThisPlayer}{gems} += $Amt;
            IRC::chanmsg("$ThisPlayer has a Gem Stone and gets $Amt more gem(s)!");
        }
    }
    elsif ($ItemUse eq "Life") {
        $Amt = int($rps{$ThisPlayer}{life}*.1);
        if ($rps{$ThisPlayer}{life} < 100) {
            if ( $rps{$ThisPlayer}{life} > 0 && ($rps{$ThisPlayer}{life} + $Amt) < 100 ) {
                $rps{$ThisPlayer}{life} += $Amt;
                IRC::chanmsg("$ThisPlayer has a Life Stone and gets $Amt life restored!");
            }
            elsif ($rps{$ThisPlayer}{life} > 0) {
                $rps{$ThisPlayer}{life} = 100;
                IRC::chanmsg("$ThisPlayer has a Life Stone and gets ALL life restored!");
            }
        }
    }
    elsif ($ItemUse eq "XP") {
        $Amt = int($ThisAmount*.5);
        if ($Amt > 0) {
            $rps{$ThisPlayer}{experience} += $Amt;
            IRC::chanmsg("$ThisPlayer has an XP Stone and gets $Amt more XP!");
        }
    }
    elsif ($ItemUse eq "TTL") {
        $Amt = int($ThisAmount*.20);
        $rps{$ThisPlayer}{next} -= $Amt;
        IRC::chanmsg("$ThisPlayer has a TTL Stone and gets ".duration($Amt)." TTL removed!");
    }
    else {
        return;
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
    IRC::chanmsg("$ThisPlayer $type was damaged and loses $ThisDamage % effectiveness!");
    $ThisDamage = (100-$ThisDamage)/100;
    $rps{$ThisPlayer}{item}{$type} = int($ThisVal*$ThisDamage);
}


1;
