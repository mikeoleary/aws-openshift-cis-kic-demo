# aws-openshift-cis-kic-demo
Setup files for OCP cluster on AWS and deploying CIS, KIC, and a demo app

## Set up of BIG-IP
remember to put the BIG-IP internal NICs in the correct SG
remember to disable source/dest check on internal NIC
remember to check that BIG-IP has AS3 on it
remember to have an admin/password on BIG-IP

## CREATE

### setup of demoapp
cd ../demoapp
oc apply -f namespace.yaml
oc apply -f deployment.yaml
oc apply -f service.yaml
oc apply -f ingress.yaml

### setup of CIS
cd ../cis
oc apply -f secret.yaml
oc apply -f sa.yaml
oc adm policy add-cluster-role-to-user cluster-admin -z bigip-ctlr -n kube-system
oc apply -f rbac.yaml
oc apply -f deployment.yaml
oc apply -f deployment2.yaml

### create KIC
cd ../nginxic
oc apply -f ns-and-sa.yaml
oc apply -f rbac.yaml
oc apply -f default-server-secret.yaml
oc apply -f nginx-config.yaml
oc apply -f deployment.yaml
oc apply -f service.yaml
oc apply -f configmap.yaml

## DELETE

### to delete CIS
cd ../cis
oc delete -f deployment2.yaml
oc delete -f deployment.yaml
oc delete -f rbac.yaml
oc delete -f sa.yaml
oc delete -f secret.yaml

### delete KIC
cd ../nginxic
oc delete -f configmap.yaml
oc delete -f service.yaml
oc delete -f deployment.yaml
oc delete -f nginx-config.yaml
oc delete -f default-server-secret.yaml
oc delete -f rbac.yaml
oc delete -f ns-and-sa.yaml

### delete of demoapp
cd ../demoapp
oc delete -f ingress.yaml
oc delete -f service.yaml
oc delete -f deployment.yaml
oc delete -f namespace.yaml