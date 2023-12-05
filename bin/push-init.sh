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
	set -ex

	[ ! -d /mnt/disks/data/\$LOGNAME ] || exit 0

	sudo mkdir /mnt/disks/data/\$LOGNAME
	sudo chown -R \$LOGNAME:\$LOGNAME /mnt/disks/data/\$LOGNAME
	cd /mnt/disks/data/\$LOGNAME

	git clone https://github.com/maxfortun/docker-scripts.git
	echo 'export PATH="\$PATH:/mnt/disks/data/\$LOGNAME/docker-scripts"' >> ~/.bash_profile

	git clone https://github.com/maxfortun/git-openssl-secrets.git
	cd git-openssl-secrets
	ln -s git-setenv-openssl-secrets-fs.sh git-setenv-openssl-secrets.sh
	cd -
	echo 'export PATH="\$PATH:/mnt/disks/data/\$LOGNAME/git-openssl-secrets"' >> ~/.bash_profile

	mkdir dpsrv
	cd dpsrv
	
	for repo in rc nginx; do
		[ ! -d \$repo ] || continue
		git clone https://github.com/dpsrv/\$repo.git 
		if grep -q openssl \$repo/.gitattributes; then
			cd \$repo
			/mnt/disks/data/\$LOGNAME/git-openssl-secrets/git-init-openssl-secrets.sh
			cd -
		fi
	done

	docker network ls|grep -q dpsrv || docker network create dpsrv

	
	echo 'export DPSRV_HOME=/mnt/disks/data/dpsrv/dpsrv' >> ~/.bash_profile
_EOT_
