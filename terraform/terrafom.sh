#!/opt/local/bin/bash -ex

cd $(dirname $0)

action=$1
env=$2
if [ -z "$env" ]; then
	echo "Usage: $0 <action> <env>"
	echo "e.g.: $0 plan dev"
fi

shift 2

function terraform() {
	docker run -it \
		-v $PWD/:/app \
		-w /app \
		-e GOOGLE_APPLICATION_CREDENTIALS=secrets/gcloud/application_default_credentials.json \
		hashicorp/terraform:1.6 \
		"$@"
}

id=$env

TFSTATE_PATH=state
TFSTATE=$TFSTATE_PATH/$id.tfstate
TFSTATE_FILE=-state=$TFSTATE

TFVARS=( common )
TFVARS+=( $env ) 

TFVARS_FILES=( -var-file=secrets/terraform/vars/common.tfvars )
for TFVARS_FILE_NAME in ${TFVARS[@]}; do
	TFVARS_FILE=vars/$TFVARS_FILE_NAME.tfvars
	[ -f $TFVARS_FILE ] || continue
	TFVARS_FILES+=( -var-file=$TFVARS_FILE ) 
done

[ -f secrets/ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -q -N "" -C "$LOGNAME@$HOSTNAME" -f secrets/ssh/id_rsa
[ -d secrets/gcloud ] || $PWD/gcloud.sh auth login

[ -d .terraform ] || terraform init
terraform $action $TFSTATE_FILE ${TFVARS_FILES[@]} "$@"

if git status state/$env.tfstate|grep -q modified; then
	git commit -m updated state/$env.tfstate
	git push
fi
