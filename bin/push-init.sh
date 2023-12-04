#!/bin/bash -ex

env=$1

if [ -z $env ]; then
	echo "Usage: $0 <env>"
	echo " e.g.: $0 dev"
	exit 1
fi

ssh dpsrv@dpsrv-$env bash <<_EOT_
	[ -d .config ] || mkdir .config
_EOT_

scp -r ~/.config/git/ dpsrv@dpsrv-$env:.config/

ssh dpsrv@dpsrv-$env bash <<_EOT_

	cd /mnt/disks/data/opt
	if [ ! -d git-openssl-secrets ]; then
		git clone https://github.com/maxfortun/git-openssl-secrets.git
		cd git-openssl-secrets
		ln -s git-setenv-openssl-secrets-fs.sh git-setenv-openssl-secrets.sh
		cd $OLDPWD
	fi

	[ -d dpsrv ] || mkdir dpsrv
	cd dpsrv
	
	for repo in rc nginx; do
		[ ! -d $repo ] || continue
		git clone https://github.com/dpsrv/$repo.git 
		if grep -q openssl $repo/.gitattributes; then
			cd $repo
			/mnt/disks/data/opt/git-openssl-secret/git-init-openssl-secrets.sh
			cd $OLDPWD
		fi
	done

_EOT_
