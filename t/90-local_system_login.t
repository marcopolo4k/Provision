#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

my $out = `../provision.pl -system 127.0.0.1`;
like( $out, qr/a provision_files/, "Text is displayed for local login: 'a provision_files'" );
