## run this script to delete OCP resources

### delete KIC
cd ../nginxic
oc delete -f configmap.yaml
oc delete -f service-80.yaml
oc delete -f service-443.yaml
oc delete -f service-10254.yaml
oc delete -f deployment.yaml
oc delete -f nginx-config.yaml
oc delete -f default-server-secret.yaml
oc delete -f rbac.yaml
oc delete -f ns-and-sa.yaml
### to delete CIS
echo "sleeping 5 seconds" && sleep 5
cd ../cis
oc delete -f deployment2.yaml
oc delete -f deployment.yaml
oc delete -f rbac.yaml
oc delete -f sa.yaml
oc delete -f secret.yaml
### delete of demoapp
echo "sleeping 5 seconds" && sleep 5
cd ../demoapp
oc delete -f ingress.yaml
oc delete -f service.yaml
oc delete -f deployment.yaml
oc delete -f namespace.yaml