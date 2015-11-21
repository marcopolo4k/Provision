Provision
==========

Script to provision files to linux VM's. Developed on Mac->CentOS.

# Usage
Use one or two arguments:
```
./provision.pl system_name [username]
```
- /system.plans - list of systems' plans
- /files - list of files to include in those plans

## Features
This is mainly designed to get basic environment stuffs over to a newly provisioned VM: 
- Stitch together a bash_custom file.  This let's you have a hierarchy of alias files for 'all VMs' vs 'QA VMs'.  References are automatically added: bash_profile->bash_custom bashrc->bash_custom.
- Copy .vimrc or any file to home directory.
- Insert your ssh key into authorized hosts.

But, it will also:
- Perform search and replace on any file copied.
- Perform the mentioned 'stitching' on any file.
- Run any bash script.
- 'sudo -i' to root if needed (like some local cP OS images).

## Installation
perl modules need to be installed:
```
cpan -i Getopt::Long File::Slurp Net::OpenSSH Config Path::Tiny
```

The system.plans/files look something like (without the '#' comments):
```
[~/provision/system.plans]$ cat userme\@demotest.server
SSH_KEY:~/.ssh/id_rsa
SSH_PORT:602
FILE:a_file_you_want_in_homedir.txt
FILE:.vimrc:SNR:set tags.*:set tags=./tags,tags
RUN_BASH_SCRIPT:do_something_custom.sh
STITCH_FILES:.bash_custom:bash_custom.02.linux.user
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_custom:ADD_TO:alias tp='top -blah blah'
STITCH_FILES:.bash_custom:bash_custom.anotherone:SNR:search for this:replace with this # not well tested
ESCALATE_USER:username # Use this with caution: this feature logs in as named user, sudo escalates to root, enables root login. It handles some little-understood cases specific for cP OpenStack VM's, so the logic might be .... confusing.
```

Examples of what I use can be found inside our wiki:
https://cpanel.wiki/display/~marco/Provision+Environment+to+CentOS+VM
