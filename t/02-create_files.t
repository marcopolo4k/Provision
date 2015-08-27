#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

chdir("../") or die "cannot change: $!\n";

chomp( my $dir_grep = `grep dir_for_files provision.pl | head -1` );
$dir_grep =~ /'(.*)'/;
my $dir_for_files = $1;

my $out_local_login = `./provision.pl -system dummy.system -user root -notransfer 2>&1`;
my $qr = "a tmp/provision_files";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );

# make sure dummy file always has vimrc
my $vimrc = `grep cpanel-store system.plans/root\@dummy.system`;
like( $vimrc, qr/cpanel-store/, "vimrc search and replace work since cpanel-store is found" );


