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

```
After running provision.pl, log into the new system and run expand.pl
```
Btw, this system is really ugly, expect some syntax to change in the future (ie you shouldn't have to log in to run expand).  But some basic features should stay the same: 
- it puts together bash_profile from smaller files in files directory
- puts your ssh key on the remote system
- it allows any other random file from files directory to be copied to remote home directory (like .vimrc), and it allows a search and replace on those other random files.
```
Here’s an example system file:
```
marco ~/Dropbox/provision/system.plans (master)$ cat root\@CPANEL 
```
~/.ssh/petvms
```
bash_custom.01.linux.root
```
bash_custom.02.linux.user
```
bash_custom.03.services
```
bash_custom.04.qa
```
bash_custom.05.cpanel
```
.vimrc:SNR:set tags.*:set tags=./tags,tags
```
marco ~/Dropbox/provision/system.plans (master)$ 
