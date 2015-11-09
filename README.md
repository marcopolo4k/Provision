Provision
==========

Script to provision files to CentOS VM's

# Usage
Use one or two arguments:
```
./provision.pl system_name [username]
```
- /system.plans - list of systems' plans
- /files - list of files to include in those plans

Features. This is mainly designed to get basic environment stuffs over to a newly provisioned VM: 
- Stitch together a bash_custom file.  The stitching is handy so some parts are universal, while others are specific to one VM.  A reference is put into bash_profile and bashrc to bash_custom.
- Copy .vimrc file.
- Insert your ssh key into authorized hosts.

But, it will also:
- Copy any file you specify over to the home dir
- Perform search and replace on parts of the file
- Run any bash script
- 'sudo -i' to root if needed (like some cP OS images)

Installation.
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
OPENSTACK_SUDO: # cludgy escalate for OpenStack VM's, this will change based on feedback
RUN_BASH_SCRIPT:do_something_custom.sh
STITCH_FILES:.bash_custom:bash_custom.02.linux.user
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_custom:ADD_TO:alias tp='top -blah blah'
STITCH_FILES:.bash_custom:bash_custom.anotherone:SNR:search for this:replace with this # not well tested
```

A couple examples of what I use currently:
```
[~/provision/system.plans]$ cat root\@CPANEL 
SSH_KEY:~/.ssh/petvms
STITCH_FILES:.bash_custom:bash_custom.01.linux.root
STITCH_FILES:.bash_custom:bash_custom.02.linux.user
STITCH_FILES:.bash_custom:bash_custom.03.services
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_custom:bash_custom.04.qa.promptps1
STITCH_FILES:.bash_custom:bash_custom.05.cpanel
STITCH_FILES:.bash_custom:bash_custom.05.cpanel.promptps1
FILE:.vimrc:SNR:set tags.*:set tags=./tags,tags
RUN_BASH_SCRIPT:cpvmsetup_fast.sh
FILE:cpvmsetup_slow.pl
```
```
[~/provision/files]$ cat bash_custom.02.linux.user 
# User
# Linux aliases, variables, and functions

export HISTTIMEFORMAT="%d/%m/%y %T "

alias diff='diff -y --suppress-common-lines'; alias less='\less -IR'; alias grep='grep --color'; 
alias ls='\ls -F --color';
alias lf='echo `\ls -lrt|\tail -1|awk "{print \\$9}"`'; alias lf2='echo `\ls -lrt|\tail -2|awk "{print \\$9}"|head -1`';
alias perms=awk\ \'BEGIN\{dir\=DIR?DIR:ENVIRON[\"PWD\"]\;l=split\(dir\,parts,\"/\"\)\;last=\"\"\;for\(i=1\;i\<l+1\;i++\)\{d=last\"/\"parts\[i\]\;gsub\(\"//\",\"/\",d\)\;system\(\"stat\ --printf\ \\\"Thu\\\t%u\\\t%g\\\t\\\"\ \\\"\"d\"\\\"\;\ echo\ -n\ \\\"\ \\\"\;ls\ -ld\ \\\"\"d\"\\\"\"\)\;last=d\}\}\'
```
