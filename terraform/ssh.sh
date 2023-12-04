#!/bin/bash -ex

env=$1
if [ -z "$env" ]; then
	echo "Usage: $0 <env>"
	echo " e.g.: $0 dev"
	exit 1
fi

ip=$(jq -r '.resources[] | select(.type == "google_compute_instance" and.name == "dpsrv").instances[].attributes.network_interface[].access_config[].nat_ip' state/$env.tfstate)

ssh -i secrets/ssh/id_rsa dpsrv@$ip
