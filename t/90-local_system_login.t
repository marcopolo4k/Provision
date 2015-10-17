#!/usr/bin/perl
# 90 series tests used on a local vm, ssh available on 127.0.0.1
use strict;
use warnings;

use Test::More 'no_plan';

chdir("../") or die "cannot change: $!\n";

# i've seen sometimes sends out to err, so capture both & check error codes
my $out = `./provision.pl -system 127.0.0.1 2>&1` ;
like( $out, qr!a tmp/provision_files!, "Text is displayed for local login: 'a tmp/provision_files'" );
like( `echo $?`, qr/0/, "./provision.pl bash command error code success." );
like( $?, qr/0/, "perl error code is success." );

foreach my $file (qw/.bash_custom .vimrc ssh_key/) {
    like( $out, qr!a tmp/provision_files/$file!, "Text is displayed indicating $file was transferred to local login: 'a tmp/provision_files/$file'" );
}
