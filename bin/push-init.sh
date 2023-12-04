#!/bin/bash -ex

env=$1

if [ -z $env ]; then
	echo "Usage: $0 <env>"
	echo " e.g.: $0 dev"
	exit 1
fi

ssh dpsrv@dpsrv-$env mkdir .config
scp -r ~/.config/git/ dpsrv@dpsrv-$env:.config/

