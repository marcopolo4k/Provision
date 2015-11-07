#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

chdir("../") or die "cannot change: $!\n";

chomp( my $dir_grep = `grep dir_for_files provision.pl | head -1` );
$dir_grep =~ /'(.*)'/;
my $dir_for_files = $1;

my $qr = '';
my $out_local_login = `./provision.pl -system dummy.system -user root -notransfer 2>&1`;
$qr = "a tmp/provision_files";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );
$qr = "a tmp/provision_files/.bash_custom";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );
$qr = "a tmp/provision_files/.vimrc";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );
$qr = "a tmp/provision_files/ssh_key";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );
$qr = "a tmp/provision_files/cpvmsetup_slow.pl";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );
$qr = "a tmp/provision_files/cpvmsetup_fast.pl";
like( $out_local_login, qr/$qr/, "Text is displayed for local login: '$qr'" );

# ensure files are saved to tmp dir
my $tar_list = `ls -la tmp/provision_files`;
foreach my $file ( qw/ssh_key .bash_custom .vimrc/ ) {
    like( $tar_list, qr/$file/, "$file was added to ./tmp/provision_files directory" );
}

# checking for words indicating specific functionality works
my %check_text = ( 
    '.vimrc' => 'cpanel-store', # SNR (for FILE)
    '.bash_custom' => 'test text in custom file'  # ADD_TO
);
# ensure certain words are in dummy system file
foreach my $certain_words ( values %check_text ) {
    chomp( my $sysfile_check = `grep "$certain_words" system.plans/root\@dummy.system` );
    like( $sysfile_check, qr/$certain_words/, "dummy system file has $certain_words in it, ready for post-tmp check" );
}
foreach my $file ( keys %check_text ) {
    my $words_check = `grep "$check_text{$file}"  ./tmp/provision_files/$file`;
    like( $words_check, qr/$check_text{$file}/, "$file has $check_text{$file}, so that functionality works" );
}
