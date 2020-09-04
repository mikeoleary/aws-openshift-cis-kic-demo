# aws-openshift-cis-kic-demo
Setup files for OCP cluster on AWS and deploying CIS, KIC, and a demo app. Running through the steps below will deploy a RedHat OpenShift cluster on AWS, a F5 BIG-IP device, and the deployments inside the container environment necessary to expose a demo application.

## Set up of OpenShift cluster
* Run the command ```oc get clusternetwork``` and make a note of the IP range from which pod IP addresses will be assigned. The default is 10.128.0.0/14 so yours may be the same. Make a note of the subnet mask (by default this is /14).
```
# oc get clusternetwork
NAME      CLUSTER NETWORK   SERVICE NETWORK   PLUGIN NAME
default   10.128.0.0/14     172.30.0.0/16     redhat/openshift-ovs-networkpolicy
```
* Edit the file [openshift-setup/f5-bigip-node01.yaml](openshift-setup/f5-bigip-node01.yaml) and change the value of **hostIP** in the last line so that the IP address is the internal SelfIP of the BIG-IP. Example:
```yaml
apiVersion: v1
kind: HostSubnet
metadata:
  name: f5-bigip-node01
  annotations:
    pod.network.openshift.io/fixed-vnid-host: "0"
    pod.network.openshift.io/assign-subnet: "true"
# provide a name for the node that will serve as BIG-IP's entry into the cluster
host: f5-bigip-node01
# The hostIP address will be the BIG-IP interface address routable to the
# OpenShift Origin nodes.
# This address is the BIG-IP VTEP in the SDN's VXLAN.
hostIP: 10.0.2.51
```
* Apply this configuration so that the BIG-IP is assigned a hostubnet from within OpenShift:
```
# cd /openshift-setup
# oc apply -f f5-bigip-node01.yaml
```
* Check to see that the BIG-IP was added to the list of hosts and that it has a hostsubnet assigned with the command ``` oc get hostsubnets ```. Example output below:
```
#oc get hostsubnets
NAME                         HOST                         HOST IP      SUBNET          EGRESS CIDRS   EGRESS IPS
f5-bigip-node01              f5-bigip-node01              10.0.2.51    10.131.2.0/23
ip-10-0-2-183.ec2.internal   ip-10-0-2-183.ec2.internal   10.0.2.183   10.128.2.0/23
ip-10-0-2-24.ec2.internal    ip-10-0-2-24.ec2.internal    10.0.2.24    10.129.0.0/23
ip-10-0-2-251.ec2.internal   ip-10-0-2-251.ec2.internal   10.0.2.251   10.128.0.0/23
ip-10-0-2-73.ec2.internal    ip-10-0-2-73.ec2.internal    10.0.2.73    10.131.0.0/23
ip-10-0-3-100.ec2.internal   ip-10-0-3-100.ec2.internal   10.0.3.100   10.129.2.0/23
ip-10-0-3-97.ec2.internal    ip-10-0-3-97.ec2.internal    10.0.3.97    10.130.0.0/23
```

## Set up of BIG-IP
### Set up the VXLAN tunnel
* Calculate selfIP of the tunnel and the subnet mask.
  * The IP address will be any IP within the subnet range that is assigned to the BIG-IP. In the example above, that is 10.131.2.0/23, so I will choose 10.131.2.100
  * The subnet mask will be that of the cluster network (in this case /14). **The subnet mask is not /23, it is /14,** because we want the tunnel to route all traffic to the entire cluster network range.
* Copy the file [bigip-setup/vxlan-setup.sh](bigip-setup/vxlan-setup.sh) to the BIG-IP, mark it as executable and run it with a single argument, which will be the value of the selfIP of the tunnel. **The script below should be run on BIG-IP after copying the file /bigip-setup/vxlan-setup.sh to the BIG-IP.** 
```
# chmod +x vxlan-setup.sh
# ./vxlan-setup.sh 10.131.2.100/14
```
* Ensure that there are no firewalls blocking traffic between the Internal NIC on F5, and the OpenShift nodes. In the case of this AWS deployment, this means adding the BIG-IP internal NIC to the Security Group that is associated with the OpenShift worker nodes.
* I like to disable source/dest check on internal NIC on BIG-IP
* Check that BIG-IP has AS3 on it. I like to use the latest version of AS3.
* Make a note of the admin/password on BIG-IP

## Files to edit
* You will need to edit the file cis/secret.yaml and use the base64-encoded value of your admin username and password on BIG-IP. Example:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bigip-login
  namespace: kube-system
data:
  username: YWRtaW4=
  password: dXNlYWJldHRlcnBhc3N3b3Jk
```

## CREATE

### setup of demoapp
```
cd ../demoapp
oc apply -f namespace.yaml
oc apply -f deployment.yaml
oc apply -f service.yaml
oc apply -f ingress.yaml
```
### setup of CIS
```
cd ../cis
oc apply -f secret.yaml
oc apply -f sa.yaml
oc adm policy add-cluster-role-to-user cluster-admin -z bigip-ctlr -n kube-system
oc apply -f rbac.yaml
oc apply -f deployment.yaml
oc apply -f deployment2.yaml
```
### create KIC
```
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
```
## DELETE

### delete KIC
```
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
```
### to delete CIS
```
cd ../cis
oc delete -f deployment2.yaml
oc delete -f deployment.yaml
oc delete -f rbac.yaml
oc delete -f sa.yaml
oc delete -f secret.yaml
```
### delete of demoapp
```
cd ../demoapp
oc delete -f ingress.yaml
oc delete -f service.yaml
oc delete -f deployment.yaml
oc delete -f namespace.yaml
```