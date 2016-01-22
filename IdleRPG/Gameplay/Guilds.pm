package Guilds;

#use IdleRPG::IRC;
#use IdleRPG::Options;

sub createGuild {
    my $u = shift;
    my $name = shift;
    my $cost = 10000;

    if($Simulation::rps{$u}{gold} >= $cost) {
        $Simulation::rps{$u}{gold} -= $cost;

        

        IRC::chanmsg("$u has founded the guild $name.");
        IRC::privmsg("Guild founded. You have earned the title $Simulation::rps{$u}{nick} of $name.", $Simulation::rps{$u}{nick});
    else {
        IRC::privmsg("You don't have enough gold. You need: $cost gold.", $Simulation::rps{$u}{nick});
    }

}

1;
