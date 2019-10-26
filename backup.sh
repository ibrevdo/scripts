#!/bin/bash

backupdir="/home/mago/Dropbox/backups"

configfiles=(	/etc/inittab
		/etc/slackpkg/mirrors
		/etc/slackpkg/blacklist
		/etc/slackpkg/slackpkgplus.conf
		/etc/httpd/httpd.conf 
		/etc/rc.d/rc.inet1.conf 
		/etc/samba/smb.conf
	    )

root_dotfiles=(	/root/.bashrc
		/root/.vimrc		
	      )

mago_dotfiles=(	/home/mago/.bashrc
		/home/mago/.conkyrc
		/home/mago/.vimrc
		/home/mago/.vim/syntax/
		/home/mago/.vim/colors/
		/home/mago/.vim/after/
		)

for f in ${configfiles[@]}; do
	rsync -avzR  $f $backupdir/system
done

#rsync -avzR --delete /usr/local/share/moin $backupdir/system

mkdir -p $backupdir/system
mkdir -p $backupdir/root_dotfiles
mkdir -p $backupdir/mago_dotfiles/vim

for f in ${root_dotfiles[@]}; do
	new=`echo $f | sed 's/^[^\.]*\.//'`
	rsync -avz  $f $backupdir/root_dotfiles/$new
done

for f in ${mago_dotfiles[@]}; do
	new=`echo $f | sed 's/^[^\.]*\.//'`
	rsync -avz  $f $backupdir/mago_dotfiles/$new
done

chown -R mago:users $backupdir
