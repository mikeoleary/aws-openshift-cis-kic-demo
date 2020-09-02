#!/bin/bash
#get variables from arguments
TUNNEL_SELF_IP_WITH_MASK=$1

#set variables for script
SELFIP_NAME="internal-self"
PROFILE_NAME="vxlan-mp"
TUNNEL_NAME="openshift_vxlan"
INTERNAL_SELF_IP_WITH_MASK=$(curl -sku admin:bogus -X GET https://localhost/mgmt/tm/net/self/~Common~$SELFIP_NAME | jq .address -r)

#get internal selfip 
read -a strarr <<< $(echo $INTERNAL_SELF_IP_WITH_MASK | tr "/" " ")
INTERNAL_SELF_IP=${strarr[0]}

#error if user does not include TUNNEL_SELF_IP_WITH_MASK
if [ -z "$TUNNEL_SELF_IP_WITH_MASK" ]
then
      echo "\$TUNNEL_SELF_IP_WITH_MASK is empty, please provide this as an argument"; exit 1;
fi

# set up vxlan on BIG-IP
tmsh create net tunnels vxlan $PROFILE_NAME flooding-type multipoint
tmsh create net tunnels tunnel $TUNNEL_NAME key 0 profile $PROFILE_NAME local-address $INTERNAL_SELF_IP
# create selfip for tunnel and allow all ports
tmsh create net self $TUNNEL_SELF_IP_WITH_MASK allow-service all vlan $TUNNEL_NAME
# allow vxlan traffic (port 4789) on selfip
tmsh modify /net self $SELFIP_NAME allow-service add { tcp:4789 }

