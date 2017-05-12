Provision
==========

Script to provision files to linux VM's. Developed on Mac->CentOS.

Similar to puppet etc but this was an attempt to focus on automating the login.

# Usage
Use one or two arguments:
```
provision system_name [username]
(default user is root)
```
~/prov_config/system_plans - list of systems' plans (ls this to look for hostnames)
~/prov_config/files - list of files to include in those plans

## Features
This is mainly designed to get basic environment stuffs over to a newly provisioned VM: 
- Stitch together a bash_custom file.  This let's you have a hierarchy of alias files for 'all VMs' vs 'QA VMs'.  References are automatically added: bash_profile->bash_custom bashrc->bash_custom.
- Copy .vimrc or any file to home directory.
- Insert your ssh key into authorized hosts.

But, it will also:
- Perform search and replace on any file copied.
- Perform the mentioned 'stitching' on any file.
- Run any bash or perl script.
- 'sudo -i' to root if needed (like some local cP OS images).
- show ~everything it does in ~/.provisioned, and you can put files here too.

Features AFAIK, puppet lacks, or difficult to achieve (I welcome msgs pointing me how to do these):
- configure a vm without a network connection out to the internet or some other server
- configure a vm without puppet already running

## Installation
1.) perl modules need to be installed:
```
cpan -i Getopt::Long File::Slurp Net::OpenSSH Config Path::Tiny
```

2.) Install project source (to any dir, but ~ is the example)
```
cd ~
git clone https://github.com/cPMarco/Provision.git
cd ~/Provision
make install
```

3.) set up config files
The system.plans/files look something like (without the '#' comments):
```
[~/prov_config/system_plans]$ cat userme\@demotest.server
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

Examples (everything I use) and Howto's:
https://enterprise.cpanel.net/users/marco/repos/prov_config/browse
https://cpanel.wiki/display/~marco/Provision+Environment+to+CentOS+VM
