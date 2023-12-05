#!/opt/local/bin/bash -e

cd $(dirname $0)/..
RWD=$PWD
cd terraform

action=$1
if [ -z "$action" ]; then
	echo "Usage: $0 <action> [env [flags]]"
	echo "e.g.: $0 plan dev"
fi

shift 

function terraform() {
	docker run -it \
		-v $RWD/:/app/ \
		-w /app/terraform \
		-e GOOGLE_APPLICATION_CREDENTIALS=../secrets/gcloud/application_default_credentials.json \
		hashicorp/terraform:1.6 \
		"$@"
}

if [ -z $1 ]; then
	terraform "$action"
	exit
fi

env=$1
shift

id=$env

TFSTATE_PATH=state
TFSTATE=$TFSTATE_PATH/$id.tfstate
TFSTATE_FILE=-state=$TFSTATE

TFVARS=( common )
TFVARS+=( $env ) 

TFVARS_FILES=( -var-file=../secrets/terraform/vars/common.tfvars )
for TFVARS_FILE_NAME in ${TFVARS[@]}; do
	TFVARS_FILE=vars/$TFVARS_FILE_NAME.tfvars
	[ -f $TFVARS_FILE ] || continue
	TFVARS_FILES+=( -var-file=$TFVARS_FILE ) 
done

[ -f ../secrets/ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -q -N "" -C "$LOGNAME@$HOSTNAME" -f ../secrets/ssh/id_rsa
[ -d ../secrets/gcloud ] || $PWD/gcloud.sh auth login

[ -d .terraform ] || terraform init
terraform $action $TFSTATE_FILE ${TFVARS_FILES[@]} "$@"

if git status state/$env.tfstate|grep -q modified; then
	git commit -m updated state/$env.tfstate
	git push
fi
