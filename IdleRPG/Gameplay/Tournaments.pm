package Tournaments;

#use IdleRPG::Constants ':locations';
#use IdleRPG::Constants ':classes';
#use IdleRPG::Options;
#use IdleRPG::Simulation;
#use IdleRPG::RNG;
#use IdleRPG::Gameplay::Equipment;

our @tournament;
our $tournamenttime = time() + 5400;
our $TournyLvl = $Options::opts{tournylvl};
my $round;
my $battle;

our @deathmatch;
my $sess;
my $scuff;
our $deathmatchtime = time() + 14400;

our @megawar;
my $runda;
my $lupta;
our $megawartime = time() + 10800;

our @powerwar;
my $play; # PW round
my $game; # PW battle
our $powerwartime = time() + 36000;

our @abilitywar;
my $playAW; # AW round
my $gameAW; # AW battle
our $abilitywartime = time() + 5400 + int(rand(3600));

our @locationwar;
my $playLW; # LW round
my $gameLW; # LW battle
our $locationwartime = time() + 5400 + int(rand(3600));

our @alignwar;
my $playALW; # ALW round
my $gameALW; # ALW battle
our $alignwartime = time() + 5400 + int(rand(3600));


sub tournament {
  return if !$Options::opts{tournament};
  my $TournyAmt = 0;
  my %u = grep { $Simulation::rps{$_}{online} &&  $Simulation::rps{$_}{level} > 15 &&  $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
           $Simulation::rps{$_}{bt} < time() && time() -  $Simulation::rps{$_}{last_login} > 3600 } keys(%Simulation::rps);
  if(%u > 1 ) {
    @tournament = sort { $Simulation::rps{$b}{level} <=> $Simulation::rps{$a}{level} || $Simulation::rps{$a}{next} <=> $Simulation::rps{$b}{next} } keys %u;
    if ($TournyLvl == 32) {
      if (@tournament < 32) {
          if (@tournament < 16) {
                  if (@tournament < 8) {
                      if (@tournament < 4) {
                          $TournyAmt = 2;
                      }
                      else {
                          $TournyAmt = 4;
                      }
                  }
                  else {
                      $TournyAmt = 8;
                  }
              }
              else {
                  $TournyAmt = 16;
              }
          }
          else {
              $TournyAmt = 32;
          }
    }
    else {
          if (@tournament < 16) {
              if (@tournament < 8) {
                  if (@tournament < 4) {
                      $TournyAmt = 2;
                  }
                  else {
                      $TournyAmt = 4;
                  }
              }
              else {
                  $TournyAmt = 8;
              }
          }
          else {
              $TournyAmt = 16;
          }
    }
    splice(@tournament,int rand @tournament,1) while @tournament > $TournyAmt;

    IRC::chanmsg(join(", ",@tournament)." have been chosen to participate in the Top Players Battle.");
    $round = 1;
    $battle = 1;
    RNG::fisher_yates_shuffle( \@tournament );
    $tournamenttime = time() + 40;
  }
}

sub tournament_battle {
   my $winner;
   my $loser;
   my $p1 = $battle*2-2;
   my $p2 = $p1 + 1;
   my $p1sum = int((Equipment::itemsum($tournament[$p1],1)+($Simulation::rps{$tournament[$p1]}{upgrade}*100))*($Simulation::rps{$tournament[$p1]}{life}/100));
   my $p2sum = int((Equipment::itemsum($tournament[$p2],1)+($Simulation::rps{$tournament[$p2]}{upgrade}*100))*($Simulation::rps{$tournament[$p2]}{life}/100));
   my $p1roll = int(rand($p1sum));
   my $p2roll = int(rand($p2sum));
   if ($p1roll >= $p2roll) {
      $winner = $p1;
      $loser = $p2;
   } else {
      $winner = $p2;
      $loser = $p1;
   }
   IRC::chanmsg("Top Players Battle $round, Fight $battle: $tournament[$p1] ".
      "[$p1roll/$p1sum] vs $tournament[$p2] [$p2roll/$p2sum] ... ".
      "$tournament[$winner] advances and gets 25 gold from $tournament[$loser]! $tournament[$winner] gets 2 XP, ".
      "$tournament[$loser] gets 1 XP and loses 2 life points.");
        $Simulation::rps{$tournament[$winner]}{gold} += 25;
        $Simulation::rps{$tournament[$winner]}{experience} += 2;
        $Simulation::rps{$tournament[$loser]}{experience} += 1;
        $Simulation::rps{$tournament[$loser]}{life} -= 2;
        $Simulation::rps{$tournament[$loser]}{gold} -= 25;
   $tournament[$loser] = "xx";
   ++$battle;
   if ($battle > (@tournament / 2)) {
      ++$round;
      $battle = 1;
      my $ucnt = (@tournament - 1);
      while ($ucnt > -1) {
         if ($tournament[$ucnt] eq "xx") {
            splice(@tournament,$ucnt ,1);
         }
         --$ucnt;
      }
      if (@tournament > 1) {
         IRC::chanmsg(join(", ",@tournament)." advance to round $round of the Top Players Battle.");
      }
      RNG::fisher_yates_shuffle( \@tournament );
   }
   if (@tournament == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $Simulation::rps{$tournament[0]}{next});
      IRC::chanmsg(Simulation::clog("$tournament[0] has won the Top Players Battle! As a ".
        "reward, $tournament[0] gets 500 gold, 10 XP and 5 points added to each item!"));
      $Simulation::rps{$tournament[0]}{item}{amulet} += 5;
      $Simulation::rps{$tournament[0]}{item}{boots} += 5;
      $Simulation::rps{$tournament[0]}{item}{charm} += 5;
      $Simulation::rps{$tournament[0]}{item}{gloves} += 5;
      $Simulation::rps{$tournament[0]}{item}{helm} += 5;
      $Simulation::rps{$tournament[0]}{item}{leggings} += 5;
      $Simulation::rps{$tournament[0]}{item}{ring} += 5;
      $Simulation::rps{$tournament[0]}{item}{shield} += 5;
      $Simulation::rps{$tournament[0]}{item}{tunic} += 5;
      $Simulation::rps{$tournament[0]}{item}{weapon} += 5;
      $Simulation::rps{$tournament[0]}{rt} += 1;
      $Simulation::rps{$tournament[0]}{gold} += 500;
      $Simulation::rps{$tournament[0]}{experience} += 10;
      $Simulation::rps{$tournament[0]}{bt} = time() + 86400;
      $tournamenttime = time() + 10800 + int(rand(3600));
      undef @tournament;
   }
    else {
      $tournamenttime = time() + 40;
   }
}

sub deathmatch {
  return if !$Options::opts{deathmatch};
  @deathmatch = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 25 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{tt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 } keys %Simulation::rps;
  if (@deathmatch < $TournyLvl) {
     $deathmatchtime = time() + 14400;
     return undef @deathmatch;
   }
  splice(@deathmatch,int rand @deathmatch,1) while @deathmatch > $Tournaments::TournyLvl;
  IRC::chanmsg(join(", ",@deathmatch)." have been chosen to participate in the Death Match.");
  $sess = 1;
  $scuff = 1;
  RNG::fisher_yates_shuffle( \@deathmatch );
  $deathmatchtime = time() + 40;
}

sub deathmatch_battle {
   my $winnar;
   my $loser;
   my $SecondPlace;
   my $DMp1 = $scuff*2-2;
   my $DMp2 = $DMp1 + 1;
   my $DMp1sum = int((Equipment::itemsum($deathmatch[$DMp1],1)+($Simulation::rps{$deathmatch[$DMp1]}{upgrade}*100))*($Simulation::rps{$deathmatch[$DMp1]}{life}/100));
   my $DMp2sum = int((Equipment::itemsum($deathmatch[$DMp2],1)+($Simulation::rps{$deathmatch[$DMp2]}{upgrade}*100))*($Simulation::rps{$deathmatch[$DMp2]}{life}/100));
   my $DMp1roll = int(rand($DMp1sum));
   my $DMp2roll = int(rand($DMp2sum));
   if ($DMp1roll >= $DMp2roll) {
      $winnar = $DMp1;
      $loser = $DMp2;
   } else {
      $winnar = $DMp2;
      $loser = $DMp1;
   }
   IRC::chanmsg("Death Match Round $sess, Fight $scuff: $deathmatch[$DMp1] ".
      "[$DMp1roll/$DMp1sum] vs $deathmatch[$DMp2] [$DMp2roll/$DMp2sum] ... ".
      "$deathmatch[$winnar] is victorious and gets 50 gold from $deathmatch[$loser]! ".
      "$deathmatch[$winnar] gets 2 XP, $deathmatch[$loser] gets 1 XP and loses 5 life points.");
        $Simulation::rps{$deathmatch[$winnar]}{gold} += 50;
        $Simulation::rps{$deathmatch[$winnar]}{experience} += 2;
        $Simulation::rps{$deathmatch[$loser]}{experience} += 1;
        $Simulation::rps{$deathmatch[$loser]}{life} -= 5;
        $Simulation::rps{$deathmatch[$loser]}{gold} -= 50;
        if (@deathmatch == 2) {
            $SecondPlace = $deathmatch[$loser];
        }
   $deathmatch[$loser] = "xx";
   ++$scuff;
   if ($scuff > (@deathmatch / 2)) {
      ++$sess;
      $scuff = 1;
      my $supunct = (@deathmatch - 1);
      while ($supunct > -1) {
         if ($deathmatch[$supunct] eq "xx") {
            splice(@deathmatch,$supunct ,1);
         }
         --$supunct;
      }
      if (@deathmatch > 1) {
         IRC::chanmsg(join(", ",@deathmatch)." progess to round $sess of the Death Match.");
      }
      RNG::fisher_yates_shuffle( \@deathmatch );
   }
   if (@deathmatch == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $Simulation::rps{$deathmatch[0]}{next});
      IRC::chanmsg(Simulation::clog("$deathmatch[0] has won the Death Match! As a reward, ".
        Simulation::duration($time)." is removed from TTL $deathmatch[0] gets 30 gems, 30 XP and 3000 gold".
        " and $SecondPlace gets 10 gems, 10 XP and 1000 gold.."));
      $Simulation::rps{$deathmatch[0]}{next} -= $time;
      $Simulation::rps{$deathmatch[0]}{gems} += 30;
      $Simulation::rps{$deathmatch[0]}{gold} += 3000;
      $Simulation::rps{$deathmatch[0]}{experience} += 30;
      $Simulation::rps{$SecondPlace}{gems} += 10;
      $Simulation::rps{$SecondPlace}{gold} += 1000;
      $Simulation::rps{$SecondPlace}{experience} += 10;
      $Simulation::rps{$deathmatch[0]}{dm} += 1;
      $Simulation::rps{$deathmatch[0]}{tt} = time() + 172800;
      $deathmatchtime = time() + 14400;
      undef @deathmatch;
   } else {
      $deathmatchtime = time() + 40;
   }
}

sub megawar {
  return if !$Options::opts{megawar};
  @megawar = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 25 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{tt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 } keys %Simulation::rps;
  if (@megawar < $Tournaments::TournyLvl) {
     $megawartime = time() + 10800;
     return undef @megawar;
   }
  splice(@megawar,int rand @megawar,1) while @megawar > $Tournaments::TournyLvl;
  IRC::chanmsg(join(", ",@megawar)." have been chosen to participate in the Champions League.");
  $runda = 1;
  $lupta = 1;
  RNG::fisher_yates_shuffle( \@megawar );
  $megawartime = time() + 40;
}

sub megawar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $MWp1 = $lupta*2-2;
   my $MWp2 = $MWp1 + 1;
   my $MWp1sum = int((Equipment::itemsum($megawar[$MWp1],1)+($Simulation::rps{$megawar[$MWp1]}{upgrade}*100))*($Simulation::rps{$megawar[$MWp1]}{life}/100));
   my $MWp2sum = int((Equipment::itemsum($megawar[$MWp2],1)+($Simulation::rps{$megawar[$MWp2]}{upgrade}*100))*($Simulation::rps{$megawar[$MWp2]}{life}/100));
   my $MWp1roll = int(rand($MWp1sum));
   my $MWp2roll = int(rand($MWp2sum));
   if ($MWp1roll >= $MWp2roll) {
      $winner = $MWp1;
      $loser = $MWp2;
   } else {
      $winner = $MWp2;
      $loser = $MWp1;
   }
   IRC::chanmsg("Champions League Round $runda, Fight $lupta: $megawar[$MWp1] ".
      "[$MWp1roll/$MWp1sum] vs $megawar[$MWp2] [$MWp2roll/$MWp2sum] ... ".
      "$megawar[$winner] advances and gets 50 gold from $megawar[$loser]! $megawar[$winner] gets 2 XP, ".
      "$megawar[$loser] gets 1 XP and loses 5 life points.");
        $Simulation::rps{$megawar[$winner]}{gold} += 50;
        $Simulation::rps{$megawar[$winner]}{experience} += 2;
        $Simulation::rps{$megawar[$loser]}{experience} += 1;
        $Simulation::rps{$megawar[$loser]}{life} -= 5;
        $Simulation::rps{$megawar[$loser]}{gold} -= 50;
        if (@megawar == 2) {
            $SecondPlace = $megawar[$loser];
        }
   $megawar[$loser] = "xx";
   ++$lupta;
   if ($lupta > (@megawar / 2)) {
      ++$runda;
      $lupta = 1;
      my $ovi = (@megawar - 1);
      while ($ovi > -1) {
         if ($megawar[$ovi] eq "xx") {
            splice(@megawar,$ovi ,1);
         }
         --$ovi;
      }
      if (@megawar > 1) {
         IRC::chanmsg(join(", ",@megawar)." advance to round $runda of the Champions League.");
      }
      RNG::fisher_yates_shuffle( \@megawar );
   }
   if (@megawar == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $Simulation::rps{$megawar[0]}{next});

      #if ($time > 86400) { $time=86400; }
      IRC::chanmsg(Simulation::clog("$megawar[0] has won the Champions League! As a reward, ".Simulation::duration($time).
        " is removed from TTL. $megawar[0] gets 15 gems, 40 XP and 2000 gold and $SecondPlace gets 5 gems, 5 XP and 500 gold"));
      $Simulation::rps{$megawar[0]}{next} -= $time;
      $Simulation::rps{$megawar[0]}{gems} += 15;
      $Simulation::rps{$megawar[0]}{gold} += 2000;
      $Simulation::rps{$megawar[0]}{experience} += 40;
      $Simulation::rps{$SecondPlace}{gems} += 5;
      $Simulation::rps{$SecondPlace}{gold} += 500;
      $Simulation::rps{$SecondPlace}{experience} += 5;
      $Simulation::rps{$megawar[0]}{cl} += 1;
      $Simulation::rps{$megawar[0]}{tt} = time() + 172800;
      $megawartime = time() + 10800 + int(rand(10800));
      undef @megawar;
   }
    else {
      $megawartime = time() + 40;
   }
}

sub powerwar {
  return if !$Options::opts{powerwar};
  @powerwar = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 25 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{tt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 } keys %Simulation::rps;
  if (@powerwar < $Tournaments::TournyLvl) {
     $powerwartime = time() + 36000;
     return undef @powerwar;
   }
  splice(@powerwar,int rand @powerwar,1) while @powerwar > $Tournaments::TournyLvl;
  IRC::chanmsg(join(", ",@powerwar)." have been chosen to participate in the Power War.");
  $play = 1;
  $game = 1;
  RNG::fisher_yates_shuffle( \@powerwar );
  $powerwartime = time() + 40;
}

sub powerwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $PWp1 = $game*2-2;
   my $PWp2 = $PWp1 + 1;
   my $PWp1sum = int((Equipment::itemsum($powerwar[$PWp1],1)+($Simulation::rps{$powerwar[$PWp1]}{upgrade}*100))*($Simulation::rps{$powerwar[$PWp1]}{life}/100));
   my $PWp2sum = int((Equipment::itemsum($powerwar[$PWp2],1)+($Simulation::rps{$powerwar[$PWp2]}{upgrade}*100))*($Simulation::rps{$powerwar[$PWp2]}{life}/100));
   my $PWp1roll = int(rand($PWp1sum));
   my $PWp2roll = int(rand($PWp2sum));
   if ($PWp1roll >= $PWp2roll) {
      $winner = $PWp1;
      $loser = $PWp2;
   } else {
      $winner = $PWp2;
      $loser = $PWp1;
   }
   IRC::chanmsg("Power War Round $play, Fight $game: $powerwar[$PWp1] ".
      "[$PWp1roll/$PWp1sum] vs $powerwar[$PWp2] [$PWp2roll/$PWp2sum] ... ".
      "$powerwar[$winner] advances and gets 50 gold from $powerwar[$loser]! $powerwar[$winner] gets 2 XP, ".
      "$powerwar[$loser] gets 1 XP and loses 5 life.");
        $Simulation::rps{$powerwar[$winner]}{gold} += 50;
        $Simulation::rps{$powerwar[$winner]}{experience} += 2;
        $Simulation::rps{$powerwar[$loser]}{experience} += 1;
        $Simulation::rps{$powerwar[$loser]}{life} -= 5;
        $Simulation::rps{$powerwar[$loser]}{gold} -= 50;
        if (@powerwar == 2) {
            $SecondPlace = $powerwar[$loser];
        }
   $powerwar[$loser] = "xx";
   ++$game;
   if ($game > (@powerwar / 2)) {
      ++$play;
      $game = 1;
      my $muie = (@powerwar - 1);
      while ($muie > -1) {
         if ($powerwar[$muie] eq "xx") {
            splice(@powerwar,$muie ,1);
         }
         --$muie;
      }
      if (@powerwar > 1) {
         IRC::chanmsg(join(", ",@powerwar)." advance to round $play of the Power War.");
      }
      RNG::fisher_yates_shuffle( \@powerwar );
   }
   if (@powerwar == 1) {
      my $time = int(((10 + int(rand(40)))/100) * $Simulation::rps{$powerwar[0]}{next});
      IRC::chanmsg(Simulation::clog("$powerwar[0] has won the Power War! As a reward, ".Simulation::duration($time).
        " is removed from TTL, gets 10 gems, 20 XP, their items gets 10 points stronger".
        " and $SecondPlace gets 5 gems and 10 XP."));
      $Simulation::rps{$powerwar[0]}{next} -= $time;
      $Simulation::rps{$powerwar[0]}{gems} += 10;
      $Simulation::rps{$powerwar[0]}{experience} += 20;
      $Simulation::rps{$SecondPlace}{gems} += 5;
      $Simulation::rps{$SecondPlace}{experience} += 10;
      $Simulation::rps{$powerwar[0]}{item}{amulet} += 10;
      $Simulation::rps{$powerwar[0]}{item}{boots} += 10;
      $Simulation::rps{$powerwar[0]}{item}{charm} += 10;
      $Simulation::rps{$powerwar[0]}{item}{gloves} += 10;
      $Simulation::rps{$powerwar[0]}{item}{helm} += 10;
      $Simulation::rps{$powerwar[0]}{item}{leggings} += 10;
      $Simulation::rps{$powerwar[0]}{item}{ring} += 10;
      $Simulation::rps{$powerwar[0]}{item}{shield} += 10;
      $Simulation::rps{$powerwar[0]}{item}{tunic} += 10;
      $Simulation::rps{$powerwar[0]}{item}{weapon} += 10;
      $Simulation::rps{$powerwar[0]}{pw} += 1;
      $Simulation::rps{$powerwar[0]}{tt} = time() + 172800;
      $powerwartime = time() + 36000 + int(rand(36000));
      undef @powerwar;
   }
    else {
      $powerwartime = time() + 40;
   }
}

sub abilitywar {
  return if !$Options::opts{abilitywar};
  my @Abilities = ("b","p","w","r");
  my $ThisAbility = $Abilities[rand(@Abilities)];
  @abilitywar = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 15 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{bt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 && $Simulation::rps{$_}{ability} eq $ThisAbility} keys %Simulation::rps;

  my $TournyAmt = $Tournaments::TournyLvl;
  if (@abilitywar < 32) {
        if (@abilitywar < 16) {
            if (@abilitywar < 8) {
                if (@abilitywar < 4) {
                    if (@abilitywar < 2) {
                        $abilitywartime = time() + 5400 + int(rand(3600));
                        return undef @abilitywar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }

  splice(@abilitywar,int rand @abilitywar,1) while @abilitywar > $TournyAmt;
   if ($ThisAbility eq BARBARIAN) {
    $ThisAbility = "Barbarian";
   }
   elsif ($ThisAbility eq PALADIN) {
    $ThisAbility = "Paladin";
   }
   elsif ($ThisAbility eq WIZARD) {
    $ThisAbility = "Wizard";
   }
   elsif ($ThisAbility eq ROGUE) {
    $ThisAbility = "Rogue";
   }
  IRC::chanmsg(join(", ",@abilitywar)." have been chosen to participate in the Ability Battle - $ThisAbility.");
  $playAW = 1;
  $gameAW = 1;
  RNG::fisher_yates_shuffle( \@abilitywar );
  $abilitywartime = time() + 40;
}

sub abilitywar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $AWp1 = $gameAW*2-2;
   my $AWp2 = $AWp1 + 1;
   my $ThisAbility = $Simulation::rps{$abilitywar[$AWp1]}{ability};
   if ($ThisAbility eq BARBARIAN) {
    $ThisAbility = "Barbarian";
   }
   elsif ($ThisAbility eq PALADIN) {
    $ThisAbility = "Paladin";
   }
   elsif ($ThisAbility eq WIZARD) {
    $ThisAbility = "Wizard";
   }
   elsif ($ThisAbility eq ROGUE) {
    $ThisAbility = "Rogue";
   }
   my $AWp1sum = int((Equipment::itemsum($abilitywar[$AWp1],1)+($Simulation::rps{$abilitywar[$AWp1]}{upgrade}*100))*($Simulation::rps{$abilitywar[$AWp1]}{life}/100));
   my $AWp2sum = int((Equipment::itemsum($abilitywar[$AWp2],1)+($Simulation::rps{$abilitywar[$AWp2]}{upgrade}*100))*($Simulation::rps{$abilitywar[$AWp2]}{life}/100));
   my $AWp1roll = int(rand($AWp1sum));
   my $AWp2roll = int(rand($AWp2sum));
   if ($AWp1roll >= $AWp2roll) {
      $winner = $AWp1;
      $loser = $AWp2;
   } else {
      $winner = $AWp2;
      $loser = $AWp1;
   }
   IRC::chanmsg("$ThisAbility Battle Round $playAW, Fight $gameAW: $abilitywar[$AWp1] ".
      "[$AWp1roll/$AWp1sum] vs $abilitywar[$AWp2] [$AWp2roll/$AWp2sum] ... ".
      "$abilitywar[$winner] advances and gets 25 gold from $abilitywar[$loser]! $abilitywar[$winner] gets 2 XP, ".
      "$abilitywar[$loser] gets 1 XP and loses 2 life.");
        $Simulation::rps{$abilitywar[$winner]}{gold} += 25;
        $Simulation::rps{$abilitywar[$winner]}{experience} += 2;
        $Simulation::rps{$abilitywar[$loser]}{experience} += 1;
        $Simulation::rps{$abilitywar[$loser]}{life} -= 2;
        $Simulation::rps{$abilitywar[$loser]}{gold} -= 25;
        if (@abilitywar == 2) {
            $SecondPlace = $abilitywar[$loser];
        }
   $abilitywar[$loser] = "xx";
   ++$gameAW;
   if ($gameAW > (@abilitywar / 2)) {
      ++$playAW;
      $gameAW = 1;
      my $muie = (@abilitywar - 1);
      while ($muie > -1) {
         if ($abilitywar[$muie] eq "xx") {
            splice(@abilitywar,$muie ,1);
         }
         --$muie;
      }
      if (@abilitywar > 1) {
         IRC::chanmsg(join(", ",@abilitywar)." advance to round $playAW of the $ThisAbility Battle.");
      }
      RNG::fisher_yates_shuffle( \@abilitywar );
   }
   if (@abilitywar == 1) {
      IRC::chanmsg(Simulation::clog("$abilitywar[0] has won the $ThisAbility Battle! As a reward, manual fights are reset to 0 for their ".
        "current level and the time for attack and slay are also reset. Good luck $abilitywar[0]!"));
      $Simulation::rps{$abilitywar[0]}{ffight} = 0;
      $Simulation::rps{$abilitywar[0]}{regentm} = 0;
      $Simulation::rps{$abilitywar[0]}{dragontm} = 0;
      $Simulation::rps{$abilitywar[0]}{aw} += 1;
      $Simulation::rps{$abilitywar[0]}{bt} = time() + 86400;
      $abilitywartime = time() + 5400 + int(rand(3600));
      undef @abilitywar;
   }
    else {
      $abilitywartime = time() + 40;
   }
}

sub locationwar {
  return if !$Options::opts{locationwar};
  my @Locations = (TOWN, WORK, FOREST);
  my $ThisLocation = $Locations[rand(@Locations)];
  @locationwar = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 15 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{bt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 && $Simulation::rps{$_}{status} == $ThisLocation } keys %Simulation::rps;

  my $TournyAmt = $Tournaments::TournyLvl;
  if (@locationwar < 32) {
        if (@locationwar < 16) {
            if (@locationwar < 8) {
                if (@locationwar < 4) {
                    if (@locationwar < 2) {
                        $locationwartime = time() + 5400 + int(rand(3600));
                        return undef @locationwar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }
  splice(@locationwar,int rand @locationwar,1) while @locationwar > $TournyAmt;
   if ($ThisLocation == TOWN) {
    $ThisLocation = "Town";
   }
   elsif ($ThisLocation == WORK) {
    $ThisLocation = "Work";
   }
   elsif ($ThisLocation == FOREST) {
    $ThisLocation = "Forest";
   }
  IRC::chanmsg(join(", ",@locationwar)." have been chosen to participate in the Location Battle - $ThisLocation.");
  $playLW = 1;
  $gameLW = 1;
  RNG::fisher_yates_shuffle( \@locationwar );
  $locationwartime = time() + 40;
}

sub locationwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $LWp1 = $gameLW*2-2;
   my $LWp2 = $LWp1 + 1;
   my $ThisLocation = $Simulation::rps{$locationwar[$LWp1]}{status};
   if ($ThisLocation == TOWN) {
    $ThisLocation = "Town";
   }
   elsif ($ThisLocation == WORK) {
    $ThisLocation = "Work";
   }
   elsif ($ThisLocation == FOREST) {
    $ThisLocation = "Forest";
   }
   my $LWp1sum = int((Equipment::itemsum($locationwar[$LWp1],1)+($Simulation::rps{$locationwar[$LWp1]}{upgrade}*100))*($Simulation::rps{$locationwar[$LWp1]}{life}/100));
   my $LWp2sum = int((Equipment::itemsum($locationwar[$LWp2],1)+($Simulation::rps{$locationwar[$LWp2]}{upgrade}*100))*($Simulation::rps{$locationwar[$LWp2]}{life}/100));
   my $LWp1roll = int(rand($LWp1sum));
   my $LWp2roll = int(rand($LWp2sum));
   if ($LWp1roll >= $LWp2roll) {
      $winner = $LWp1;
      $loser = $LWp2;
   } else {
      $winner = $LWp2;
      $loser = $LWp1;
   }
   IRC::chanmsg("$ThisLocation Battle Round $playLW, Fight $gameLW: $locationwar[$LWp1] ".
      "[$LWp1roll/$LWp1sum] vs $locationwar[$LWp2] [$LWp2roll/$LWp2sum] ... ".
      "$locationwar[$winner] advances and gets 25 gold from $locationwar[$loser]! $locationwar[$winner] gets 2 XP, ".
      "$locationwar[$loser] gets 1 XP and loses 2 life.");
        $Simulation::rps{$locationwar[$winner]}{gold} += 25;
        $Simulation::rps{$locationwar[$winner]}{experience} += 2;
        $Simulation::rps{$locationwar[$loser]}{experience} += 1;
        $Simulation::rps{$locationwar[$loser]}{life} -= 2;
        $Simulation::rps{$locationwar[$loser]}{gold} -= 25;
        if (@locationwar == 2) {
            $SecondPlace = $locationwar[$loser];
        }
   $locationwar[$loser] = "xx";
   ++$gameLW;
   if ($gameLW > (@locationwar / 2)) {
      ++$playLW;
      $gameLW = 1;
      my $muie = (@locationwar - 1);
      while ($muie > -1) {
         if ($locationwar[$muie] eq "xx") {
            splice(@locationwar,$muie ,1);
         }
         --$muie;
      }
      if (@locationwar > 1) {
         IRC::chanmsg(join(", ",@locationwar)." advance to round $playLW of the $ThisLocation Battle.");
      }
      RNG::fisher_yates_shuffle( \@locationwar );
   }
   if (@locationwar == 1) {
      IRC::chanmsg(Simulation::clog("$locationwar[0] has won the $ThisLocation Battle!"));
      if ($Simulation::rps{$locationwar[0]}{Worktime} > 0) {
        my $time = int(((10 + int(rand(40)))/100) * $Simulation::rps{$locationwar[0]}{next});
        $Simulation::rps{$locationwar[0]}{next} -= $time;
        IRC::chanmsg(Simulation::clog("$locationwar[0] received 2 days of wages (1440 gold) and ".Simulation::duration($time)." is removed from TTL!"));
        $Simulation::rps{$locationwar[0]}{gold} += 1440;
      }
      if ($Simulation::rps{$locationwar[0]}{Towntime} > 0) {
        IRC::chanmsg(Simulation::clog("$locationwar[0] received 2 days of experience (96 XP)!"));
        $Simulation::rps{$locationwar[0]}{experience} += 96;
      }
      if ($Simulation::rps{$locationwar[0]}{Foresttime} > 0) {
        IRC::chanmsg(Simulation::clog("$locationwar[0] found 10 gems near a cave! $locationwar[0] will now explore the cave..."));
        $Simulation::rps{$locationwar[0]}{gems} += 10;
        Events::forestwalk($locationwar[0]);
      }
      $Simulation::rps{$locationwar[0]}{lw} += 1;
      $Simulation::rps{$locationwar[0]}{bt} = time() + 86400;
      $locationwartime = time() + 5400 + int(rand(3600));
      undef @locationwar;
   }
    else {
      $locationwartime = time() + 40;
   }
}

sub alignwar {
  return if !$Options::opts{alignwar};
  my @Align = ("g","n","e");
  my $ThisAlign = $Align[rand(@Align)];
  @alignwar = grep { $Simulation::rps{$_}{online} && $Simulation::rps{$_}{level} > 15 && $Simulation::rps{$_}{gold} > 100 && $Simulation::rps{$_}{life} > 20 &&
    $Simulation::rps{$_}{bt} < time() && time()-$Simulation::rps{$_}{last_login} > 3600 && $Simulation::rps{$_}{alignment} eq $ThisAlign} keys %Simulation::rps;

  my $TournyAmt = $Tournaments::TournyLvl;
  if (@alignwar < 32) {
        if (@alignwar < 16) {
            if (@alignwar < 8) {
                if (@alignwar < 4) {
                    if (@alignwar < 2) {
                        $alignwartime = time() + 5400 + int(rand(3600));
                        return undef @alignwar;
                    }
                    else {
                        $TournyAmt = 2;
                    }
                }
                else {
                    $TournyAmt = 4;
                }
            }
            else {
                $TournyAmt = 8;
            }
        }
        else {
            $TournyAmt = 16;
        }
    }
    else {
        $TournyAmt = 32;
    }
  splice(@alignwar,int rand @alignwar,1) while @alignwar > $TournyAmt;
   if ($ThisAlign eq "g") {
    $ThisAlign = "Good";
   }
   elsif ($ThisAlign eq "n") {
    $ThisAlign = "Neutral";
   }
   elsif ($ThisAlign eq "e") {
    $ThisAlign = "Evil";
   }
  IRC::chanmsg(join(", ",@alignwar)." have been chosen to participate in the Alignment Battle - $ThisAlign.");
  $playALW = 1;
  $gameALW = 1;
  RNG::fisher_yates_shuffle( \@alignwar );
  $alignwartime = time() + 40;
}
sub alignwar_battle {
   my $winner;
   my $loser;
   my $SecondPlace;
   my $ALWp1 = $gameALW*2-2;
   my $ALWp2 = $ALWp1 + 1;
   my $ThisAlign = $Simulation::rps{$alignwar[$ALWp1]}{alignment};
   if ($ThisAlign eq "g") {
    $ThisAlign = "Good";
   }
   elsif ($ThisAlign eq "n") {
    $ThisAlign = "Neutral";
   }
   elsif ($ThisAlign eq "e") {
    $ThisAlign = "Evil";
   }
   my $ALWp1sum = int((Equipment::itemsum($alignwar[$ALWp1],1)+($Simulation::rps{$alignwar[$ALWp1]}{upgrade}*100))*($Simulation::rps{$alignwar[$ALWp1]}{life}/100));
   my $ALWp2sum = int((Equipment::itemsum($alignwar[$ALWp2],1)+($Simulation::rps{$alignwar[$ALWp2]}{upgrade}*100))*($Simulation::rps{$alignwar[$ALWp2]}{life}/100));
   my $ALWp1roll = int(rand($ALWp1sum));
   my $ALWp2roll = int(rand($ALWp2sum));
   if ($ALWp1roll >= $ALWp2roll) {
      $winner = $ALWp1;
      $loser = $ALWp2;
   } else {
      $winner = $ALWp2;
      $loser = $ALWp1;
   }
   IRC::chanmsg("$ThisAlign Battle Round $playALW, Fight $gameALW: $alignwar[$ALWp1] ".
      "[$ALWp1roll/$ALWp1sum] vs $alignwar[$ALWp2] [$ALWp2roll/$ALWp2sum] ... ".
      "$alignwar[$winner] advances and gets 25 gold from $alignwar[$loser]! $alignwar[$winner] gets 2 XP, ".
      "$alignwar[$loser] gets 1 XP and loses 2 life.");
        $Simulation::rps{$alignwar[$winner]}{gold} += 25;
        $Simulation::rps{$alignwar[$winner]}{experience} += 2;
        $Simulation::rps{$alignwar[$loser]}{experience} += 1;
        $Simulation::rps{$alignwar[$loser]}{life} -= 2;
        $Simulation::rps{$alignwar[$loser]}{gold} -= 25;
        if (@alignwar == 2) {
            $SecondPlace = $alignwar[$loser];
        }
   $alignwar[$loser] = "xx";
   ++$gameALW;
   if ($gameALW > (@alignwar / 2)) {
      ++$playALW;
      $gameALW = 1;
      my $muie = (@alignwar - 1);
      while ($muie > -1) {
         if ($alignwar[$muie] eq "xx") {
            splice(@alignwar,$muie ,1);
         }
         --$muie;
      }
      if (@alignwar > 1) {
         IRC::chanmsg(join(", ",@alignwar)." advance to round $playALW of the $ThisAlign Battle.");
      }
      RNG::fisher_yates_shuffle( \@alignwar );
   }
   if (@alignwar == 1) {
      if ($Simulation::rps{$alignwar[0]}{alignment} eq "g") {
        IRC::chanmsg(Simulation::clog("$alignwar[0] has won the $ThisAlign Battle! $alignwar[0] received 500 gold, 10 gems and 20 XP ".
            "and a chance to find an item!"));
        $Simulation::rps{$alignwar[0]}{gold} += 500;
        $Simulation::rps{$alignwar[0]}{gems} += 10;
        $Simulation::rps{$alignwar[0]}{experience} += 20;
        Equipment::find_item($alignwar[0]);
      }
      if ($Simulation::rps{$alignwar[0]}{alignment} eq "n") {
        IRC::chanmsg(Simulation::clog("$alignwar[0] has won the $ThisAlign Battle! $alignwar[0] received 250 gold, 5 gems and 10 XP."));
        $Simulation::rps{$alignwar[0]}{gems} += 5;
        $Simulation::rps{$alignwar[0]}{gold} += 250;
        $Simulation::rps{$alignwar[0]}{experience} += 10;
      }
      if ($Simulation::rps{$alignwar[0]}{alignment} eq "e") {
        IRC::chanmsg(Simulation::clog("$alignwar[0] has won the $ThisAlign Battle! $alignwar[0] gets a chance to steal!"));
        Events::evilness($alignwar[0]);
        Events::evilnessOffline($alignwar[0]);
      }
      $Simulation::rps{$alignwar[0]}{alw} += 1;
      $Simulation::rps{$alignwar[0]}{bt} = time() + 86400;
      $alignwartime = time() + 5400 + int(rand(3600));
      undef @alignwar;
   }
    else {
      $alignwartime = time() + 40;
   }
}

sub ab_pit { # pit argument players against each other
    my $u = shift;
    my $opp = shift;
    if ($Simulation::rps{$u}{level} < 25) { return unless rand(4) < 1; }
    my $mysum = int((Equipment::itemsum($u,1)+($Simulation::rps{$u}{upgrade}*100))*($Simulation::rps{$u}{life}/100));
    my $oppsum = int((Equipment::itemsum($opp,1)+($Simulation::rps{$opp}{upgrade}*100))*($Simulation::rps{$opp}{life}/100));
    my $myroll = int(rand($mysum));
    my $opproll = int(rand($oppsum));
    if ($myroll >= $opproll) {
        my $gain = ($opp eq $IRC::primnick)?20:int($Simulation::rps{$opp}{level}/4);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$u}{next});
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has challenged $opp [$opproll/".
                     "$oppsum] in combat and won! ".Simulation::duration($gain)." is ".
                     "removed from $u\'s clock."));
        $Simulation::rps{$u}{next} -= $gain;
                $Simulation::rps{$u}{bwon} += 1;
                $Simulation::rps{$opp}{blost} += 1;
                $Simulation::rps{$u}{bminus} += $gain;
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
        my $csfactor = $Simulation::rps{$u}{alignment} eq "g" ? 50 :
                       $Simulation::rps{$u}{alignment} eq "e" ? 20 :
                       35;
        if (rand($csfactor) < 1 && $opp ne $IRC::primnick) {
            $gain = int(((5 + int(rand(20)))/100) * $Simulation::rps{$opp}{next});
            IRC::chanmsg(Simulation::clog("$u has dealt $opp a Critical Strike! ".
                         Simulation::duration($gain)." is added to $opp\'s clock."));
            $Simulation::rps{$opp}{next} += $gain;
                        $Simulation::rps{$opp}{badd} += $gain;
            IRC::chanmsg("$opp reaches next level in ".Simulation::duration($Simulation::rps{$opp}{next}).
                    ".");
        }
        elsif (rand(25) < 1 && $opp ne $IRC::primnick && $Simulation::rps{$u}{level} > 19) {
            my @items = ("ring","amulet","charm","weapon","helm","tunic","gloves","leggings","shield","boots");
            my $type = $items[rand(@items)];
            if (int($Simulation::rps{$opp}{item}{$type}) > int($Simulation::rps{$u}{item}{$type})) {
                IRC::chanmsg(Simulation::clog("In the fierce battle, $opp dropped his level ".int($Simulation::rps{$opp}{item}{$type})." $type! $u picks ".
                    "it up, tossing his old level ".int($Simulation::rps{$u}{item}{$type})." $type to $opp."));
                my $tempitem = $Simulation::rps{$u}{item}{$type};
                $Simulation::rps{$u}{item}{$type}=$Simulation::rps{$opp}{item}{$type};
                $Simulation::rps{$opp}{item}{$type} = $tempitem;
            }
        }
    }
    else {
        my $gain = ($opp eq $IRC::primnick)?10:int($Simulation::rps{$opp}{level}/7);
        $gain = 7 if $gain < 7;
        $gain = int(($gain/100)*$Simulation::rps{$u}{next});
        IRC::chanmsg(Simulation::clog("$u [$myroll/$mysum] has challenged $opp [$opproll/".
            "$oppsum] in combat and lost! ".Simulation::duration($gain)." is added to $u\'s clock."));
        $Simulation::rps{$u}{next} += $gain;
        $Simulation::rps{$u}{blost} += 1;
        $Simulation::rps{$opp}{bwon} += 1;
        $Simulation::rps{$u}{badd} += $gain;
        IRC::chanmsg("$u reaches next level in ".Simulation::duration($Simulation::rps{$u}{next}).".");
    }
}


1;
