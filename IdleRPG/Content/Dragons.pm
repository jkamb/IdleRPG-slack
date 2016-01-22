package Dragons;
use warnings;
use strict;

sub getList {

my %dragon;
#### Dragons ####

###$dragon{"XXX"}{level}
###$dragon{"XXX"}{gain} = 5;
###$dragon{"XXX"}{regen} = 2;
###$dragon{"XXX"}{goldm}

$dragon{"Blue_Dragon"}{item} = 2;
$dragon{"Blue_Dragon"}{sum} = 5000;
$dragon{"Blue_Dragon"}{gold} = 800;
$dragon{"Blue_Dragon"}{gem} = 3;
$dragon{"Yellow_Dragon"}{item} = 3;
$dragon{"Yellow_Dragon"}{sum} = 7500;
$dragon{"Yellow_Dragon"}{gold} = 1200;
$dragon{"Yellow_Dragon"}{gem} = 5;
$dragon{"Green_Dragon"}{item} = 3;
$dragon{"Green_Dragon"}{sum} = 15000;
$dragon{"Green_Dragon"}{gold} = 2000;
$dragon{"Green_Dragon"}{gem} = 10;
$dragon{"Red_Dragon"}{item} = 4;
$dragon{"Red_Dragon"}{sum} = 25000;
$dragon{"Red_Dragon"}{gold} = 3000;
$dragon{"Red_Dragon"}{gem} = 15;
$dragon{"Black_Dragon"}{item} = 4;
$dragon{"Black_Dragon"}{sum} = 35000;
$dragon{"Black_Dragon"}{gold} = 4000;
$dragon{"Black_Dragon"}{gem} = 20;
$dragon{"White_Dragon"}{item} = 5;
$dragon{"White_Dragon"}{sum} = 40000;
$dragon{"White_Dragon"}{gold} = 5000;
$dragon{"White_Dragon"}{gem} = 25;
$dragon{"Bronze_Dragon"}{item} = 6;
$dragon{"Bronze_Dragon"}{sum} = 50000; #add 10k on fight roll
$dragon{"Bronze_Dragon"}{gold} = 7500;
$dragon{"Bronze_Dragon"}{gem} = 30;
$dragon{"Silver_Dragon"}{item} = 8;
$dragon{"Silver_Dragon"}{sum} = 60000; #add 20k on fight roll
$dragon{"Silver_Dragon"}{gold} = 10000;
$dragon{"Silver_Dragon"}{gem} = 45;
$dragon{"Gold_Dragon"}{item} = 10;
$dragon{"Gold_Dragon"}{sum} = 60000; #add 40k on fight roll
$dragon{"Gold_Dragon"}{gold} = 15000;
$dragon{"Gold_Dragon"}{gem} = 60;
$dragon{"Platinum_Dragon"}{item} = 12;
$dragon{"Platinum_Dragon"}{sum} = 90000; #add 60k on fight roll
$dragon{"Platinum_Dragon"}{gold} = 20000;
$dragon{"Platinum_Dragon"}{gem} = 75;

return %dragon;

}

1;
