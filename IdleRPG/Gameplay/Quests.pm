package Quests;

#use IdleRPG::IRC;
#use IdleRPG::Simulation;
#use IdleRPG::Options;

our %quest = (
    questers => [],
    p1       => [],
    p2       => [],
    qtime    => time() + int(rand(7200)),
    text     => "",
    type     => 1,
    stage    => 1,
);

sub quest {
    @{$quest{questers}} = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > $Options::opts{questminlevel} && time()-$Simulation::rps{$_}{last_login}>3600 } keys(%Simulation::rps);
    if (@{$quest{questers}} < $Options::opts{questplayers}) { return undef(@{$quest{questers}}); }
    while (@{$quest{questers}} > $Options::opts{questplayers}) {
        splice(@{$quest{questers}},int(rand(@{$quest{questers}})),1);
    }
    if (!open(Q,$Options::opts{eventsfile})) {
        return IRC::chanmsg("ERROR: Failed to open $Options::opts{eventsfile}: $!");
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
        return IRC::chanmsg("ERROR: Failed to close $Options::opts{eventsfile}: $!");
    };
    if ($quest{type} == 1) {
        IRC::chanmsg(join(", ",(@{$quest{questers}})[0..$Options::opts{questplayers}-2]).", and $quest{questers}->[$Options::opts{questplayers}-1] have been chosen to ".
                "$quest{text}. Quest to end in ".Simulation::duration($quest{qtime}-time()).".");
    }
    elsif ($quest{type} == 2) {
        IRC::chanmsg(join(", ",(@{$quest{questers}})[0..$Options::opts{questplayers}-2]).", and $quest{questers}->[$Options::opts{questplayers}-1] have been chosen to ".
                "$quest{text}. Participants must first reach [$quest{p1}->[0],$quest{p1}->[1]], then [$quest{p2}->[0],$quest{p2}->[1]].".
                ($Options::opts{mapurl}?" See $Options::opts{mapurl} to monitor their journey's progress.":""));
    }
    Quests::writequestfile();
}

sub questpencheck {
    my $k = shift;
    my ($quester,$player);
    for $quester (@{$quest{questers}}) {
        if ($quester eq $k) {
            IRC::chanmsg(Simulation::clog("$k has ruined the quest. One day will be added to $k\'s TTL!"));
            $Simulation::rps{$k}{next} += 86400;
            undef(@{$quest{questers}});
            $quest{qtime} = time() + 7200;
            Quests::writequestfile();
            last;
        }
    }
    #If someone gets a penalty during a tourny, then the tourny is restarted.
    for my $tourney (@Tournaments::tournament) {
       if ($tourney eq $k) {
          IRC::chanmsg("$k has left so the Top Players Battle will be restarted in 1 minute.");
          undef @Tournaments::tournament;
          $Tournaments::tournamenttime = time() + 60;
          Level::penalize($k,"tourney");
       }
    }
    for my $DMtourney (@Tournaments::deathmatch) {
       if ($DMtourney eq $k) {
          IRC::chanmsg("$k has left so the Death Match will be restarted in 1 minute.");
          undef @Tournaments::deathmatch;
          $Tournaments::deathmatchtime = time() + 60;
          Level::penalize($k,"DMtourney");
       }
    }
    for my $MWtourney (@Tournaments::megawar) {
       if ($MWtourney eq $k) {
          IRC::chanmsg("$k has left so the Champions League will be restarted in 1 minute.");
          undef @Tournaments::megawar;
          $Tournaments::megawartime = time() + 60;
          Level::penalize($k,"MWtourney");
       }
    }
    for my $PWtourney (@Tournaments::powerwar) {
       if ($PWtourney eq $k) {
          IRC::chanmsg("$k has left so the Power War will be restarted in 1 minute.");
          undef @Tournaments::powerwar;
          $Tournaments::powerwartime = time() + 60;
          Level::penalize($k,"PWtourney");
        }
     }
     for my $AWtourney (@Tournaments::abilitywar) {
       if ($AWtourney eq $k) {
          IRC::chanmsg("$k has left so the Ability Battle will be restarted in 1 minute.");
          undef @Tournaments::abilitywar;
          $Tournaments::abilitywartime = time() + 60;
          Level::penalize($k,"AWtourney");
        }
     }
     for my $LWtourney (@Tournaments::locationwar) {
       if ($LWtourney eq $k) {
          IRC::chanmsg("$k has left so the Location Battle will be restarted in 1 minute.");
          undef @Tournaments::locationwar;
          $Tournaments::locationwartime = time() + 60;
          Level::penalize($k,"LWtourney");
        }
     }
     for my $ALWtourney (@Tournaments::alignwar) {
       if ($ALWtourney eq $k) {
          IRC::chanmsg("$k has left so the Alignment Battle will be restarted in 1 minute.");
          undef @Tournaments::alignwar;
          $Tournaments::alignwartime = time() + 60;
          Level::penalize($k,"ALWtourney");
        }
     }
}

sub writequestfile {
    return unless $Options::opts{writequestfile};
    open(QF,">$Options::opts{questfilename}") or do {
        IRC::chanmsg("Error: Cannot open $Options::opts{questfilename}: $!");
        return;
    };
    if (@{$quest{questers}}) {
        if ($quest{type}==1) {
            print QF "T $quest{text}\n".
                     "Y 1\n".
                     "S $quest{qtime}\n";

            for (my $i=0; $i<$Options::opts{questplayers}; $i++) {
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

            for (my $i=0; $i<$Options::opts{questplayers}; $i++) {
                last if($i > $#{$quest{questers}} || !$quest{questers}->[$i]);

                my $n = $i+1;

                print QF "P$n $quest{questers}->[$i] $Simulation::rps{$quest{questers}->[$i]}{pos_x} $Simulation::rps{$quest{questers}->[$i]}{pos_y}\n";
            }
        }
    }
    close(QF) or do {
        IRC::chanmsg("Error: Cannot close $Options::opts{questfilename}: $!");
    };
}

sub loadquestfile {
    return unless ($Options::opts{writequestfile} && -e $Options::opts{questfilename});
    open(QF,$Options::opts{questfilename}) or do {
        IRC::chanmsg("Error: Cannot open $Options::opts{questfilename}: $!");
        return;
    };
    my %questdata = ();
    while (my $line = <QF>) {
        chomp $line;
        my ($tag,$data) = split(/ /,$line,2);
        $questdata{$tag} = $data;
        Bot::debug("loadquestfile(): questdata: $tag = $data\r\n");
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
    for my $i (0..$Options::opts{questplayers}-1) {
        last if($i > $#{$quest{questers}} || !$quest{questers}->[$i]);

        ($quest{questers}->[$i],) = split(/ /,$questdata{'P'.($i+1)},2);
        Bot::debug("loadquestfile(): quester $i = $Simulation::rps{$quest{questers}->[$i]}{online}\r\n");
        if (!$Simulation::rps{$quest{questers}->[$i]}{online}) {
            undef(@{$quest{questers}});
            last;
        }
    }
    close(QF) or do {
        IRC::chanmsg("Error: Cannot close $Options::opts{questfilename}: $!");
    };
    writequestfile();
}


1;
