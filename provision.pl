#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Slurp;

my $help;
my $system;
my $user;
my $transfer = 1;
help() if ( @ARGV < 1 or 5 < @ARGV );
GetOptions(
    "system=s" => \$system,
    "user=s"   => \$user,
    "transfer!"   => \$transfer,
    "help"     => \$help
) or die("Error in command line arguments\n");
help() if ( defined $help );
$system = $ARGV[0] if ( ! defined $system );
my $sys_address_for_scp = $system;
if ( ! defined $user || $user eq '' ) {
    if ( defined $ARGV[1] && $ARGV[1] !~ /\./ ) {
        $user = $ARGV[1];
    }else{
        $user = 'root';
    }
}

my $dir_for_files = 'tmp/provision_files';
make_tmp_dir();

set_sysip_prompt() if ( $sys_address_for_scp =~ /(\d{1,3}\.){3}\d{1,3}/ );

unless ( -e "system.plans/${user}\@$system" ){
    $system = 'CPANEL';
}
chomp( my @files = read_file( "system.plans/${user}\@$system" ) );
my @use_ssh_key;
my @use_port;
foreach my $file ( sort @files ) {
    $file =~ s/~/$ENV{HOME}/g;
    if ( $file =~ /\.ssh/ ) {
        system( 'cp', "${file}.pub", "$dir_for_files/ssh_key");
        if ( $file =~ /(.*)\.pub$/ ) {
            $file = $1;
        }
        @use_ssh_key = ( '-i', $file );
    }
    elsif ( $file =~ /port:(\d*)/ ) {
        @use_port = ( '-P', $1 );
    }
    elsif ( $file =~ /bash_custom/ ) {
        my $file_part = read_file( "files/$file" );
        write_file( "$dir_for_files/.bash_custom", {append => 1 }, "\n# $file\n" . $file_part );
    }
    elsif ( $file =~ /(.*):SNR:(.*):(.*)/ ) { # so can't use colons in the regex
        my ( $filename, $search, $replace ) = ( $1, $2, $3 );
        system( "cp files/$filename $dir_for_files/" );
        replace_text_in_file( $dir_for_files, $filename, $search, $replace );
    }
    else { # default files going to user's home dir on destination
        system( "cp files/$file $dir_for_files/" );
    }
}

system( 'tar', '-cvf', 'totransfer.tar', $dir_for_files );
if ( $transfer ) {
    my $place = "${user}\@$sys_address_for_scp";
    system( 'scp', '-q', @use_ssh_key, @use_port, 'totransfer.tar', "$place:transferred_by_provision_script.tar" );
    system( 'scp', '-q', @use_ssh_key, @use_port, 'expand.pl', "$place:provision_expand.pl" );
}


# subroutines
sub make_tmp_dir {
    if ( -d $dir_for_files ) { # transfer will keep this tmp files dir
        system( 'rm', '-rvf', "${dir_for_files}.bak" );
        system( 'mv', '-v', $dir_for_files, "${dir_for_files}.bak" );
    }
    system( 'mkdir', $dir_for_files );
}

sub set_sysip_prompt {
    # TODO: use CPANEL by default if system is an IP address without a system file
    open( my $fh, '>>', "$dir_for_files/.bash_custom" ) or die "Couldn't open file $!";
    print $fh "hostip=$sys_address_for_scp\n";
}

sub replace_text_in_file {
    my ( $dir, $filename, $search, $replace ) = @_;
    use Path::Tiny qw(path);
    my $file = path( "$dir/$filename" );
    my $data = $file->slurp_utf8;
    $data =~ s/$search/$replace/g;
    $file->spew_utf8( $data );
}

sub help {
    print "\nPlease enter one or two arguments:\n";
    print "provision.pl <system_name|ip_address> [username]\n\n";
    print "/system.plans - list of systems' plans\n";
    print "/files - list of files to include in those plans\n\n";
    exit;
}

# cleanup
system( 'rm', '-rf', $dir_for_files ) if ( $transfer );
system( 'rm', '-rf', 'totransfer.tar' ) if ( $transfer );
