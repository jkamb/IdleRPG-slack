package Bot;

#use IdleRPG::Options;

sub daemonize() {
    if ($^O eq "MSWin32") {
        print debug("Nevermind, this is Win32, no I'm not.")."\n";
        return;
    }
    use POSIX 'setsid';
    $SIG{CHLD} = sub { };
    fork() && exit(0);
    POSIX::setsid() || debug("POSIX::setsid() failed: $!",1);
    $SIG{CHLD} = sub { };
    fork() && exit(0);
    $SIG{CHLD} = sub { };
    open(STDIN,'/dev/null') || debug("Cannot read /dev/null: $!",1);
    open(STDOUT,'>std.out') || debug("Cannot write to std.out: $!",1);
    open(STDERR,'>std.err') || debug("Cannot write to std.err: $!",1);
    open(PIDFILE,">$Options::opts{pidfile}") || do {
        debug("Error: failed opening pid file: $!");
        return;
    };
    print PIDFILE $$;
    close(PIDFILE);
}

sub debug {
    (my $text = shift) =~ s/[\r\n]//g;
    my $die = shift;
    if ($Options::opts{debug} || $Options::opts{verbose}) {
        open(DBG,">>Logs/dbg.txt") or do {
            chanmsg("Error: Cannot open debug file: $!");
            return;
        };
        print DBG ts()."$text\n";
        close(DBG);
    }
    if ($die) { die("$text\n"); }
    return $text;
}

sub ts { # timestamp
    my @ts = localtime(time());
    return sprintf("[%02d/%02d/%02d %02d:%02d:%02d] ", $ts[4]+1,$ts[3],$ts[5]%100,$ts[2],$ts[1],$ts[0]);
}

1;
