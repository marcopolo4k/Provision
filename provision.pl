#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Slurp;
use Net::OpenSSH;

use Data::Dumper::Simple;

my $help;
my $system;
my $user;
my $transfer = 1;
help() if ( @ARGV < 1 or 5 < @ARGV );
GetOptions(
    "system=s"  => \$system,
    "user=s"    => \$user,
    "transfer!" => \$transfer,
    "help"      => \$help
) or die("Error in command line arguments\n");
help() if ( defined $help );
$system = $ARGV[0] if ( !defined $system );
my $sys_address_for_scp = $system;

if ( !defined $user || $user eq '' ) {
    if ( defined $ARGV[1] && $ARGV[1] !~ /\./ ) {
        $user = $ARGV[1];
    }
    else {
        $user = 'root';
    }
}

my $dir_for_files = 'tmp/provision_files';
make_tmp_dir();

set_sysip_prompt() if ( $sys_address_for_scp =~ /(\d{1,3}\.){3}\d{1,3}/ );

unless ( -e "system.plans/${user}\@$system" ) {
    $system = 'CPANEL';
}
chomp( my @lines = read_file("system.plans/${user}\@$system") );
my @use_ssh_key;
my @use_port;
foreach my $line (@lines) {
    $line =~ s/~/$ENV{HOME}/g;
    if ( $line =~ /^SSH_KEY:(.+)/ ) {
        my $ssh_key = $1;
        system( 'cp', "${ssh_key}.pub", "$dir_for_files/ssh_key" );
        if ( $ssh_key =~ /(.*)\.pub$/ ) {    # untested
            $ssh_key = $1;
        }
        @use_ssh_key = ( '-i', $ssh_key );
    }
    elsif ( $line =~ /^SSH_PORT:(\d*)/ ) {
        @use_port = ( '-P', $1 );
    }
    elsif ( $line =~ /bash_custom/ ) {
        my $file_part;
        if ( $line =~ /(.*):SNR:(.*):(.*)/ ) {
            my ( $filename, $search, $replace ) = ( $1, $2, $3 );
            $file_part = read_file("files/$filename");
            $file_part =~ s/$search/$replace/g;
        }
        else {
            $file_part = read_file("files/$line");
        }
        write_file( "$dir_for_files/.bash_custom", { append => 1 }, "\n# $line\n" . $file_part );
    }
    elsif ( $line =~ /(.*):SNR:(.*):(.*)/ ) {    # so can't use colons in the regex
        my ( $filename, $search, $replace ) = ( $1, $2, $3 );
        system( 'cp', "files/$filename", "$dir_for_files/" );
        replace_text_in_file( $dir_for_files, $filename, $search, $replace );
    }
    else {                                       # default files going to user's home dir on destination
        system( 'cp', "files/$line", "$dir_for_files/" );
    }
}

system( 'tar', '-cvf', 'totransfer.tar', $dir_for_files );



if ($transfer) {
    my %opts = (
        'user' => $user,
        'port' => $use_port[1],
        'key_path' => $use_ssh_key[1],
    );
    my $ssh = Net::OpenSSH->new( $sys_address_for_scp, %opts );
    $ssh->error and
      die "Couldn't establish SSH connection: ". $ssh->error;
    $ssh->scp_put( 'totransfer.tar', './transferred_by_provision_script.tar' );
    $ssh->scp_put( 'expand.pl', './provision_expand.pl' );
    $ssh->system( 'perl ./provision_expand.pl' ) or
     die "remote command failed: " . $ssh->error;
}

# tmp dir for backups and testing
sub make_tmp_dir {
    if ( -d $dir_for_files ) {    # transfer will keep this tmp files dir
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
    my $file = path("$dir/$filename");
    my $data = $file->slurp_utf8;
    $data =~ s/$search/$replace/g;
    $file->spew_utf8($data);
}

sub help {
    print "\nPlease enter one or two arguments:\n";
    print "provision.pl <system_name|ip_address> [username]\n\n";
    print "/system.plans - list of systems' plans\n";
    print "/files - list of files to include in those plans\n\n";
    exit;
}

# cleanup
system( 'rm', '-rf', $dir_for_files )   if ($transfer);
system( 'rm', '-rf', 'totransfer.tar' ) if ($transfer);
