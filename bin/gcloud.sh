#!/opt/local/bin/bash -ex

SWD=$(cd $(dirname $0); pwd)

docker run -it -v $SWD/../secrets/gcloud/:/root/.config/gcloud/ gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine gcloud "$@"

