#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket;
use IO::Select;
use Data::Dumper;
use Getopt::Long;
use Tie::SubstrHash;
use File::Slurp;
use Encode;
use JSON;
use DBI;
use IdleRPG::Bot;
#use IdleRPG::Constants;
use IdleRPG::Database;
use IdleRPG::Constants ':locations';
use IdleRPG::Constants ':classes';
#require IdleRPG::Database;
use IdleRPG::IRC;
use IdleRPG::RNG;
use IdleRPG::Options;
use IdleRPG::Simulation;
use IdleRPG::Content::Monsters;
use IdleRPG::Content::Dragons;
use IdleRPG::Gameplay::PVE;
use IdleRPG::Gameplay::PVP;
use IdleRPG::Gameplay::Equipment;
use IdleRPG::Gameplay::Events;
use IdleRPG::Gameplay::Level;
use IdleRPG::Gameplay::Store;
use IdleRPG::Gameplay::Quests;
use IdleRPG::Gameplay::World;
use IdleRPG::Gameplay::Tournaments;
my $version = "1.0.0";
$SIG{HUP} = "readconfig";

# Load database
Database::checkdbfile();

#Database::connect();

# Daemonize
Bot::daemonize();

# Connect to Slack IRC gateway
IRC::connect();

# Start up the game loop!
my $buffer;
while (1) {
    my($readable) = IO::Select->select($IRC::sel,undef,undef,0.5);
    if (defined($readable)) {
        my $fh = $readable->[0];
        my $buffer2;
        $fh->recv($buffer2,512,0);
        if (length($buffer2)) {
            $buffer .= $buffer2;
            while (index($buffer,"\n") != -1) {
                my $line = substr($buffer,0,index($buffer,"\n")+1);
                $buffer = substr($buffer,length($line));
                IRC::parse($line);
            }
        }
        else {
            $Simulation::rps{$_}{online}=1 for keys(%IRC::auto_login);
            Database::writejsondb(\%Simulation::rps);

            close($fh);
            $IRC::sel->remove($fh);

            if ($Options::opts{reconnect}) {
                undef(@IRC::queue);
                undef($IRC::sock);
                Bot::debug("Socket closed; Cleared queue. Waiting $Options::opts{reconnect_wait}s to connect.");
                sleep($Options::opts{reconnect_wait});
		IRC::createSocket();

                if (!$IRC::sock) {
                   Bot::debug("Failed to connect to all servers\r\n");
                exit 1;
                }

            }
            else { Bot::debug("Socket closed; disconnected.",1); }
        }
    }
    else { select(undef,undef,undef,1); }
    if ((time()-$IRC::lasttime) >= $Options::opts{self_clock}) { 
       Simulation::rpcheck(); 
    }
}
