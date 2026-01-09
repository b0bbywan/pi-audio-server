#!/usr/bin/perl
# sudo dnf install perl-MusicBrainz-DiscID

use strict;
use warnings;
use MusicBrainz::DiscID;

# Define the CD-ROM device path
my $device = "/dev/sr0"; # Change this if your device is different

# Create a new DiscID object
my $discid = MusicBrainz::DiscID->new();

# Attempt to read the Disc ID from the device
if ($discid->read($device)) {
	#    print "Disc ID: " . $discid->id() . "\n";
    print $discid->id() . "\n";
} else {
    die "Could not calculate Disc ID: " . $discid->error() . "\n";
}
