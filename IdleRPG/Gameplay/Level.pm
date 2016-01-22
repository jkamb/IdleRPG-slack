package Level;

#use IdleRPG::Database;
#use IdleRPG::IRC;
#use IdleRPG::Options;
#use IdleRPG::Simulation;
#use IdleRPG::Gameplay::Quests;

sub ttl {
    my $lvl = shift;
    return ($Options::opts{rpbase} * ($Options::opts{rpstep}**$lvl)) if $lvl <= 60;
    return (($Options::opts{rpbase} * ($Options::opts{rpstep}**60)) + (86400*($lvl - 60)));
}

sub penttl {
    my $lvl = shift;
    return ($Options::opts{rpbase} * ($Options::opts{rppenstep}*$lvl));
}

sub penalize {
    my $username = shift;
    return 0 if !defined($username);
    return 0 if !exists($Simulation::rps{$username});
    my $type = shift;
    my $pen = 0;
    Quests::questpencheck($username);
    if ($type eq "tourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen}; 
        } 
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving the 5Top Players Battle.");
    }
    if ($type eq "DMtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 6Death Match.");
    }
    if ($type eq "MWtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 7Champions League.");
    }
    if ($type eq "PWtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 12Power War".
             "$username just lost 5 points at each item." );
              $Simulation::rps{$username}{item}{amulet} -= 5;
              $Simulation::rps{$username}{item}{boots} -= 5;
              $Simulation::rps{$username}{item}{charm} -= 5;
              $Simulation::rps{$username}{item}{gloves} -= 5;
              $Simulation::rps{$username}{item}{helm} -= 5;
              $Simulation::rps{$username}{item}{leggings} -= 5;
              $Simulation::rps{$username}{item}{ring} -= 5;
              $Simulation::rps{$username}{item}{shield} -= 5;
              $Simulation::rps{$username}{item}{tunic} -= 5;
              $Simulation::rps{$username}{item}{weapon} -= 5;
    }
    if ($type eq "AWtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 3Ability Battle.");
    }
    if ($type eq "LWtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 13Location Battle.");
    }
    if ($type eq "ALWtourney") {
        $pen = int(300 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for leaving The 14Alignment Battle.");
    }

    if ($type eq "quit") {
        $pen = int(20 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{pen_quit}+=$pen;
        $Simulation::rps{$username}{next}+=$pen;
        $Simulation::rps{$username}{online}=0;
          IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for quitting.");
    }
    elsif ($type eq "nick") {
        my $newnick = shift;
        $pen = int(30 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{pen_nick}+=$pen;
        $Simulation::rps{$username}{next}+=$pen;
        $Simulation::rps{$username}{nick} = substr($newnick,1);
        $Simulation::rps{$username}{userhost} =~ s/^[^!]+/$Simulation::rps{$username}{nick}/e;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for nick change.");
    }
    elsif ($type eq "privmsg" || $type eq "notice") {
        $pen = int(shift(@_) * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{pen_mesg}+=$pen;
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for $type.");
    }
    elsif ($type eq "part") {
        $pen = int(200 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{pen_part}+=$pen;
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for parting.");
        $Simulation::rps{$username}{online}=0;
    }
    elsif ($type eq "kick") {
        $pen = int(250 * penttl($Simulation::rps{$username}{level}) / $Options::opts{rpbase});
        if ($Options::opts{limitpen} && $pen > $Options::opts{limitpen}) {
            $pen = $Options::opts{limitpen};
        }
        $Simulation::rps{$username}{pen_kick}+=$pen;
        $Simulation::rps{$username}{next}+=$pen;
        IRC::chanmsg("Penalty of ".Simulation::duration($pen)." added to ".$username."'s TTL for being kicked.");
        $Simulation::rps{$username}{online}=0;
    }
    elsif ($type eq "logout") {
        IRC::chanmsg("$username has logged out.");
        $Simulation::rps{$username}{online}=0;
    }
    Database::writejsondb(\%Simulation::rps);
    return 1;
}


1;
