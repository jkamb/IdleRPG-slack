package Constants;
use strict;
use warnings;

use base 'Exporter';

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

our @EXPORT_OK = ('TOWN','WORK','FOREST','BARBARIAN','PALADIN','ROGUE','WIZARD');

our %EXPORT_TAGS = ( locations => [ 'TOWN', 'WORK', 'FOREST' ], 
                     classes => [ 'BARBARIAN', 'PALADIN', 'ROGUE', 'WIZARD' ] 
                    );

1;
