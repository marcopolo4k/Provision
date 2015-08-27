#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

like( `../provision.pl`, qr/Please enter/, "Help text is displayed if no arguments" );
like( `../provision.pl -h`, qr/Please enter/, "Help text is displayed if -h" );
like( `../provision.pl --h`, qr/Please enter/, "Help text is displayed if --h" );
like( `../provision.pl -help`, qr/Please enter/, "Help text is displayed if -help" );
like( `../provision.pl --help`, qr/Please enter/, "Help text is displayed if --help" );
# this could be brittle
#unlike( `../provision.pl 127.0.0.1`, qr/Please enter/, "Help text is not displayed if no help" );


