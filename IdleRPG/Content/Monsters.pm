package Monsters;

use IdleRPG::IRC;

sub getList {
my %monster;
#### Monsters ####

###$monster{"XXX"}{gain} = 5;
###$monster{"XXX"}{regen} = 2;
###$monster{"XXX"}{goldm} -> $monster{"XXX"}{gold}

$monster{"Roach"}{sum} = 500;
$monster{"Roach"}{gold} = 0;
$monster{"Roach"}{gem} = 1;
$monster{"Spider"}{sum} = 1000;
$monster{"Spider"}{gold} = 250;
$monster{"Spider"}{gem} = 0;
$monster{"Bat"}{sum} = 2000;
$monster{"Bat"}{gold} = 0;
$monster{"Bat"}{gem} = 2;
$monster{"Wolf"}{sum} = 3000;
$monster{"Wolf"}{gold} = 400;
$monster{"Wolf"}{gem} = 0;
$monster{"Goblin"}{sum} = 4000;
$monster{"Goblin"}{gold} = 0;
$monster{"Goblin"}{gem} = 3;
$monster{"Shadow"}{sum} = 5000;
$monster{"Shadow"}{gold} = 500;
$monster{"Shadow"}{gem} = 0;
$monster{"Lich"}{sum} = 6000;
$monster{"Lich"}{gold} = 0;
$monster{"Lich"}{gem} = 4;
$monster{"Skeleton"}{sum} = 7000;
$monster{"Skeleton"}{gold} = 700;
$monster{"Skeleton"}{gem} = 0;
$monster{"Ghost"}{sum} = 8000;
$monster{"Ghost"}{gold} = 0;
$monster{"Ghost"}{gem} = 5;
$monster{"Phantom"}{sum} = 9000;
$monster{"Phantom"}{gold} = 800;
$monster{"Phantom"}{gem} = 0;
$monster{"Troll"}{sum} = 10000;
$monster{"Troll"}{gold} = 0;
$monster{"Troll"}{gem} = 6;
$monster{"Cyclop"}{sum} = 12000;
$monster{"Cyclop"}{gold} = 1000;
$monster{"Cyclop"}{gem} = 0;
$monster{"Mutant"}{sum} = 14000;
$monster{"Mutant"}{gold} = 0;
$monster{"Mutant"}{gem} = 8;
$monster{"Ogre"}{sum} = 17000;
$monster{"Ogre"}{gold} = 1400;
$monster{"Ogre"}{gem} = 0;
$monster{"Phoenix"}{sum} = 21000;
$monster{"Phoenix"}{gold} = 0;
$monster{"Phoenix"}{gem} = 10;
$monster{"Demon"}{sum} = 25000;
$monster{"Demon"}{gold} = 1700;
$monster{"Demon"}{gem} = 0;
$monster{"Centaur"}{sum} = 30000;
$monster{"Centaur"}{gold} = 0;
$monster{"Centaur"}{gem} = 12;
$monster{"Werewolf"}{sum} = 35000;
$monster{"Werewolf"}{gold} = 2000;
$monster{"Werewolf"}{gem} = 0;
$monster{"Giant"}{sum} = 40000;
$monster{"Giant"}{gold} = 0;
$monster{"Giant"}{gem} = 15;

return %monster;

}

sub get_monst_name {
    my $monsum = shift;
    my $monname = "Monster";
    if (!open(Q,$Options::opts{monstfile})) {
        IRC::chanmsg("ERROR: Failed to open $Options::opts{monstfile}: $!");
        return $monname;
    }
    while (my $line = <Q>) {
        chomp($line);
        if ($line =~ /^(\d+) ([^\r]*)\r*/) {
            if ($1 >= $monsum) {
                $monname = $2;
                last();
            }
        }
    }
    close(Q);
    return $monname;
}

1;
