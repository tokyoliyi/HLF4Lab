#!/bin/bash

source .env
source common.sh


sudo cp -rf network/organizations/fabric-ca "${NFS_DIR}"
helm install ca-orderer helms/hlf-ca \
  -f values/ca-orderer.yaml \
  --set hlfCa.nfs.path="${NFS_DIR}" \
  --set hlfCa.nfs.server="${NFS_SERVER}"
helm install ca-org1 helms/hlf-ca \
  -f values/ca-org1.yaml \
  --set hlfCa.nfs.path="${NFS_DIR}" \
  --set hlfCa.nfs.server="${NFS_SERVER}"
helm install ca-org2 helms/hlf-ca \
  -f values/ca-org2.yaml \
  --set hlfCa.nfs.path="${NFS_DIR}" \
  --set hlfCa.nfs.server="${NFS_SERVER}"
waitForChart "ca-orderer"
waitForChart "ca-org1"
waitForChart "ca-org2"

sleep 2

CA_ORDERER_POD="$(kubectl get pod -l app.kubernetes.io/instance=ca-orderer -o jsonpath="{.items[0].metadata.name}")"
CA_ORG1_POD="$(kubectl get pod -l app.kubernetes.io/instance=ca-org1 -o jsonpath="{.items[0].metadata.name}")"
CA_ORG2_POD="$(kubectl get pod -l app.kubernetes.io/instance=ca-org2 -o jsonpath="{.items[0].metadata.name}")"

kubectl exec "${CA_ORDERER_POD}" -- sh -c "
  . /hlf/fabric-ca/registerEnroll.sh
  createOrderer
  echo \"*** Orderer MSP Finished\"
"

kubectl exec "${CA_ORG1_POD}" -- sh -c "
  . /hlf/fabric-ca/registerEnroll.sh
  createOrg1
  echo \"*** Org1 MSP Finished\"
"

kubectl exec "${CA_ORG2_POD}" -- sh -c "
  . /hlf/fabric-ca/registerEnroll.sh
  createOrg2
  echo \"*** Org2 MSP Finished\"
"
