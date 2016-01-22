package Options;

our %opts = (
             help            => 0,
             verbose         => 0,
             debug           => 0,
             debugfile       => 'dbg.txt',
             pidfile         => '.irpg.pid',
             conffile        => 'idlerpg.conf',
             dbfile          => 'irpg.db',
             modsfile        => 'modifiers.txt',
             ipv6            => 0,
             localaddr       => '127.0.0.1',
             servers         => [],
             password        => '',
             botnick         => 'idlerpgbotdev',
             botchan         => '#idlerpg-dev',
             botmodes        => '+i',
             botghostcmd     => '',
             helpurl         => 'http://idlerpg/help.php',
             mapurl          => 'http://idlerpg/quests.php',
             writequestfile  => 1,
             questfilename   => 'questinfo.txt',
             questplayers    => 8,
             questminlevel   => 40,
             reconnect       => 1,
             reconnect_wait  => 30,
             self_clocks     => 2,
             casematters     => 0,
             noscale         => 0,
             owner           => '',
             owneraddonly    => 0,
             ownerdelonly    => 0,
             ownerpevalonly  => 0,
             peval           => 0,
             limitpen        => 0,
             mapx            => 700,
             mapy            => 700,
             modesperline    => 12,
             eventsfile      => 'events.txt',
             monstfile       => 'monsters.txt',
             rpbase          => 600,
             rpstep          => 1.16,
             rppenstep       => 1.14,
             tournylvl       => 16,
             fightlowerlevel => 0,
           );

    if (-r "Config/$opts{conffile}") {
        open(CONF, '<', "Config/$opts{conffile}") or return;

        my($line,$key,$val);

        while ($line=<CONF>) {
            next() if $line =~ /^#/; # skip comments

            $line =~ s/[\r\n]//g;
            $line =~ s/^\s+//g;

            next() if !length($line); # skip blank lines

            ($key,$val) = split(/\s+/,$line,2);

            $key = lc($key);
            $val = "" if(!defined($val));

            if    (lc($val) eq "on"  || lc($val) eq "yes") { $val = 1; }
            elsif (lc($val) eq "off" || lc($val) eq "no")  { $val = 0; }

            if ($key eq "die") {
                die("Please edit the file Config/$opts{conffile} to setup your bot's options. Also, read the README file if you haven't yet.\n");
            }
            elsif ($key eq "server") {
                push(@{$opts{servers}},$val);
            }
            else {
                $opts{$key} = $val;
            }
        }
    }


1;
