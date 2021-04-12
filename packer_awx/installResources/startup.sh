#!/usr/bin/env bash
set -e

# Args: podName namespace selector sleepTime
function waitForPod () {
  printf "waiting for $1 pod to indicate ready: "
  while [ "$(kubectl get pods -l=$3 -o jsonpath='{.items[*].status.containerStatuses[0].ready}' -n $2)" != "true" ]; do
    reason=`kubectl get pods -l=$3 -o jsonpath='{.items[*].status.containerStatuses[0].state.waiting.reason}' -n $2`
    if [[ $reason =~ Err.* ]]; then
      message=`kubectl get pods -l=$3 -o jsonpath='{.items[*].status.containerStatuses[0].state.waiting.message}' -n $2`
      printf "\nERR: $1 will not become ready: $reason - $message\n"
      exit 1
    fi
    sleep $4
    printf '.'
  done
  printf 'done!\n'
}

printf '===> Checking base K3s status\n'
waitForPod coredns kube-system k8s-app='kube-dns' 3
waitForPod local-path-provisioner kube-system app='local-path-provisioner' 3
waitForPod traefik kube-system app='traefik' 3

# First create the AWX Operator
printf '\n===> Applying AWX Operator\n'
kubectl apply -f /etc/awx/awx-operator.yaml

printf '\n===> Checking if AWX Operator appears ready\n'
waitForPod awx-operator default name='awx-operator' 3

# Apply the main AWX manifest and the Operator should see it on the next reconcile
printf '\n===> Applying AWX manifest\n'
kubectl apply -f /etc/awx/awx.yaml

printf '\n===> Checking if AWX appears ready\n'
waitForPod awx-postgres default app.kubernetes.io/name='awx-postgres' 3
waitForPod awx default app.kubernetes.io/name='awx' 3

printf '\n\n===> AWX service on port: '
kubectl get services awx-service -o jsonpath='{.spec.ports[0].nodePort}'
printf '\n===> AWX admin password:  '
kubectl get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode

printf '\n\n===> Done!\n'
exit 0