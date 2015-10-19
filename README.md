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
- puts a pointer in .bash_profie to .bash_custom
- adds your ssh pub key to remote system known_hosts
- it allows any other random file from files directory to be copied to remote home directory (like .vimrc), and it allows a search and replace (SNR) on those other random files.

So the system.plans/files look something like:
```
[~/provision/files]$ cat userme\@demotest.server
SSH_KEY:~/.ssh/id_rsa
SSH_PORT:602
FILE:a_file_you_want_in_homedir.txt
FILE:.vimrc:SNR:set tags.*:set tags=./tags,tags
STITCH_FILES:.bash_custom:bash_custom.01.linux.root
STITCH_FILES:.bash_custom:bash_custom.04.qa.alias
STITCH_FILES:.bash_custom:bash_custom.anotherone:SNR:searching for this:replacing with this # untested
APPEND:.bash_custom:alias tp='top -blah blah' # not done yet - placeholder
RUN_PERL_SCRIPT:do_something_custom.pl # not done yet - placeholder
```
