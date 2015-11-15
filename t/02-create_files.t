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
my @check_text_array = ( 
    { 'title' => 'SNR for FILE',   'file' => '.vimrc',       'text' => 'cpanel-store' },
    { 'title' => 'SNR for STITCH', 'file' => '.bash_custom', 'text' => 'NewName' }, 
    { 'title' => 'ADD_TO',       'file' => '.bash_custom', 'text' => 'test text in custom file' } 
);
# ensure certain words are in dummy system file
foreach my $feature_first_check ( @check_text_array ) {
    chomp( my $sysfile_check = `grep "$feature_first_check->{'text'}" system.plans/root\@dummy.system` );
    like( $sysfile_check, qr/$feature_first_check->{'text'}/, "dummy system file has $feature_first_check->{'text'} in it, ready for post-tmp check for feature \'$feature_first_check->{'title'}\'" );
}
# ensure those same words are in the files to be shipped
foreach my $feature_second_check ( @check_text_array ) {
    my $words_check = `grep "$feature_second_check->{'text'}"  ./tmp/provision_files/$feature_second_check->{'file'}`;
    like( $words_check, qr/$feature_second_check->{'text'}/, "$feature_second_check->{'file'} has $feature_second_check->{'text'}, so the feature \'$feature_second_check->{'title'}\' works" );
}
