#!/bin/bash -eux

function stride_notification () {
  curl -X POST \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer '$STRIDE_TOKEN'' \
  -d '{"content":[{"attrs":{"collapsible":true,"context":{"icon":{"label":"PrEnvBuilder","url":"https://www.atpress.ne.jp/releases/129565/img_129565_3.jpg"},"text":"Pull Request Triggered Environment"},"description":{"text":"http://'$1'"},"details":[{"lozenge":{"appearance":"success","text":"$2"}},{"lozenge":{"appearance":"success","text":"$TRAVIS_PULL_REQUEST_BRANCH"},"title":"PULL REQUEST BRANCH"},{"lozenge":{"appearance":"success","text":"$TRAVIS_PULL_REQUEST"},"title":"PR ID"}],"link":{"url":"http://'$1'"},"text":"Pullrequestnumber","title":{"text":"branch&pullrequest","user":{"icon":{"url":"https://pbs.twimg.com/profile_images/916039848301027328/KSMZFYAz_400x400.jpg","label":"SUCCEEDED"}}}},"type":"applicationCard"}],"type":"doc","version":1}' \
  --url $STRIDE_CONVERSATION_URL
}

cat manifest.tmpl | \
sed 's/\$DOCKER_REGISTRY'"/$DOCKER_REGISTRY/g" | \
sed 's/\$DOCKER_PROJECT'"/$DOCKER_PROJECT/g" | \
sed 's/\$TAG'"/$TAG/g" | \
sed 's/\$NAMESPACE'"/$NAMESPACE/g" | \
kubectl apply -f -

while true; do
  external_ip=`kubectl get services --namespace austin | tail -n1 | awk '{print $4}'`
  echo $external_ip
  if [ $external_ip != "<pending>" ]; then
    stride_notification $external_ip "DEPLOYED"
    break
  fi
  sleep 1
done

sleep 300
kubectl delete namespace $NAMESPACE
