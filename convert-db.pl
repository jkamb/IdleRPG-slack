#!/usr/bin/perl -w

use strict;
use Encode;
use Data::Dumper;
use File::Basename;
use File::Slurp;
use Getopt::Long qw(:config bundling);
use JSON;

my %cfg = (
	    in      => 'irpg.db',
	    out     => 'irpg-db.json',
	    verbose => 0,
	    help    => 0,
	  );

my $result = GetOptions(
			 'i|in=s'    => \$cfg{in},
			 'o|out=s'   => \$cfg{out},
			 'v|verbose' => \$cfg{verbose},
			 'h|help'    => \$cfg{help},
		       );

if(!$result || $cfg{help}) {
	print STDERR "\n" if(!$result);
	print "Usage: ".basename($0)." [OPTIONS]\n\n";
	print "Options:\n";
	print "-i, --in <FILE>    Old IdleRPG database text file ($cfg{in})\n";
	print "-o, --out <FILE>   New IdleRPG database JSON file ($cfg{out})\n";
	print "-v, --verbose      Enable verbose output\n";
	print "-h, --help         Display this usage information\n";

	exit 1;
}

if(!-f $cfg{in}) {
	print "Error: Not a file: $cfg{in}\n";
	exit 1;
}
elsif(!-r $cfg{in}) {
	print "Error: Cannot read file: $cfg{in}\n";
	exit 1;
}

my %rps = ();

if(!loaddb()) {
	print "Error: Failed to load database: $cfg{in}\n";
	exit 1;
}

print "rps:\n".Dumper(\%rps) if($cfg{verbose});

my $json = writedb();

if(!$json) {
	print "Error: Failed to write database: $cfg{out}\n";
	exit 1;
}

print "json:\n".Dumper($json) if($cfg{verbose});

exit 0;

################################################################################
# Subroutines

sub chanmsg {
	my ($message) = @_;

	print $message ."\n" if(defined $message);
}

sub loadjsondb {
	%rps = ();

	if(-r $cfg{in}) {
		my $json = read_file($cfg{in}, err_mode => 'carp');
		
		if($json) {
			my $data = from_json(encode('utf8', $json), { utf8 => 1 });

			%rps = %{$data};

			return $data;
		}
	}

	return;
}

sub writejsondb() {
	my $json = to_json(\%rps, { utf8 => 1, pretty => 1 });

	if(!write_file($cfg{out}, $json, { err_mode => 'carp' })) {
		chanmsg("ERROR: Cannot write $cfg{out}: $!");
        	return;
	}

	return $json;
}

sub loaddb {
    %rps = ();

    if(!-r $cfg{in}) {
	sts("QUIT :loaddb() cannot read database");
	return;
    }
    if (!open(RPS,$cfg{in})) {
        sts("QUIT :loaddb() failed: $!");
	return;
    }

    my $l = '';
    my $n = 1;
    my $r = undef;

    while ($l=<RPS>) {
        chomp($l);

	if($n == 1 && $l =~ /^\{/o) {
		# new JSON database format
		$r = loadjsondb();
		last;
	}

        next if $l =~ /^#/;

        my @i = split("\t",$l);

        print Dumper(@i) if @i != 80;
        if (@i != 80) {
            sts("QUIT: Anomaly in loaddb(); line $. of $cfg{in} has wrong fields (".scalar(@i).")");
            debug("Anomaly in loaddb(); line $. of $cfg{in} has wrong fields (".scalar(@i).")",1);
	    last;
        }

        #if (!$sock) {
        #    if ($i[8]) { $prev_online{$i[7]}=$i[0]; }
        #}

        ($rps{$i[0]}{pass},
        $rps{$i[0]}{admin},
        $rps{$i[0]}{level},
        $rps{$i[0]}{class},
        $rps{$i[0]}{next},
        $rps{$i[0]}{nick},
        $rps{$i[0]}{userhost},
        $rps{$i[0]}{online},
        $rps{$i[0]}{idled},
        $rps{$i[0]}{pos_x},
        $rps{$i[0]}{pos_y},
        $rps{$i[0]}{pen_mesg},
        $rps{$i[0]}{pen_nick},
        $rps{$i[0]}{pen_part},
        $rps{$i[0]}{pen_kick},
        $rps{$i[0]}{pen_quit},
        $rps{$i[0]}{pen_quest},
        $rps{$i[0]}{pen_logout},
        $rps{$i[0]}{created},
        $rps{$i[0]}{last_login},
        $rps{$i[0]}{item}{amulet},
        $rps{$i[0]}{item}{charm},
        $rps{$i[0]}{item}{helm},
        $rps{$i[0]}{item}{boots},
        $rps{$i[0]}{item}{gloves},
        $rps{$i[0]}{item}{ring},
        $rps{$i[0]}{item}{leggings},
        $rps{$i[0]}{item}{shield},
        $rps{$i[0]}{item}{tunic},
        $rps{$i[0]}{item}{weapon},
        $rps{$i[0]}{alignment},
        $rps{$i[0]}{ffight},
        $rps{$i[0]}{bwon},
        $rps{$i[0]}{blost},
        $rps{$i[0]}{badd},
        $rps{$i[0]}{bminus},
        $rps{$i[0]}{gold},
        $rps{$i[0]}{powerpotion},
        $rps{$i[0]}{status},
        $rps{$i[0]}{ability},
        $rps{$i[0]}{gems},
        $rps{$i[0]}{upgrade},
        $rps{$i[0]}{rt},
        $rps{$i[0]}{dm},
        $rps{$i[0]}{cl},
        $rps{$i[0]}{pw},
        $rps{$i[0]}{aw},
        $rps{$i[0]}{lw},
        $rps{$i[0]}{alw},
        $rps{$i[0]}{tt},
        $rps{$i[0]}{bt},
        $rps{$i[0]}{regentm},
        $rps{$i[0]}{dragontm},
        $rps{$i[0]}{mana},
        $rps{$i[0]}{lotto11},
        $rps{$i[0]}{lotto12},
        $rps{$i[0]}{lotto13},
        $rps{$i[0]}{lotto21},
        $rps{$i[0]}{lotto22},
        $rps{$i[0]}{lotto23},
        $rps{$i[0]}{lotto31},
        $rps{$i[0]}{lotto32},
        $rps{$i[0]}{lotto33},
        $rps{$i[0]}{experience},
        $rps{$i[0]}{life},
        $rps{$i[0]}{lottowins},
        $rps{$i[0]}{lottosumwins},
        $rps{$i[0]}{aligntime},
        $rps{$i[0]}{Worktime},
        $rps{$i[0]}{Towntime},
        $rps{$i[0]}{Foresttime},
        $rps{$i[0]}{Special01},
        $rps{$i[0]}{Special02},
        $rps{$i[0]}{Special03},
        $rps{$i[0]}{ExpertItem01},
        $rps{$i[0]}{ExpertItem02},
        $rps{$i[0]}{ExpertItem03},
        $rps{$i[0]}{EndPlayer},
        $rps{$i[0]}{EmptyField}) = (@i[1..7],$i[8],@i[9..$#i]);

	$n++;
	$r = \%rps;
    }
    close(RPS);

    return $r;
}

sub writedb {
    # New databases should only use the JSON format
    return writejsondb();

    open(RPS,">$cfg{in}") or do {
        chanmsg("ERROR: Cannot write $cfg{in}: $!");
        return 0;
    };
    print RPS join("\t","# username",
        "pass",
        "admin",
        "level",
        "class",
        "next",
        "nick",
        "userhost",
        "online",
        "idled",
        "pos_x",
        "pos_y",
        "pen_mesg",
        "pen_nick",
        "pen_part",
        "pen_kick",
        "pen_quit",
        "pen_quest",
        "pen_logout",
        "created",
        "last_login",
        "amulet",
        "charm",
        "helm",
        "boots",
        "gloves",
        "ring",
        "leggings",
        "shield",
        "tunic",
        "weapon",
        "alignment",
        "ffight",
        "bwon",
        "blost",
        "badd",
        "bminus",
        "gold",
        "powerpotion",
        "status",
        "ability",
        "gems",
        "upgrade",
        "rt",
        "dm",
        "cl",
        "pw",
        "aw",
        "lw",
        "alw",
        "tt",
        "bt",
        "regentm",
        "dragontm",
        "mana",
        "lotto11",
        "lotto12",
        "lotto13",
        "lotto21",
        "lotto22",
        "lotto23",
        "lotto31",
        "lotto32",
        "lotto33",
        "experience",
        "life",
        "lottowins",
        "lottosumwins",
        "aligntime",
        "Worktime",
        "Towntime",
        "Foresttime",
        "Special01",
        "Special02",
        "Special03",
        "ExpertItem01",
        "ExpertItem02",
        "ExpertItem03",
        "EndPlayer",
        "EmptyField")."\n";
    my $k;
    keys(%rps);
    while ($k=each(%rps)) {
        if (exists($rps{$k}{next}) && defined($rps{$k}{next})) {
            print RPS join("\t",$k,
                $rps{$k}{pass},
                $rps{$k}{admin},
                $rps{$k}{level},
                $rps{$k}{class},
                $rps{$k}{next},
                $rps{$k}{nick},
                $rps{$k}{userhost},
                $rps{$k}{online},
                $rps{$k}{idled},
                $rps{$k}{pos_x},
                $rps{$k}{pos_y},
                $rps{$k}{pen_mesg},
                $rps{$k}{pen_nick},
                $rps{$k}{pen_part},
                $rps{$k}{pen_kick},
                $rps{$k}{pen_quit},
                $rps{$k}{pen_quest},
                $rps{$k}{pen_logout},
                $rps{$k}{created},
                $rps{$k}{last_login},
                $rps{$k}{item}{amulet},
                $rps{$k}{item}{charm},
                $rps{$k}{item}{helm},
                $rps{$k}{item}{boots},
                $rps{$k}{item}{gloves},
                $rps{$k}{item}{ring},
                $rps{$k}{item}{leggings},
                $rps{$k}{item}{shield},
                $rps{$k}{item}{tunic},
                $rps{$k}{item}{weapon},
                $rps{$k}{alignment},
                $rps{$k}{ffight},
                $rps{$k}{bwon},
                $rps{$k}{blost},
                $rps{$k}{badd},
                $rps{$k}{bminus},
                $rps{$k}{gold},
                $rps{$k}{powerpotion},
                $rps{$k}{status},
                $rps{$k}{ability},
                $rps{$k}{gems},
                $rps{$k}{upgrade},
                $rps{$k}{rt},
                $rps{$k}{dm},
                $rps{$k}{cl},
                $rps{$k}{pw},
                $rps{$k}{aw},
                $rps{$k}{lw},
                $rps{$k}{alw},
                $rps{$k}{tt},
                $rps{$k}{bt},
                $rps{$k}{regentm},
                $rps{$k}{dragontm},
                $rps{$k}{mana},
                $rps{$k}{lotto11},
                $rps{$k}{lotto12},
                $rps{$k}{lotto13},
                $rps{$k}{lotto21},
                $rps{$k}{lotto22},
                $rps{$k}{lotto23},
                $rps{$k}{lotto31},
                $rps{$k}{lotto32},
                $rps{$k}{lotto33},
                $rps{$k}{experience},
                $rps{$k}{life},
                $rps{$k}{lottowins},
                $rps{$k}{lottosumwins},
                $rps{$k}{aligntime},
                $rps{$k}{Worktime},
                $rps{$k}{Towntime},
                $rps{$k}{Foresttime},
                $rps{$k}{Special01},
                $rps{$k}{Special02},
                $rps{$k}{Special03},
                $rps{$k}{ExpertItem01},
                $rps{$k}{ExpertItem02},
                $rps{$k}{ExpertItem03},
                $rps{$k}{EndPlayer},
                $rps{$k}{EmptyField})."\n";
        }
    }
    close(RPS);
}

