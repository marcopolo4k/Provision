#!/usr/bin/perl
use strict;
use warnings;

my $dir_for_files = "$ENV{HOME}/tmp/provision_files";

bash_custom_refs();

system( 'tar', '-C', $ENV{HOME}, '-xvf',
    "$ENV{HOME}/transferred_by_provision_script.tar" );

chomp( my @files = grep { !/^\.*$/ } `ls -a $dir_for_files` );
for my $file (@files) {
    if ( $file =~ /ssh_key/ ) {
        authorize_key($file);
    }
    elsif ( $file =~ /^RUN_BASH_(.*)/ ) {
        system( "sh $dir_for_files/$file" );
    }
    else {    # add non-default files above here
        replace_file( $file, "$ENV{HOME}/" );
    }
}

## subroutines
sub bash_custom_refs {
    my $add_to_startups = <<'EOF';

if [ -f ~/.bash_custom ]; then
        . ~/.bash_custom
fi
EOF
    ensure_bash_custom_ref( '.bashrc',       $add_to_startups );
    ensure_bash_custom_ref( '.bash_profile', $add_to_startups );
}

sub ensure_bash_custom_ref {
    my ( $filename, $add_to_startups ) = @_;
    my $already_has_it = !system( 'grep', '-q', 'bash_custom', $filename );
    if ( !$already_has_it ) {
        open( my $fh, '>>', $filename ) or die "Couldn't open file $!";
        print $fh $add_to_startups;
    }
}

sub replace_file {
    my ( $filename, $location ) = @_;
    my $full_path_dest = "$location/$filename";
    # if file already exists, save as file.bak
    if ( -e $full_path_dest ) {
        system( "cat $full_path_dest >> $full_path_dest.bak" );
    }
    system( 'cp', "$dir_for_files/$filename", $full_path_dest );
}

sub authorize_key {
    my $key_file = shift;
    if ( !-d "$ENV{HOME}/.ssh" ) {
        system( 'mkdir', "$ENV{HOME}/.ssh" );
        system( 'chmod', '700', "$ENV{HOME}/.ssh" );
    }
    system( "cat $dir_for_files/$key_file >> $ENV{HOME}/.ssh/authorized_keys" );
}

## Cleanup
system( 'rm', '-rf', "$dir_for_files" );
system( 'rm', "$ENV{HOME}/transferred_by_provision_script.tar" );
system( 'rm', "$ENV{HOME}/provision_expand.pl" );
