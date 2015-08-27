#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

my $help_test = `../provision.pl`;
like($help_test, qr/Please enter/, "Help text is displayed if no arguments");

# not gona test till its better code?
# my $expand_test = `../t/files/0.expand.pl`;
# like($expand_test, qr/Error opening archive/, "expand gives tar error");
