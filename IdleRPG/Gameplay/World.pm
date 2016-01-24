package World;

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

sub change_location {
    my $nick = shift;
    my $user = shift;
    my $location = shift;
    for my $LWtourney (@Tournaments::locationwar) {
       if ($LWtourney eq $user) {
          IRC::chanmsg("$user changed location during the Location Battle! Their TTL is doubled.");
          my $ThisTTL = $Simulation::rps{$user}{next} * 2;
          $Simulation::rps{$user}{next} = $ThisTTL;
        }
     }
    if ($location eq 'town') {
        if ($Simulation::rps{$user}{level} > 0) {
            if ($Simulation::rps{$user}{status} == WORK) {
                my $worktime = time() - $Simulation::rps{$user}{Worktime};
                my $perc = ($worktime/60)/$Simulation::rps{$user}{level};
                my $gainttl = int(($perc*0.01*$Simulation::rps{$user}{next})/4);
                if ($Simulation::rps{$user}{next} - $gainttl < 0) {
                    $Simulation::rps{$user}{next} = 5;
                }
                else {
                    $Simulation::rps{$user}{next} -= $gainttl;
                }
                my $gaingold = int($worktime/86.4);
                if ($gainttl != 0 && $gaingold != 0) {
                    IRC::chanmsg("$user worked for " .Simulation::duration($worktime). " and is now " .Simulation::duration($gainttl).
                        " closer to the next level. $user gained " .$gaingold. " gold. $user is in Town.");
                }
                else {
                    IRC::chanmsg("$user is now in Town but didn't work long enough to earn any thing.");
                }
                $Simulation::rps{$user}{gold} += $gaingold;
                $Simulation::rps{$user}{status} = TOWN;
                $Simulation::rps{$user}{Worktime} = 0;
                $Simulation::rps{$user}{Towntime} = time();
            }
            elsif ($Simulation::rps{$user}{status} == FOREST) {
                if (($Simulation::rps{$user}{Foresttime} + 21600) < time()) {
                    if (rand(99) < 50) {
                        IRC::chanmsg("$user found a cave near the edge of the forest! $user will explore it...");
                        Events::forestwalk($user, 'cave');
                    }
                    $Simulation::rps{$user}{status} = TOWN;
                    $Simulation::rps{$user}{Towntime} = time();
                    $Simulation::rps{$user}{Foresttime} = 0;
                    IRC::chanmsg("$user is now in Town.");
                }
                else {
                    IRC::privmsg("You must explore the forest for at least 6 hours!", $nick);
                }
            }
        }
        else {
            IRC::privmsg("You need to get to level 1 before changing location!", $nick);
        }
    }
    elsif ($location eq 'work') {
        if ($Simulation::rps{$user}{status} == FOREST) {
            IRC::privmsg("You first need to go to Town!", $nick);
        }
        elsif ($Simulation::rps{$user}{status} == TOWN) {
            if ($Simulation::rps{$user}{Towntime} > 0) {
                my $Towntime = time() - $Simulation::rps{$user}{Towntime};
                my $gainXP = int($Towntime/1800);
                $Simulation::rps{$user}{status} = WORK;
                $Simulation::rps{$user}{Worktime} = time();
                $Simulation::rps{$user}{Towntime} = 0;
                if ($gainXP > 0) {
                    IRC::chanmsg("$user has been in town for " .Simulation::duration($Towntime). " and gained " .$gainXP. " XP. $user is at Work.");
                    $Simulation::rps{$user}{experience} += $gainXP;
                }
                else {
                    IRC::chanmsg("$user is now at Work.");
                    IRC::privmsg("You were not in Town long enough to gain XP.", $nick);
                }
            }
            else {
                $Simulation::rps{$user}{status} = WORK;
                $Simulation::rps{$user}{Worktime} = time();
                IRC::chanmsg("$user is now at Work.");
            }
        }
        else {
            $Simulation::rps{$user}{status} = WORK;
            $Simulation::rps{$user}{Worktime} = time();
            IRC::chanmsg("$user is now at Work.");
        }
    }
    elsif ($location eq 'forest') {
        if ($Simulation::rps{$user}{status} == WORK) {
            IRC::privmsg("You first need to go to Town to recieve payment!", $nick);
        }
        elsif ($Simulation::rps{$user}{status} == TOWN) {
            if ($Simulation::rps{$user}{Towntime} > 0) {
                my $Towntime = time() - $Simulation::rps{$user}{Towntime};
                my $gainXP = int($Towntime/1800);
                $Simulation::rps{$user}{status} = FOREST;
                $Simulation::rps{$user}{Towntime} = 0;
                if ($gainXP > 0) {
                    IRC::chanmsg("$user has been in town for " .Simulation::duration($Towntime). " and gained " .$gainXP. " XP. $user is in the Forest.");
                    $Simulation::rps{$user}{experience} += $gainXP;
                }
                else {
                    IRC::chanmsg("$user is now in the Forest.");
                    IRC::privmsg("You were not in Town long enough to gain XP.", $nick);
                }
                $Simulation::rps{$user}{Foresttime} = time();
                Events::forestwalk($user);
            }
            else {
                $Simulation::rps{$user}{status} = FOREST;
                IRC::chanmsg("$user is now in the Forest.");
                $Simulation::rps{$user}{Foresttime} = time();
                Events::forestwalk($user);
            }
        }
    }
}

1;
