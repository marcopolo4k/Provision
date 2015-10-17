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
- it stiches together a bash_custom file, and any file, from smaller files in files directory
- puts a pointer in .bash_profie to .bash_custom
- puts your ssh key on the remote system
- it allows any other random file from files directory to be copied to remote home directory (like .vimrc), and it allows a search and replace on those other random files.

So the system.plans/files look something like:
```
SSH_KEY:~/.ssh/id_rsa
SSH_PORT:602
FILE:a_file_you_want_in_homedir.txt
FILE:.vimrc:SNR:set tags.*:set tags=./tags,tags
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_anotherone:SNR:searching for this:replacing with this
APPEND:.bash_custom:alias tp='top -blah blah' # not done yet - placeholder
RUN_PERL_SCRIPT:do_something_custom.pl # not done yet - placeholder
```
