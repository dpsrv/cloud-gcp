#!/bin/bash -e

env=$1
if [ -z "$env" ]; then
	echo "Usage: $0 <env>"
	echo " e.g.: $0 dev"
	exit 1
fi

ip=$(ip.sh $env)

ssh -i secrets/ssh/id_rsa dpsrv@$ip
