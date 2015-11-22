#!/usr/bin/perl
package provision;

use strict;
use warnings;
use Getopt::Long;
use File::Slurp qw(read_file write_file);
use Net::OpenSSH;
use Config;
use Path::Tiny qw(path);

my $help;
my $system;
my $sys_address_for_scp;
my $user;
my $sudo_user;
my $sudo_pass;
my $ssh_key         = '';
my $port            = '22';
my $transfer        = 1;
my $default_user    = 1; # try default user before sudo user
my $use_sudo        = 0;
my $tried_sudo      = 0;
my $escalated       = 0;
my $mac_tar_options = '';
my $dir_for_files   = 'tmp/provision_files';

exit main() unless caller();

sub main {
    help() if ( @ARGV < 1 or 5 < @ARGV );
    GetOptions(
        "system=s"  => \$system,
        "user=s"    => \$user,
        "transfer!" => \$transfer,
        "defuser!"  => \$default_user,
        "help"      => \$help
    ) or die("Error in command line arguments\n");
    help() if ( defined $help );
    $system = $ARGV[0] if ( !defined $system );
    $sys_address_for_scp = $system;

    if ( !defined $user || $user eq '' ) {
        if ( defined $ARGV[1] && $ARGV[1] !~ /\./ ) {
            $user = $ARGV[1];
        }
        else {
            $user = 'root';
        }
    }

    make_tmp_dir($dir_for_files); # for backups and unit tests

    set_sysip_prompt() if $sys_address_for_scp =~ /(\d{1,3}\.){3}\d{1,3}/;

    parse_config();

    create_tar_file();

    if ($transfer) { # some testing avoids this
        transfer();
        cleanup();
    }

    return 0
}


sub parse_config {
    print "\nParsing system config file...\n";
    unless ( -e "system.plans/${user}\@$system" ) {
        $system = 'DEFAULT';
    }
    chomp( my @lines = read_file("system.plans/${user}\@$system") );
    foreach my $line (@lines) {
        $line =~ s/~/$ENV{HOME}/g;
        if ( $line =~ /^ESCALATE_USER:(.*)/ ) {
            $sudo_user = $1;
            $use_sudo  = 1;
        }
        elsif ( $line =~ /^SSH_KEY:(.+)/ ) {
            $ssh_key = $1;
            system( 'cp', "${ssh_key}.pub", "$dir_for_files/ssh_key" );
            if ( $ssh_key =~ /(.*)\.pub$/ ) {    # never used unless user messes up, but also not tested
                $ssh_key = $1;
            }
        }
        elsif ( $line =~ /^SSH_PORT:(\d*)/ ) {
            $port = $1;
        }
        elsif ( $line =~ /^FILE:(.*)/ ) {        # warning: can't use colons in the regex
            my $remainder_of_line = $1;
            if ( $remainder_of_line =~ /(.*):SNR:(.*):(.*)/ ) {    # warning: can't use colons in the regex
                my ( $filename, $search, $replace ) = ( $1, $2, $3 );
                file_copy_to_tmp_homedir( $filename, '' );
                replace_text_in_file( $dir_for_files, $filename, $search, $replace );
            }
            else {                                                 # default files going to user's home dir on destination
                file_copy_to_tmp_homedir( $remainder_of_line, '' );
            }
        }
        elsif ( $line =~ /^STITCH_FILES:(.+?):([^:]+)(:(.+))?/ ) {

            # $filename_dest, $filename_local (or a directive), $remainder_of_line
            stitch_file( $1, $2, $4 );
        }
        elsif ( $line =~ /^RUN_BASH_SCRIPT:(.*)/ ) {
            my $filename       = $1;
            my $change_name_to = 'zzRUN_BASH_' . $filename; # scripts to run handled last
            file_copy_to_tmp_homedir( $filename, $change_name_to );
        }
        else {    # should be nothing
            print "The system file has an (improperly|un)labeled entry:\n";
            print "[$line]\n";
            print "Please see docs or label all entries\n";
            help();
        }
    }
}

sub create_tar_file {
    print "\n\nCreating tar of files for transport...\n";
    if ( $Config{osname} =~ /darwin/ ) {
        $mac_tar_options = '--disable-copyfile';
    }
    system( 'tar', $mac_tar_options, '-cvf', 'totransfer.tar', $dir_for_files );
}

sub transfer {
    my %opts = (
        'user'     => $user,
        'port'     => $port,
        'key_path' => $ssh_key,
    );
    my $ssh;
    my $connected;

    if ( $default_user ) {
        print "Logging in with user $user...\n";
        $ssh = Net::OpenSSH->new( $sys_address_for_scp, %opts );
        $ssh->error
            and print "Couldn't establish SSH connection: " . $ssh->error;
        $connected = check_ssh_connection( $user, $ssh );
    }
    if ( ! $connected ) {
        if ($use_sudo) {
            print "\nThe default user couldn't log in, so we'll sudo the workaround.
It's kinda brute, but this will copy all the files as sudo user first, then do it again for root.
This means sudo user will run any custom scripts...\n\n";
            $escalated = escalate( $sudo_user, $sys_address_for_scp, %opts );
            if ($escalated) {
                print "\nNow that root has a key, logging in with $user...\n";
                $ssh = Net::OpenSSH->new( $sys_address_for_scp, %opts );
                $ssh->error
                    and print "Couldn't establish SSH connection: " . $ssh->error;
            }
        }

        if ( ! $escalated ) {
            $ssh = try_input_pass( $sys_address_for_scp, %opts );
        }
        $connected = check_ssh_connection( $user, $ssh );
    }
    if ($connected) {
        transfer_and_expand_files($ssh);
    }
    else {
        die "All SSH attempts failed. Please try again.\n";
    }
}

sub cleanup {
    system(qq{ rm -rf $dir_for_files }) if ($transfer);
    system(q{ rm -rf totransfer.tar })  if ($transfer);
}

sub check_ssh_connection {
    my ( $user_local, $ssh_local ) = @_;

    chomp( my $me = $ssh_local->capture("whoami") );
    $ssh_local->error and
      print "Remote command failed: " . $ssh_local->error . "\n";

    if ( $me eq $user_local ) {
        print "Remote connection was set up properly...\n";
        return 1;
    }
    else {
        print "Remote connection was not set up properly:\n$me\n";
        return 0;
    }
}

sub try_input_pass {
    my ( $sys_address_for_scp, %opts_local ) = @_;

    print "SSH attempt for $opts_local{'user'} failed using the key specified. Let's try using a password:\n";
    delete $opts_local{'key_path'};
    chomp( my $pass = <STDIN> );
    $opts_local{'password'} = $pass;

    print "Logging in with user $opts_local{'user'}...\n";
    my $ssh_local = Net::OpenSSH->new( $sys_address_for_scp, %opts_local );
    if ( $ssh_local->error ) {
        print "Couldn't establish SSH connection: " . $ssh_local->error . "\n";
        return 0;
    }
    else {
        return $ssh_local;
    }
}

sub escalate {
    my ( $sudo_user_local, $sys_address_for_scp, %opts_sudo ) = @_;

    $opts_sudo{'user'} = $sudo_user_local;
    print "Logging in with user $sudo_user_local...\n";
    my $ssh_sudo = Net::OpenSSH->new( $sys_address_for_scp, %opts_sudo );
    my $connected = check_ssh_connection( $sudo_user_local, $ssh_sudo );
    if ( ! $connected ) { # tested, this does produce an error (always? todo) 
        $ssh_sudo = try_input_pass( $sys_address_for_scp, %opts_sudo );
    }
    $connected = check_ssh_connection( $sudo_user_local, $ssh_sudo );
    if ($connected) {
        transfer_and_expand_files($ssh_sudo);

        # standard OpenSSH examples didn't work
        my $cmd = <<"EOF";
sudo -i
cd
pwd
sed -i.bak '/no-agent-forwarding/d' /root/.ssh/authorized_keys
sed -i -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i -e 's/.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
tail -1 /home/$sudo_user_local/.ssh/authorized_keys >> /$user/.ssh/authorized_keys
service sshd reload
exit
exit

EOF
        my @capture = $ssh_sudo->capture( { tty => 1, stdin_data => "$cmd\n" }, '' );
        return 1;
    }
    else {
        print "Sudo user was not able to log in. Moving on...\n";
        return 0;
    }
}

sub transfer_and_expand_files {
    my $ssh = shift;

    print "\nCopying files to destination...\n";
    $ssh->scp_put( 'totransfer.tar', './transferred_by_provision_script.tar' );
    $ssh->scp_put( 'expand.pl',      './provision_expand.pl' );

    print "\nExpanding files on destination...\n";
    $ssh->system( 'perl', './provision_expand.pl' )
        or die "remote command failed: " . $ssh->error;
}

sub make_tmp_dir {
    my $dir_for_files = shift;
    if ( -d $dir_for_files ) {    # transfer will keep this tmp files dir
        system( 'rm', '-rf', "${dir_for_files}.bak" );
        system( 'mv', '-v', $dir_for_files, "${dir_for_files}.bak" );
    }
    system( 'mkdir', $dir_for_files );
}

sub file_copy_to_tmp_homedir {
    my ( $filename, $change_name_to ) = (@_);
    my $new_filename;
    if ( $change_name_to eq '' ) {
        $new_filename = $filename;
    }
    else {
        $new_filename = $change_name_to;
    }
    print "\nAdding $filename to local copy of files for transport...";
    system( 'cp', "files/$filename", "$dir_for_files/$new_filename" );
}

sub set_sysip_prompt {
    open( my $fh, '>>', "$dir_for_files/.bash_custom" )
        or die "At least one .bash_custom system file is required.  Couldn't open file $!";
    print $fh "hostip=$sys_address_for_scp\n";
}

sub replace_text_in_file {
    my ( $dir, $filename, $search, $replace ) = @_;
    my $file = path("$dir/$filename");
    my $data = $file->slurp_utf8;
    $data =~ s/$search/$replace/g;
    $file->spew_utf8($data);
}

sub stitch_file {
    my ( $filename_dest, $filename_local, $remainder_of_line ) = (@_);
    if ( !defined $remainder_of_line || $remainder_of_line =~ /^\s+$/ ) {
        $remainder_of_line = '';
    }
    my $file_part;
    if ( $remainder_of_line =~ /^SNR:/ ) {
        $remainder_of_line =~ /SNR:(.*):(.*)/;
        my ( $search, $replace ) = ( $1, $2 );
        $file_part = read_file("files/$filename_local");
        $file_part =~ s/$search/$replace/g;
    }
    elsif ( $filename_local =~ /^ADD_TO$/ ) {
        $file_part = $remainder_of_line;
    }
    else {
        $file_part = read_file("files/$filename_local");
    }
    write_file( "$dir_for_files/$filename_dest", { append => 1 }, "\n# $filename_local\n" . $file_part );
}

sub help {
    print "\nPlease enter one or two arguments:\n";
    print "provision.pl <system_name|ip_address> [username]\n\n";
    print "/system.plans - list of systems' plans\n";
    print "/files - list of files to include in those plans\n\n";
    print "-nodefuser = no default user - don't try the main username before sudo user\n";
    print "-notransfer = only create files locally and leave them there (for testing)\n\n";
    exit;
}
