#!/bin/bash -eux

function stride_notification () {
  curl -X POST \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer '$STRIDE_TOKEN'' \
  -d '{"content":[{"attrs":{"collapsible":true,"context":{"icon":{"label":"PrEnvBuilder","url":"https://www.atpress.ne.jp/releases/129565/img_129565_3.jpg"},"text":"Pull Request Triggered Environment"},"description":{"text":"http://'$1'"},"details":[{"lozenge":{"appearance":"success","text":"'$TRAVIS_PULL_REQUEST_BRANCH-$TRAVIS_PULL_REQUEST'"},"title":"K8S NAMESPACE"},{"lozenge":{"appearance":"success","text":"'$TRAVIS_PULL_REQUEST_BRANCH'"},"title":"PR BRANCH"},{"lozenge":{"appearance":"success","text":"'$TRAVIS_PULL_REQUEST'"},"title":"PR ID"}],"link":{"url":"http://'$1'"},"text":"Pullrequestnumber","title":{"text":"Author: '"$AUTHOR_NAME"'","user":{"icon":{"url":"https://pbs.twimg.com/profile_images/916039848301027328/KSMZFYAz_400x400.jpg","label":"SUCCEEDED"}}}},"type":"applicationCard"}],"type":"doc","version":1}' \
  --url $STRIDE_CONVERSATION_URL
}

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install gcloud command
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk

# Setup GKE credentials
echo ${GCLOUD_SERVICE_KEY} | base64 --decode --ignore-garbage > ${HOME}/gcloud-service-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json --project ${GCLOUD_PROJECT}
gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE}

cat manifest.tmpl | \
sed 's/\$DOCKER_REGISTRY'"/$DOCKER_REGISTRY/g" | \
sed 's/\$GCLOUD_PROJECT'"/$GCLOUD_PROJECT/g" | \
sed 's/\$TAG'"/$TAG/g" | \
sed 's/\$NAMESPACE'"/$NAMESPACE/g" | \
kubectl apply -f -

while true; do
  external_ip=`kubectl get services --namespace $NAMESPACE | tail -n1 | awk '{print $4}'`
  echo $external_ip
  if [ $external_ip != "<pending>" ]; then
    stride_notification $external_ip
    break
  fi
  sleep 1
done

sleep 300
kubectl delete namespace $NAMESPACE | true
