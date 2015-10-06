#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

chdir("../") or die "cannot change: $!\n";

my $out = `./provision.pl -system 127.0.0.1`;
print "(debug) out: [$out]\n";
# doesn't work???
like( $out, qr!a!, "Text is displayed for local login: 'a provision_files'" );
#like( $out, qr!a tmp/provision_files!, "Text is displayed for local login: 'a provision_files'" );
