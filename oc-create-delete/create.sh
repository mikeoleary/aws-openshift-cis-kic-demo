## Run this script to create OCP resources
### setup of demoapp
cd ../demoapp
oc apply -f namespace.yaml
oc apply -f deployment.yaml
oc apply -f service.yaml
oc apply -f ingress.yaml
### setup of CIS
echo "sleeping 5 seconds" && sleep 5
cd ../cis
oc apply -f secret.yaml
oc apply -f sa.yaml
oc adm policy add-cluster-role-to-user cluster-admin -z bigip-ctlr -n kube-system
oc apply -f rbac.yaml
oc apply -f deployment.yaml
oc apply -f deployment2.yaml
### create KIC
echo "sleeping 5 seconds" && sleep 5
cd ../nginxic
oc apply -f ns-and-sa.yaml
oc apply -f rbac.yaml
oc apply -f default-server-secret.yaml
oc apply -f nginx-config.yaml
oc apply -f deployment.yaml
oc apply -f service-80.yaml
oc apply -f service-443.yaml
oc apply -f service-10254.yaml
oc apply -f configmap.yaml
