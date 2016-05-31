#!/usr/bin/perl
# 90 series tests used on a local vm, ssh available on 127.0.0.1
use strict;
use warnings;

use Test::More 'no_plan';
use Net::OpenSSH;

chdir("../") or die "cannot change: $!\n";

# i've seen sometimes sends out to err, so capture both & check error codes
my $run_prov_on_local = './provision.pl -v -system 127.0.0.1 2>&1';
diag 'Using ' . $run_prov_on_local;
my $out = `$run_prov_on_local` ;

like( $out, qr!a tmp/provision_files!, "Text is displayed for local login: 'a tmp/provision_files'" );
like( `echo $?`, qr/0/, "./provision.pl bash command error code success." );
like( $?, qr/0/, "perl error code is success." );

chomp( my @file_list_text = `grep ^FILE system.plans/root\@127.0.0.1 | cut -d: -f2` );
unshift @file_list_text, qw/.bash_custom ssh_key zzRUN_BASH_cpvmsetup_fast.sh/;
foreach my $file (@file_list_text) {
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
my $old_cpvmsetup_slow = $ssh->capture("find cpvmsetup_slow.pl -mmin +1 2>&1");
# see prev comments
unlike( $old_cpvmsetup_slow, qr/cpvmsetup_slow.pl$/, "remote system cpvmsetup_slow.pl is not old" );
unlike( $old_cpvmsetup_slow, qr/No such file/, "remote system cpvmsetup_slow.pl exists" );

# going back and forth with how to deal with SNR files. See the commented like below.
#chomp( my @file_list_content = `grep ^FILE system.plans/root\@127.0.0.1 | grep -v SNR | cut -d: -f2` );
chomp( my @file_list_content = `grep ^FILE system.plans/root\@127.0.0.1 | cut -d: -f2` );
foreach my $file (@file_list_content) {
    my $file_contents_remote = $ssh->capture("cat ~/$file 2>&1");
    my $file_contents_local;
    {
        local $/;
        open my $fh, '<', "./files/$file" or die "can't open $file: $!";
        $file_contents_local = <$fh>;
    }
    # going back and forth with how to deal with SNR files.
    #like( $file_contents_local, qr/^\Q$file_contents_remote\E/, "Remote content matches local content for file $file." );
    if ( $file eq '.vimrc' ){
        use Text::Diff;
        my $diff = diff \$file_contents_local, \$file_contents_remote;
        print "Skipping vimrc, here's the diff:\n$diff\n"; 
        next;
    }
    like( $file_contents_local, qr/^\Q$file_contents_remote\E/, "Remote content matches local content for file $file." );
}
