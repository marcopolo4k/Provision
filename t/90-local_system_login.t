#!/usr/bin/perl
# 90 series tests used on a local vm, ssh available on 127.0.0.1
use strict;
use warnings;

use Test::More 'no_plan';
use Net::OpenSSH;

chdir("../") or die "cannot change: $!\n";

# i've seen sometimes sends out to err, so capture both & check error codes
my $out = `./provision.pl -system 127.0.0.1 2>&1` ;
like( $out, qr!a tmp/provision_files!, "Text is displayed for local login: 'a tmp/provision_files'" );
like( `echo $?`, qr/0/, "./provision.pl bash command error code success." );
like( $?, qr/0/, "perl error code is success." );

foreach my $file (qw/.bash_custom .vimrc ssh_key/) {
    like( $out, qr!a tmp/provision_files/$file!, "Text is displayed indicating $file was transferred to local login: 'a tmp/provision_files/$file'" );
}

# login to check stuff
my %opts = (
    'user' => 'root',
    'port' => '2222',
    'key_path' => '/Users/marco/.ssh/petvms',
);
my $ssh = Net::OpenSSH->new( '127.0.0.1', %opts );
$ssh->error and
  die "Couldn't establish SSH connection: ". $ssh->error;

# check files
my $bash_custom_good = '';
my $bash_custom_check = $ssh->capture("find .bash_custom -mmin +1 2>&1");
my $old_bash_custom = $ssh->capture("find .bash_custom -mmin +1 2>&1");
# written positively: If old-file-search replies with filename, then error b/c file is old
unlike( $old_bash_custom, qr/bash_custom$/, "remote system .bash_custom is not older than 1 min" );
# written positively: If file-search doesn't find the file at all, then error
unlike( $old_bash_custom, qr/No such file/, "remote system .bash_custom exists" );
my $old_vimrc = $ssh->capture("find .vimrc -mmin +1 2>&1");
# see prev comments
unlike( $old_vimrc, qr/vimrc$/, "remote system .vimrc is not old" );
unlike( $old_vimrc, qr/No such file/, "remote system .vimrc exists" );
