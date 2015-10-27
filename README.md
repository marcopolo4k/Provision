Provision
==========

Script to provision files to a new server

# Usage
Enter one or two arguments:
```
provision.pl <system_name> username
```
- /system.plans - list of systems' plans
- /files - list of files to include in those plans

Some basic features: 
- stiches together a bash_custom file, and any file, from smaller files in /files
    .bash_custom is mandatory (blank is ok) for now. for stuff you'd put in bashrc or bash_profile
- puts a pointer in .bash_profie to .bash_custom
- adds your ssh pub key to remote system known_hosts
- it allows any other random file from files directory to be copied to remote home directory (like .vimrc), and it allows a search and replace (SNR) on those other random files.

So the system.plans/files look something like:
```
[~/provision/system.plans]$ cat userme\@demotest.server
SSH_KEY:~/.ssh/id_rsa
SSH_PORT:602
FILE:a_file_you_want_in_homedir.txt
FILE:.vimrc:SNR:set tags.*:set tags=./tags,tags
STITCH_FILES:.bash_custom:bash_custom.02.linux.user
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_custom:bash_custom.anotherone:SNR:searching for this:replacing with this # not really tested
OPENSTACK_SUDO: # cludgy escalate for OS VM's
APPEND:.bash_custom:alias tp='top -blah blah' # not done yet - placeholder
RUN_PERL_SCRIPT:do_something_custom.pl # not done yet - placeholder
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
FILE:cpvmsetup_fast.pl
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
