#!/opt/local/bin/bash -ex

SWD=$(cd $(dirname $0); pwd)

action=$1
env=$2
if [ -z "$env" ]; then
	echo "Usage: $0 <action> <env>"
	echo "e.g.: $0 plan dev"
fi

shift 2

function terraform() {
	docker run -it \
		-v $SWD/:/app \
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
[ -d secrets/gcloud ] || docker run -it -v secrets/gcloud/:/root/.config/gcloud/ gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine gcloud auth application-default login

[ -d .terraform ] || terraform init
terraform $action $TFSTATE_FILE ${TFVARS_FILES[@]} "$@"

exit
	--entrypoint ash \
	--entrypoint ash \
	#-u $(id -u):$(id -g) \
