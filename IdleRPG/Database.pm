package Database;
use JSON;
use Encode;
use File::Slurp;

sub mksalt { # passwds
    join '',('a'..'z','A'..'Z','0'..'9','/','.')[rand(64), rand(64)];
}

sub loadjsondb {
    backup();
    %rps = ();

    if(-r "Database/$Options::opts{dbfile}") {
        my $json = read_file("Database/$Options::opts{dbfile}", err_mode => 'carp');

        if($json) {
            my $data = from_json(encode('utf8', $json), { utf8 => 1 });

            return %rps = %{$data};
        }
    }

    return;
}

sub writejsondb {
    my $stats = shift;
    my %rps = %$stats;
    delete $rps{''} if(exists $rps{''});
    my $rps = shift;
    foreach my $username (keys %rps) {
        delete $rps{$username} if(!defined $rps{$username}{level});
    }

    my $json = to_json(\%rps, { utf8 => 1, pretty => 1 });

    if(!write_file("Database/$Options::opts{dbfile}", { err_mode => 'carp' }, $json)) {
        IRC::chanmsg("ERROR: Cannot write Database/$Options::opts{dbfile}: $!");
        return;
    }

    return $json;
}

sub backup() {
    if (! -d "Database/Backup") { mkdir("Database/Backup",0700); }
    my $dbfile = $Options::opts{dbfile};
    system("cp Database/$dbfile Database/Backup/$dbfile".time());
}

sub checkdbfile {
 if (! -e "Database/$Options::opts{dbfile}") {
    $|=1;
    %rps = ();
    print "Database/$Options::opts{dbfile} does not exist enter account name for admin access [$Options::opts{owner}]: ";
    chomp(my $uname = <STDIN>);
    $uname =~ s/\s.*//g;
    $uname = length($uname)?$uname:$Options::opts{owner};
    print "Enter an ability (b,w,p,r): ";
    chomp(my $uability = <STDIN>);
    $rps{$uname}{ability} = $uability;
    print "Enter a character desc.: ";
    chomp(my $uclass = <STDIN>);
    $rps{$uname}{class} = substr($uclass,0,30);
    print "Enter a password: ";
    if ($^O ne "MSWin32") {
        system("stty -echo");
    }
    chomp(my $upass = <STDIN>);
    if ($^O ne "MSWin32") {
        system("stty echo");
    }
    $rps{$uname}{pass} = crypt($upass,mksalt());
    $rps{$uname}{admin} = 1;
    $rps{$uname}{next} = $Options::opts{rpbase};
    $rps{$uname}{nick} = "";
    $rps{$uname}{userhost} = "";
    $rps{$uname}{level} = 0;
    $rps{$uname}{online} = 0;
    $rps{$uname}{idled} = 0;
    $rps{$uname}{created} = time();
    $rps{$uname}{last_login} = time();
    $rps{$uname}{pos_x} = int(rand($Options::opts{mapx}));
    $rps{$uname}{pos_y} = int(rand($Options::opts{mapy}));
    $rps{$uname}{alignment} = "n";
    $rps{$uname}{gold} = 500;
    $rps{$uname}{life} = 100;
    for my $item ("ring","amulet","charm","weapon","helm","tunic","gloves","shield","leggings","boots") {
        $rps{$uname}{item}{$item} = 0;
    }
    for my $pen ("pen_mesg","pen_nick","pen_part","pen_kick","pen_quit","pen_quest","pen_logout","pen_logout") {
        $rps{$uname}{$pen} = 0;
    }
    for my $ThisField ("scrolls","ffight","bwon","blost","badd","bminus","powerpotion","status","gems","upgrade",
        "rt","dm","cl","pw","aw","lw","alw","tt","bt","regentm","dragontm","mana","lotto11","lotto12","lotto13","lotto21","lotto22","lotto23",
        "lotto31","lotto32","lotto33","experience","lottowins","lottosumwins","aligntime","Worktime","Towntime","Foresttime",
        "Special01","Special02","Special03","ExpertItem01","ExpertItem02","ExpertItem03","EndPlayer","EmptyField") {
        $rps{$uname}{$ThisField} = 0;
    }
    writejsondb(\%rps);
    print "OK, wrote you into Database/$Options::opts{dbfile}.\n";
 } else {
    return 0;
 }

}

1;
